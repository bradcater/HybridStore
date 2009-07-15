#!/bin/sh

gdc -O3 -foptimize-register-move -funroll-loops -fPIC -inline -Wall -frelease server.d dlib/args.d dlib/attrobj.d dlib/config.d dlib/core.d dlib/file.d dlib/getconfig.d dlib/json.d dlib/normalqueryresponder.d dlib/observer.d dlib/parser.d dlib/rbtree.d dlib/remote.d dlib/shorttests.d dlib/stats.d dlib/verbal.d ev/c.d -lev

mv a.out hybridstore
