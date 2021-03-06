module dlib.remote;

import dlib.attrobj;
import dlib.config;
import dlib.core;
import dlib.rbtree;
import dlib.shorttests;
import dlib.verbal;
import std.socket;
import std.socketstream;
import std.stdio;
import std.string;

/**
    Returns an aggregated list of keys or key=value pairs into groups by their
    respective instances.
*/
string[][char[]] aggregate_keys(char[][] servers, char[][] keys)
{
    string[][char[]] agg;
    char[][] spl;
    foreach (k; keys)
    {
        spl = split(k,"=");
        // Since key always comes before value, we can always use spl[0].
        agg[choose_server(servers,spl[0])] ~= [k];
    }
    return agg;
}

/**
    Returns a string of key1=value1,key2=value2,...
*/
char[] assemble_data(AttrObj[] aobjs)
{
    char[][] ao_strs;
    foreach (ao; aobjs)
    {
        ao_strs ~= [ao.joinAttrs("key","value","=")];
    }
    return ao_strs.join(",");
}

/**
    Closes a if it is not already closed.
*/
void close_if_alive(Socket a)
{
    if (a.isAlive())
    {
        a.shutdown(SocketShutdown.BOTH);
        a.close();
    }
}

/**
    Returns a numeric hash for the given string.
*/
private int _hash(char[] s, int sofar=0)
{
    return (s.length == 0) ? sofar : _hash(s[1..$], sofar * 11 + s[0]);
}

/**
    Returns one member of servers by hashing key.
*/
char[] choose_server(char[][] servers, char[] key)
{
    return servers[choose_server_index(servers,key)];
}

/**
    Returns an index of servers to which key must map.
*/ 
int choose_server_index(char[][] servers, char[] key)
{
    int sum = _hash(key) % SERVER_COUNT;
    // deal with dead servers
    while (array_contains(DEAD_SERVERS,sum))
    {
        sum = (sum + 1) % SERVER_COUNT;
    }
    return sum;
}

/**
    Returns the data read from s.
*/
char[] collect_input(Socket s)
{
    //char buff[BUFFER_SIZE];
    ubyte[BUFFER_SIZE] buff;
    char[] r;
    char[] ext;
    int size_received;
    SocketStream ss = new SocketStream(s);
    while ((size_received = ss.read(buff)) > 0)
    {
        ext = cast(char[])buff[0..size_received];
        r ~= ext;
        if (ext[$-1] == ';')
        {
            return r;
        }
    }
    return r;
}

/**
    Returns a list of Nodes generated from the JSON output from server.
*/
Node[] get_remote_nodes(char[] server, char[] tree_name)
{
    char[] query = format("ALL FROM %s;", tree_name);
    char[] response = dlib.remote.send_msg(server, query);
    return (response == NULL) ? null : nodes_from_response(response);
}

/**
    Returns a list of Nodes generated from response (JSON).
*/
Node[] nodes_from_response(char[] response)
{
    Node[] nodes;
    if (response.length > 2)
    {
        /*
         * TODO: I can't get this to fire. When is it called?
         * It should be used in GET_R in server.d, but it never appears.
         */
        writefln("nodes_from_response response: %s", response);
        response = response[1..$-2];
        char[][] spl = split(response,"},{");
        char[][] spl_n;
        char[] key;
        char[] data;
        for (int i=0; i<spl.length; i++)
        {
            spl_n = split(spl[i],"\",\"");
            key = split(spl_n[0],":\"")[1];
            data = split(spl_n[1],":\"")[1][0..$-2];
            nodes ~= (new Node(key,data));
        }
    }
    return nodes;
}

/**
    Returns a string (JSON) response formatted with status and (possibly)
    response attributes.
*/
char[] response_as_json(bool success, char[] response = null, bool wrap_response = true)
{
    char[] r = format("\"status\":\"%s\"", ((success) ? OK : FAIL));
    if (response)
    {
        r = (wrap_response) ? format("%s,\"response\":\"%s\"", r, response) : format("%s,\"response\":%s", r, response);
    }
    return format("{%s}", r);
}

/**
    Sends msg to address.
    Returns the response.
*/
char[] send_msg(char[] address, char[] msg)
{
    Socket s = new TcpSocket();
    char[][] spl = split(address,":");
    char[] a = spl[0];
    ushort p;
    if (spl.length == 1)
    {
        p = HSPORT;
    } else {
        p = cast(ushort)atoi(spl[1]);
    }
    try
    {
        s.connect(new InternetAddress(a,p));
        say(format("sending \"%s\" to %s:%s", msg, a, p),VERBOSITY,3);
        s.send(msg);
        char[BUFFER_SIZE] buff;
        int size_received = s.receive(buff);
        s.shutdown(SocketShutdown.BOTH);
        s.close();
        char[] c;
        return buff[0..size_received] ~ c[0..0];
    } catch (Exception e) {
        DEAD_SERVERS ~= [index_of(SERVER_POOL,address)];
        return null;
    }
}

/**
    Sends msg to each member of (servers - exclude).
*/
char[][] send_msg_all(char[][] servers, char[] exclude, char[] msg)
{
    char[][] responses;
    foreach (server; servers)
    {
        if (server != exclude)
        {
            responses ~= [send_msg(server,msg)];
        }
    }
    return responses;
}

unittest {
    //Node[] nodes = nodes_from_response("[{\"key1\":\"value1\"},{\"key2\":\"value2\"}]");
    //writefln(format(nodes));
    //Node[] nodes_from_response(char[] response)
    assert(response_as_json(true) == "{\"status\":\"Ok.\"}");
    assert(response_as_json(false,BAD_QUERY) == "{\"status\":\"Failure.\",\"response\":\"BAD QUERY.\"}");
}
