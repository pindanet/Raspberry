#!/bin/bash
echo -e "Content-type: text/html\n"
ls background/ | sort -R | tail -1
