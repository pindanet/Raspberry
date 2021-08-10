#!/bin/bash

# ToDo

morningShutterDown="05:00"
morningShutterUp="08:00"
eveningShutterDown="22:20"
eveningShutterUp="23:00"

lighttimer=180 #in seconds

lightSwitch="tasmota_15dd89-7561"
_pir_pin=4

declare -A status=()
status["$lightSwitch"]=$(wget -qO- http://$lightSwitch/cm?cmnd=Power)
echo "${status["$lightSwitch"]}" > /var/www/html/data/light-bulb
chown www-data:www-data /var/www/html/data/light-bulb

function tasmota () {
  if [ $2 == "on" ] && [ "${status["$1"]}" == '{"POWER":"OFF"}' ]; then
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power%20On)
    echo "${status["$1"]}" > /var/www/html/data/light-bulb
    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
  elif [ $2 == "off" ] && [ "${status["$1"]}" == '{"POWER":"ON"}' ]; then
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power%20Off)
    echo "${status["$1"]}" > /var/www/html/data/light-bulb
    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
  elif [ "${status["$1"]}" != '{"POWER":"OFF"}' ] && [ "${status["$1"]}" != '{"POWER":"ON"}' ]; then
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power)
    echo "${status["$1"]}" > /var/www/html/data/light-bulb
    echo "$(date): Communication error. Heating $1" >> /tmp/PindaNetDebug.txt
  fi
}

raspi-gpio set $_pir_pin ip pd # input pull down

timer=$(date +"%s")
sunrise=$(hdate -s -l N51 -L E3 -z0 -q | grep sunrise | tail -c 6)
sunset=$(hdate -s -l N51 -L E3 -z0 -q | tail -c 6)

while true; do
  clock=$(date -u +"%H:%M")
  localclock=$(date +"%H:%M")

  if [[ $localclock > $morningShutterDown ]] && [[ $localclock < $morningShutterUp ]]; then # Morning and shutters down
    shutter="down"
  elif [[ $localclock > $eveningShutterDown ]] && [[ $localclock < $eveningShutterUp ]]; then # Evening and shutters down
    shutter="down"
  else
    shutter="up"
  fi
#shutter="down" # Test
  if [[ $clock < $sunrise ]] || [[ $clock > $sunset ]] || [[ $shutter == "down" ]]; then # Night
    starttime=$(date +"%s")
    while [ $(($(date +"%s") - starttime)) -lt 55 ]; do
      pir=$(raspi-gpio get $_pir_pin)
      if [[ $pir == *"level=1"* ]]; then 
        if [ "${status["$lightSwitch"]}" == '{"POWER":"OFF"}' ]; then
          echo "$(date): Motion: Light on"
          tasmota "$lightSwitch" "on"
        fi
        timer=$(date +"%s")
      else
        if [ $(($(date +"%s") - timer)) -gt "$lighttimer" ] && [ "${status["$lightSwitch"]}" == '{"POWER":"ON"}' ]; then
          echo "$(date): Motion: Light off"
          tasmota "$lightSwitch" "off"
        fi
      fi
      sleep 0.2
    done
  else # Day
    if [ "${status["$lightSwitch"]}" == '{"POWER":"ON"}' ]; then
      tasmota "$lightSwitch" "off"
    fi
    sleep 55
  fi
done
