module dlib.parser;

import dlib.core;
import std.string;

/*
 * CREATE TREE mytree;
 * LOAD mytree FROM myfile [COMPRESSED];
 * SET mykey=myvalue[,mykey2=myvalue2]* IN mytree;
 * GET mykey[,mykey2]* FROM mytree [RANGE mykeymax [LIMT mylimit]];
 * DEL mykey[,mykey2]* FROM mytree;
 * INFO FROM mytree;
 * ALL FROM mytree;
 * COMMIT mytree TO myfile [COMPRESSED];
 * DROP mytree;
 * SWAP SERVER oldserver newserver;
 * ELECT SERVER newmaster;
 * EXIT;
 */ 

enum K
{
    PING,
    CREATE,
    LOAD,
    LOAD_C,
    SET,
    GET,
    GET_R,
    GET_R_L,
    DEL,
    INFO,
    ALL,
    COMMIT,
    COMMIT_C,
    EXIT,
    DROP,
    SWAP,
    ELECT,
    OTHER
}

bool is_query(char[] query)
{
    return (query.length > 0 && query[$-1] == ';');
}

int query_kind(char[] query)
{
    if (is_ping(query)) {
        return K.PING;
    } else if (is_create(query))
    {
        return K.CREATE;
    } else if (is_load(query)) {
        return K.LOAD;
    } else if (is_load_compressed(query)) {
        return K.LOAD_C;
    } else if (is_set(query)) {
        return K.SET;
    } else if (is_get(query)) {
        return K.GET;
    } else if (is_get_range(query)) {
        return K.GET_R;
    } else if (is_get_range_limit(query)) {
        return K.GET_R_L;
    } else if (is_del(query)) {
        return K.DEL;
    } else if (is_info(query)) {
        return K.INFO;
    } else if (is_all(query)) {
        return K.ALL;
    } else if (is_commit(query)) {
        return K.COMMIT;
    } else if (is_commit_compressed(query)) {
        return K.COMMIT_C;
    } else if (is_drop(query)) {
        return K.DROP;
    } else if (is_swap(query)) {
        return K.SWAP;
    } else if (is_elect(query)) {
        return K.ELECT;
    } else if (is_exit(query)) {
        return K.EXIT;
    } else {
        return K.OTHER;
    }
}

/*
 * in-memory operations
 */

bool is_all(char[] query)
{
    // ALL FROM mytree;
    return _is_op_well_formed(query, "ALL", 0, "FROM", 2);
}

bool is_create(char[] query)
{
    // CREATE TREE mytree;
    return _is_op_well_formed(query, "CREATE", 0, "TREE", 2);
}

bool is_del(char[] query)
{
    // DEL mykey FROM mytree;
    return _is_op_well_formed(query, "DEL", 1, "FROM", 3);
}

bool is_get(char[] query)
{
    // GET mykey FROM mytree;
    if (_is_op_well_formed(query, "GET", 1, "FROM", 3))
    {
        return _is_legal_get_keyset(split(query," ")[1]);
    }
    return false;
}

bool is_get_range(char[] query)
{
    // GET mykey_lower FROM mytree RANGE mykey_upper;
    if (_is_op_well_formed(query, "GET", 1, "FROM", 5, 3, "RANGE", 5))
    {
        char[][] p = params(query,3);
        char[][] keys = split(p[0],",");
        char[][] keys2 = split(p[4],",");
        if (keys.length == 1 && keys2.length == 1)
        {
            return (_is_legal_key(keys[0]) && _is_legal_key(keys2[0]));
        }
    }
    return false;
}

bool is_get_range_limit(char[] query)
{
    // GET mykey_lower FROM mytree RANGE mykey_upper LIMIT mylimit;
    if (_is_op_well_formed(query, "GET", 1, "FROM", 7, 3, "RANGE", 7, 5, "LIMIT", 7))
    {
        char[][] spl = split(query);
        char[] q = array_join(spl[0..$-2]," ");
        if (is_get_range(format("%s;", q)))
        {
            try {
                int l = cast(int)atoi(spl[$-1]);
                return (l > 0);
            } catch (Exception e) {}
        }
    }
    return false;
}

bool is_info(char[] query)
{
    // INFO FROM mytree;
    return _is_op_well_formed(query, "INFO", 0, "FROM", 2);
}

bool is_set(char[] query)
{
    // SET mykey myvalue IN mytree;
    return _is_op_well_formed(query, "SET", 1, "IN", 3);
}

/*
 * disk manipulations
 */

bool is_commit(char[] query)
{
    // COMMIT mytree TO myfile;
    return _is_op_well_formed(query, "COMMIT", 1, "TO", 3);
}

bool is_commit_compressed(char[] query)
{
    // COMMIT mytree TO myfile COMPRESSED;
    return _is_op_well_formed(query, "COMMIT", 1, "TO", 3, 3, "COMPRESSED", 4);
}

bool is_load(char[] query)
{
    // LOAD mytree FROM myfile;
    return _is_op_well_formed(query, "LOAD", 1, "FROM", 3);
}

bool is_load_compressed(char[] query)
{
    // LOAD mytree FROM myfile COMPRESSED;
    return _is_op_well_formed(query, "LOAD", 1, "FROM", 3, 3, "COMPRESSED", 4);
}

/*
 * other
 */

bool is_drop(char[] query)
{
    // DROP TREE mytree;
    return _is_op_well_formed(query, "DROP", 0, "TREE", 2);
}

bool is_exit(char[] query)
{
    return (query == "EXIT;");
}

bool is_ping(char[] query)
{
    return (query == "PING;");
}

bool is_swap(char[] query)
{
    // SWAP SERVER myoldserver mynewserver;
    return _is_op_well_formed(query, "SWAP", 0, "SERVER", 3);
}

bool is_elect(char[] query)
{
    // ELECT SERVER newmaster;
    return _is_op_well_formed(query, "ELECT", 0, "SERVER", 2);
}

/*
 * params
 */

char[][] params(char[] query, int start)
{
    return split(query[start..$-1]);
}

/*
 * private helpers
 */

private bool _is_legal_get_keyset(char[] keyset)
{
    char[][] keys = split(keyset,",");
    foreach (key; keys)
    {
        if (!_is_legal_key(key))
        {
            return false;
        }
    }
    return true;
}

private bool _is_legal_key(char[] key)
{
    return !array_contains(key,"=");
}

private bool _is_op(char[] query, char[] kind)
{
    return (query.length > kind.length && query[0..kind.length] == kind && query[kind.length..kind.length+1] == " ");
}

private bool _is_op_well_formed(char[] query, char[] kind, int index, char[] goal, int exp_length, 
                                int index_opt = 0, char[] goal_opt = " ", int exp_length_opt = 0,
                                int index_opt2 = 0, char[] goal_opt2 = " ", int exp_length_opt2 = 0)
{
    if (_is_op(query,kind))
    {
        char[][] p = params(query,cast(int)kind.length);
        if (p.length > index && p[index] == goal)
        {
            if (p.length == exp_length)
            {
                return true;
            } else if (p.length == exp_length_opt) {
                return (p.length > index_opt && p[index_opt] == goal_opt);
            } else if (p.length == exp_length_opt2) {
                return (p.length > index_opt2 && p[index_opt2] == goal_opt2);
            }
        }
    }
    return false;
}