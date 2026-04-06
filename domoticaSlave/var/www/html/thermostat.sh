#!/bin/bash
# Thermostat

# Delete from conf.php.conf
# "sensorPowerGPIO": 17,

# Read configuration
# https://www.baeldung.com/linux/jq-command-json
# https://www.baeldung.com/linux/jq-passing-bash-variables
jsonConf=$(cat /var/www/html/data/conf.php.json)
room=$(echo $jsonConf | jq --arg jq_hostname_var $HOSTNAME -r '.rooms.[] | select(.Hostname==$jq_hostname_var)')
thermostat=$(echo $room | jq -r '.thermostat')
read -r dataGPIO powerGPIO tempNightTime < <(echo $thermostat | jq -r '[ .ds18b20.dataGPIO, .ds18b20.powerGPIO, .tempNightTime] | join(" ")')

# Get thermostat schedule
times=()
temps=()
hm=$(date +"%H:%M")
while read -r json_record; do
  IFS=' ' read -r -a array <<< "$json_record"
  if [[ "$hm" > "${array[0]}" ]]; then # Tomorrow
    times+=($(($(date -d"${array[0]}" +%s) + 86400)))
  else # Today
    times+=($(date -d"${array[0]}" +%s))
  fi
#  times+=(${array[0]})
  temps+=(${array[1]})
done < <(echo $thermostat | jq -r '.schedule | keys[] as $k | "\($k) \(.[$k])"')

i=0
for time in "${times[@]}"
do
  echo $(date -d @${time}) ${temps[$i]}
  ((i++))
done

# Initialise
if [ -f /tmp/PinDa.temp.count ]; then
  rm /tmp/PinDa.temp.count
fi

while :
do
  echo Thermostat uitvoeren
# DS18B20
# GPIO 17 (11) (switchable 3,3 V) naar Vdd (Rood)
# GPIO4 (7) naar Data (Geel) naar 4k7 naar 3,3 V (Orange)(GPIO27)
# GND (9) naar GND (Zwart)
  output=$(cat /sys/bus/w1/devices/28-*/w1_slave)
  if [ $? -ne 0 ]; then # error
    # Reset DS18B20
    # Power off
    pinctrl set $powerGPIO op dl # DS18B20 temperature sensor power off
    pinctrl set $dataGPIO op dh # PullUp 1-wire Data
    sleep 3
    # Power on
    pinctrl set $powerGPIO op dh # DS18B20 temperature sensor power on
    sleep 5
    echo "Reset Ds18b20"
  else
    if [[ $output != *"YES"* ]]; then
      echo Ds18b20 CRC error
    else
      temp="${output#*t=}"
      if [ ! -f /tmp/PinDa.temp.count ]; then
        if [[ $temp == 0 ]]; then
          echo "Ds18b20 rejected first 0"
        else
          echo "Ds18b20 rejected first measurement"
          touch /tmp/PinDa.temp.count
        fi
      else
        echo $temp
        echo $temp > /tmp/temp

      fi
    fi
  fi

  sleep 10 # every minute
done

exit


crc=$(echo "${output}" | head -1)
if [[ $crc == *"YES" ]]; then
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
#timestamp=$(date +"%m-%d_")
#if [ ! -f /var/www/html/data/temp.log/${timestamp}tempmax ]; then
#  echo 0 > /var/www/html/data/temp.log/${timestamp}tempmax
#fi
#tempmax=$(cat /var/www/html/data/temp.log/${timestamp}tempmax)
#if [ ! -f /var/www/html/data/temp.log/${timestamp}tempmin ]; then
#  echo 100000 > /var/www/html/data/temp.log/${timestamp}tempmin
#fi
#tempmin=$(cat /var/www/html/data/temp.log/${timestamp}tempmin)
#if [ ${temp%.*} -eq ${tempmax%.*} ] && [ ${temp#*.} \> ${tempmax#*.} ] || [ ${temp%.*} -gt ${tempmax%.*} ]; then
#  tempmax=$temp
#  echo $tempmax > /var/www/html/data/temp.log/${timestamp}tempmax
#fi
#if [ ${temp%.*} -eq ${tempmin%.*} ] && [ ${temp#*.} \< ${tempmin#*.} ] || [ ${temp%.*} -lt ${tempmin%.*} ]; then
#  tempmin=$temp
#  echo $tempmin > /var/www/html/data/temp.log/${timestamp}tempmin
#fi
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


  sleep 60
