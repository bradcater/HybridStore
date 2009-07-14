/**
    This code has been adapted from
    http://svn.dsource.org/projects/freeuniverse/trunk/freeuniverse/arc/templates/redblacktree.d
*/
module dlib.rbtree;

import dlib.config;
import dlib.file;
import dlib.verbal;
import std.stdio;
import std.string;
static import std.date;

// Red-Black Tree container class 
class RedBlackTree
{
  public:
    // create blank tree
    this()
    {
        root = null;
        size = 0; 
    }
    
    // destroy all contents in tree 
    ~this()
    {
        // remove all elements from tree and set root null and size to 0 
        destroy(); 
    }

    // print contents of the tree with writefln 
    void print() { print_r(root); }

    // add data to the tree 
    bool add(char[] data, char[] value)
    {
        root = add_r(root, new Node(data,value), root);
        root.red = 0;
        if (STRICT_TREES)
        {
            isValid();
        }
        return true;
    }

    // add idata to the tree
    bool add(double idata, char[] value)
    {
        root = add_r(root, new Node(idata,value), root);
        root.red = 0;
        if (STRICT_TREES)
        {
            isValid();
        }
        return true;
    }
    
    // remove data from tree 
    bool remove(char[] data)
    {
        int done = 0;
        root = remove_r(root, data, done);
        if (root !is null)
        {
            root.red = 0;
        }
        if (STRICT_TREES)
        {
            isValid();
        }
        return true;
    }
    
    // remove idata from the tree
    bool remove(double idata)
    {
        int done = 0;
        root = remove_r(root, idata, done);
        if (root !is null)
        {
            root.red = 0;
        }
        if (STRICT_TREES)
        {
            isValid();
        }
        return true;
    }
    
    // remove oldest (given) node
    bool remove_oldest(Node oldest)
    {
        if (AUTO_PRUNE && (this.size > MAX_SIZE) && (oldest !is null))
        {
            (oldest.data is null) ? remove(oldest.idata) : remove(oldest.data);
        }
        return false;
    }

    // return the maximum keyed element in the tree
    Node max(Node node = null)
    {
        node = set_node(node);
        return superlative_r(node,RIGHT);
    }
    
    // return the minimum keyed element in the tree
    Node min(Node node = null)
    {
        node = set_node(node);
        return superlative_r(node,LEFT);
    }
    
    // search for a key in the tree and return it if found
    Node search(char[] data, Node node = null) 
    {
        node = set_node(node);          
        int nResult;
        while (node !is null && (nResult = (data == node.data ? 0 : (data >= node.data ? -1 : 1))) != 0)
        {
            node = node.link[nResult < 0];
        }
        return node is null ? null : node;
    }
    
    // search for a ikey in the tree and return it if found
    Node search(double idata, Node node = null)
    {
        node = set_node(node);
        int nResult;
        while (node !is null && (nResult = (idata == node.idata ? 0 : (idata >= node.idata ? -1 : 1))) != 0)
        {
            node = node.link[nResult < 0];
        }
        return node is null ? null : node;
    }
    
    Node[] search_range(char[] min_data, char[] max_data, Node node = null)
    {
        node = set_node(node);
        Node[] ns;
        int side;
        if (node.data < min_data)
        {
            side = RIGHT;
        } else if (node.data > max_data) {
            side = LEFT;
        } else {
            bool belongs(Node n)
            {
                return (n.data >= min_data && n.data <= max_data);
            }
            ns = nodes_r(node,&belongs);
            return ns;
        }
        if (node.link[side] !is null)
        {
            ns = search_range(min_data, max_data, node.link[side]);
        }
        return ns;
    }
    
    Node[] search_range(double min_data, double max_data, Node node = null)
    {
        node = set_node(node);
        Node[] ns;
        int side;
        if (node.idata < min_data)
        {
            side = RIGHT;
        } else if (node.idata > max_data) {
            side = LEFT;
        } else {
            bool belongs(Node n)
            {
                return (n.idata >= min_data && n.idata <= max_data);
            }
            ns = nodes_r(node,&belongs);
            return ns;
        }
        if (node.link[side] !is null)
        {
            ns = search_range(min_data, max_data, node.link[side]);
        }
        return ns;
    }

    // remove all data from the tree  
    void destroy()
    {
        destroy_r(root);
        size = 0;
        root = null;
    }
    
    // returns whether the binary tree is valid or not
    int isValid() { return assertNode(root); } 

    // return all nodes
    Node[] getNodes() { return nodes_r(root); }
    
    // return tree nodes size
    int getSize() { return size; }

    // true if empty
    bool isEmpty() { return getSize() == 0; }

    // foreach iterator forwards 
    int opApply(int delegate(inout Node) dg)
    {
        return applyForward(root, dg); 
    }

    // simply return whether value is in tree 'if (4 in tree)'
    bool opIn_r(char[] data)
    {
        return (search(data) !is null);
    }
    
    // simply return whether value is in tree 'if (4 in tree)'
    bool opIn_r(double idata)
    {
        return (search(idata) !is null);
    }

  private:
    // set node to root is it is null
    Node set_node(Node node)
    {
        return (node is null ? root : node);
    }
  
    // iterate tree forwards 
    int applyForward(Node node, int delegate(inout Node) dg)
    {
        int result = 0;
        while (node !is null) 
        {
            result = applyForward(node.link[LEFT], dg);
            if (result)
            {
                return result;
            }
            result = dg(node);
            if (result)
            {
                return result;
            }
            node = node.link[RIGHT];
        }
        return result;        
    }

    // general recursive superlative
    Node superlative_r(Node node, int dir)
    {
        if (node is null)
        {
            return null;
        }
        while (node.link[dir] !is null)
        {
            node = node.link[dir];
        }
        return node;
    }
    
    // recursive remove node 
    Node remove_r(Node node, char[] data, inout int done)
    {
        if (node is null)
        {
            done = 1;
            size--;
        } else {
            node = remove_r_logic(node, data, double.min, done);
        }
        return node;
    }
    
    // remove_r
    Node remove_r(Node node, double idata, inout int done)
    {
        if (node is null)
        {
            done = 1;
            size--;
        } else {
            node = remove_r_logic(node, null, idata, done);
        }
        return node;
    }
    
    Node remove_r_logic(Node node, char[] data, double idata, int done)
    {
        if (node is null)
        {
            done = 1;
        } else {
            int dir;
            bool use_data = (data !is null);
            bool equal = use_data ? (node.data == data) : (node.idata == idata);
            if (equal) 
            {
                if (node.link[LEFT] is null || node.link[RIGHT] is null)
                {
                    Node save = node.link[node.link[LEFT] is null];
                    /* Case 0 */
                    if (isRed(node))
                    {
                        done = 1;
                    } else if (isRed(save)) {
                        /*
                         * This used to be here, but I don't think that it should be.
                         * Any black violations will make me reconsider.
                         * save.red = 0;
                         */
                        done = 1;
                    }
                    delete node;
                    size--;
                    return save;
                } else {
                    Node heir = node.link[LEFT];
                    while (heir.link[RIGHT] !is null)
                    {
                        heir = heir.link[RIGHT];
                    }
                    if (use_data)
                    {
                        node.data = heir.data;
                        data = heir.data;
                    } else {
                        node.idata = heir.idata;
                        idata = heir.idata;
                    }
                }
            }
            if (use_data)
            {
                dir = node.data < data;
                node.link[dir] = remove_r(node.link[dir], data, done);
            } else {
                dir = node.idata < idata;
                node.link[dir] = remove_r(node.link[dir], idata, done);
            }
            if (!done)
            {
                node = remove_balance(node, dir, done);
            }
        }
        return node;
    }

    // remove and balances the nodes 
    Node remove_balance(Node node, int dir, inout int done)
    {
        Node p = node;
        Node s = node.link[!dir];
        /* Case reduction, remove red sibling */
        if (isRed(s))
        {
            node = singleRotation(node, dir);
            s = p.link[!dir];
        }
        if (s !is null)
        {
            if (!isRed(s.link[LEFT]) && !isRed(s.link[RIGHT]))
            {
                if (isRed(p))
                {
                    done = 1;
                }
                p.red = 0;
                s.red = 1;
            } else {
                int save = node.red;
                if (isRed(s.link[!dir]))
                {
                    node = singleRotation(p, dir);
                } else {
                    node = doubleRotation(p, dir);
                }
                node.red = save;
                node.link[LEFT].red = 0;
                node.link[RIGHT].red = 0;
                done = 1;
            }
        }
        return node;
    }

    // add recursive
    Node add_r(Node node, Node new_node, Node oldest)
    {
        if (node is null)
        {
            node = new_node;
            size++;
            remove_oldest(oldest);
        } else if (node.sameData(new_node)) {
            node = new_node;
        } else {
            if (node !is null && oldest !is null && node.created_at < oldest.created_at)
            {
                oldest = node;
            }
            int dir = (node.data !is null) ? node.data < new_node.data : node.idata < new_node.idata;
            node.link[dir] = add_r(node.link[dir], new_node, oldest);
            if (isRed(node.link[dir]))
            {
                if (isRed(node.link[!dir]))
                {
                    /* Case 1 */
                    node.red = 1;
                    node.link[LEFT].red = 0;
                    node.link[RIGHT].red = 0;
                } else {
                    /* Cases 2 & 3 */
                    if (isRed(node.link[dir].link[dir]))
                    {
                        node = singleRotation(node, !dir);
                    } else if (isRed(node.link[dir].link[!dir])) {
                        node = doubleRotation(node, !dir);
                    }
                }
            }
        }
        return node;
    }
    
    // recursive all nodes
    Node[] nodes_r(Node node, bool delegate(Node n) belongs = null)
    {
        Node[] nodes;
        if (node !is null)
        {
            int[2] dirs = [LEFT,RIGHT];
            Node[] tmp;
            foreach (dir; dirs)
            {
                if (node.link[dir] !is null)
                {
                    nodes ~= (belongs is null) ? nodes_r(node.link[dir]) : nodes_r(node.link[dir],belongs);
                }
            }
            if ((belongs is null) || belongs(node))
            {
                nodes ~= [node];
            }
        }
        return nodes;
    }
    
    // recursive print routine
    void print_r(Node node)
    {
        char[] d;
        Node[] nodes = nodes_r(node);
        foreach (n; nodes)
        { 
            writefln("%s -> %s, %s", n.getData(), n.getValue(), n.red);
            if (n.link[LEFT] !is null)
            {
                writefln("    left is %s", n.link[LEFT].getData());
            }
            if (n.link[RIGHT] !is null)
            {
                writefln("    right is %s", n.link[RIGHT].getData());
            }
        }
    }

    // recursive destruction of all tree elements 
    void destroy_r(Node node)
    {
        if (node !is null)
        {
            destroy_r(node.link[LEFT]);
            destroy_r(node.link[RIGHT]);
            delete node;
            node = null;  
        }
    }

    // assert node 
    int assertNode(Node node)
    {
        int lh, rh;
        if (node is null)
        {
            return 1;
        } else {
            Node ln = node.link[LEFT];
            Node rn = node.link[RIGHT];
            /* Consecutive red links */
            if (isRed(node))
            {
                if (isRed(ln) || isRed(rn))
                {
                    say("Red violation.",VERBOSITY,1);
                    this.print();
                    return 0;
                }
            }
            lh = assertNode(ln);
            rh = assertNode(rn);
            /* Invalid binary search tree */
            if ((ln !is null && ln.data !is null && ln.data >= node.data) ||
                (rn !is null && rn.data !is null && rn.data <= node.data))
            {
                say("Binary tree violation.",VERBOSITY,1);
                this.print();
                return 0;
            }
            /* Black height mismatch */
            if (lh != 0 && rh != 0 && lh != rh)
            {
                say(format("Black violation: lh=%s, rh=%s.", lh, rh),VERBOSITY,1);
                this.print();
                return 0;
            }
            /* Only count black links */
            if (lh != 0 && rh != 0)
            {
                return isRed(node) ? lh : lh + 1;
            } else {
                return 0;
            }
        }
    }
    
    // single rotation 
    Node singleRotation(Node node, int dir)
    {
        say(format("RBTree.singleRotation(): %s->%s %s", node.getData(), node.getValue(), dir),VERBOSITY,9);
        Node save = node.link[!dir];
        node.link[!dir] = save.link[dir];
        save.link[dir] = node;
        node.red = 1;
        save.red = 0;
        return save;
    }

    // double rotation 
    Node doubleRotation(Node node, int dir)
    {
        say(format("RBTree.doubleRotation(): %s->%s %s", node.getData(), node.getValue(), dir),VERBOSITY,9);
        node.link[!dir] = singleRotation(node.link[!dir], !dir);
        return singleRotation(node, dir);
    }
  
    // node is red? or not
    int isRed(Node node)
    {
        return ((node !is null) && (node.red == 1));
    }

    // root node of our tree 
    Node root;
    // number of items in the tree 
    int size;
}

enum { LEFT=0, RIGHT=1 }

// a tree node 
class Node 
{
    char[] data;
    double idata;
    ubyte[] cvalue;
    int red;
    std.date.d_time created_at;
    Node link[2];
    this(char[] data, char[] value)
    {
        this.data = data;
        this.idata = double.min;
        this.cvalue = z_compress(value);
        this.red = 1; // 1 is red, 0 is black
        this.created_at = std.date.getUTCtime();
        link[LEFT] = null; 
        link[RIGHT] = null; 
    }
    this(double idata, char[] value)
    {
        this.data = null;
        this.idata = idata;
        this.cvalue = z_compress(value);
        this.red = 1; // 1 is red, 0 is black
        this.created_at = std.date.getUTCtime();
        link[LEFT] = null;
        link[RIGHT] = null;
    }
    char[] getData()
    {
        return (this.data is null) ? format("%s", this.idata) : this.data;
    }
    char[] getValue()
    {
        return z_decompress(this.cvalue);
    }
    void setValue(char[] value)
    {
        this.cvalue = z_compress(value);
    }
    bool sameData(Node n)
    {
        return ((this.data !is null && n.data !is null && this.data == n.data) ||
                (this.idata !is double.min && n.idata !is double.min && this.idata == n.idata));
    }
    unittest {
        Node n_s = new Node("mydata","myvalue");
        assert(n_s.getData() == "mydata", "Node failed data lookup.");
        assert(n_s.getValue() == "myvalue", "Node failed value lookup.");
        n_s.setValue("mynewvalue");
        assert(n_s.getValue() == "mynewvalue", "Node failed new value lookup.");
        assert((new Node("a","b")).sameData(new Node("a","c")) == true, "Node failed sameData() check.");
        assert((new Node("a","b")).sameData(new Node("b","b")) == false, "Node failed sameData() check.");
    }
}

char[] node_info(Node n, char[] d = null, char[] v = null)
{
    char[][] x = _node_info_collect(n,d,v);
    return _node_info_format("key",x[0],"value",x[1]);
}

char[] node_info_short(Node n, char[] d = null, char[] v = null)
{
    char[][] x = _node_info_collect(n,d,v);
    return format("%s:\"%s\"", x[0], x[1]);
}

private char[][] _node_info_collect(Node n, char[] d, char[] v)
{
    char[][] x;
    if (n is null && d is null && v is null)
    {
        x ~= "";
        x ~= "";
    } else {
        d = (n is null) ? d : n.data;
        d = (d is null) ? format("%s", n.idata) : format("\"%s\"", d);
        v = (n is null) ? v : n.getValue();
        x ~= d;
        x ~= v;
    }
    return x;
}

private char[] _node_info_format(char[] d_lbl, char[] d, char[] v_lbl, char[] v)
{
    char[] v2 = (v is NULL) ? format("\"%s\"", NULL) : v;
    return format("{\"%s\":%s,\"%s\":\"%s\"}", d_lbl, d, v_lbl, v2);
}

unittest {
    Node n = new Node("mykey","myvalue");
    assert(node_info(n) == "{\"key\":\"mykey\",\"value\":\"myvalue\"}");
    assert(node_info_short(n) == "\"mykey\":\"myvalue\"");
    Node n2 = new Node(7,"myvalue2");
    assert(node_info(n2) == "{\"key\":7,\"value\":\"myvalue2\"}");
    assert(node_info_short(n2) == "7:\"myvalue2\"");
}
