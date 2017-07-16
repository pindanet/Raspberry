#!/bin/bash
# Bluetooth Proximity Detection

# hcitool scan
# echo -n "MA:C-:ad:dr:es:BT" > bluetooth.detection
# sudo hcitool info MA:C-:ad:dr:es:BT | md5sum | awk '{ print $1 }' >> bluetooth.detection
# sudo mv bluetooth.detection /var/www/html/ /var/www/html/data/

while IFS='' read -r bluetooth || [[ -n "$bluethooth" ]]; do
# bluetooth=`cat /var/www/html/data/bluetooth.detection`
  info=`hcitool info ${bluetooth:0:17} | md5sum`
  if [ ${bluetooth:17:32} == ${info:0:32} ]; then
    echo 0 > /sys/class/backlight/rpi_backlight/bl_power
    echo 255 > /sys/class/leds/led0/brightness
    echo 255 > /sys/class/leds/led1/brightness
    exit
  fi
done < "/var/www/html/data/bluetooth.detection"
echo 1 > /sys/class/backlight/rpi_backlight/bl_power
echo 0 > /sys/class/leds/led0/brightness
echo 0 > /sys/class/leds/led1/brightness
