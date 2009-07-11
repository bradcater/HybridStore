#!/bin/sh

gdc -O3 -foptimize-register-move -funroll-loops -inline -Wall -funittest -c -pg server.d dlib/args.d dlib/attrobj.d dlib/config.d dlib/core.d dlib/file.d dlib/getconfig.d dlib/json.d dlib/parser.d dlib/rbtree.d dlib/remote.d dlib/shorttests.d dlib/stats.d dlib/verbal.d

gdc -O3 -foptimize-register-move -funroll-loops -inline -Wall -funittest -pg server.o args.o attrobj.o config.o core.o file.o getconfig.o json.o parser.o rbtree.o remote.o shorttests.o stats.o verbal.o

mv a.out hybridstored
