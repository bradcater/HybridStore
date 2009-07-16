module json.d;

import dlib.core;
import dlib.rbtree;
import std.stdio;
import std.string;

/**
    Pre-processes the given string according to its sub-functions,
    _chop_single_bracket and _chop_string.
*/
private char[] _chop_all(char[] s)
{
    return _chop_string(_chop_single_bracket(strip(s)));
}

/**
    If a value like {"asdf" or "asdf"}, we want to get rid of the opening or
    closing bracket.
*/
private char[] _chop_single_bracket(char[] s)
{
    if (s[0] == '{' && s[$-1] != '}')
    {
        s = s[1..$];
    } else if (s[0] != '{' && s[$-1] == '}') {
        s = s[0..$-1];
    }
    return s;
}

/**
    Returns s without leading and trailing quotes.
*/
private char[] _chop_string(char[] s)
{
    if (s[0] == '"' && s[$-1] == '"')
    {
        s = s[1..$-1];
    }
    return s;
}

/**
    Given { "status" : "msg" , "response" : "{ "status" : "msg" , "response" : ... }" },
    returns json["status"] -> "msg" ,
       json["response"] -> "{ "status" : "msg" , "response" : ... }"
    Do not recurse.
*/
char[][char[]] decode(char[] j)
{
    char[][char[]] json;
    char[][] spl = splitn(j,",",1);
    char[][] s_spl;
    char[] key;
    char[] value;
    foreach (s; spl)
    {
        s_spl = splitn(s,":",1);
        if (s_spl.length == 2)
        {
            key = _chop_all(s_spl[0]);
            value = _chop_all(s_spl[1]);
            json[key] = value;
        }
    }
    return json;
}

/**
    Given arr["status"] -> "Ok.", arr["response"] -> "There are 10 nodes.",
    returns {"status":"Ok.","response":"There are 10 nodes."}
*/
char[] encode(char[][char[]] arr, bool wrap_vals = true)
{
    char[][] pairs;
    char[] v;
    char[] v_tmp;
    foreach (key; arr.keys)
    {
        v_tmp = arr[key];
        // make sure it's not a JSON object that we're putting in
        v = (wrap_vals && v_tmp.length > 0 && (v_tmp[0] != '{' && v_tmp[$-1] != '}')) ? format("\"%s\"", v_tmp) : v_tmp;
        pairs ~= [format("\"%s\":%s", key, v)];
    }
    return format("{%s}", pairs.join(","));
}

/**
    Returns nodes as JSON.
*/
char[] format_nodes_as_json(Node[] nodes)
{
    char[][] node_info;
    foreach (n; nodes)
    {
        node_info ~= [node_info_short(n)];
    }
    return format("{%s}", node_info.join(","));
}

/**
    Given a "JSON" object, returns true if the value associated with the given
    key matches the given value, false otherwise.
*/
bool has_and_is(char[][char[]] json, char[] key, char[] val)
{
    return (has_key(json,key) && json[key] == val);
}

/**
    Given a "JSON" object, returns true if the given key is present, false
    otherwise.
*/
bool has_key(char[][char[]] json, char[] key)
{
    return array_contains(json.keys,key);
}

unittest {
    char[] x = "\"pants\"";
    char[] y = _chop_string(x);
    assert(y == "pants");
    assert(_chop_string(y) == y);
    char[][char[]] a;
    a["status"] = "Ok.";
    a["response"] = "{\"key\":\"value\"}";    
    char[] json = "{\"response\":{\"key\":\"value\"},\"status\":\"Ok.\"}";
    /*
     * TODO: This use of format() is a dirty hack!
     */
    //writefln(json);
    //writefln(decode(json));
    //writefln(format(decode(json)));
    //writefln(format(a));
    assert(format(decode(json)) == format(a));
    //writefln(encode(a));
    assert(encode(a) == json);
    assert(has_and_is(a,"status","Ok."));
}
