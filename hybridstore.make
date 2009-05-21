#!/bin/sh

gdc -O3 -foptimize-register-move -funroll-loops -inline -Wall server.d dlib/args.d dlib/attrobj.d dlib/config.d dlib/core.d dlib/file.d dlib/getconfig.d dlib/json.d dlib/parser.d dlib/rbtree.d dlib/remote.d dlib/shorttests.d dlib/verbal.d

#dmd -O -inline -profile server.d dlib/args.d dlib/attrobj.d dlib/config.d dlib/core.d dlib/file.d dlib/getconfig.d dlib/json.d dlib/parser.d dlib/rbtree.d dlib/remote.d dlib/shorttests.d dlib/verbal.d

mv a.out hybridstored
