#!/bin/bash

# ToDo

morningShutterDown="05:00"
morningShutterUp="08:00"
eveningShutterDown="22:20"
eveningShutterUp="23:00"

lighttimer=180 #in seconds
lightSwitch="tasmota_15dd89-7561"

_pir_pin=4
#_pir_2_pin=7

dim=0
brightday=128
brightnight=32
bright=$brightday
brightness=$(cat /sys/class/backlight/rpi_backlight/brightness)

declare -A status=()
status["$lightSwitch"]=$(wget -qO- http://$lightSwitch/cm?cmnd=Power)
echo "${status["$lightSwitch"]}" > /var/www/html/data/$lightSwitch
chown www-data:www-data /var/www/html/data/$lightSwitch

function tasmota () {
  if [ $2 == "on" ] && [ "${status["$1"]}" == '{"POWER":"OFF"}' ]; then
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power%20On)
    echo "${status["$1"]}" > /var/www/html/data/$lightSwitch
    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
  elif [ $2 == "off" ] && [ "${status["$1"]}" == '{"POWER":"ON"}' ]; then
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power%20Off)
    echo "${status["$1"]}" > /var/www/html/data/$lightSwitch
    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
  elif [ "${status["$1"]}" != '{"POWER":"OFF"}' ] && [ "${status["$1"]}" != '{"POWER":"ON"}' ]; then
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power)
    echo "${status["$1"]}" > /var/www/html/data/$lightSwitch
    echo "$(date): Communication error. Heating $1" >> /tmp/PindaNetDebug.txt
  fi
}

raspi-gpio set $_pir_pin ip pd # input pull down
#raspi-gpio set $_pir_2_pin ip pd # input pull down

timer=$(date +"%s")
sunrise=$(hdate -s -l N51 -L E3 -z0 -q | grep sunrise | tail -c 6)
sunset=$(hdate -s -l N51 -L E3 -z0 -q | tail -c 6)

while true; do
  pir=$(raspi-gpio get $_pir_pin)
  if [[ $pir == *"level=1"* ]]; then # Motion
#    echo "$(date): Motion"
    if [[ $brighness != $bright ]]; then
      echo $bright > /sys/class/backlight/rpi_backlight/brightness
      brightness=$bright
    fi
    timer=$(date +"%s")
    sunrise=$(hdate -s -l N51 -L E3 -z0 -q | grep sunrise | tail -c 6)
    sunset=$(hdate -s -l N51 -L E3 -z0 -q | tail -c 6)
    localclock=$(date +"%H:%M")
    clock=$(date -u +"%H:%M")
    if [[ $localclock > $morningShutterDown ]] && [[ $localclock < $morningShutterUp ]]; then # Morning and shutters down
      shutter="down"
    elif [[ $localclock > $eveningShutterDown ]] && [[ $localclock < $eveningShutterUp ]]; then # Evening and shutters down
      shutter="down"
    else
      shutter="up"
    fi
#shutter="down" # Test
    if [[ $clock < $sunrise ]] || [[ $clock > $sunset ]] || [[ $shutter == "down" ]]; then # Night
      bright=$brightnight
      if [ "${status["$lightSwitch"]}" == '{"POWER":"OFF"}' ]; then
#        echo "$(date): Motion: Light on"
        tasmota "$lightSwitch" "on"
      fi
    else
      bright=$brightday
    fi
  fi
  if [ $(($(date +"%s") - timer)) -gt "$lighttimer" ]; then
#    echo "$(date): All clear"
    if [[ $brighness != $dim ]]; then
      echo $dim > /sys/class/backlight/rpi_backlight/brightness
      brightness=$dim
    fi
    if [ "${status["$lightSwitch"]}" == '{"POWER":"ON"}' ]; then
      tasmota "$lightSwitch" "off"
    fi
  fi
  sleep 0.2
done
