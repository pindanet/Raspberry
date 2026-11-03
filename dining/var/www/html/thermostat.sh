#!/bin/bash
# Thermostat 

# ToDo

source /var/www/html/functions.sh

thermostat=$(echo $room | jq -r '.thermostat')
heaters=$(echo $thermostat | jq -r '.heater')
read -r tempCorrection pullupGPIO powerGPIO < <(echo $thermostat | jq -r '[ .tempCorrection, .ds18b20.pullupGPIO, .ds18b20.powerGPIO] | join(" ")')
read -r tempComfort tempAux tempOff tempNight tempNightTime hysteresis < <(echo $jsonConf | jq -r '[ .thermostat.tempComfort, .thermostat.tempAux, .thermostat.tempOff, .thermostat.tempNight, .thermostat.tempNightTime, .thermostat.hysteresis] | join(" ")')

while read -r json_record; do # heaters
  channel=$(echo $heaters | jq -r ".$json_record.Channel")
  switchesChannel["$json_record"]="$channel"
  switchesHostname["$json_record"]=$(echo $heaters | jq -r ".$json_record.Hostname")
done < <(echo $heaters | jq -r '. | keys[]')

timeVariables

# Get thermostat schedule
times=()
temps=()
while read -r json_record; do
  IFS=' ' read -r -a array <<< "$json_record"
  times+=(${array[0]})
  temps+=(${array[1]})
done < <(echo $thermostat | jq -r '.schedule | keys[] as $k | "\($k) \(.[$k])"')

# Initialise
if [ -f /dev/shm/temp.count ]; then
  rm /dev/shm/temp.count
fi

# echo "${times[@]}"

while :; do
  # DS18B20
  # GPIO 17 (11) (switchable 3,3 V) naar Vdd (Rood)
  # GPIO4 (7) naar Data (Geel) naar 4k7 naar 3,3 V (Orange)(GPIO27)
  # GND (9) naar GND (Zwart)
  output=$(cat /sys/bus/w1/devices/28-*/w1_slave)

  if [ $? -ne 0 ]; then # error
    # Reset DS18B20
    # Power off
    pinctrl set $powerGPIO op dl # DS18B20 temperature sensor power off
    pinctrl set $pullupGPIO op dh # PullUp 1-wire Data
    sleep 3
    # Power on
    pinctrl set $powerGPIO op dh # DS18B20 temperature sensor power on
    sleep 5
    writeLog "Reset Ds18b20"
  else
    if [[ $output != *"YES"* ]]; then
      writeLog "Ds18b20 CRC error"
    else
      temp="${output#*t=}"
      if [ ! -f /dev/shm/temp.count ]; then
        if [[ $temp == 0 ]]; then
          writeLog "Ds18b20 rejected first 0"
        else
          writeLog "Ds18b20 rejected first measurement"
          touch /dev/shm/temp.count
        fi
        
      fi
      echo $temp
    fi
  fi
    
  now=$(date +"%H:%M")
echo $now
  sleep 60 # every minute
  if [[ "$(stat $confFile | grep Modify)" != "$confDate" ]]; then
    exit
  fi
done
