#!/bin/bash
# ToDo

## Compensate temperature sensor
#tempOffset=-0.4
tempfact=1  # Zomer, omgevingstemp: 0.97, Winter, IR temp: 1.00

function relayGPIO () {
  _r1_pin=${1#*relayGPIO}

  if [ ! -f /tmp/$1 ]; then # initialize
    echo '{"POWER":"ON"}' > /tmp/$1
    echo "$(date -u +%s),off" >> /var/www/html/data/$1.log
  fi
  if [ $2 == "on" ] && [ "$(cat /tmp/$1)" == '{"POWER":"OFF"}' ]; then
    raspi-gpio set $_r1_pin op dl # Power on
    echo '{"POWER":"ON"}' > /tmp/$1
    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
  elif [ $2 == "off" ] && [ "$(cat /tmp/$1)" == '{"POWER":"ON"}' ]; then
    raspi-gpio set $_r1_pin op dh # Power off
    echo '{"POWER":"OFF"}' > /tmp/$1
    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
  elif [ "$(cat /tmp/$1)" != '{"POWER":"OFF"}' ] && [ "$(/tmp/$1)" != '{"POWER":"ON"}' ]; then
    echo '{"POWER":"ON"}' > /tmp/$1
    echo "$(date): Relay error. Heating $1" >> /tmp/PindaNetDebug.txt
  fi
}
declare -A status=()
function tasmota () {
  if [[ $1 == *"relayGPIO"* ]]; then
    relayGPIO $1 $2
    return
  fi
  if [ -z ${status["$1"]} ]; then # initialize
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power)
    two=$(echo ${status["$1"]} | awk -F"\"" '{print $4}')
    twolower=${two,,}
    if [ $twolower == "on" ] || [ $twolower == "off" ]; then
      echo "$(date -u +%s),$twolower" >> /var/www/html/data/$1.log
    fi
  fi
  if [ $2 == "on" ] && [ "${status["$1"]}" == '{"POWER":"OFF"}' ]; then
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power%20On)
    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
  elif [ $2 == "off" ] && [ "${status["$1"]}" == '{"POWER":"ON"}' ]; then
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power%20Off)
    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
  elif [ "${status["$1"]}" != '{"POWER":"OFF"}' ] && [ "${status["$1"]}" != '{"POWER":"ON"}' ]; then
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power)
    echo "$(date): Communication error. Heating $1" >> /tmp/PindaNetDebug.txt
  fi

#  if [ ! -f /tmp/$1 ]; then # initialize
#    echo $(wget -qO- http://$1/cm?cmnd=Power) > /tmp/$1
#    two=$(wget -qO- http://$1/cm?cmnd=Power | awk -F"\"" '{print $4}')
#    twolower=${two,,}
#    if [ $twolower == "on" ] || [ $twolower == "off" ]; then
#      echo "$(date -u +%s),$twolower" >> /var/www/html/data/$1.log
#    fi
#  fi
#  if [ $2 == "on" ] && [ "$(cat /tmp/$1)" == '{"POWER":"OFF"}' ]; then
#    dummy=$(wget -qO- http://$1/cm?cmnd=Power%20On)
#    echo $(wget -qO- http://$1/cm?cmnd=Power) > /tmp/$1
#    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
#  elif [ $2 == "off" ] && [ "$(cat /tmp/$1)" == '{"POWER":"ON"}' ]; then
#    dummy=$(wget -qO- http://$1/cm?cmnd=Power%20Off)
#    echo $(wget -qO- http://$1/cm?cmnd=Power) > /tmp/$1
#    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
#  elif [ "$(cat /tmp/$1)" != '{"POWER":"OFF"}' ] && [ "$(cat /tmp/$1)" != '{"POWER":"ON"}' ]; then
#    echo $(wget -qO- http://$1/cm?cmnd=Power) > /tmp/$1
#    echo "$(date): Communication error. Heating $1" >> /tmp/PindaNetDebug.txt
#  fi
}
#function thermostatOff {
#  for switch in "${!heater[@]}"
#  do
#     tasmota ${heater[$switch]} "off"
#  done
#}

function thermostat {
  temp=$(tail -1 $PresHumiTempfile)
  temp=${temp%% C*}
  # remove leading whitespace characters
  temp="${temp#"${temp%%[![:space:]]*}"}"

  # minimum maximum temp
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

   unset thermostatdefault
   DOW=$(date +%u)
#   echo $DOW
   for thermostatday in "${thermostatkitchenweek[@]}"; do
     daytime=(${thermostatday})
     if [ "$DOW" == "${daytime[0]}" ]; then
       thermostatdefault+=("${daytime[1]} ${daytime[2]} ${daytime[3]} ")
     fi
   done
 
#   for thermostatitem in "${thermostatdefault[@]}"; do
#     daytime=(${thermostatitem})
#     echo ${daytime[0]} ${daytime[1]} ${daytime[2]} ${daytime[3]}
#   done

  IFS=$'\n' thermostatroom=($(sort <<<"${thermostatdefault[*]}"))
  unset IFS

  heatingRoom="off"
# Default times for heating
  for thermostatitem in "${thermostatroom[@]}"; do
    daytime=(${thermostatitem})
    if [[ "${daytime[0]}" < "$now" || "${daytime[0]}" == "$now" ]] && [[ "${daytime[1]}" > "$now" ]]; then
      heatingRoom="on"
      if [[ -v "daytime[2]" ]] ; then
#        echo "tempComfort: ${daytime[2]}"
        tempComfort=${daytime[2]}
      fi
      break
    fi
  done
# Exceptions with recurrent dates and times
  for thermostatitem in "${thermostatroomevent[@]}"; do
    daytime=(${thermostatitem})
    recevent=$(date -u --date "${daytime[0]}" +%s)
    timebetween=$((${daytime[1]} * 86400))
    nowSec=$(date -u +%s)
    today=$((nowSec - (nowSec % 86400)))
    if [[ "$timebetween" > "0" ]]; then # repeating event
      while  [ $recevent -lt $today ]; do
        recevent=$((recevent + timebetween))
      done
    fi
    if [ $today == $recevent ]; then
      echo "Event in $room on $(date -u --date @$recevent)"
      if [[ "${daytime[2]}" < "$now" || "${daytime[2]}" == "$now" ]] && [[ "${daytime[3]}" > "$now" ]]; then
        heatingRoom=${daytime[4]}
        if [[ -v "daytime[5]" ]] ; then
          tempComfort=${daytime[5]}
        fi
        echo "Between ${daytime[2]} en ${daytime[3]}: heating: ${daytime[4]}, temp: $tempComfort °C"
        break
      fi
    fi
  done

  tempWanted=$tempComfort

  roomtemp=$(cat /tmp/thermostatManual)
  if [ $? -gt 0 ]; then
    echo "Auto"
  else
    if [ "$roomtemp" == "off" ]; then
      echo "Heating Manual Off"
      heatingRoom="off"
    else
      tempWanted=$(awk "BEGIN {print ($roomtemp + $tempOffset)}")
      echo "Manual temp $room: $tempWanted °C"
      heatingRoom="on"
    fi
  fi
  if [ "$heatingRoom" == "off" ]; then
    if [[ "$tempNightTime" > "$now" ]]; then
      echo "Heating: off at night, $tempNight °C"
      tempWanted=$tempNight
    else
      echo "Heating: off, $tempOff °C"
      tempWanted=$tempOff
    fi
  fi
  total=${#heaterRoom[@]}
  for (( i=0; i<$total; i++ )); do
    tempToggle=$(awk "BEGIN {print ($tempWanted - $hysteresis - $hysteresis * (2 * $i))}")
    echo "${heaterRoom[$i]} switch on at $tempToggle °C."
    if (( $(awk "BEGIN {print ($temp < $tempToggle)}") )); then
      echo "${heaterRoom[$i]} on at $temp °C."
      tasmota ${heater[${heaterRoom[$i]}]} on
    fi
    tempToggle=$(awk "BEGIN {print ($tempWanted + $hysteresis - $hysteresis * (2 * $i))}")
    echo "${heaterRoom[$i]} switch off at $tempToggle °C."
    if (( $(awk "BEGIN {print ($temp > $tempToggle)}") )); then
      echo "${heaterRoom[$i]} off at $temp °C."
      tasmota ${heater[${heaterRoom[$i]}]} off
    fi
  done
}

if [ -f "/root/thermostatManual" ]; then
  mv /root/thermostatManual /tmp/thermostatManual
fi

while true
do
#  timerfile="/var/www/html/data/timer"
#  thermostatkitchenfile="/var/www/html/data/thermostatkitchen"
  room="Keuken"
  PresHumiTempfile="/var/www/html/data/PresHumiTemp"
  stderrLogfile="/var/www/html/stderr.log"

  # Received new configuration file
  if [ -f /tmp/thermostat ]; then
    mv -f /tmp/thermostat /var/www/html/data/thermostat
  fi
  . /var/www/html/data/thermostat

  thermostatroomdefault=("${thermostatkitchendefault[@]}")
  thermostatroomevent=("${thermostatkitchenevent[@]}")
  tempOffset=$kitchenTempOffset

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

  if [ -f /tmp/thermostatReset ]; then
    echo "Resetting thermostat"
    for switch in "${!heater[@]}"
    do
      heateritem=${heater[$switch]}
      if [[ "$heateritem" == tasmota* ]]; then
          tempfile="/var/www/html/data/${heateritem:0:19}"
      fi
      if [ -f $tempfile ]; then
        rm $tempfile
      fi
    done
    rm /tmp/thermostatReset
  fi

  # Collect sensordata
  # MCP9808 I2C Temperature and Pressure Sensor
  # 3v3 - Vin (red)
  # Gnd - Gnd (black)
  # BCM 3 (SCL) - SCK (Brown)
  # BCM 2 (SDA) - SDI (White)
  # read temperature from sensor
#  mcp9808.py > $PresHumiTempfile
  error_file=$(mktemp)
  PresHumiTempVar=$(mcp9808.py 2>$error_file)
  if [ "$?" -ne 0 ]; then # skip faulty reading
      echo "___________________________" >> $stderrLogfile
      echo "$(date)" >> $stderrLogfile
      echo "$(< $error_file)" >> $stderrLogfile
    else
      temp=$PresHumiTempVar
      newtemp=$(awk "BEGIN {printf \"%0.2f\", ($temp * $tempfact)}")
      echo "$newtemp" > $PresHumiTempfile
  fi
  rm $error_file

  weekday=$(date +%w)
  now=$(date +%H:%M)

  thermostat

  sleep 55
done
