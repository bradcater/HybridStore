import os, readline, socket, sys, time

if len(sys.argv) == 2:
    PORT = int(sys.argv[1])
else:
    # int PORT = 41111;
    PORT = int(os.popen('grep PORT\ =\  dlib/config.d').read().split('=')[-1][1:-2])

ok = True

while ok:
    i = raw_input()
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(("localhost", PORT))
    print 'sending "%s"' % i
    t1 = time.time()
    s.send(i)
    resp = s.recv(8192)
    t2 = time.time()
    print 'received %s (%.3fms)' % (resp,t2-t1)
    s.close()
    if i == "EXIT;":
        ok = False
