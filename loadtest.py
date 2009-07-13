import os, socket, sys, time
from random import random

try:
    import psyco
    psyco.full()
except ImportError: pass

if len(sys.argv) == 2:
    PORT = int(sys.argv[1])
else:
    # int PORT = 41111;
    PORT = int(os.popen('grep PORT\ =\  dlib/config.d').read().split('=')[-1][1:-2])

def socket_send(msg,p):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(("localhost", p))
    s.sendall(msg)
    resp = s.recv(8192)
    s.close()
    return resp

TRIALS = 50000#0
METHODS = ('hybridstore','memcached','tokyocabinet','mysql')
METHOD = METHODS[0]
b = 30

start = time.time()

if METHOD == 'hybridstore':
    msg = "CREATE TREE test;"
    socket_send(msg,PORT)
    #from tests import hybridstore
    #h = hybridstore.HybridStore()
    #h.create('test')
    for i in xrange(0,TRIALS,b):
        #h.set(",".join([ "%d=%d" % (j,j) for j in xrange(i,i+b) ]),'test')
        msg = "SET %s IN test;" % ",".join([ "%d=%d" % (j,j) for j in xrange(i,i+b) ])
        # TODO: h.get() seems to fail after the response gets too big.
        #h.get(",".join([ "%d" % j for j in xrange(i,i+b) ]),'test')
        #msg = "GET %s FROM test;" % ",".join([ "%d" % j for j in xrange(i,i+b) ])
        #msg = "GET %d FROM test RANGE %d;" % (i,i+b)
        socket_send(msg,PORT)
    #socket_send("DROP TREE test;",PORT)
elif METHOD == 'memcached':
    import memcache
    memc = memcache.Client(['127.0.0.1:11211','10.0.1.115:11211'])
    for i in xrange(TRIALS):
        resp = memc.set(str(i),str(i),60)
        #resp = memc.get(str(i))
elif METHOD == 'tokyocabinet':
    import pytyrant
    t = pytyrant.PyTyrant.open('127.0.0.1',1978)
    for i in xrange(TRIALS):
        t[str(i)] = str(i)
        #resp = t[str(i)]
elif METHOD == 'mysql':
    import MySQLdb as msql
    db = msql.connect(host="localhost", user="root", db="test")
    c = db.cursor()
    for i in xrange(0,TRIALS,b):
        c.execute("INSERT INTO test (`k`,`v`) VALUES %s" % ",".join([ "('%d','%d')" % (j,j) for j in xrange(i,i+b) ]))
        #c.execute("SELECT v FROM test WHERE %s" % " or ".join([ "k='%d'" % j for j in xrange(i,i+b) ]))
        result = c.fetchall()
else:
    print 'Uh oh.'

finish = time.time()

print "%f seconds have elapsed." % (finish - start)
