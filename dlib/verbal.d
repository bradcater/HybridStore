module dlib.verbal;

import std.stdio;

/*
 * Write a message to the screen if the current verbosity is at least as high
 * as it must be.
 * In general, the levels of verbosity are as follows:
 * 0 - critical messages
 * 1 - important warnings
 * 5 - network messages
 * 9 - grossly verbose
 */
void say(char[] msg, int activelevel, int requiredlevel)
{
    if (activelevel >= requiredlevel)
    {
        writefln(msg);
    }
}
