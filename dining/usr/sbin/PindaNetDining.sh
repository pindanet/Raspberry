#!/bin/bash
function tasmota () {
  if [ ! -f /tmp/$1 ]; then # initialize
    echo $(wget -qO- http://$1/cm?cmnd=Power) > /tmp/$1
    two=$(wget -qO- http://$1/cm?cmnd=Power | awk -F"\"" '{print $4}')
    twolower=${two,,}
    if [ $twolower == "on" ] || [ $twolower == "off" ]; then
      echo "$(date -u +%s),$twolower" >> /var/www/html/data/$1.log
    fi
  fi
  if [ $2 == "on" ] && [ "$(cat /tmp/$1)" == '{"POWER":"OFF"}' ]; then
    dummy=$(wget -qO- http://$1/cm?cmnd=Power%20On)
    echo $(wget -qO- http://$1/cm?cmnd=Power) > /tmp/$1
    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
  elif [ $2 == "off" ] && [ "$(cat /tmp/$1)" == '{"POWER":"ON"}' ]; then
    dummy=$(wget -qO- http://$1/cm?cmnd=Power%20Off)
    echo $(wget -qO- http://$1/cm?cmnd=Power) > /tmp/$1
    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
  elif [ "$(cat /tmp/$1)" != '{"POWER":"OFF"}' ] && [ "$(cat /tmp/$1)" != '{"POWER":"ON"}' ]; then
    echo $(wget -qO- http://$1/cm?cmnd=Power) > /tmp/$1
    echo "$(date): Communication error. Heating $1" >> /tmp/PindaNetDebug.txt
  fi
}

. /var/www/html/data/config

# Lights on in the morning 
wget -qO- http://$diningLight/cm?cmnd=Power%20On

# Lights out in the morning
# From UTC
sunrise=$(hdate -s -l N51 -L E3 -z0 -q | grep sunrise | tail -c 6)
sunriseSec=$(date -d "$sunrise" +"%s")
localToUTC=$(($(date +"%k") - $(date -u +"%k")))
sunriseLocalSec=$((sunriseSec + localToUTC * 3600))
# to Local
sunrise=$(date -d @$sunriseLocalSec +"%H:%M")
if [[ $morningShutterUp > $sunrise ]]; then # sun shines
  echo "wget -qO- http://$diningLight/cm?cmnd=Power%20Off" | at $morningShutterUp
else # still dark
  echo "wget -qO- http://$diningLight/cm?cmnd=Power%20Off" | at $sunrise
fi

# Lights on in the evening
# From UTC
sunset=$(hdate -s -l N51 -L E3 -z0 -q | tail -c 6)
sunsetSec=$(date -d "$sunset" +"%s")
sunsetLocalSec=$((sunsetSec + localToUTC * 3600))
# to Local
sunset=$(date -d @$sunsetLocalSec +"%H:%M")
if [[ $eveningShutterDown > $sunset ]]; then # already dark
  echo "wget -qO- http://$diningLight/cm?cmnd=Power%20On" | at $sunset
else # still daylight
  echo "wget -qO- http://$diningLight/cm?cmnd=Power%20On" | at $eveningShutterDown
fi
# All lights out
echo "wget -qO- http://$diningLight/cm?cmnd=Power%20Off" | at $lightevening

while true
do
  starttime=$(date +"%s") # complete cycle: 1 minute

  temp=$(python /home/*/ds18b20.py)
  LC_ALL=C printf "%.1f °C" "$temp" > /home/*/temp.txt

  sudo pkill -9 pngview
#  convert -size 1920x70 xc:none -font Bookman-DemiItalic -pointsize 32 -fill black -stroke white -gravity center -draw "text 0,0 '$(date +"%A, %e %B %Y   %k:%M")   $(cat /home/*/temp.txt)'" /home/*/image.png
  convert -size 1920x70 xc:none -font /usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf -pointsize 32 -fill black -gravity center -draw "text 0,0 '$(date +"%A, %e %B %Y   %k:%M")   $(cat /home/*/temp.txt)'" /home/*/image.png
  /home/*/raspidmx-master/pngview/pngview -b 0 -l 3 -y 1130 /home/*/image.png &

  sleepSec=$((60 - ($(date +"%s") - starttime)))
  sleep $sleepSec
done
