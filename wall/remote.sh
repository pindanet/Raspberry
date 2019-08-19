#!/bin/bash
command=$(cat $1)
cat $1 > /home/dany/remote.log
rm $1
case "$command" in
  halt)
    shutdown -h now
    ;;
esac
