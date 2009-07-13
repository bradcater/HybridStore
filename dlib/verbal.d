module dlib.verbal;

import std.stdio;

/**
    Write a message to stdout if activelevel is at least as high as
    requiredlevel.
    In general, the levels of verbosity are as follows:
    0 - critical messages
    1 - important warnings
    5 - network messages
    9 - grossly verbose
*/
void say(char[] msg, int activelevel, int requiredlevel)
{
    if (activelevel > requiredlevel)
    {
        writefln(msg);
    }
}
