#!/bin/bash
echo -e "Content-type: text/html\n"
ls background/*.jpg | sort -R | tail -1

if [ ! -f background/latest.txt ]; then
  mkdir background
  touch -d "1 days ago" background/latest.txt
fi

if [[ `date -r background/latest.txt +%s` -lt `date -d "1 day ago" +%s` ]]; then
  touch background/latest.txt

  # Keep the 300 latest wallpapers
  numfiles=`ls /var/www/html/background | wc -l`
  while [ $((numfiles)) -gt 299 ]; do
    oldest=`ls -t /var/www/html/background/* | tail -1`
    rm $oldest
    numfiles=`ls /var/www/html/background | wc -l`
  done

  # Nieuwe achtergrond instellen
  # Set InterfaceLift specifics
  SITE=interfacelift.com
  PAGE=https://$SITE/wallpaper/downloads/random/android/800x480/index.html

  # check if InterfaceLift is reachable
  if curl -s --head  --request GET https://$SITE ; then
    # extract wallpaper of the day url
    WOTD=`wget --user-agent="Mozilla/5.0 (X11; Linux x86_64; rv:49.0) Gecko/20100101 Firefox/49.0" -qO - $PAGE | grep "click here to download" | head -1 | sed -e "s,.*href=\",," -e "s,\",," | cut -d '>' -f 1`

    wget --user-agent="Mozilla/5.0 (X11; Linux x86_64; rv:49.0) Gecko/20100101 Firefox/49.0"  --output-document=/var/www/html/background/$(basename $WOTD) https://$SITE$WOTD
  else
    PICPAGEURL=`wget -qO - http://wallpaperswide.com/latest_wallpapers.html | awk '/mini-hud/{getline; print}' | head -1 | sed -e "s,.*href=\",," -e "s,\",," | cut -d ' ' -f 1`
    PICURL=`wget -qO - http://wallpaperswide.com$PICPAGEURL | grep 800x600.jpg | head -1 | sed -e "s,.*href=\",," -e "s,\",," | cut -d ' ' -f 1`
    wget -O /var/www/html/background/${PICURL:10} http://wallpaperswide.com$PICURL
    mogrify -crop 800x480+0+60 /var/www/html/background/${PICURL:10}
  fi
fi
