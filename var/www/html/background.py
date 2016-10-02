#!/usr/bin/python3
# -*- coding: UTF-8 -*-# enable debugging
import cgitb
import random, glob, os
cgitb.enable()
print("Content-Type: text/html;charset=utf-8")
print()
files = glob.glob("background/*.jpg")
print(random.choice(files))
