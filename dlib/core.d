module dlib.core;

import std.md5;
import std.string;

/*
 * Everything in this module is something that should be included in D.
 */

bool array_contains(char[] arr, char[] elm)
{
    foreach (a; arr)
    {
        if ([a] == elm)
        {
            return true;
        }
    }
    return false;
}

bool array_contains(char[][] arr, char[] elm)
{
    foreach (a; arr)
    {
        if (a == elm)
        {
            return true;
        }
    }
    return false;
}

bool array_contains(int[] arr, int elm)
{
    foreach (a; arr)
    {
        if (a == elm)
        {
            return true;
        }
    }
    return false;
}

char[] array_join(char[][] arr, char[] sep)
{
    if (arr.length > 0)
    {
        char[] j = arr[0];
        for (int i=1; i<arr.length; i++)
        {
            j ~= format("%s%s", sep, arr[i]);
        }
        return j;
    } else {
        return "";
    }
}

int[] array_remove(int[] arr, int elm)
{
    for (int i=0; i<arr.length; i++)
    {
        if (arr[i] == elm)
        {
            return arr[0..i] ~ arr[i+1..$];
        }
    }
    return arr;
}

int index_of(char[][] arr, char[] elm)
{
    for (int i=0; i<arr.length; i++)
    {
        if (arr[i] == elm)
        {
            return i;
        }
    }
    return -1;
}

char[] md5_hex_digest(char[] a)
{
    ubyte digest[16];
    MD5_CTX context;
    context.start();
    context.update(a);
    context.finish(digest);
    return digestToString(digest);
}

char[][] splitn(char[] str, char[] delim, int n)
{
    if (n <= 0)
    {
        return [str];
    }
    char[] s;
    char[][] x;
    char[] y;
    for (int i=0; i<str.length; i++)
    {
        if (n == 0)
        {
            x ~= [str[i..$]];
            return x;
        }
        s = [str[i]];
        if (s == delim)
        {
            x ~= [y];
            y = "";
            n -= 1;
        } else {
            y ~= s;
        }
    }
    x ~= [y];
    return x;
}
