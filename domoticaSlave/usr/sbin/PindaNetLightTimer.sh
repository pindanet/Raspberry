#!/bin/bash
# Gnd (9) > Gnd (Brown)
# GPIO 4 (7) > Output (White)
# 5 V (2) > Vcc (Orange)

# ToDo

morningShutterDown="05:00"
morningShutterUp="08:00"
eveningShutterDown="22:20"
eveningShutterUp="23:00"

lighttimer=180 #in seconds

_pir_pin=4

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

raspi-gpio set $_pir_pin ip pd # input pull down

timer=$(date +"%s")

while true; do
  sunrise=$(hdate -s -l N51 -L E3 -z0 -q | grep sunrise | tail -c 6)
  sunset=$(hdate -s -l N51 -L E3 -z0 -q | tail -c 6)
  clock=$(date -u +"%H:%M")
  localclock=$(date +"%H:%M")

#  echo "down: $morningShutterDown, up:  $morningShutterUp, tijd: $localclock"

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
        echo "$(date): Motion: Light on"
        tasmota "tasmota_15dd89-7561" "on"
        timer=$(date +"%s")
      else
        if [ $(($(date +"%s") - timer)) -gt "$lighttimer" ]; then
          echo "$(date): Motion: Light off"
          tasmota "tasmota_15dd89-7561" "off"
        fi
      fi
      sleep 0.2
    done
  else # Day
    tasmota "tasmota_15dd89-7561" "off"
    sleep 55
  fi
done
