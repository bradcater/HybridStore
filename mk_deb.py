#!/usr/bin/python

VERBOSE = True
VERSION = 1.0

import os

def say(msg):
    if VERBOSE: print msg

def bzip_files(v):
    os.system('tar cjvf hybridstore-%s.tar.bz2 ../hybridstore-%s/*' % (v,v))
    os.system('mv hybridstore-%s.tar.bz2 ../' % v)

def copy_debian(v):
    os.system('cp -r debian ../hybridstore-%s/' % v)

def copy_readme(v):
    os.system('cp README ../hybridstore-%s/debian/README.Debian' % v)

def print_info(v):
    print 'Now run:'
    print '\tsudo dpkg-buildpackage -rfakeroot'
    print '\tsudo dpkg -i hybridstore-%s-0ubuntu1_i386.deb' % v

def setup_files(v):
    try: os.system('rm -rf ../hybridstore-%s' % v)
    except: pass
    try: os.system('rm ../hybridstore-%s.tar.bz2' % v)
    except: pass
    os.mkdir('../hybridstore-%s' % v)
    say('copying dirs:')
    for root, dirs, files in os.walk('.'):
        for d in dirs:
            if d in ['dlib','doc','ev','man','tests']:
                say('\t%s' % d)
                os.system('mkdir ../hybridstore-%s/%s' % (v,d))
        for f in files:
            ext = f.split('.')[-1]
            if ext in ['1','conf','d','make','py','rj','rjc','txt'] or f == 'README':
                if not f in ['d.d','ev.d','server_blocking.d','test_server.d','tserver.d','profile_hybridstore.make','thybridstore.make','mk_deb.py']:
                    fname = '%s/%s' % (root,f)
                    say('\t%s' % fname)
                    after_hybridstore = fname.split('HybridStore/')[-1]
                    cmd = 'cp %s/%s ../hybridstore-%s/%s' % (root,f,v,after_hybridstore)
                    say('\t%s' % cmd)
                    os.system(cmd)

def main():
    v = str(VERSION)
    setup_files(v)
    copy_debian(v)
    copy_readme(v)
    bzip_files(v)
    print_info(v)

if __name__ == '__main__':
    main()
