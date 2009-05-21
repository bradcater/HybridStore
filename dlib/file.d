module dlib.file;

import dlib.config;
import std.stdio;
import std.stream;
import std.string;
static import std.file;
static import std.zlib;

string[] read_file(char[] f, bool compress = false)
{
    if (std.file.exists(f) != 0)
    {
        char[] data;
        if (compress)
        {
            ubyte[] src = cast(ubyte[])std.file.read(f);
            data = z_decompress(src);
        } else {
            data = cast(char[])std.file.read(f);
        }
        return split(data,"\n");
    } else {
        string[] x;
        return x;
    }
}

void write_file(char[] f, char[] data, bool compress = false)
{
    if (std.file.exists(f) != 0)
    {
        std.file.remove(f);
    }
    if (compress)
    {
        ubyte[] compressed = z_compress(data);
        std.file.write(f,compressed);
    } else {
        std.file.write(f,data);
    }
}

ubyte[] z_compress(char[] data)
{
    ubyte[] beforeCompression = cast(ubyte[])data;
    return cast(ubyte[])std.zlib.compress(cast(void[])beforeCompression,COMPRESSION_LEVEL);
}

char[] z_decompress(ubyte[] src)
{
    ubyte[] afterDecompression = cast(ubyte[])std.zlib.uncompress(cast(void[])src);
    return _array_reconcile(afterDecompression);
}

private char[] _array_reconcile(ubyte[] array)
{
    char[] data;
    for (int i=0; i<array.length; i++)
    {
        data ~= [cast(char)array[i]];
    }
    return data;
}
