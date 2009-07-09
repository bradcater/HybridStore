module json.d;

import dlib.core;
import std.stdio;
import std.string;

/*
 * If a variable is, e.g., "string", we should cut it to string.
 */
private char[] _chop_string(char[] s)
{
    if (s[0..1] == "\"" && s[$-1..$] == "\"")
    {
        s = s[1..$-1];
    }
    return s;
}

/*
 * Given { "status" : "msg" , "response" : "{ "status" : "msg" , "response" : ... }" },
 * return json["status"] -> "msg" , json["response"] -> "{ "status" : "msg" , "response" : ... }"
 * Do not recurse.
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
            key = strip(s_spl[0]);
            if ([key[0]] == "{")
            {
                key = key[1..$];
            }
            key = _chop_string(key);
            value = s_spl[1];
            if ([value[$-1]] == "}")
            {
                value = value[0..$-1];
            }
            value = _chop_string(value);
            json[key] = value;
        }
    }
    return json;
}

/*
 * Given arr["status"] -> "Ok.", arr["response"] -> "There are 10 nodes.",
 * return {"status":"Ok.","response":"There are 10 nodes."}
 */
char[] encode(char[][char[]] arr, bool wrap_vals = true)
{
    char[] json;
    char[] v;
    char[] v_tmp;
    foreach (key; arr.keys)
    {
        v_tmp = arr[key];
        // make sure it's not a JSON object that we're putting in
        v = (wrap_vals && v_tmp.length > 0 && (v_tmp[0..1] != "{" && v_tmp[$-1..$] != "}")) ? format("\"%s\"", v_tmp) : v_tmp;
        json = format("\"%s\":%s,%s", key, v, json);
    }
    return format("{%s}", json[0..$-1]);
}

/*
 * Given a "JSON" object, return true if the value associated with the given
 * key matches the given value, otherwise false.
 */
bool has_and_is(char[][char[]] json, char[] key, char[] val)
{
    return (has_key(json,key) && json[key] == val);
}

/*
 * Given a "JSON" object, return true if the given key is present, false
 * otherwise.
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
    char[] json = "{\"status\":\"Ok.\",\"response\":{\"key\":\"value\"}}";
    /*
     * TODO: This use of format() is a dirty hack!
     */
    //writefln(decode(json));
    //writefln(format(decode(json)));
    assert(format(decode(json)) == format(a));
    //writefln(encode(a));
    assert(encode(a) == json);
    assert(has_and_is(a,"status","Ok."));
}
