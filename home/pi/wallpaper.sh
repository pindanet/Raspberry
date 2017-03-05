#!/bin/bash

# Set InterfaceLift specifics
SITE=interfacelift.com
PAGE=https://$SITE/wallpaper/downloads/random/android/800x480/index.html

# Can we reach the site
if ping -c 1 $SITE; then
  # Keep the 100 latest wallpapers
  numfiles=`ls /var/www/html/background | wc -l`
  while [ $((numfiles)) -gt 99 ]; do
    oldest=`ls -t /var/www/html/background/* | tail -1`
    rm $oldest
    numfiles=`ls /var/www/html/background | wc -l`
  done
  # extract wallpaper 
  WOTD=`wget --user-agent="Mozilla/5.0 (X11; Linux x86_64; rv:49.0) Gecko/20100101 Firefox/49.0" -qO - $PAGE | grep "click here to download" | head -1 | sed -e "s,.*href=\",," -e "s,\",," | cut -d '>' -f 1`
  wget --user-agent="Mozilla/5.0 (X11; Linux x86_64; rv:49.0) Gecko/20100101 Firefox/49.0" --directory-prefix=/var/www/html/background/ https://$SITE$WOTD
fi
