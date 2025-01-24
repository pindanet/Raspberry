#!/bin/bash
# $1 = URL, $2 = volume
#interval=$(timeout 2 curl -H "Icy-MetaData:1" --silent -L "$1" 2>&1 | stdbuf -oL grep -aob "StreamTitle" | head -n1 | sed 's@^[^0-9]*\([0-9]\+\).*@\1@')
#interval=$((interval - 1))
interval="8192"
curl -H "Icy-MetaData:1" --silent -L "$1" 2>&1 | mpg123 --icy-interval $interval -f -$2 -
