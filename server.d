import dlib.args;
import dlib.attrobj;
import dlib.config;
import dlib.core;
import dlib.file;
import dlib.parser;
import dlib.rbtree;
import dlib.shorttests;
import dlib.stats;
import dlib.verbal;
import std.c.time;
import std.conv;
import std.cstream;
import std.socket;
import std.stream;
import std.string;
import std.thread;
static import dlib.json;
static import dlib.remote;

/*
 * Aggregate a list of keys or key=value pairs into groups by their respective servers.
 */
private string[][char[]] _aggregate_keys(char[][] servers, char[][] keys)
{
    string[][char[]] agg;
    char[][] spl;
    foreach (k; keys)
    {
        spl = split(k,"=");
        // Since key always comes before value, we can always use spl[0].
        agg[dlib.remote.choose_server(servers,spl[0])] ~= [k];
    }
    return agg;
}

/*
 * Turn a list of AttrObjs into a string of key1=value1,key2=value2,...
 */
private char[] _assemble_data(AttrObj[] aobjs)
{
    char[] data;
    foreach (ao; aobjs)
    {
        data = format("%s,%s", ao.joinAttrs("key","value","="), data);
    }
    return data[0..$-1];
}

/*
 * If a key is like NUMERIC(key), then turn it into a double.
 * Otherwise, return double.min.
 */
private double _convert_key(char[] k)
{
    if ((k.length > NUMERIC.length + 2) &&
        (k[0..NUMERIC.length + 1] == format("%s(", NUMERIC)) &&
        (k[$-1..$] == ")"))
    {
        char[] t;
        char[] a = k[NUMERIC.length+1..$-1] ~ [t[0]];
        return cast(double)atoi(a);
    } else {
        return double.min;
    }
}

/*
 * Format a list of Nodes as JSON.
 */
private char[] _format_nodes_as_json(Node[] nodes)
{
    char[] resp;
    foreach (n; nodes)
    {
        resp = format("%s,%s", node_info_short(n), resp);
    }
    if (resp.length > 0)
    {
        resp = resp[0..$-1];
    }
    return format("{%s}", resp);
}

/*
 * Perform an operation on a local tree.
 */
private char[] _perform_local_op(RedBlackTree btree, int kind, char[] key, char[] value = null)
{
    char[] resp = OK;
    double ikey = _convert_key(key);
    switch (kind)
    {
        case K.DEL:
            (ikey is double.min) ? btree.remove(key) : btree.remove(ikey);
            break;
        case K.GET:
            Node n;
            if (ikey is double.min)
            {
                if (key == "MAX")
                {
                    n = btree.max();
                } else if (key == "MIN") {
                    n = btree.min();
                } else {
                    n = btree.search(key);
                }
            } else {
                n = btree.search(ikey);
            }
            resp = node_info_short(n,key,NULL);
            break;
        case K.SET:
            (ikey is double.min) ? btree.add(key,value) : btree.add(ikey,value);
            break;
        default:
            say(INVALID_STATE,VERBOSITY,1);
    }
    return resp;
}

/*
 * Read the recordjar file f and send each bit of information to the appropriate
 * server based on its key.
 * Return a RedBlackTree that will exist locally.
 */
RedBlackTree buildRedBlackTrees(char[][] servers, char[] tree_name, char[] f, bool compress)
{
    // load the data
    AttrObj[] aobjs = gatherObjs(f, compress);
    // split the aos in which servers they belong to
    AttrObj[][char[]] split_aobjs;;
    foreach (ao; aobjs)
    {
        split_aobjs[dlib.remote.choose_server(servers,ao.getAttr("key"))] ~= ao;
    }
    // send the remote data
    char[] query;
    char[] data;
    char[] server;
    for (int i=0; i<servers.length; i++)
    {
        if (!array_contains(DEAD_SERVERS,i))
        {
            server = servers[i];
            if (server != SERVER)
            {
                data = _assemble_data(split_aobjs[server]);
                query = format("SET %s IN %s;", data,tree_name);
                say(format("Sending to %s: %s", server, query),VERBOSITY,5);
                dlib.remote.send_msg(server,query);
            }
        }
    }
    // populate and return my btree
    AttrObj[] my_aobjs = split_aobjs[SERVER];
    RedBlackTree btree = new RedBlackTree();
    char[] key;
    double k;
    foreach(ao; my_aobjs)
    {
        key = ao.getAttr("key");
        k = _convert_key(key);
        (k == double.min) ? btree.add(key,ao.getAttr("value")) : btree.add(k,ao.getAttr("value"));
    }
    return btree;
}

/*
 * Handlers
 * All handlers must return a JSON response.
 */

private char[] _handle_del_get_set(char[][] servers, RedBlackTree btree, char[] tree_name, char[] input, int kind, char[][] p)
{
    char[] command = split(input," ")[0];
    char[] preposition = (kind == K.SET) ? "IN" : "FROM";
    char[][] keys = split(p[0],",");
    string[][char[]] agg = _aggregate_keys(servers,keys);
    char[] resp, sm_resp, s_keys_str;
    char[][] s_keys;
    int server_index;
    foreach (server; agg.keys)
    {
        if (SERVER == server || MASTER)
        {
            server_index = index_of(servers,server);
            if (!array_contains(DEAD_SERVERS,server_index))
            {
                s_keys = agg[server];
                if (server == SERVER)
                {
                    char[] local_resp;
                    char[][] spl;
                    foreach (key; s_keys)
                    {
                        if (kind == K.SET)
                        {
                            spl = split(key,"=");
                            // spl.length != 2 is only possible with strict_syntax off.
                            if (spl.length == 2)
                            {
                                local_resp = _perform_local_op(btree,kind,spl[0],spl[1]);
                            }
                        } else {
                            local_resp = _perform_local_op(btree,kind,key);
                        }
                        resp = format("%s,%s", local_resp, resp);
                    }
                } else {
                    s_keys_str = join(s_keys,",");
                    sm_resp = dlib.remote.send_msg(server,format("%s %s %s %s;", command, s_keys_str, preposition, tree_name));
                    if (sm_resp !is null)
                    {
                        char[][char[]] json_sm_resp = dlib.json.decode(sm_resp);
                        if (dlib.json.has_and_is(json_sm_resp,"status",OK) && dlib.json.has_key(json_sm_resp,"response"))
                        {
                            resp = format("%s,%s", json_sm_resp["response"][1..$-1], resp);
                        }
                    }
                }
            }
        }
    }
    if (resp.length > 0)
    {
        // clear the trailing comma
        resp = resp[0..$-1];
    }
    if (kind == K.GET)
    {
        resp = format("{%s}", resp);
        return dlib.remote.response_as_json(true,resp,false);
    } else {
        return dlib.remote.response_as_json(true);
    }
}

private int _handle_elect(char[] query, Socket a)
{
    // ELECT SERVER newmaster;
    char[][] p = params(query,5);
    char[] server = p[1];
    // if we're the old master, tell the new master to promote itself
    if (MASTER)
    {
        dlib.remote.send_msg(server,query);
    }
    // set master status
    MASTER = (SERVER == server);
    // if we're the new master, tell the slaves
    if (MASTER)
    {
        dlib.remote.send_msg_all(SERVER_POOL,SERVER,query);
    }
    a.send(dlib.remote.response_as_json(true));
    dlib.remote.close_if_alive(a);
    return 0;
}

private char[] _handle_get_r_l(char[][] servers, RedBlackTree btree, char[] tree_name, char[] input, int kind, char[][] p)
{
    char[] resp;
    char[] server;
    int limit = (kind == K.GET_R ? 0 : cast(int)atoi(p[$-1]));
    char[] key = p[0];
    char[] max_key = p[4];
    double ikey = _convert_key(key);
    // get all the local nodes in RANGE first
    Node[] nodes = (ikey is double.min) ? btree.search_range(key,max_key) : btree.search_range(ikey,_convert_key(max_key));
    // if there aren't enough, then try other servers
    int server_index = 0;
    char[] sm_resp;
    if ((limit == 0 || limit > nodes.length) && server_index < SERVER_COUNT)
    {
        server = SERVER_POOL[server_index];
        if (server != SERVER)
        {
            sm_resp = dlib.remote.send_msg(server,input);
            if (sm_resp !is null)
            {
                nodes ~= dlib.remote.nodes_from_response(sm_resp);
            }
        }
        server_index++;
    }
    if (limit > 0 && nodes.length > limit) {
        nodes = nodes[0..limit];
    }
    resp = (nodes.length == 0) ? NULL : _format_nodes_as_json(nodes);
    if (resp)
    {
        char[][char[]] arr;
        arr["status"] = format("\"%s\"", OK);
        arr["response"] = resp;
        resp = dlib.json.encode(arr,false);
    }
    return resp;
}

private char[] _handle_info_all(char[][] servers, RedBlackTree btree, char[] tree_name, char[] input, int kind, char[][] p)
{
    char[] resp;
    char[][] responses;
    if (kind == K.INFO)
    {
        char[] valid_s = btree.isValid() ? OK : NOT_OK;
        Node n = btree.max();
        char[] max = (n is null) ? "-" : n.getData();
        n = btree.min();
        char[] min = (n is null) ? "-" : n.getData();
        char[][char[]] json_arr;
        json_arr["status"] = valid_s;
        json_arr["size"] = format("%s", btree.getSize());
        json_arr["max"] = max;
        json_arr["min"] = min;
        json_arr["common_queries"] = pretty_queries(STATS_COMMON_QUERIES);
        char[][char[]] big_json_arr;
        big_json_arr[SERVER] = dlib.json.encode(json_arr);
        resp = dlib.json.encode(big_json_arr,false)[1..$-1];
    } else {
        Node[] nodes = btree.getNodes();
        resp = _format_nodes_as_json(nodes);
    }
    responses ~= resp;
    char[] sm_resp;
    char[] ss;
    char[][char[]] json;
    if (MASTER)
    {
        for (int i=0; i<SERVER_COUNT; i++)
        {
            if (!array_contains(DEAD_SERVERS,i))
            {
                ss = SERVER_POOL[i];
                if (ss != SERVER)
                {
                    sm_resp = dlib.remote.send_msg(ss,input);
                    if (sm_resp is null)
                    {
                        char[][char[]] r_json;
                        r_json["status"] = UNAVAILABLE;
                        char[][char[]] r_big_json;
                        r_big_json[ss] = dlib.json.encode(r_json);
                        responses ~= dlib.json.encode(r_big_json,false)[1..$-1];
                    } else {
                        json = dlib.json.decode(sm_resp);
                        if (dlib.json.has_and_is(json,"status",OK) && dlib.json.has_key(json,"response"))
                        {
                            responses ~= json["response"][1..$];
                        }
                    }
                }
            }
        }
    }
    if (kind == K.INFO)
    {
        resp = join(responses,",");
        if (MASTER)
        {
            resp = format("{%s}", resp);
        }
        resp = dlib.remote.response_as_json(true,resp,false);
    } else if (kind == K.ALL) {
        // responses is now like [[a,b,c],[a,b,c]],..., so we can't just join them
        // instead, we will strip them, then join them
        resp = "";
        foreach (r; responses)
        {
            if (r.length > 0)
            {
                r = r[1..$-1];
            }
            resp = format("%s,%s", r, resp);
        }
        resp = format("{%s}", resp[0..$-1]);
        resp = dlib.remote.response_as_json(true,resp,false);
    } else {
        say(INVALID_STATE,VERBOSITY,1);
    }
    return resp;
}

/*
 * Respond to a simple input query.
 * If you are MASTER, then you get to decide to do the query or to pass it to another
 * server. All others must do the query.
 */
private int _respond_to_normal_query(char[][] servers, Socket a, char[] input, int kind, RedBlackTree[char[]]* trees)
{
    char[] resp;
    char[][] p;
    char[] tree_name;
    RedBlackTree btree;
    if (kind == K.COMMIT || kind == K.COMMIT_C)
    {
        p = params(input,6);
        tree_name = p[0];
        char[] file_name = p[2];
        if (!(tree_name in *trees))
        {
            resp = dlib.remote.response_as_json(false,INVALID_TREE);
        } else {
            btree = (*trees)[tree_name];
            char[] data;
            Node[] nodes = btree.getNodes();
            Node[] remote_nodes;
            char[] server;
            for (int i=0; i<servers.length; i++)
            {
                if (!array_contains(DEAD_SERVERS,i))
                {
                    server = servers[i];
                    if (server != SERVER)
                    {
                        remote_nodes = dlib.remote.get_remote_nodes(server,tree_name);
                        if (remote_nodes !is null)
                        {
                            nodes ~= remote_nodes;
                        }
                    }
                }
            }
            foreach (n; nodes)
            {
                data = (n.data is null) ?
                    format("%%%%\nkey: NUMERIC(%s)\nvalue: %s\n%s", n.idata, n.getValue(), data) :
                    format("%%%%\nkey: %s\nvalue: %s\n%s", n.data, n.getValue(), data);
            }
            data = format("%s%%%%", data);
            write_file(file_name, data, kind == K.COMMIT_C);
            resp = dlib.remote.response_as_json(true);
        }
    } else {
        p = params(input,3);
        tree_name = (kind == K.GET_R || kind == K.GET_R_L) ? p[2] : p[$-1];
        if (!(tree_name in *trees))
        {
            resp = dlib.remote.response_as_json(false,INVALID_TREE);
        } else {
            char[] server;
            int server_index;
            double ikey;
            btree = (*trees)[tree_name];
            switch (kind)
            {
                case K.DEL, K.GET, K.SET:
                    if (kind == K.DEL || kind == K.SET)
                    {
                        // since we don't need any more info, we can run this
                        // on a seperate thread and avoid I/O problems
                        int f()
                        {
                            _handle_del_get_set(servers,btree,tree_name,input,kind,p);
                            return 0;
                        }
                        Thread action_thread = new Thread(&f);
                        action_thread.run();
                        resp = dlib.remote.response_as_json(true);
                    } else {
                        resp = _handle_del_get_set(servers,btree,tree_name,input,kind,p);
                    }
                    break;
                case K.GET_R, K.GET_R_L:
                    resp = _handle_get_r_l(servers,btree,tree_name,input,kind,p);
                    break;
                case K.INFO, K.ALL:
                    resp = _handle_info_all(servers,btree,tree_name,input,kind,p);
                    break;
                default:
                    resp = dlib.remote.response_as_json(false,UNIMPLEMENTED);
            }
        }
    }
    int size_sent = a.send(resp);
    dlib.remote.close_if_alive(a);
    return 0;
}

private RedBlackTree[char[]] _response_handler(Socket a, char[] query, int kind, RedBlackTree[char[]] trees)
{
    // do the special cases
    switch (kind)
    {
        case K.CREATE:
            synchronized
            {
                if (MASTER)
                {
                    char[][] responses = dlib.remote.send_msg_all(SERVER_POOL,SERVER,query);
                }
                char[][] p = params(query,6);
                char[] tree_name = p[1];
                trees[tree_name] = new RedBlackTree();
                a.send(dlib.remote.response_as_json(true));
                dlib.remote.close_if_alive(a);
            }
            break;
        case K.LOAD, K.LOAD_C:
            synchronized
            {
                // LOAD mytree FROM myfile [COMPRESSED];
                if (MASTER)
                {
                    char[][] p = params(query,4);
                    char[] file_name = p[2];
                    if (std.file.exists(file_name))
                    {
                        char[] tree_name = p[0];
                        RedBlackTree t = buildRedBlackTrees(SERVER_POOL, tree_name, file_name, kind == K.LOAD_C);
                        trees[tree_name] = t;
                        a.send(dlib.remote.response_as_json(true));
                    } else {
                        a.send(dlib.remote.response_as_json(false,INVALID_FILE));
                    }
                }
            }
            dlib.remote.close_if_alive(a);
            break;
        case K.PING:
            int f_ping()
            {
                a.send(dlib.remote.response_as_json(true,PONG));
                dlib.remote.close_if_alive(a);
                return 0;
            }
            Thread response_thread = new Thread(&f_ping);
            response_thread.run();
            break;
        case K.DROP:
            synchronized
            {
                // DROP TREE mytree;
                if (MASTER)
                {
                    char[][] responses = dlib.remote.send_msg_all(SERVER_POOL,SERVER,query);
                }
                char[][] p = params(query,4);
                char[] tree_name = p[1];
                if (tree_name in trees)
                {
                    trees.remove(tree_name);
                    a.send(dlib.remote.response_as_json(true));
                } else {
                    a.send(dlib.remote.response_as_json(false,INVALID_TREE));
                }
            }
            dlib.remote.close_if_alive(a);
            break;
        case K.SWAP:
            // SWAP SERVER myoldserver mynewserver;
            if (MASTER)
            {
                char[][] responses = dlib.remote.send_msg_all(SERVER_POOL,SERVER,query);
            }
            char[][] p = params(query,4);
            int index = index_of(SERVER_POOL,p[1]);
            SERVER_POOL[index] = p[2];
            DEAD_SERVERS = array_remove(DEAD_SERVERS,index);
            a.send(dlib.remote.response_as_json(true));
            dlib.remote.close_if_alive(a);
            break;
        case K.ELECT:
            int f_elect()
            {
                return _handle_elect(query,a);
            }
            Thread response_thread = new Thread(&f_elect);
            response_thread.run();
            break;
        // do the normal queries
        case K.DEL, K.GET, K.GET_R, K.GET_R_L, K.SET, K.COMMIT, K.COMMIT_C, K.INFO, K.ALL:
            int f_normal()
            {
                return _respond_to_normal_query(SERVER_POOL,a,query,kind,&trees);
            }
            Thread response_thread = new Thread(&f_normal);
            response_thread.run();
            break;
        // do the error queries
        case K.E_DEL_GET_KEYS:
            a.send(dlib.remote.response_as_json(false,BAD_QUERY_E_DEL_GET_KEYS));
            dlib.remote.close_if_alive(a);
            break;
        case K.E_SET_PAIRS:
            a.send(dlib.remote.response_as_json(false,BAD_QUERY_E_SET_PAIRS));
            dlib.remote.close_if_alive(a);
            break;
        default:
            a.send(dlib.remote.response_as_json(false,UNRECOGNIZED));
    }
    return trees;
}

void main(char[][] args)
{
    say(WELCOME,VERBOSITY,1);
    say("Processing args...",VERBOSITY,9);
    char[][] args2;
    process_args(args);
    // create the trees array
    RedBlackTree[char[]] trees;
    // create the listener
    say(format("Listening on port %s.", PORT),VERBOSITY,1);
    Socket s = new TcpSocket();
    s.bind(new InternetAddress(PORT));
    // listen forever
    bool go = true;
    while (go)
    {
        s.listen(1);
        Socket a = s.accept();
        char[] query = dlib.remote.collect_input(a);
        say(format("query: \"%s\"", query),VERBOSITY,5);
        if (is_query(query))
        {
            // maintain the query stats
            maintain_queries(query);
            int kind = query_kind(query);
            if (kind == K.EXIT) {
                // kill all other servers first
                if (MASTER)
                {
                    char[][] responses = dlib.remote.send_msg_all(SERVER_POOL,SERVER,query);
                }
                go = false;
                a.send(dlib.remote.response_as_json(true));
                dlib.remote.close_if_alive(a);
            } else {
                trees = _response_handler(a,query,kind,trees);
            }
        } else {
            a.send(dlib.remote.response_as_json(false,BAD_QUERY));
            dlib.remote.close_if_alive(a);
        }
    }
    s.shutdown(SocketShutdown.BOTH);
    s.close();
}
