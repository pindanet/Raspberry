#!/bin/bash
# DS18B20
# GPIO 17 (11) (switchable 3,3 V) naar Vdd (Rood)
# GPIO4 (7) naar Data (Geel) naar 4k7 naar 3,3 V (Rood)
# GND (9) naar GND (Zwart)

powergpio=17

output=$(cat /sys/bus/w1/devices/28-*/w1_slave)
if [ $? -ne 0 ]; then # error
  # Reset DS18B20
  # Power off
  pinctrl set $powergpio op dl # Bookworm
  sleep 3
  # Power on
  pinctrl set $powergpio op dh # Bookworm
  sleep 5
  echo "Reset Ds18b20"
  if [ -f /tmp/PinDa.temp.count ]; then
    rm /tmp/PinDa.temp.count
  fi
  exit
fi

crc=$(echo "${output}" | head -1)
if [[ $crc == *"YES" ]]; then
  temp="${output#*t=}"
  if [ ! -f /tmp/PinDa.temp.count ]; then
    if [[ $temp == 0 ]]; then
      echo "Ds18b20 rejected first 0"
      exit
    fi
  fi
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
logfile="/var/www/html/data/temp.log"
month=$(date +"%m")
day=$(date +"%d")
timestamp="${month}/${day}"
if [ -f "${logfile}" ]; then
  dateminmax=$(grep "^${timestamp}," ${logfile})
  if [ -z ${dateminmax} ]; then # first entry for date
    echo "${timestamp},${temp},${temp}" >> ${logfile}
  else # adjust min and max temp
    CSVarray=($(echo $dateminmax | tr ',' "\n"))
    tempmin=${CSVarray[1]}
    tempmax=${CSVarray[2]}
    if [ ${temp%.*} -eq ${tempmax%.*} ] && [ ${temp#*.} \> ${tempmax#*.} ] || [ ${temp%.*} -gt ${tempmax%.*} ]; then
      tempmax=$temp
    fi
    if [ ${temp%.*} -eq ${tempmin%.*} ] && [ ${temp#*.} \< ${tempmin#*.} ] || [ ${temp%.*} -lt ${tempmin%.*} ]; then
      tempmin=$temp
    fi
    if [ ${tempmin} -lt ${CSVarray[1]} ] || [ ${tempmax} -gt ${CSVarray[2]} ]; then
      sed -i "/${month}\/${day}/c${month}\/${day},${tempmin},${tempmax}" ${logfile}
    fi
  fi
else # Initialise log file
  echo "${timestamp},${temp},${temp}" >> $logfile
fi
