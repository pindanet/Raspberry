#!/bin/bash
# DS18B20
# GPIO 17 (11) (switchable 3,3 V) naar Vdd (Rood)
# GPIO4 (7) naar Data (Geel) naar 4k7 naar 3,3 V (Orange)(GPIO27)
# GND (9) naar GND (Zwart)

powergpio=17
pullupgpio=27

if [ ! -d /var/www/html/data/temp.log ]; then
  mkdir -p /var/www/html/data/temp.log
fi

#cat /sys/devices/w1_bus_master1/28-*/temperature
#temp=$(cat /sys/bus/w1/devices/28-*/temperature)
output=$(cat /sys/bus/w1/devices/28-*/w1_slave)
if [ $? -ne 0 ]; then # error
  # Reset DS18B20
  # Power off
  pinctrl set $powergpio op dl
  pinctrl set $pullupgpio op dh
  sleep 3
  # Power on
  pinctrl set $powergpio op dh
  sleep 5
  echo "Reset Ds18b20"
  exit
fi

crc=$(echo "${output}" | head -1)
if [[ $crc == *"YES" ]]; then
  temp="${output#*t=}"
else
  echo "Ds18b20 CRC error"
  exit
fi

if [ ! -f /tmp/PinDa.temp.count ]; then
  echo "Ds18b20 rejected first measurement"
  touch /tmp/PinDa.temp.count
  exit
fi

echo $temp
echo $temp > /var/www/html/data/temp

# minimum maximum temp
timestamp=$(date +"%m-%d_")
if [ ! -f /var/www/html/data/temp.log/${timestamp}tempmax ]; then
  echo 0 > /var/www/html/data/temp.log/${timestamp}tempmax
fi
tempmax=$(cat /var/www/html/data/temp.log/${timestamp}tempmax)
if [ ! -f /var/www/html/data/temp.log/${timestamp}tempmin ]; then
  echo 100000 > /var/www/html/data/temp.log/${timestamp}tempmin
fi
tempmin=$(cat /var/www/html/data/temp.log/${timestamp}tempmin)
if [ ${temp%.*} -eq ${tempmax%.*} ] && [ ${temp#*.} \> ${tempmax#*.} ] || [ ${temp%.*} -gt ${tempmax%.*} ]; then
  tempmax=$temp
  echo $tempmax > /var/www/html/data/temp.log/${timestamp}tempmax
fi
if [ ${temp%.*} -eq ${tempmin%.*} ] && [ ${temp#*.} \< ${tempmin#*.} ] || [ ${temp%.*} -lt ${tempmin%.*} ]; then
  tempmin=$temp
  echo $tempmin > /var/www/html/data/temp.log/${timestamp}tempmin
fi
