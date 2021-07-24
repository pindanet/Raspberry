#!/bin/bash
function relayGPIO () {
  _r1_pin=23
  # Activate GPIO Relay
  if [ ! -d "/sys/class/gpio/gpio$_r1_pin" ]; then
    #   Exports pin to userspace
    echo $_r1_pin > /sys/class/gpio/export
    # Sets pin as an output
    echo "out" > /sys/class/gpio/gpio$_r1_pin/direction
  fi

  if [ ! -f /tmp/$1 ]; then # initialize
    echo '{"POWER":"ON"}' > /tmp/$1
    echo "$(date -u +%s),off" >> /var/www/html/data/$1.log
  fi
  if [ $2 == "on" ] && [ "$(cat /tmp/$1)" == '{"POWER":"OFF"}' ]; then
    echo 0 > /sys/class/gpio/gpio$_r1_pin/value # Power on
    echo '{"POWER":"ON"}' > /tmp/$1
    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
  elif [ $2 == "off" ] && [ "$(cat /tmp/$1)" == '{"POWER":"ON"}' ]; then
    echo 1 > /sys/class/gpio/gpio$_r1_pin/value # Power off
    echo '{"POWER":"OFF"}' > /tmp/$1
    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
  elif [ "$(cat /tmp/$1)" != '{"POWER":"OFF"}' ] && [ "$(cat /tmp/$1)" != '{"POWER":"ON"}' ]; then
    echo '{"POWER":"ON"}' > /tmp/$1
    echo "$(date): Relay error. Heating $1" >> /tmp/PindaNetDebug.txt
  fi
}
function tasmota () {
  if [[ $1 == *"relayGPIO"* ]]; then
    relayGPIO $1 $2
    return
  fi
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

function thermostat {
  temp=$(tail -1 $PresHumiTempfile)
  temp=${temp%% C*}
  temp=${temp%% °C*}
  # remove leading whitespace characters
  temp="${temp#"${temp%%[![:space:]]*}"}"

  IFS=$'\n' thermostatkitchen=($(sort <<<"${thermostatkitchendefault[*]}"))
  unset IFS
#  unset raw
}

. /var/www/html/data/thermostat
while true
do
  starttime=$(date +"%s") # complete cycle: 1 minute

#  temp=$(python /home/*/ds18b20.py)
#  LC_ALL=C printf "%.1f °C" "$temp" > /home/*/temp.txt
########

  room="Dining"
  PresHumiTempfile="/home/*/temp.txt"

  # Received new configuration file
  if [ -f /tmp/thermostat ]; then
    mv -f /tmp/thermostat /var/www/html/data/thermostat
  fi
  . /var/www/html/data/thermostat

  printf '%s\n' "${thermostatdiningdefault[@]}"
  thermostatroomdefault=("${thermostatdiningdefault[@]}")
  printf '%s\n' "${thermostatroomdefault[@]}"
  tempOffset=$diningTempOffset

  # compensate position temperature sensor
#  hysteresis=$(awk "BEGIN {print ($hysteresis * 2)}")
  tempComfort=$(awk "BEGIN {print ($tempComfort + $tempOffset)}")

  declare -A heater
  unset heaterRoom
  declare -a heaterRoom
  for heateritem in "${heaters[@]}"; do
    line=(${heateritem})
    heater[${line[0]}]=${line[1]}
    if [ ${heateritem:0:6} == "$room" ]; then
      heaterRoom+=(${line[0]})
    fi
  done
#  printf '%s\n' "${heaterRoom[@]}"

  if [ -f /tmp/thermostatReset ]; then
    echo "Resetting thermostat"
    for switch in "${!heater[@]}"
    do
      heateritem=${heater[$switch]}
      if [[ "$heateritem" == tasmota* ]]; then
          tempfile="/tmp/${heateritem:0:19}"
      fi
      if [ -f $tempfile ]; then
        rm $tempfile
      fi
    done
    rm /tmp/thermostatReset
  fi

  weekday=$(date +%w)
  now=$(date +%H:%M)

  thermostat

########
  sleepSec=$((60 - ($(date +"%s") - starttime)))
  sleep $sleepSec
done
