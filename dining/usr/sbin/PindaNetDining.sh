#!/bin/bash
function relayGPIO () {
  _r1_pin=23
  # Activate GPIO Relay
  if [ ! -d "/sys/class/gpio/gpio$_r1_pin" ]; then
    #   Exports pin to userspace
    echo $_r1_pin > /sys/class/gpio/export
    # Sets pin as an output
    echo "out" > /sys/class/gpio/gpio$_r1_pin/direction
  fi

  if [ ! -f /tmp/$1 ]; then # initialize
    echo '{"POWER":"ON"}' > /tmp/$1
    echo "$(date -u +%s),off" >> /var/www/html/data/$1.log
  fi
  if [ $2 == "on" ] && [ "$(cat /tmp/$1)" == '{"POWER":"OFF"}' ]; then
    echo 0 > /sys/class/gpio/gpio$_r1_pin/value # Power on
    echo '{"POWER":"ON"}' > /tmp/$1
    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
  elif [ $2 == "off" ] && [ "$(cat /tmp/$1)" == '{"POWER":"ON"}' ]; then
    echo 1 > /sys/class/gpio/gpio$_r1_pin/value # Power off
    echo '{"POWER":"OFF"}' > /tmp/$1
    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
  elif [ "$(cat /tmp/$1)" != '{"POWER":"OFF"}' ] && [ "$(cat /tmp/$1)" != '{"POWER":"ON"}' ]; then
    echo '{"POWER":"ON"}' > /tmp/$1
    echo "$(date): Relay error. Heating $1" >> /tmp/PindaNetDebug.txt
  fi
}
function tasmota () {
  if [[ $1 == *"relayGPIO"* ]]; then
    relayGPIO $1 $2
    return
  fi
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

. /var/www/html/data/thermostat
# Calculated configs
# domoOn
today=$(date +%u)
domoOn=${alarmtimes[$((today - 1))]}

for alarmitem in "${alarmevent[@]}"; do
  daytime=(${alarmitem})
  recevent=$(date -u --date "${daytime[0]}" +%s)
  todaySec=$(date -u +%s)
  today=$((todaySec - (todaySec % 86400)))
#  date -u -d @$today
  if [[ "${#daytime[@]}" > "2" ]]; then # recurrent alarm event
    timebetween=$((${daytime[2]} * 86400))
    while  [ $recevent -lt $today ]; do
      recevent=$((recevent + timebetween))
    done
  fi
  if [ $today == $recevent ]; then
    echo "Domoticasystem wakes up on $(date -u --date @$recevent +'%a %d %b %Y') at ${daytime[1]}"
    domoOn=${daytime[1]}
  fi
done
echo $domoOn > /var/www/html/data/domoOn

# Lights on in the morning 
#wget -qO- http://$diningLight/cm?cmnd=Power%20On
raspi-gpio set $diningLight op dl

# Lights out in the morning
# From UTC
lightsOut=$(date -d "$domoOn" +"%s")
lightsOut=$((lightsOut + 60 * 60)) # 1 hour after wakeup
lightsOut=$(date -d @$lightsOut +%H:%M)

sunrise=$(hdate -s -l N51 -L E3 -z0 -q | grep sunrise | tail -c 6)
sunriseSec=$(date -d "$sunrise" +"%s")
localToUTC=$(($(date +"%k") - $(date -u +"%k")))
sunriseLocalSec=$((sunriseSec + localToUTC * 3600))
# to Local
sunrise=$(date -d @$sunriseLocalSec +"%H:%M")
if [[ $lightsOut > $sunrise ]]; then # sun shines
  echo "raspi-gpio set $diningLight op dh" | at $lightsOut
#  echo "wget -qO- http://$diningLight/cm?cmnd=Power%20Off" | at $lightsOut
else # still dark
  echo "raspi-gpio set $diningLight op dh" | at $sunrise
#  echo "wget -qO- http://$diningLight/cm?cmnd=Power%20Off" | at $sunrise
fi

# Lights on in the evening
# From UTC
sunset=$(hdate -s -l N51 -L E3 -z0 -q | tail -c 6)
sunsetSec=$(date -d "$sunset" +"%s")
sunsetLocalSec=$((sunsetSec + localToUTC * 3600))
# to Local
sunset=$(date -d @$sunsetLocalSec +"%H:%M")
if [[ $eveningShutterDown > $sunset ]]; then # already dark
  echo "raspi-gpio set $diningLight op dl" | at $sunset
#  echo "wget -qO- http://$diningLight/cm?cmnd=Power%20On" | at $sunset
else # still daylight
  echo "raspi-gpio set $diningLight op dl" | at $eveningShutterDown
#  echo "wget -qO- http://$diningLight/cm?cmnd=Power%20On" | at $eveningShutterDown
fi
# All lights out
echo "raspi-gpio set $diningLight op dh" | at $lightevening
#echo "wget -qO- http://$diningLight/cm?cmnd=Power%20Off" | at $lightevening

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
