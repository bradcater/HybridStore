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

void arg_error(char[] arg, char[] val)
{
    say(format("Unrecognized value %s for argument %s.", val, arg),VERBOSITY,1);
}

bool numeric_range(char[] val)
{
    return (val == "0" || val == "1" || val == "2" || val == "3" || val == "4" ||
            val == "5" || val == "6" || val == "7" || val == "8" || val == "9");
}

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

// do auto-prune the tree on SET if the size > MAX_SIZE
bool AUTO_PRUNE = true;

// the level of compression to use
// must be in range [0,9]
int COMPRESSION_LEVEL = 9;

// the maximum number of tree nodes before auto_pruning
int MAX_SIZE = 1000000;

// the name of the numeric type
const char[] NUMERIC = "NUMERIC";

// the number of most frequent queries to maintain
int QUERY_COUNT = 10;

// to track common queries, or not
bool TRACK_QUERIES = true;

/*
 * MESSAGES
 */

// how much info to print to the screen
// 9 is most, 1 is least, 0 is none
int VERBOSITY = 9;

// the bad query message
const char[] BAD_QUERY = "BAD QUERY.";

// the bad query E_GET_KEYS message
const char[] BAD_QUERY_E_DEL_GET_KEYS = "The given key(s) is invalid.";

// the bad query E_SET_PAIRS message
const char[] BAD_QUERY_E_SET_PAIRS = "The given key->value pair(s) is invalid.";

// the failure message
const char[] FAIL = "Failure.";

// the invalid file message
const char[] INVALID_FILE = "That is not a valid file.";

// the invalid state message
const char[] INVALID_STATE = "We are in an invalid state.";

// the invalid tree message
const char[] INVALID_TREE = "That is not a valid tree.";

// the success response message
const char[] OK = "Ok.";

// the not ok message
const char[] NOT_OK = "NOT OK.";

// the not found message
const char[] NULL = "NULL.";

// the ping response message
const char[] PONG = "PONG.";

// the unavailable message
const char[] UNAVAILABLE = "Unavailable.";

// the unimplemented message
const char[] UNIMPLEMENTED = "Unimplemented query type. No action was taken.";

// the unrecognized query message
const char[] UNRECOGNIZED = "Query seems well-formed, but it is unrecognized.";

// the welcome message
const char[] WELCOME = "Welcome to HybridStore.";

/*
 * NETWORK
 */

// the size of the buffer to allocate to receive messages
const int BUFFER_SIZE = 16384;

// the default port to use
ushort PORT = 41111;

// if true, this is the master
bool MASTER = true;

// the servers to use
char[] SERVER = "localhost";
char[][] SERVER_POOL = ["localhost","localhost:51111","10.0.1.115:51111"];
int[] SERVER_WEIGHTS = [2,1,1];
int[] DEAD_SERVERS;

// the count of unique servers (since we duplicate them for weighting)
int SERVER_COUNT;

/*
 * SYNTAX
 */

// to make strict checks on input queries
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
