#!/bin/bash
# Gnd (9) > Gnd (Black)
# GPIO 4 (7) > Output (White)
# 5 V (2) > Vcc (Grey)

# ToDo

morningShutterDown="05:00"
morningShutterUp="08:00"
eveningShutterDown="22:20"
eveningShutterUp="23:00"

lighttimer=180 #in seconds

_pir_pin=4
_light_pin=24

raspi-gpio set $_pir_pin ip pd # input pull down
raspi-gpio set $_light_pin op dh  # output high

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

  if [[ $clock < $sunrise ]] || [[ $clock > $sunset ]] || [[ $shutter == "down" ]]; then # Night
#    echo "Test"
#  else
    starttime=$(date +"%s")
    while [ $(($(date +"%s") - starttime)) -lt 55 ]; do
      pir=$(raspi-gpio get $_pir_pin)
#      echo "$(date): $pir)"
      if [[ $pir == *"level=1"* ]]; then
        if [[ $(raspi-gpio get $_light_pin) == *"level=1"* ]]; then
          echo "$(date): Motion: Light on"
          raspi-gpio set $_light_pin dl
#        else
#          echo "$(date): Motion: Keep light on"
       fi
        timer=$(date +"%s")
      else
        if [ $(($(date +"%s") - timer)) -gt "$lighttimer" ]; then
          if [[ $(raspi-gpio get $_light_pin) == *"level=0"* ]]; then
            echo "$(date): Motion: Light off"
            raspi-gpio set $_light_pin dh
#          else
#            echo "$(date): Motion: Keep light off"
          fi
        fi
      fi
      sleep 0.2
    done
  else
#    echo "$(date): Dag: Lights off"
    raspi-gpio set $_light_pin dh
    sleep 55
  fi
done
