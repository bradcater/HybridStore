module dlib.args;

import dlib.config;
import dlib.core;
import dlib.getconfig;
import dlib.shorttests;
import dlib.stats;
import dlib.verbal;
import std.string;

/*
 * Process all of the command-line arguments along with the conf file.
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
                if (val == "true")
                {
                    AUTO_PRUNE = true;
                } else if (val == "false") {
                    AUTO_PRUNE = false;
                } else {
                    arg_error(c,val);
                }
                break;
            case "compression_level":
                COMPRESSION_LEVEL = set_numeric_range(val,"compression_level",COMPRESSION_LEVEL);
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
            case "mode":
                if (val == "master")
                {
                    MASTER = true;
                } else if (val == "slave") {
                    MASTER = false;
                } else {
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
            case "verbosity":
                VERBOSITY = set_numeric_range(val,"verbosity",VERBOSITY);
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
