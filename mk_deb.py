#!/usr/bin/python

VERBOSE = True

import os

def say(msg):
    if VERBOSE: print msg

def bzip_files():
    os.system('tar cjvf hybridstore-1.0.tar.bz2 ../hybridstore-1.0/*')
    os.system('mv hybridstore-1.0.tar.bz2 ../')

def copy_debian():
    os.system('cp -r debian ../hybridstore-1.0/')

def setup_files():
    try: os.system('rm -rf ../hybridstore-1.0')
    except: pass
    os.mkdir('../hybridstore-1.0')
    say('copying dirs:')
    for root, dirs, files in os.walk('.'):
        for d in dirs:
            if d in ['dlib','doc','ev','man','tests']:
                say('\t%s' % d)
                os.system('mkdir ../hybridstore-1.0/%s' % d)
        for f in files:
            ext = f.split('.')[-1]
            if ext in ['1','conf','d','make','py','rj','rjc','txt'] or f == 'README':
                if not f in ['d.d','ev.d','server_blocking.d','test_server.d','tserver.d','profile_hybridstore.make','thybridstore.make','mk_deb.py']:
                    fname = '%s/%s' % (root,f)
                    say('\t%s' % fname)
                    after_hybridstore = fname.split('HybridStore/')[-1]
                    cmd = 'cp %s/%s ../hybridstore-1.0/%s' % (root,f,after_hybridstore)
                    say('\t%s' % cmd)
                    os.system(cmd)

def main():
    setup_files()
    copy_debian()
    bzip_files()

if __name__ == '__main__':
    main()
