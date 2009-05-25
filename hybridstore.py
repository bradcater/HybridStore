from cjson import decode
from pickle import dumps, loads
import socket

class HybridStore:
    def __init__(self, host="localhost", port=41111):
        self._SOCKET_TIMEOUT = 3
        self.host = host
        self.port = port
        self.family = socket.AF_INET
        self.address = (self.host,self.port)
    
    def __unicode__(self):
        if self.family == socket.AF_INET:
            return u"inet: %s:%d" % (self.address[0], self.address[1])
        else:
            return u"unix: %s" % self.address

    def __is_str__(self,s):
        assert isinstance(s,str) or isinstance(s,unicode), u"Given s (%s) is the wrong type." % str(s)
        return s
    
    def _check_filename(self,filename):
        filename = self.__is_str__(filename)
        return filename

    def _transform_key(self,key):
        if isinstance(key,int) or isinstance(key,float):
            key = u'NUMERIC(%s)' % key
        return key

    def _check_keys(self,keys):
        print '*************************keys',keys
        keys2 = self._transform_key(keys)
        if keys2 != keys: return keys2
        if isinstance(keys,str) or isinstance(keys,unicode): return keys
        assert isinstance(keys,tuple) or isinstance(keys,list), u"keys (%s) is the wrong type." % str(keys)
        if isinstance(keys,tuple):
            print u'%s=%s' % (self._transform_key(keys[0]),self._dumps(keys[1]))
            return u'%s=%s' % (self._transform_key(keys[0]),self._dumps(keys[1]))
        else:
            for i in xrange(len(keys)):
                k = self._transform_key(k)
                assert isinstance(k,tuple), u"key (%s) is the wrong type." % str(k)
                if len(k) == 2:
                    k = u'%s=%s' % (k[0],self._dumps(k[1]))
                else:
                    # If for some reason someone wants to pre-serialize and put
                    # the data in the form key=serialize(value), who am I to say no?
                    print '*************preserialized'
                    k = u'%s' % k[0]
                keys[i] = k
            return u','.join(keys)
    
    def _check_server(self,server):
        server = self.__is_str__(server)
        return server
    
    def _check_tree(self,tree):
        tree = self.__is_str__(tree)
        return tree

    def _dumps(self,obj):
        return dumps(obj).replace('\n','\\n')
    
    def _get_socket(self):
        s = socket.socket()
        s.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)
        if hasattr(s, u'settimeout'):
            s.settimeout(self._SOCKET_TIMEOUT)
        try:
            s.connect(self.address)
        except socket.timeout, msg:
            print u"Socket timeout: %s" % msg
            return None
        except socket.error, msg:
            print u"Socket error: %s" % msg
            return None
        return s

    def _loads(self,s):
        return loads(s)

    def _send_cmd(self, cmd):
        if len(cmd) > 0 and cmd[-1] != u";":
            cmd = u"%s;" % cmd
        #print u'sending %s' % cmd
        s = self._get_socket()
        if s:
            s.send(cmd)
            resp = s.recv(512)
            s.close()
            return resp

    def all(self,tree):
        self._tree = self._check_tree(tree)
        return self._send_cmd("ALL FROM %s;" % _tree)
    
    def commit(self,tree,filename,compressed=False):
        filename = self._check_filename(filename)
        tree = self._check_tree(tree)
        s = u"COMMIT %s TO %s" % (tree,filename)
        if compressed:
            s = u"%s COMPRESSED" % s
        return self._send_cmd("%s;" % s)
    
    def create(self,tree):
        tree = self._check_tree(tree)
        return self._send_cmd("CREATE TREE %s;" % tree)
    
    def dell(self,key,tree):
        keys = self._check_keys(key)
        tree = self._check_tree(tree)
        return self._send_cmd("DEL %s FROM %s;" % (keys,tree))
    
    def drop(self,tree):
        tree = self._check_tree(tree)
        return self._send_cmd("DROP TREE %s;" % tree)
    
    def elect(self,newmaster):
        newmaster = self._check_server(newmaster)
        return self._send_cmd("ELECT SERVER %s;" % newmaster)
    
    def exit(self):
        return self._send_cmd("EXIT;")
    
    def get(self,key,tree):
        keys = self._check_keys(key)
        tree = self._check_tree(tree)
        r = self._send_cmd("GET %s FROM %s;" % (keys,tree))
        # TODO: It's dumb that we have to decode and then stringify (only to be
        # decoded again later).
        print 'response from server',r
        json = decode(r)
        if json.get('status') == 'Ok.':
            d = {}
            pairs = json.get('response',{})
            for k,v in pairs.items():
                print '**************************k,v',k,v
                d[k] = self._loads(v)
            json['response'] = d
            return str(json)
        return r

    def get_r(self,keymin,keymax,tree):
        keymin = self._check_keys(keymin)
        keymax = self._check_keys(keymax)
        tree = self._check_tree(tree)
        return self._send_cmd("GET %s FROM %s RANGE %s;" % (keymin,tree,keymax))
    
    def info(self,tree):
        tree = self._check_tree(tree)
        return self._send_cmd("INFO FROM %s;" % tree)
    
    def load(self,filename,tree,compressed=False):
        filename = self._check_filename(filename)
        tree = self._check_tree(tree)
        s = u"LOAD %s FROM %s" % (tree,filename)
        if compressed:
            s = u"%s COMPRESSED"
        return self._send_cmd("%s;" % s)
    
    def set(self,key,tree):
        keys = self._check_keys(key)
        tree = self._check_tree(tree)
        return self._send_cmd("SET %s IN %s;" % (keys,tree))
    
    def swap(self,old_server,new_server):
        for x in [old_server,new_server]:
            self._check_server(x)
        return self._send_cmd("SWAP SERVER %s %s;" % (old_server,new_server))
