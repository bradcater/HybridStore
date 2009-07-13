module dlib.args;

import dlib.config;
import dlib.core;
import dlib.getconfig;
import dlib.shorttests;
import dlib.stats;
import dlib.verbal;
import std.string;

/**
    Returns true if val is "true", false if val is "false", dephault otherwise.
    If val is neither "true" nor "false", an error message is written to stdout.
*/
private bool _arg_true_false(char[] c, char[] val, bool dephault)
{
    if (val == "true")
    {
        return true;
    } else if (val == "false") {
        return false;
    } else {
        arg_error(c,val);
        return dephault;
    }
}

/**
    Processes all of the command-line arguments and the conf file.
    If config_file is given, it will be used as the configuration file instead
    of the default configuration file.
    The values of command-line arguments will supercede those found in whichever
    configuration file is used.
*/
void process_args(char[][] args)
{
    char[][char[]] cl_args;
    char[][] spl;
    char[] arg;
    char[] val;
    for (int i=1; i<args.length; i++)
    {
        spl = split(args[i],"=");
        arg = spl[0];
        val = spl[1];
        cl_args[arg] = val;
    }
    bool force_config_file = array_contains(cl_args.keys,"config_file");
    // get configuration directives from file but use command-line vals if given
    char[][char[]] config = force_config_file ? get_config(cl_args["config_file"]) : get_config(CONFIG_FILE);
    bool use_cl;
    foreach (c; config.keys)
    {
        use_cl = (array_contains(cl_args.keys,c) && !force_config_file);
        val = (use_cl) ? cl_args[c] : config[c];
        switch (c)
        {
            case "auto_prune":
                AUTO_PRUNE = _arg_true_false(c,val,AUTO_PRUNE);
                break;
            case "compression_level":
                COMPRESSION_LEVEL = set_numeric_range(val,"compression_level",COMPRESSION_LEVEL);
                break;
            case "master":
                MASTER = _arg_true_false(c,val,MASTER);
                break;
            case "max_size":
                try
                {
                    int x = cast(int)atoi(val);
                    if (x > 0)
                    {
                        MAX_SIZE = x;
                    } else {
                        say(format("%s must be greater than %s.", c, val),VERBOSITY,1);
                    }
                } catch (Exception e) {
                    arg_error(c,val);
                }
                break;
            case "port":
                try
                {
                    ushort p = cast(ushort)atoi(val);
                    PORT = p;
                } catch (Exception e) {
                    arg_error(c,val);
                }
                break;
            case "query_count":
                try
                {
                    int qc = cast(int)atoi(val);
                    QUERY_COUNT = qc;
                } catch (Exception e) {
                    arg_error(c,val);
                }
                break;
            case "server":
                SERVER = val;
                break;
            case "server_pool":
                SERVER_POOL = split(val,",");
                break;
            case "server_weights":
                char[][] sweights = split(val,",");
                if (sweights.length == SERVER_POOL.length)
                {
                    int w;
                    for (int i=0; i<sweights.length; i++)
                    {
                        try
                        {
                            w = cast(int)atoi(sweights[i]);
                            while (w > 1)
                            {
                                SERVER_POOL ~= SERVER_POOL[i];
                                w -= 1;
                            }
                        } catch (Exception e) {
                            say(format("Unrecognized weight %s for server %s with index %s.", sweights[i], SERVER_POOL[i], i),VERBOSITY,1);
                        }
                    }
                }
                break;
            case "strict_syntax":
                STRICT_SYNTAX = _arg_true_false(c,val,STRICT_SYNTAX);
                break;
            case "strict_trees":
                STRICT_TREES = _arg_true_false(c,val,STRICT_TREES);
                break;
            case "track_queries":
                TRACK_QUERIES = _arg_true_false(c,val,TRACK_QUERIES);
                break;
            case "verbosity":
                // We want to add 1 here so that when we test for sufficiently
                // high verbosity in verbal.say(), we can test with >, not >=.
                VERBOSITY = set_numeric_range(val,"verbosity",VERBOSITY) + 1;
                break;
            default:
                say(format("Unrecognized configuration directive \"%s = %s\".", c, config[c]),VERBOSITY,1);
        }
    }
    // check errors
    if (!array_contains(SERVER_POOL,SERVER))
    {
        say(format("You must add this server (%s) to the server pool %s.", SERVER, SERVER_POOL),VERBOSITY,1);
    }
    // set the server count
    bool[char[]] unique_servers;
    foreach (server; SERVER_POOL)
    {
        unique_servers[server] = true;
    }
    SERVER_COUNT = cast(int)unique_servers.length;
}
