module dlib.llrbtree;

import std.stdio;

enum : bool
{
    RED = true,
    BLACK = false
}

class LLRBTree
{
    private bool color = RED;
    private bool deleted = false;
    protected char[] mykey;
    protected char[] myvalue;
    private LLRBTree left; // these have key <= root.key
    private LLRBTree right; // these have key > root.key
    this(char[] key, char[] value)
    {
        mykey = key;
        myvalue = value;
        writefln("this maps %s => %s", mykey, myvalue);
    }
    protected void _delete()
    {
        deleted = true;
    }
    protected void _colorFlip()
    {
        //writefln("color flip");
        this._colorSwap();
        if (this._hasLeft())
        {
            this._getLeft()._colorSwap();
        }
        if (this._hasRight())
        {
            this._getRight()._colorSwap();
        }
    }
    protected void _colorSwap()
    {
        if (color == RED)
        {
            this.color = BLACK;
        } else {
            this.color = RED;
        }
    }
    protected bool _isRed()
    {
        return (this.color == RED);
    }
    protected bool _getColor()
    {
        return this.color;
    }
    protected LLRBTree _getLeft()
    {
        return this.left;
    }
    protected LLRBTree _getRight()
    {
        return this.right;
    }
    protected LLRBTree* _getLeftP()
    {
        return &this.left;
    }
    protected LLRBTree* _getRightP()
    {
        return &this.right;
    }
    protected bool _hasLeft()
    {
        //writefln("has left");
        if (this.left)
        {
            //writefln("true");
            return true;
        } else {
            //writefln("false");
            return false;
        }
    }
    protected bool _hasRight()
    {
        //writefln("has right");
        if (this.right)
        {
            //writefln("true");
            return true;
        } else {
            //writefln("false");
            return false;
        }
    }
    protected void _setColor(bool c)
    {
        this.color = c;
    }
    protected void _setLeft(LLRBTree t)
    {
        this.left = t;
    }
    protected void _setRight(LLRBTree t)
    {
        this.right = t;
    }
    private void _rotateLeft()
    {
        writefln("rotating left");
        LLRBTree x = *this._getRightP();
        this._setRight(*x._getLeftP());
        x._setLeft(this);
        x._setColor(x._getLeft()._getColor());
        LLRBTree y = *x._getLeftP();
        y._setColor(RED);
        //*x._getLeftP()._setColor(RED);
    }
    private void _rotateRight()
    {
        writefln("rotating right");
        LLRBTree x = *this._getLeftP();
        this._setLeft(*x._getRightP());
        x._setRight(this);
        x._setColor(x._getRight()._getColor());
        LLRBTree y = *x._getRightP();
        y._setColor(RED);
        //*x._getRight()._setColor(RED);
    }
    char[] getValue()
    {
        return myvalue;
    }
    void addNode(char[] key, char[] value)
    {
        //writefln("key: %s value: %s", key, value);
        if (mykey)
        {
            if (key <= mykey)
            {
                if (this._hasLeft())
                {
                    this._getLeft().addNode(key, value);
                } else {
                    this._setLeft(new LLRBTree(key, value));
                    this._handleRotations();
                    writefln("left mapped %s => %s", key, value);
                }
            } else if (key > mykey) {
                if (this._hasRight())
                {
                    this._getRight().addNode(key, value);
                } else {
                    this._setRight(new LLRBTree(key, value));
                    writefln("right mapped %s => %s", key, value);
                    this._handleRotations();
                }
            } else {
                // keys are equal
                myvalue = value;
                deleted = false;
            }
        }
    }
    protected void _handleRotations()
    {
        if (this._hasRight() && this._getRight()._isRed())
        {
            this._rotateLeft();
        }
        if (this._hasLeft() && this._getLeft()._isRed() && this._getLeft()._hasLeft() && this._getLeft()._getLeft()._isRed())
        {
            this._rotateRight();
        }
        if (this._hasLeft() && this._getLeft()._isRed() && this._hasRight() && this._getRight()._isRed())
        {
            this._colorFlip();
        }
    }
    char[] prettyPrint(char[] t = "")
    {
        char[] m = mykey ~ " => " ~ myvalue ~ ", ";
        writefln(m);
        t = t ~ m;
        if (this._hasLeft())
        {
            t = t ~ ", " ~ this._getLeft().prettyPrint(t = t);
        }
        if (this._hasRight())
        {
            t = t ~ ", " ~ this._getRight().prettyPrint(t = t);
        }
        return t;
    }
    void deleteNode(char[] key)
    {
        // this is not recursive, but that shouldn't matter
        LLRBTree* t = this.seekKey(key);
        t._delete();
    }
    bool hasKey(char[] key)
    {
        if (key == mykey)
        {
            return true;
        } else if (key <= mykey && this._hasLeft()) {
            return left.hasKey(key);
        } else if (this._hasRight()) {
            return right.hasKey(key);
        } else {
            return false;
        }
    }
    LLRBTree* seekKey(char[] key)
    {
        if (key == mykey)
        {
            if (deleted)
            {
                return cast(LLRBTree*)null;
            } else {
                return cast(LLRBTree*)this;
            }
        } else if (key <= mykey && this._hasLeft()) {
            return _getLeft().seekKey(key);
        } else if (this._hasRight()) {
            return this._getRight().seekKey(key);
        } else {
            return cast(LLRBTree*)null;
        }
    }
}
