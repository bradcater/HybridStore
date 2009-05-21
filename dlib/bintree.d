module dlib.bintree;

import dlib.parser;

class BinaryTree
{
    protected bool deleted = false;
    protected char[] mykey;
    protected char[] myvalue;
    private BinaryTree left; // these have key <= root.key
    private BinaryTree right; // these have key > root.key
    this(char[] key, char[] value)
    {
        mykey = key;
        myvalue = value;
    }
    protected void _delete()
    {
        deleted = true;
    }
    char[] getValue()
    {
        return myvalue;
    }
    void addNode(char[] key, char[] value)
    {
        if (mykey)
        {
            if (key <= mykey)
            {
                if (left)
                {
                    left.addNode(key, value);
                } else {
                    left = new BinaryTree(key, value);
                }
            } else if (key > mykey) {
                if (right)
                {
                    right.addNode(key, value);
                } else {
                    right = new BinaryTree(key, value);
                }
            } else {
                // keys are equal
                myvalue = value;
                deleted = false;
            }
        }
    }
    void deleteNode(char[] key)
    {
        // this is not recursive, but that shouldn't matter
        BinaryTree* bt = this.seekKey(key);
        bt._delete();
    }
    bool hasKey(char[] key)
    {
        if (key == mykey)
        {
            return true;
        } else if (key <= mykey && left) {
            return left.hasKey(key);
        } else if (right) {
            return right.hasKey(key);
        } else {
            return false;
        }
    }
    char[] prettyPrint()
    {
        return "%s %s", mykey, myvalue;
    }
    BinaryTree* seekKey(char[] key)
    {
        if (key == mykey)
        {
            if (deleted)
            {
                return cast(BinaryTree*)null;
            } else {
                return cast(BinaryTree*)this;
            }
        } else if (key < mykey && left) {
            return left.seekKey(key);
        } else if (right) {
            return right.seekKey(key);
        } else {
            return cast(BinaryTree*)null;
        }
    }
}
