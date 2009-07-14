/*
----------------------------------------------------------------------
Libraries have been installed in:
   /usr/local/lib

If you ever happen to want to link against installed libraries
in a given directory, LIBDIR, you must either use libtool, and
specify the full pathname of the library, or use the `-LLIBDIR'
flag during linking and do at least one of the following:
   - add LIBDIR to the `LD_LIBRARY_PATH' environment variable
     during execution
   - add LIBDIR to the `LD_RUN_PATH' environment variable
     during linking
   - use the `-Wl,--rpath -Wl,LIBDIR' linker flag
   - have your system administrator add LIBDIR to `/etc/ld.so.conf'

See any operating system documentation about shared libraries for
more information, such as the ld(1) and ld.so(8) manual pages.
----------------------------------------------------------------------
*/
import dlib.args;
import dlib.attrobj;
import dlib.config;
import dlib.core;
import dlib.file;
import dlib.normalqueryresponder;
import dlib.observer;
import dlib.parser;
import dlib.rbtree;
import dlib.shorttests;
import dlib.stats;
import dlib.verbal;
import ev.c;
import std.c.time;
import std.conv;
import std.cstream;
import std.stdio;
import std.socket;
import std.stream;
import std.string;
import std.thread;
static import dlib.remote;

RedBlackTree[char[]] trees;
TcpSocket listener;

/**
    Reads the recordjar file f and send each bit of information to the
    appropriate instance.
    Returns a RedBlackTree that will exist locally.
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
                data = dlib.remote.assemble_data(split_aobjs[server]);
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
        k = convert_key(key);
        (k == double.min) ? btree.add(key,ao.getAttr("value")) : btree.add(k,ao.getAttr("value"));
    }
    return btree;
}

/*
 * Handlers
 * All handlers must return a JSON response.
 */

/**
    Handles ELECT queries.
    Returns 0.
*/
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

/**
    The main loop for handling queries.
    Returns an associative array of RedBlackTrees keyed by name.
    Synchronization on trees should take place only in this function.
*/
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
            Observer ob = new Observer(a);
            NormalQueryResponder nqr = new NormalQueryResponder();
            nqr.connect(&ob.watch);
            nqr.act(SERVER_POOL,query,kind,&trees);
            // return _respond_to_normal_query(SERVER_POOL,query,kind,&trees);
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

/**
    Maintain the list of common queries.
    Use a separate thread to keep from blocking the response thread.
*/
private void _sync_maintain_queries(char[] query)
{
    int f_queries()
    {
    synchronized
    {
            maintain_queries(query);
            return 0;
        }
    }
    Thread queries_thread = new Thread(&f_queries);
    queries_thread.run();
}

extern (C)
{
    static void libev_cb(ev_loop_t *loop, ev_io *w, int revents)
    {
        callback(loop,w);
    }
}

void callback(ev_loop_t *loop, ev_io *w)
{
    Socket a = listener.accept();
    char[] query = dlib.remote.collect_input(a);
    say(format("query: \"%s\"", query),VERBOSITY,5);
    if (is_query(query))
    {
        // maintain the query stats
        if (TRACK_QUERIES)
        {
            _sync_maintain_queries(query);
        }
        int kind = query_kind(query);
        if (kind == K.EXIT) {
            // kill all other servers first
            if (MASTER)
            {
                char[][] responses = dlib.remote.send_msg_all(SERVER_POOL,SERVER,query);
            }
            a.send(dlib.remote.response_as_json(true));
            dlib.remote.close_if_alive(a);
            ev_io_stop(loop, w);
            ev_unloop(loop, EVUNLOOP_ONE);
            listener.shutdown(SocketShutdown.BOTH);
            listener.close();
        } else {
            trees = _response_handler(a,query,kind,trees);
        }
    } else {
        a.send(dlib.remote.response_as_json(false,BAD_QUERY));
        dlib.remote.close_if_alive(a);
    }
}

/**
    The entrance to HybridStore.
*/
void main(char[][] args)
{
    say(WELCOME,VERBOSITY,1);
    say("Processing args...",VERBOSITY,9);
    char[][] args2;
    process_args(args);
    // create the listener
    listener = new TcpSocket();
    listener.blocking(false);
    listener.bind(new InternetAddress(HSPORT));
    listener.listen(1);
    say(format("Listening on port %s.", HSPORT),VERBOSITY,1);
    // Listen forever (until we decide to stop).
    // Start libev
    ev_loop_t* loop = ev_default_loop(0);
    ev_io io_watcher;
    ev_io_init(&io_watcher, &libev_cb, listener.handle(), EV_READ);
    ev_io_start(loop, &io_watcher);
    ev_loop(loop, 0);
}
