module dlib.file;

import dlib.config;
import std.stream;
import std.string;
static import std.file;
static import std.zlib;

/**
    Returns the contents of f.
    If compress is true, this will uncompress the data after reading.
*/
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

/**
    Writes data to f.
    If compress is true, it will compress the data before writing.
*/
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

/**
    Returns data in compressed form.
*/
ubyte[] z_compress(char[] data)
{
    ubyte[] beforeCompression = cast(ubyte[])data;
    return cast(ubyte[])std.zlib.compress(cast(void[])beforeCompression,COMPRESSION_LEVEL);
}

/**
    Returns src in uncompressed form.
*/
char[] z_decompress(ubyte[] src)
{
    ubyte[] afterDecompression = cast(ubyte[])std.zlib.uncompress(cast(void[])src);
    return _array_reconcile(afterDecompression);
}

/**
    Returns array as characters.
*/
private char[] _array_reconcile(ubyte[] array)
{
    char[] data;
    foreach (ub; array) {
        data ~= cast(char)ub;
    }
    return data;
}

unittest {
    /*
     * TODO: I still can't explain why these differ in length.
     */
    assert(read_file("tests/dictionary.rj",false).length == 35);
    assert(read_file("tests/dictionary.rjc",true).length == 34);
}
