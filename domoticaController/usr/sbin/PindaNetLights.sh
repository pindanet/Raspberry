#!/bin/bash
# ToDo
# .source functions, config

logExt="log"

sunrise=$(hdate -s -l N51 -L E3 -z0 -q | grep sunrise | tail -c 6)
sunriseSec=$(date -d "$sunrise" +"%s")
localToUTC=$(($(date +"%k") - $(date -u +"%k")))
sunriseLocalSec=$((sunriseSec + localToUTC * 3600))
# to Local
sunrise=$(date -d @$sunriseLocalSec +"%H:%M")

sunset=$(hdate -s -l N51 -L E3 -z0 -q | tail -c 6)
sunsetSec=$(date -d "$sunset" +"%s")
sunsetLocalSec=$((sunsetSec + localToUTC * 3600))
# to Local
sunset=$(date -d @$sunsetLocalSec +"%H:%M")

lightevening="22:50"
eveningShutterDown="22:20"

unset lights
# Name URL Power On Off
lights+=("Tandenborstel tasmota-a943fa-1018 20 16:00 22:15")
lights+=("Apotheek tasmota-c699b5-6581 20 $sunset $(date -d "$sunset 15 minutes" +'%H:%M')")
lights+=("Apotheek tasmota-c699b5-6581 20 22:24 bedtime")

# in the evening
if [[ $eveningShutterDown > $sunset ]]; then # already dark
  lights+=("Haardlamp tasmota-1539f2-6642 20 $sunset bedtime")
  lights+=("TVlamp tasmota-a94717-1815 20 $sunset bedtime")
else # still daylight
  lights+=("Haardlamp tasmota-1539f2-6642 20 $eveningShutterDown bedtime")
  lights+=("TVlamp tasmota-a94717-1815 20 $eveningShutterDown bedtime")
fi

declare -A status=()
function tasmota () {
  if [ -z ${status["$1"]} ]; then # initialize
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power)
    two=$(echo ${status["$1"]} | awk -F"\"" '{print $4}')
    twolower=${two,,}
    if [ $twolower == "on" ] || [ $twolower == "off" ]; then
      echo "$(date),$twolower,$3" >> /var/www/html/data/$4.$logExt
    fi
  fi
  if [ $2 == "on" ] && [ "${status["$1"]}" == '{"POWER":"OFF"}' ]; then
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power%20On)
    echo "$(date),$2,$3" >> /var/www/html/data/$4.$logExt
  elif [ $2 == "off" ] && [ "${status["$1"]}" == '{"POWER":"ON"}' ]; then
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power%20Off)
    echo "$(date),$2,$3" >> /var/www/html/data/$4.$logExt
  elif [ "${status["$1"]}" != '{"POWER":"OFF"}' ] && [ "${status["$1"]}" != '{"POWER":"ON"}' ]; then
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power)
    echo "$(date): Communication error. Heating $1" >> /tmp/PindaNetDebug.txt
  fi
}

while true
do
  starttime=$(date +"%s") # complete cycle: 1 minute
  now=$(date +%H:%M)
  # Get bedtime
  bedtime="24:30"
  if [[ $(cat /sys/class/backlight/rpi_backlight/bl_power) == "1" ]]; then # LCD backlight off
    bedtime="$now"
  fi
  for light in "${lights[@]}"; do
    lightProperties=(${light})
    if [[ "${lightProperties[4]}" == "bedtime" ]]; then
      lightProperties[4]="$bedtime"
    fi
    if [[ "${lightProperties[3]}" < "$now" ]] && [[ "$now" < "${lightProperties[4]}" ]]; then
      tasmota ${lightProperties[1]} on ${lightProperties[2]} ${lightProperties[0]}
    else
      tasmota ${lightProperties[1]} off ${lightProperties[2]} ${lightProperties[0]}
    fi
#    echo ${lightProperties[@]}
  done

  sleepSec=$((60 - ($(date +"%s") - starttime)))
  sleep $sleepSec
done
