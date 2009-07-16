#!/usr/bin/python

from os import system

a = [0,250000,500000,750000]

for b in a:
  system('python loadtest.py 41111 %d' % b)
