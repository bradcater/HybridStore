module dlib.attrobj;

import dlib.config;
import dlib.file;
import dlib.verbal;
import std.string;

/**
    An AttrObj is a thin wrapper around an associative array.
*/
class AttrObj
{
    /**
        The attributes contained by this AttrObj.
    */
    private char[][char[]] attrs;
    /**
        Add the pair name->value to this.
    */
    void addAttr(char[] name, char[] value)
    {
        attrs[name] = value;
    }
    /**
        Returns true if this has no attributes, false otherwise.
    */
    bool empty()
    {
        return (attrs.length == 0);
    }
    /**
        Returns the value associated with the attribute name if it exists.
        Returns an empty array otherwise.
    */
    char[] getAttr(char[] name)
    {
        try
        {
            return attrs[name];
        }
        catch(Exception e)
        {
            return [];
        }
    }
    /**
        Returns a string of the values of attr1 and attr2 joined by sep.
    */
    char[] joinAttrs(char[] attr1, char[] attr2, char[] sep)
    {
        return format("%s%s%s", this.getAttr(attr1), sep, this.getAttr(attr2));
    }
    unittest {
        AttrObj ao = new AttrObj();
        ao.addAttr("key","mykey");
        ao.addAttr("value","myvalue");
        assert(ao.getAttr("key") == "mykey", "AttrObj failed property lookup.");
        assert(ao.getAttr("value") == "myvalue", "AttrObj failed property lookup.");
        assert(ao.joinAttrs("key","value","=") == "mykey=myvalue", "AttrObj failed property join.");
    }
}

/**
    Returns an array of AttrObjs listed in f.
    If compress is true, f will be decompressed before building the array.
*/
AttrObj[] gatherObjs(char[] f, bool compress)
{
    AttrObj ao = new AttrObj();
    AttrObj[] objs;
    string[] lines = read_file(f,compress);
    foreach (line; lines)
    {
        if (!find(line,"%%"))
        {
            objs = objs ~ ao;
            ao = new AttrObj();
        } else {
            string[] s = split(line,":");
            if (s.length == 2)
            {
                s[0] = strip(s[0]);
                s[1] = strip(s[1]);
                if (s[0] == "key") {
                    if (find(s[1]," ") > -1) {
                        say(format("Key \"%s\" contains a space(s) at index %s, but that is not allowed.", s[1], find(s[1]," ")),VERBOSITY,1);
                        s[1] = replace(s[1]," ","_");
                    }
                }
                ao.addAttr(s[0],s[1]);
            }
        }
    }
    return (objs.length > 1) ? objs[1..$] : objs;
}

unittest {
    AttrObj[] aobjs = gatherObjs("tests/dictionary.rj", false);
    assert(aobjs.length == 11);
    AttrObj[] aobjs_c = gatherObjs("tests/dictionary.rjc", true);
    assert(aobjs_c.length == 11);
}
