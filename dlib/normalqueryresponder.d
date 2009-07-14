module dlib.normalqueryresponder;

import dlib.config;
import dlib.core;
import dlib.file;
import dlib.parser;
import dlib.rbtree;
import dlib.stats;
import dlib.verbal;
import std.signals;
import std.string;
import std.thread;
static import dlib.json;
static import dlib.remote;

/**
    Responds to a simple input query.
    If this instance is MASTER, then it decides whether to act on input or to
    pass it to another instance.
    If this instance is not MASTER, it must do the query.
*/
class NormalQueryResponder
{
    void act(char[][] servers, char[] input, int kind, RedBlackTree[char[]]* trees)
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
        emit(resp);
    }
    // Mix in all the code we need to make Foo into a signal
    mixin Signal!(char[]);
}

/**
    Handles DEL, GET, and SET queries.
    Returns a JSON response.
*/
private char[] _handle_del_get_set(char[][] servers, RedBlackTree btree, char[] tree_name, char[] input, int kind, char[][] p)
{
    char[] command = split(input," ")[0];
    char[] preposition = (kind == K.SET) ? "IN" : "FROM";
    char[][] keys = split(p[0],",");
    string[][char[]] agg = dlib.remote.aggregate_keys(servers,keys);
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

/**
    Handles GET_R_L queries.
    Returns a JSON response.
*/
private char[] _handle_get_r_l(char[][] servers, RedBlackTree btree, char[] tree_name, char[] input, int kind, char[][] p)
{
    char[] resp;
    char[] server;
    int limit = (kind == K.GET_R ? 0 : cast(int)atoi(p[$-1]));
    char[] key = p[0];
    char[] max_key = p[4];
    double ikey = convert_key(key);
    // get all the local nodes in RANGE first
    Node[] nodes = (ikey is double.min) ? btree.search_range(key,max_key) : btree.search_range(ikey,convert_key(max_key));
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
    resp = (nodes.length == 0) ? NULL : dlib.json.format_nodes_as_json(nodes);
    if (resp)
    {
        char[][char[]] arr;
        arr["status"] = format("\"%s\"", OK);
        arr["response"] = resp;
        resp = dlib.json.encode(arr,false);
    }
    return resp;
}

/**
    Handles INFO and ALL queries.
    Returns a JSON response.
*/
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
        if (TRACK_QUERIES)
        {
            json_arr["common_queries"] = pretty_queries(STATS_COMMON_QUERIES);
        }
        char[][char[]] big_json_arr;
        big_json_arr[SERVER] = dlib.json.encode(json_arr);
        resp = dlib.json.encode(big_json_arr,false)[1..$-1];
    } else {
        Node[] nodes = btree.getNodes();
        resp = dlib.json.format_nodes_as_json(nodes);
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

/**
    Performs an operation on a local tree.
    Returns the JSON response.
*/
private char[] _perform_local_op(RedBlackTree btree, int kind, char[] key, char[] value = null)
{
    char[] resp = OK;
    double ikey = convert_key(key);
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
