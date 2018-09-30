#!/bin/bash

BTController="B8:27:EB:49:17:03"
# Array bluetooth MAC addresses
# Scan with: hcitool scan
bluetooth=(94:0E:6B:F8:97:31 6C:24:83:B8:98:7B)

sendFile () {
  obexftp --bluetooth $BTController --channel 23 -p $1
}

home="1"
for i in ${bluetooth[@]}; do
  sdptool browse $i
  if [ $? == 0 ]; then # home
    home="0"
    break
  fi
done

tail -999 /var/PindaNet/debug.txt > /var/PindaNet/debug.trunc
mv /var/PindaNet/debug.trunc /var/PindaNet/debug.txt
if [ "$home" -gt "0" ]; then
  # Disable Pi Zero ACT LED
  echo none > /sys/class/leds/led0/trigger
  echo 1 > /sys/class/leds/led0/brightness
  # Sleep state
  if [ $(cat /var/PindaNet/state) == "awake" ]; then
    echo "sleep" > /var/PindaNet/state
    sendFile /var/PindaNet/state
  fi
else
  # Activate Pi Zero ACT LED
  echo mmc0 > /sys/class/leds/led0/trigger
  echo 0 > /sys/class/leds/led0/brightness
  read_bme280 --i2c-address 0x77 > /var/PindaNet/PresHumiTemp
  sendFile /var/PindaNet/PresHumiTemp
  # Awake state
  if [ $(cat /var/PindaNet/state) == "sleep" ]; then
    echo "awake" > /var/PindaNet/state
    sendFile /var/PindaNet/state
  fi
fi
