#!/bin/bash
# ToDo

function tasmota () {
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
function thermostatOff {
  for switch in "${!heater[@]}"
  do
     tasmota ${heater[$switch]} "off"
  done
}

function thermostat {
  temp=$(tail -1 $PresHumiTempfile)
  temp=${temp%% C*}
  # remove leading whitespace characters
  temp="${temp#"${temp%%[![:space:]]*}"}"

  # mininmum maximum temp
### ToDo Reset dagelijkse tempmax, tempmin
  if [ ! -f /var/www/html/data/tempmax ]; then
    echo 0 > /var/www/html/data/tempmax
  fi
  tempmax=$(cat /var/www/html/data/tempmax)
  if [ ! -f /var/www/html/data/tempmin ]; then
    echo 100 > /var/www/html/data/tempmin
  fi
  tempmin=$(cat /var/www/html/data/tempmin)
  if [ ${temp%.*} -eq ${tempmax%.*} ] && [ ${temp#*.} \> ${tempmax#*.} ] || [ ${temp%.*} -gt ${tempmax%.*} ]; then
    tempmax=$temp
    echo $tempmax > /var/www/html/data/tempmax
    echo "Min: $tempmin, Max: $tempmax" > /var/www/html/data/temp$(date +%A)
  fi
  if [ ${temp%.*} -eq ${tempmin%.*} ] && [ ${temp#*.} \< ${tempmin#*.} ] || [ ${temp%.*} -lt ${tempmin%.*} ]; then
    tempmin=$temp
    echo $tempmin > /var/www/html/data/tempmin
    echo "Min: $tempmin, Max: $tempmax" > /var/www/html/data/temp$(date +%A)
  fi

  IFS=$'\n' thermostatkitchen=($(sort <<<"${thermostatkitchendefault[*]}"))
  unset IFS
#  unset raw

  heatingKitchen="off"
# Default times for heating
  for thermostatitem in "${thermostatkitchen[@]}"; do
    daytime=(${thermostatitem})
    if [[ "${daytime[0]}" < "$now" ]] && [[ "${daytime[1]}" > "$now" ]]; then
      heatingKitchen="on"
      break
    fi
  done
# Exceptions with recurrent dates and times
  for thermostatitem in "${thermostatkitchenevent[@]}"; do
    daytime=(${thermostatitem})
    recevent=$(date -u --date "${daytime[0]}" +%s)
    timebetween=$((${daytime[1]} * 86400))
    nowSec=$(date -u +%s)
    today=$((nowSec - (nowSec % 86400)))
    while  [ $recevent -lt $today ]; do
      recevent=$((recevent + timebetween))
    done
#    echo $today $recevent
    if [ $today == $recevent ]; then
      echo "Event in Keuken op $(date -u --date @$recevent)"
      if [[ "${daytime[2]}" < "$now" ]] && [[ "${daytime[3]}" > "$now" ]]; then
        echo "Tussen ${daytime[2]} en ${daytime[3]}: heatingKitchen: ${daytime[4]}"
        heatingKitchen=${daytime[4]}
        break
      fi
    fi
  done

  tempWanted=$tempComfort

  roomtemp=$(wget -qO- http://pindadomo/data/thermostatManualkitchen)
  if [ $? -gt 0 ]; then
    echo Auto
  else
#  fi
#  if [ -f /var/www/html/data/thermostatManualkitchen ]; then
#    read roomtemp < /var/www/html/data/thermostatManualkitchen
    tempWanted=$roomtemp
    echo "Manual temp kichen: $tempWanted °C"
    heatingKitchen="on"
  fi
  if [ "$heatingKitchen" == "off" ]; then
    echo "Keuken basisverwarming"
    tempWanted=$(awk "BEGIN {print ($tempComfort - 5)}")
  fi
#  if [ "$heatingKitchen" == "on" ]; then
  total=${#heaterKeuken[@]}
  for (( i=0; i<$total; i++ )); do
#    tempToggle=$(awk "BEGIN {print ($tempWanted + ($hysteresis * 2) - $hysteresis - $hysteresis * (2 * $i))}")
    tempToggle=$(awk "BEGIN {print ($tempWanted - $hysteresis - $hysteresis * (2 * $i))}")
#    echo  ${heater[${heaterKeuken[$i]}]}
    echo "${heaterKeuken[$i]} aan bij $tempToggle °C."
    if (( $(awk "BEGIN {print ($temp < $tempToggle)}") )); then
      echo "${heaterKeuken[$i]} ingeschakeld bij $temp °C."
      tasmota ${heater[${heaterKeuken[$i]}]} on
    fi
    tempToggle=$(awk "BEGIN {print ($tempWanted + $hysteresis - $hysteresis * (2 * $i))}")
    echo "${heaterKeuken[$i]} uit bij $tempToggle °C."
    if (( $(awk "BEGIN {print ($temp > $tempToggle)}") )); then
      echo "${heaterKeuken[$i]} uitgeschakeld bij $temp °C."
      tasmota ${heater[${heaterKeuken[$i]}]} off
    fi
  done
}

_pir_pin=4 # BCM4
 
# https://raspberrypi-aa.github.io/session2/bash.html
# Clean up on ^C and TERM, use 'gpio unexportall' to flush everything manually.
#trap "gpio unexport $_pir_pin" INT TERM
if [ -d "/sys/class/gpio/gpio$_pir_pin" ]; then
  echo $_pir_pin > /sys/class/gpio/unexport
fi
fotomap="/var/www/html/motion/fotos"
if [ ! -d "$fotomap" ]; then
  mkdir -p "$fotomap"
fi
 
#   Exports pin to userspace
echo $_pir_pin > /sys/class/gpio/export
# Sets pin as an input
echo "in" > /sys/class/gpio/gpio$_pir_pin/direction
 
# Let PIR settle to ambient IR to avoid false positives? 
# Uncomment line below.
#sleep 30
 
while true
do
  timerfile="/var/www/html/data/timer"
  thermostatkitchenfile="/var/www/html/data/thermostatkitchen"
  PresHumiTempfile="/var/www/html/data/PresHumiTemp"

  if [ -f /tmp/thermostat ]; then
    mv -f /tmp/thermostat /var/www/html/data/thermostat
  fi
  . /var/www/html/data/thermostat

  declare -A heater
  unset heaterKeuken
  declare -a heaterKeuken
  for heateritem in "${heaters[@]}"; do
    line=(${heateritem})
    heater[${line[0]}]=${line[1]}
    if [ ${heateritem:0:6} == "Keuken" ]; then
      heaterKeuken+=(${line[0]})
    fi
  done
#  printf '%s\n' "${heaterKeuken[@]}"

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

  # Collect sensordata
  # MCP9808 I2C Temperature and Pressure Sensor
  # 3v3 - Vin (Orange)
  # Gnd - Gnd (Yellow)
  # BCM 3 (SCL) - SCK (Green)
  # BCM 2 (SDA) - SDI (Blue)
  # read temperature from sensor
  mcp9808.py > $PresHumiTempfile

  weekday=$(date +%w)
  now=$(date +%H:%M)

  thermostat

  echo "heatingKitchen: $heatingKitchen"

if true; then # Dummy
  sleep 55
else # Niet uitvoeren

# mood lighting on/off
  sunset=$(hdate -s -l N51 -L E3 -z0 -q | tail -c 6)
  startInterval=$(date -u --date='-1 minute' +"%H:%M")
  endInterval=$(date -u --date='+1 minute' +"%H:%M")
echo "sunset:$sunset start:$startInterval end:$endInterval"
  if [[ $startInterval < $sunset ]] && [[ $endInterval > $sunset ]]; then
#    dummy=$(wget -qO- http://tasmota_e7b609-5641/cm?cmnd=Power%20On)
    echo "Mood light On"
  elif [[ $startInterval > $sunset ]]; then
    startInterval=$(date --date='-1 minute' +"%H:%M")
    endInterval=$(date --date='+1 minute' +"%H:%M")
echo "start:$startInterval end:$endInterval light:$lightliving"
    if [[ $startInterval < $lightliving ]] && [[ $endInterval > $lightliving ]]; then
      echo "Mood light Off"
#      dummy=$(wget -qO- http://tasmota_e7b609-5641/cm?cmnd=Power%20Off)
    fi
  fi

# PIR detector for 1 minute
  starttime=$(date +"%s")
  while [ $(($(date +"%s") - starttime)) -lt 60 ]; do
    _ret=$( cat /sys/class/gpio/gpio$_pir_pin/value )
    if [ $_ret -eq 1 ]; then
      echo "[!] PIR is tripped, Smile ..."
      sleep 3 # time to reset PIR
    elif [ $_ret -eq 0 ]; then
#       echo "Geen beweging"
      sleep 3 # time to reset PIR
    fi
#    echo $(($(date +"%s") - starttime))
  done

fi # Einde niet uitvoeren

done
