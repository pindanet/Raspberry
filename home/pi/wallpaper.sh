#!/bin/bash

# Set InterfaceLift specifics
SITE=interfacelift.com
PAGE=https://$SITE/wallpaper/downloads/random/android/800x480/index.html

# Wacht tot het netwerk opgestart is.
while ! ping -c 1 $SITE; do
  sleep 1m
done
# Hou enkel de 100 recenste achtergronden
numfiles=`ls /media/data/var/www/html/background | wc -l`
while [ $((numfiles)) -gt 99 ]; do
  oldest=`ls -t /media/data/var/www/html/background/* | tail -1`
  rm $oldest
  numfiles=`ls /media/data/var/www/html/background | wc -l`
done
# extract wallpaper 
WOTD=`wget --user-agent="Mozilla/5.0 (X11; Linux x86_64; rv:49.0) Gecko/20100101 Firefox/49.0" -qO - $PAGE | grep "click here to download" | head -1 | sed -e "s,.*href=\",," -e "s,\",," | cut -d '>' -f 1`
wget --user-agent="Mozilla/5.0 (X11; Linux x86_64; rv:49.0) Gecko/20100101 Firefox/49.0" --directory-prefix=/media/data/var/www/html/background/ https://$SITE$WOTD
