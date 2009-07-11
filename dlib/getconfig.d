module dlib.getconfig;

import dlib.config;
import dlib.file;
import dlib.verbal;
import std.string;

/**
    Returns an associative array of configuration directives from configfile.
*/
char[][char[]] get_config(char[] configfile)
{
    char[][char[]] config;
    char[][] lines = read_file(configfile);
    char[][] spl;
    foreach (line; lines)
    {
        if (line.length > 0 && line[0..1] != "#")
        {
            spl = split(line,"=");
            if (spl.length == 2)
            {
                config[strip(spl[0])] = strip(spl[1]);
            } else {
                say(format("\"%s\" is not a well-formatted directive.", line),VERBOSITY,1);
            }
        }
    }
    return config;
}
