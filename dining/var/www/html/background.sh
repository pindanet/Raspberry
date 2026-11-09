#!/bin/bash
# check if InterfaceLift is reachable
if (curl -s --head  --request GET https://wallpaperscraft.com > /dev/zero) ; then
  URL="https://wallpaperscraft.com/catalog/nature/1920x1200/page$((RANDOM % 1687))"
  PICURLPAGE=`wget --compression=auto -qO - $URL | grep wallpapers__image | head -$(((RANDOM % 14) + 1)) | tail -1 | sed -e "s,.*src=\",," -e "s,\",," | cut -d ' ' -f 1` 
  PICURL="${PICURLPAGE:0: -11}1920x1080.jpg"
  echo $PICURL
elif (curl -s --head  --request GET https://wallhaven.cc > /dev/zero) ; then
  PICURLPAGE=`wget -qO - "https://wallhaven.cc/search?q=id%3A37&resolutions=1920x1200&sorting=random" | grep -oP "(?<=preview\" )[^ ]+" | head -1 | sed -e "s,.*href=\",," -e "s,\",,"`
  PICURL=`wget -qO - $PICURLPAGE | grep -oP "(?<=id=\"wallpaper\" )[^ ]+"| sed -e "s,.*src=\",," -e "s,\",,"`
  echo $PICURL
elif (curl -s --head  --request GET https://www.bing.com/HPImageArchive.aspx > /dev/zero) ; then
  api_url="https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US"
  url_path=$(curl -s "$api_url" | jq -r ".images[0].url")
  echo "https://www.bing.com${url_path}"
fi
exit
else # wallpaperswide.com; download only
  PICPAGEURL=`wget --user-agent="Mozilla/5.0 (X11; Linux x86_64; rv:153.0) Gecko/20100101 Firefox/153.0" -qO - https://wallpaperswide.com/latest_wallpapers.html | awk '/mini-hud/{getline; print}' | head -1 | sed -e "s,.*href=\",," -e "s,\",," | cut -d ' ' -f 1`
  PICURL=`wget --user-agent="Mozilla/5.0 (X11; Linux x86_64; rv:153.0) Gecko/20100101 Firefox/153.0" -qO - https://wallpaperswide.com$PICPAGEURL | grep 1920x1200.jpg | sed -e "s,.*href=\",," -e "s,\",," | cut -d ' ' -f 1`
  echo https://wallpaperswide.com$PICURL
fi
