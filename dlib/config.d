module dlib.config;

import dlib.verbal;
import std.string;

/*
 * NETWORK
 */

// the size of the buffer to allocate to receive messages
const int BUFFER_SIZE = 8192;

// the default port to use
ushort PORT = 41111;

// if true, this is the master
bool MASTER = true;

// the servers to use
char[] SERVER = "localhost";
char[][] SERVER_POOL = ["localhost","localhost:51111","10.0.1.115:51111"];
int[] SERVER_WEIGHTS = [2,1,1];
int[] DEAD_SERVERS;

// this is the count of unique servers (since we duplicate them for weighting)
int SERVER_COUNT;

/*
 * MEMORY
 */

// do auto-prune the tree on SET if the size > MAX_SIZE
bool AUTO_PRUNE = true;

// the level of compression to use
// must be in range [0,9]
int COMPRESSION_LEVEL = 9;

// the maximum number of tree nodes before auto_pruning
int MAX_SIZE = 100000;

// the name of the numeric type
const char[] NUMERIC = "NUMERIC";

/*
 * DISK
 */

char[] CONFIG_FILE = "hybridstore.conf";

/*
 * MESSAGES
 */

// how much info to print to the screen
// 9 is most, 1 is least, 0 is none
int VERBOSITY = 9;

// the bad query message
const char[] BAD_QUERY = "BAD QUERY.";

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
