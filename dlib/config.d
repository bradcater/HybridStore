module dlib.config;

import dlib.verbal;
import std.string;

/*
 * DISK
 */

char[] CONFIG_FILE = "hybridstore.conf";

/*
 * FUNCTIONS
 */

/**
    Prints an error message to stdout if arg is not recognized.
*/
void arg_error(char[] arg, char[] val)
{
    say(format("Unrecognized value %s for argument %s.", val, arg),VERBOSITY,1);
}

/**
    Returns true if val is on [0,9], false otherwise.
*/
bool numeric_range(char[] val)
{
    return (val == "0" || val == "1" || val == "2" || val == "3" || val == "4" ||
            val == "5" || val == "6" || val == "7" || val == "8" || val == "9");
}

/**
    Returns val as an integer if possible, dephaults otherwise.
*/
int set_numeric_range(char[] val, char[] name, int dephault)
{
    if (numeric_range(val))
    {
        return cast(int)atoi(val);
    } else {
        arg_error(val,name);
        return dephault;
    }
}

/*
 * MEMORY
 */

/**
    Automatically prune the tree on SET if tree.size > MAX_SIZE.
*/
bool AUTO_PRUNE = true;

/**
    The level of compression to use when writing data to file.
    Must be on [0,9].
    Higher compression levels require more time but use less space.
*/
int COMPRESSION_LEVEL = 9;

/**
    The maximum number of nodes before automatically pruning the tree.
*/
int MAX_SIZE = 1000000;

/**
    The keyword for the numeric type.
    For example, if NUMERIC = "FOO", then the key "100" will be treated as a
    string, but the key "FOO(100)" will use the number 100 as the key.
*/
const char[] NUMERIC = "NUMERIC";

/**
    The number of frequent queries to maintain if TRACK_QUERIES is true.
    Tracking more queries requires more time (and space).
*/
int QUERY_COUNT = 10;

/**
    Strictly check tree integrity against the red-black tree representation
    invariant on every SET and DEL if true.
*/
bool STRICT_TREES = true;

/**
    To track common queries.
    Tracking queries will slow query reading.
*/
bool TRACK_QUERIES = true;

/*
 * MESSAGES
 */

/**
    How much info to print to stdout.
    9 is most, 0 is none.
    Must be on [0,9].
*/
int VERBOSITY = 9;

/**
    The bad query message.
    Printed to stdout if a query is ill-formatted (but in an otherwise
    non-specific way).
*/
const char[] BAD_QUERY = "BAD QUERY.";

/**
    The bad query E_GET_KEYS message.
    Printed to stdout if a DEL or GET query has an invalid key(s).
*/
const char[] BAD_QUERY_E_DEL_GET_KEYS = "The given key(s) is invalid.";

/**
    The bad query E_SET_PAIRS message.
    Printed to stdout if a SET query has an invalid key->value pair(s).
*/
const char[] BAD_QUERY_E_SET_PAIRS = "The given key->value pair(s) is invalid.";

/**
    The failure message.
*/
const char[] FAIL = "Failure.";

/**
    The invalid file message.
    Given as a response when a requested input file is not valid.
*/
const char[] INVALID_FILE = "That is not a valid file.";

/**
    The invalid state message.
    Given as a response when the tree enters an invalid state.
*/
const char[] INVALID_STATE = "We are in an invalid state.";

/**
    The invalid tree message.
    Given when a requested tree is not valid.
*/
const char[] INVALID_TREE = "That is not a valid tree.";

/**
    The success message.
    Given when an operation has been successful.
*/
const char[] OK = "Ok.";

/**
    The not ok message.
    Given when something is not successful.
*/
const char[] NOT_OK = "NOT OK.";

/**
    The not found message.
    Given when a key in a GET query is not found.
*/
const char[] NULL = "NULL.";

/**
    The ping response message.
    Given in response to a PING query.
*/
const char[] PONG = "PONG.";

/**
    The unavailable message.
    Given when an instance has become unavailable.
*/
const char[] UNAVAILABLE = "Unavailable.";

/**
    The unimplemented message.
    Given when a query has been given for an unimplemented query type.
*/
const char[] UNIMPLEMENTED = "Unimplemented query type. No action was taken.";

/**
    The unrecognized query message.
    Given when a query (superficially) looks correct but cannot be recognized.
*/
const char[] UNRECOGNIZED = "Query seems well-formed, but it is unrecognized.";

/**
    The welcome message.
    Printed to stdout upon starting HybridStore.
*/
const char[] WELCOME = "Welcome to HybridStore.";

/*
 * NETWORK
 */

/**
    The size of the buffer to allocate to receive messages.
*/
const int BUFFER_SIZE = 16384;

/**
    The default port to use.
*/
ushort PORT = 41111;

/**
    If true, this is the master.
    Only one instance may be master.
*/
bool MASTER = true;

/**
    This server.
*/
char[] SERVER = "localhost";

/**
    The available instances.
    Listing an instance twice has the same effect as doubling its weight.
*/
char[][] SERVER_POOL = ["localhost","localhost:51111","10.0.1.115:51111"];

/**
    The weights to use for distributing keys to instances. An instance with a
    weight of 2 should receive approximately twice as many keys as an instance
    with a weight of 1.
*/
int[] SERVER_WEIGHTS = [2,1,1];

/**
    The dead instances.
*/
int[] DEAD_SERVERS;

/**
    The count of unique instances (since we duplicate them for weighting).
*/
int SERVER_COUNT;

/*
 * SYNTAX
 */

/**
    To make strict checks on input queries.
    This will slow down query parsing markedly.
*/
bool STRICT_SYNTAX = true;

unittest {
    assert(BUFFER_SIZE > 0,"BUFFER_SIZE must be positive.");
    assert(PORT > 0,"PORT must be positive.");
    assert(COMPRESSION_LEVEL > 0 && COMPRESSION_LEVEL < 10,"COMPRESSION_LEVEL must be positive and less than 10.");
    assert(MAX_SIZE > 0,"MAX_SIZE must be positive.");
    assert(QUERY_COUNT >= 0,"QUERY_COUNT must be non-negative.");
    assert(VERBOSITY >= 0 && VERBOSITY < 10,"VERBOSITY must be non-negative and less than 10.");
    assert(numeric_range("5"));
    assert(!numeric_range("apple"));
}
