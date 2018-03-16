#!/bin/bash
# Wait until network is up
sleep 60

backgroundDir="/var/www/html/background"
if [ ! -f ${backgroundDir}/latest.txt ]; then
  sudo mkdir ${backgroundDir}
  sudo touch -d "1 days ago" ${backgroundDir}/latest.txt
fi

if [[ `date -r ${backgroundDir}/latest.txt +%s` -lt `date -d "1 day ago" +%s` ]]; then
  sudo touch ${backgroundDir}/latest.txt

  # Keep the 300 latest wallpapers
  numfiles=`ls ${backgroundDir} | wc -l`
  while [ $((numfiles)) -gt 299 ]; do
    oldest=`ls -t ${backgroundDir}/* | tail -1`
    sudo rm $oldest
    numfiles=`ls ${backgroundDir}/ | wc -l`
  done

  # Nieuwe achtergrond instellen
  # Set InterfaceLift specifics
  SITE=interfacelift.com
  PAGE=https://$SITE/wallpaper/downloads/random/wide_16:10/1920x1200/index.html

  # check if InterfaceLift is reachable
  if curl -s --head  --request GET https://$SITE ; then
    # extract wallpaper of the day url
    WOTD=`wget --user-agent="Mozilla/5.0 (X11; Linux x86_64; rv:49.0) Gecko/20100101 Firefox/49.0" -qO - $PAGE | grep "click here to download" | head -1 | sed -e "s,.*href=\",," -e "s,\",," | cut -d '>' -f 1`

    sudo wget --user-agent="Mozilla/5.0 (X11; Linux x86_64; rv:49.0) Gecko/20100101 Firefox/49.0"  --output-document=${backgroundDir}/$(basename $WOTD) https://$SITE$WOTD
  else
    PICPAGEURL=`wget -qO - http://wallpaperswide.com/latest_wallpapers.html | awk '/mini-hud/{getline; print}' | head -1 | sed -e "s,.*href=\",," -e "s,\",," | cut -d ' ' -f 1`
    PICURL=`wget -qO - http://wallpaperswide.com$PICPAGEURL | grep 1920x1200.jpg | head -1 | sed -e "s,.*href=\",," -e "s,\",," | cut -d ' ' -f 1`
    sudo wget -O ${backgroundDir}/${PICURL:10} http://wallpaperswide.com$PICURL
#    mogrify -crop 800x480+0+60 /var/www/html/background/${PICURL:10}
  fi
fi
# make backup (opgenomen in globaal backup-script)
# sudo rsync -aAXv --delete --relative /home/pi/install.sh /home/pi/bin/ /var/www/  pindabackup.local::backup/rpiwall
