#!/bin/bash
# ToDo
# .source functions, config
# split PindaNetSwitches - PindaNetLights

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

eveningShutterDown="22:20"

unset lights
# Name URL Power On Off
lights+=("Tandenborstel tasmota-a943fa-1018 20 16:00 22:15")
lights+=("Apotheek tasmota-c699b5-6581 20 $sunset $(date -d "$sunset 15 minutes" +'%H:%M')")
lights+=("Apotheek tasmota-c699b5-6581 20 22:24 bedtime")

# in the evening
if [[ $(date -d "$eveningShutterDown" +'%Y%m%d%H%M') > $(date -d "$sunset" +'%Y%m%d%H%M') ]]; then # already dark
  lights+=("Haardlamp tasmota-1539f2-6642 20 $sunset bedtime")
  lights+=("TVlamp tasmota-a94717-1815 20 $sunset bedtime")
else # still daylight
  lights+=("Haardlamp tasmota-1539f2-6642 20 $eveningShutterDown bedtime")
  lights+=("TVlamp tasmota-a94717-1815 20 $eveningShutterDown bedtime")
fi

#lights+=("TVlamp tasmota-a94717-1815 20 18:58 19:00")

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
  declare -A process=()
  declare -A processed=()
  starttime=$(date +"%s") # complete cycle: 1 minute
  now=$(date +'%Y%m%d%H%M')
  if [[ $(cat /sys/class/backlight/rpi_backlight/bl_power) == "1" ]]; then # LCD backlight off
    bedtime="$now"
  else
    bedtime=$(date -d "2 minutes" +'%Y%m%d%H%M')
  fi
  for light in "${lights[@]}"; do
    lightProperties=(${light})
    if [ -z ${processed["${lightProperties[0]}"]} ]; then # not yet processed
      if [[ "${lightProperties[4]}" == "bedtime" ]]; then
        endDate="$bedtime"
      else
        endDate=$(date -d "${lightProperties[4]}" +'%Y%m%d%H%M')
      fi
      startDate=$(date -d "${lightProperties[3]}" +'%Y%m%d%H%M')
      if [[ "$startDate" < "$now" ]] && [[ "$now" < "$endDate" ]]; then
#        tasmota ${lightProperties[1]} on ${lightProperties[2]} ${lightProperties[0]}
        process["${lightProperties[0]}"]="${lightProperties[0]} ${lightProperties[1]} ${lightProperties[2]} on"
        processed["${lightProperties[0]}"]="on"
      else
#        tasmota ${lightProperties[1]} off ${lightProperties[2]} ${lightProperties[0]}
        process["${lightProperties[0]}"]="${lightProperties[0]} ${lightProperties[1]} ${lightProperties[2]} off"
      fi
    fi
#    echo ${lightProperties[@]}
  done
  for key in "${!process[@]}"; do
    lightProperties=(${process[$key]})
    tasmota ${lightProperties[1]} ${lightProperties[3]} ${lightProperties[2]} ${lightProperties[0]}
    echo "$key: ${lightProperties[3]}"
  done
#  echo ${process[@]}
#  echo ${!process[@]}

  sleepSec=$((60 - ($(date +"%s") - starttime)))
  sleep $sleepSec
done
