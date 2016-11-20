#!/bin/bash
# Truncate Image file
# Written by Dany Pinoy

if [[ ! $(whoami) =~ "root" ]]; then
  echo ""
  echo "**********************************"
  echo "*** This should be run as root ***"
  echo "**********************************"
  echo ""
  exit
fi

if [[ -z $1 ]]; then
  echo "Usage: ./raspbian-truncate.sh raspian-netbios-vnc.img"
  exit
fi

if [[ ! -e $1 || ! $(file $1) =~ "DOS/MBR boot sector" ]]; then
  echo "Error : Not an image file, or file doesn't exist"
  exit
fi

truncate -s 5422186496 $1
