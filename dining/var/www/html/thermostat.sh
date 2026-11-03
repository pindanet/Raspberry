#!/bin/bash
# Thermostat 

# ToDo

source /var/www/html/functions.sh

thermostat=$(echo $room | jq -r '.thermostat')
heaters=$(echo $thermostat | jq -r '.heater')
read -r tempCorrection pullupGPIO powerGPIO < <(echo $thermostat | jq -r '[ .tempCorrection, .ds18b20.pullupGPIO, .ds18b20.powerGPIO] | join(" ")')
read -r tempComfort tempAux tempOff tempNight hysteresis < <(echo $jsonConf | jq -r '[ .thermostat.tempComfort, .thermostat.tempAux, .thermostat.tempOff, .thermostat.tempNight, .thermostat.hysteresis] | join(" ")')

while read -r json_record; do # heaters
  channel=$(echo $heaters | jq -r ".$json_record.Channel")
  switchesChannel["$json_record"]="$channel"
  switchesHostname["$json_record"]=$(echo $heaters | jq -r ".$json_record.Hostname")
done < <(echo $heaters | jq -r '. | keys[]')

timeVariables

# Get thermostat schedule
# Substitute time variables
for key in "${!timeVar[@]}"; do
  thermostat=${thermostat//$key/${timeVar[$key]}}
done

times=()
temps=()
while read -r json_record; do
  IFS=' ' read -r -a array <<< "$json_record"
  times+=(${array[0]})
  temps+=(${array[1]})
done < <(echo $thermostat | jq -r '.schedule | keys[] as $k | "\($k) \(.[$k])"')

# Initialise
echo "${LINENO}: Debug"
# if [ -f ${memDir}temp.count ]; then
#   rm ${memDir}temp.count
# fi

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
      if [ ! -f ${memDir}temp.count ]; then
        if [[ $temp == 0 ]]; then
          writeLog "Ds18b20 rejected first 0"
        else
          writeLog "Ds18b20 rejected first measurement"
          touch ${memDir}temp.count
        fi
      else
        echo $temp > ${memDir}temp
        # minimum maximum temp
        logfile="${dataDir}temp.log"
        timestamp=$(date +"%m/%d")
        if [ -f "${logfile}" ]; then
          dateminmax=$(grep "^${timestamp}," ${logfile})
          if [ -z "${dateminmax}" ]; then # first entry for date
            echo "${timestamp},${temp},${temp}" >> ${logfile}
          else # adjust min and max temp
            IFS="," read -r -a CSVarray <<< "$dateminmax"
            tempmin=${CSVarray[1]}
            tempmax=${CSVarray[2]}
            if [ ${temp%.*} -eq ${tempmax%.*} ] && [ ${temp#*.} \> ${tempmax#*.} ] || [ ${temp%.*} -gt ${tempmax%.*} ]; then
              tempmax=$temp
            fi
            if [ ${temp%.*} -eq ${tempmin%.*} ] && [ ${temp#*.} \< ${tempmin#*.} ] || [ ${temp%.*} -lt ${tempmin%.*} ]; then
              tempmin=$temp
            fi
            if [ ${tempmin} -lt ${CSVarray[1]} ] || [ ${tempmax} -gt ${CSVarray[2]} ]; then
              IFS="/" read -r month day <<< "${CSVarray[0]}"
              sed -i "/${month}\/${day}/c${month}\/${day},${tempmin},${tempmax}" ${logfile}
            fi
          fi
        else # Initialise log file
          echo "${timestamp},${temp},${temp}" >> $logfile
        fi
        temp=$(awk "BEGIN { printf(\"%.1f\", $temp / 1000 + $tempCorrection) }")
        now=$(date +"%H:%M")
        # Get Scheduled temp
        i=0
        for time in "${times[@]}"
        do
          if [[ ! $now < ${time} ]]; then # >=
            schedTemp=${temps[$i]}
          else
            break
          fi
          ((i++))
        done
        if [[ $temp < $schedTemp ]]; then # To cold, heater on
echo "${LINENO}: $now $temp $schedTemp ON"
        #   tasmotaSwitch 0 "ON"
        else
echo "${LINENO}: $now $temp $schedTemp OFF"
        #   tasmotaSwitch 0 "OFF"
        fi


      fi
    fi
  fi
    
  sleep 60 # every minute
  if [[ "$(stat $confFile | grep Modify)" != "$confDate" ]]; then
    exit
  fi
done
