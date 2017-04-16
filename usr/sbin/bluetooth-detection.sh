#!/bin/bash
# Bluetooth Proximity Detection

# hcitool scan
# echo -n "MA:C-:ad:dr:es:BT" > bluetooth.detection
# sudo hcitool info MA:C-:ad:dr:es:BT | md5sum | awk '{ print $1 }' >> bluetooth.detection
# sudo mv bluetooth.detection /var/www/html/ /var/www/html/data/

while IFS='' read -r bluetooth || [[ -n "$bluethooth" ]]; do
# bluetooth=`cat /var/www/html/data/bluetooth.detection`
  info=`hcitool info ${bluetooth:0:17} | md5sum | awk '{ print $1 }'`
  if [ ${bluetooth:17:32} == $info ]; then
    echo 0 > /sys/class/backlight/rpi_backlight/bl_power
    exit
  fi
done < "/var/www/html/data/bluetooth.detection"
echo 1 > /sys/class/backlight/rpi_backlight/bl_power
