#!/bin/bash
# DS18B20
# GPIO 17 (11) (switchable 3,3 V) naar Vdd (Rood)
# GPIO4 (7) naar Data (Geel) naar 4k7 naar 3,3 V (Rood)
# GND (9) naar GND (Zwart)

powergpio=17

# cat /sys/devices/w1_bus_master1/28-*/temperature
temp=$(cat /sys/bus/w1/devices/28-*/temperature)
if [[ $temp =~ ^[0-9]+$ ]]; then
  echo $temp
  echo $temp > /var/www/html/data/temp

  # minimum maximum temp
  timestamp=$(date +"%m-%d_")
  if [ ! -f /var/www/html/data/${timestamp}tempmax ]; then
    echo 0 > /var/www/html/data/${timestamp}tempmax
  fi
  tempmax=$(cat /var/www/html/data/${timestamp}tempmax)
  if [ ! -f /var/www/html/data/${timestamp}tempmin ]; then
    echo 100000 > /var/www/html/data/${timestamp}tempmin
  fi
  tempmin=$(cat /var/www/html/data/${timestamp}tempmin)
  if [ ${temp%.*} -eq ${tempmax%.*} ] && [ ${temp#*.} \> ${tempmax#*.} ] || [ ${temp%.*} -gt ${tempmax%.*} ]; then
    tempmax=$temp
    echo $tempmax > /var/www/html/data/${timestamp}tempmax
  fi
  if [ ${temp%.*} -eq ${tempmin%.*} ] && [ ${temp#*.} \< ${tempmin#*.} ] || [ ${temp%.*} -lt ${tempmin%.*} ]; then
    tempmin=$temp
    echo $tempmin > /var/www/html/data/${timestamp}tempmin
  fi
else
  # Reset DS18B20
  # Power off
  pinctrl set $powergpio op dl
  sleep 3
  # Power on
  pinctrl set $powergpio op dh
  sleep 5
fi
