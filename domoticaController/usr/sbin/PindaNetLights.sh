#!/bin/bash
# ToDo
# .source functions, config

logExt="log.test"

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

unset lights
# Name URL Power On Off
lights+=("Apotheek tasmota-c699b5-6581 20 $sunset $(date -d "$sunset 15 minutes" +'%H:%M')")
#lights+=("Apotheek tasmota-c699b5-6581 20 10:37 10:39")

declare -A status=()
function tasmota () {
  if [ -z ${status["$1"]} ]; then # initialize
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power)
    two=$(echo ${status["$1"]} | awk -F"\"" '{print $4}')
    twolower=${two,,}
    if [ $twolower == "on" ] || [ $twolower == "off" ]; then
      echo "$(date -u +%s),$twolower,$3" >> /var/www/html/data/$1.$logExt
    fi
  fi
  if [ $2 == "on" ] && [ "${status["$1"]}" == '{"POWER":"OFF"}' ]; then
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power%20On)
    echo "$(date -u +%s),$2,$3" >> /var/www/html/data/$1.$logExt
  elif [ $2 == "off" ] && [ "${status["$1"]}" == '{"POWER":"ON"}' ]; then
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power%20Off)
    echo "$(date -u +%s),$2,$3" >> /var/www/html/data/$1.$logExt
  elif [ "${status["$1"]}" != '{"POWER":"OFF"}' ] && [ "${status["$1"]}" != '{"POWER":"ON"}' ]; then
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power)
    echo "$(date): Communication error. Heating $1" >> /tmp/PindaNetDebug.txt
  fi
}

while true
do
  starttime=$(date +"%s") # complete cycle: 1 minute
  now=$(date +%H:%M)
  for light in "${lights[@]}"; do
    lightProperties=(${light})
    if [[ "${lightProperties[3]}" < "$now" ]] && [[ "$now" < "${lightProperties[4]}" ]]; then
      tasmota ${lightProperties[1]} on ${lightProperties[2]}
    else
      tasmota ${lightProperties[1]} off ${lightProperties[2]}
    fi
#    echo ${lightProperties[@]}
  done

  sleepSec=$((60 - ($(date +"%s") - starttime)))
  sleep $sleepSec
done
