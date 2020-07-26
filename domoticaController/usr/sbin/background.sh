#!/bin/bash
#echo -e "Content-type: text/html\n"
#ls background/*.jpg | sort -R | tail -1

# Wait until network is up
sleep 60

backgroundDir="/var/www/html/background"
#rm ${backgroundDir}/latest.txt
if [ ! -f ${backgroundDir}/latest.txt ]; then
  mkdir -p ${backgroundDir}
  touch -d "2 days ago" ${backgroundDir}/latest.txt
fi

if [[ `date -r ${backgroundDir}/latest.txt +%s` -lt `date -d "1 day ago" +%s` ]]; then
  touch ${backgroundDir}/latest.txt

  # Keep the 400 latest wallpapers
  numfiles=`ls ${backgroundDir} | wc -l`
  while [ $((numfiles)) -gt 399 ]; do
    oldest=`ls -t ${backgroundDir}/* | tail -1`
    rm $oldest
    numfiles=`ls ${backgroundDir} | wc -l`
  done

  # Nieuwe achtergrond instellen
  # check if wall.alphacoders.com is reachable
  if curl -s --head  --request GET https://wall.alphacoders.com ; then
    DOWNLOADBUTTONS=$(wget -qO - --post-data 'view=paged&min_resolution=1920x1080&resolution_equals=%3D&sort_search=newest' https://wall.alphacoders.com/search.php?search=landscape\&page=$(((RANDOM % 50) + 1)) | awk '/download-button\"/{print}')
    BUTTONCOUNT=$(echo "$DOWNLOADBUTTONS" | wc -l)
    readarray -t BUTTONSARRAY <<<"$DOWNLOADBUTTONS"
    BUTTON=$(echo ${BUTTONSARRAY[((RANDOM %BUTTONCOUNT))]})
    OIFS="$IFS"
    IFS="\""
    read -a BUTTONARRAY <<<"$BUTTON"
    IFS="$OIFS"
    wget  -O "${backgroundDir}/${BUTTONARRAY[5]}.${BUTTONARRAY[7]}" "https://initiate.alphacoders.com/download/wallpaper/${BUTTONARRAY[5]}/${BUTTONARRAY[9]}/${BUTTONARRAY[7]}/${BUTTONARRAY[11]}"
    convert -scale "800x480^" -gravity center -crop "800x480+0+0" +repage "${backgroundDir}/${BUTTONARRAY[5]}.${BUTTONARRAY[7]}" "${backgroundDir}/${BUTTONARRAY[5]}.jpg"
    IMGFROM="AlphaCoders: ${BUTTONARRAY[5]}.jpg"
    achtergrond=${backgroundDir}/${BUTTONARRAY[5]}.jpg
  elif curl -s --head  --request GET https://interfacelift.com ; then
    PAGE=https://interfacelift.com/wallpaper/downloads/random/android/800x480/index.html
    # extract wallpaper of the day url
    WOTD=`wget --user-agent="Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/60.0" -qO - $PAGE | grep "click here to download" | head -1 | sed -e "s,.*href=\",," -e "s,\",," | cut -d '>' -f 1`

    wget --user-agent="Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/60.0"  --output-document=${backgroundDir}/$(basename $WOTD) https://interfacelift.com$WOTD
    IMGFROM="InterfaceLift: $(basename $WOTD)"
    achtergrond=${backgroundDir}/$(basename $WOTD)
  else
    PICPAGEURL=`wget -qO - http://wallpaperswide.com/latest_wallpapers.html | awk '/mini-hud/{getline; print}' | head -1 | sed -e "s,.*href=\",," -e "s,\",," | cut -d ' ' -f 1`
    PICURL=`wget -qO - http://wallpaperswide.com$PICPAGEURL | grep 800x480.jpg | head -1 | sed -e "s,.*href=\",," -e "s,\",," | cut -d ' ' -f 1`
    wget -O ${backgroundDir}/background/${PICURL:10} http://wallpaperswide.com$PICURL
    IMGFROM="WallpapersWide: $(basename $PICURL)"
    achtergrond=${backgroundDir}/${PICURL:10}
#    mogrify -crop 800x480+0+60 ${achtergrond}
  fi
  if file "$achtergrond" | grep 'JPEG image data' ; then
    echo "New backgroundimage from ${IMGFROM}."
  else
    rm "$achtergrond"
    echo "The image from ${IMGFROM} was no JPEG image." 5
  fi
fi
