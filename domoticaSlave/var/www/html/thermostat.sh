#!/bin/bash
# Thermostat

#ToDo
# tasmota Channel

#tempStorage /dev/shm/PindaDomo/
#/var/wwww/html/data/temp.log naar tempStorage
#   schrijven naar beiden

# Delete from conf.php.conf
# "sensorPowerGPIO": 17,
# "tasmota": {},

# Read configuration
# https://www.baeldung.com/linux/jq-command-json
# https://www.baeldung.com/linux/jq-passing-bash-variables
jsonConf=$(cat /var/www/html/data/conf.php.json)
read -r controller < <(echo $jsonConf | jq -r '[ .Controller] | join(" ")')
room=$(echo $jsonConf | jq --arg jq_hostname_var $HOSTNAME -r '.rooms.[] | select(.Hostname==$jq_hostname_var)')
thermostat=$(echo $room | jq -r '.thermostat')
read -r tempCorrection dataGPIO powerGPIO tempOff tempNight tempNightTime < <(echo $thermostat | jq -r '[ .tempCorrection, .ds18b20.dataGPIO, .ds18b20.powerGPIO, .tempOff, .tempNight, .tempNightTime] | join(" ")')
# Get thermostat heaters
heatersStatus=()
while read -r json_record; do
  heatersStatus+=($json_record)
done < <(echo $thermostat | jq -r '.heater.[].status')

heatersHostname=()
while read -r json_record; do
  heatersHostname+=($json_record)
done < <(echo $thermostat | jq -r '.heater.[].Hostname')

writeLog () { # log message $1
  echo $(date): $1
}

tasmotaSwitch () { # switch $1 cmd $2
  if [[ ${heatersStatus[$1]} != *":\"OFF\"}"* ]] && [[ ${heatersStatus[$1]} != *":\"ON\"}"* ]]; then
    heatersStatus[$1]=$(wget -qO- http://${heatersHostname[$1]}/cm?cmnd=Power%20OFF)
    if [[ ${heatersStatus[$1]} != *":\"OFF\"}"* ]]; then  # Persistent Connection error
      heatersStatus[$1]='{"POWER":"OFF"}'
      writeLog "Recreate power after persistent error for ${heatersHostname[$1]}"
    fi
  fi
  if [[ ${heatersStatus[$1]} == *":\"OFF\"}"* ]] && [[ $2 == "ON" ]]; then
    XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 wtype heaterOn -k return
    heatersStatus[$1]=$(wget -qO- http://${heatersHostname[$1]}/cm?cmnd=Power%20ON)

  elif [[ ${heatersStatus[$1]} == *":\"ON\"}"* ]] && [[ $2 == "OFF" ]]; then
    XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 wtype heaterOff -k return
    heatersStatus[$1]=$(wget -qO- http://${heatersHostname[$1]}/cm?cmnd=Power%20OFF)
  fi
}

# Get thermostat schedule
times=()
temps=()
while read -r json_record; do
  IFS=' ' read -r -a array <<< "$json_record"
  times+=(${array[0]})
  temps+=(${array[1]})
done < <(echo $thermostat | jq -r '.schedule | keys[] as $k | "\($k) \(.[$k])"')

#i=0
#for time in "${times[@]}"
#do
#  echo $time ${temps[$i]}
#  ((i++))
#done

# Initialise
if [ -f /tmp/PinDa.temp.count ]; then
  rm /tmp/PinDa.temp.count
fi
# PullUp 1-wire Data
pinctrl set 4 ip pu

while :
do
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
    writeLog "Reset Ds18b20"
  else
    if [[ $output != *"YES"* ]]; then
      writeLog Ds18b20 CRC error
    else
      temp="${output#*t=}"
      if [ ! -f /tmp/PinDa.temp.count ]; then
        if [[ $temp == 0 ]]; then
          writeLog "Ds18b20 rejected first 0"
        else
          writeLog "Ds18b20 rejected first measurement"
          touch /tmp/PinDa.temp.count
        fi
      else
        echo $temp > /tmp/temp

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
        temp=$(awk "BEGIN { printf(\"%.1f\", $temp / 1000 + $tempCorrection) }")

        XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 wtype t=$temp -k return

        now=$(date +"%H:%M")
        if (($(cat /sys/class/backlight/10-0045/brightness) > 0)); then
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
            tasmotaSwitch 0 "ON"
          else
            tasmotaSwitch 0 "OFF"
          fi
        else # No motion
          if [[ $now < ${tempNightTime} ]]; then # Night temperature
            if [[ $temp < $tempNight ]]; then
              tasmotaSwitch 0 "ON"
            else
              tasmotaSwitch 0 "OFF"
            fi
          else # Day Off temperature
            if [[ $temp < $tempOff ]]; then
              tasmotaSwitch 0 "ON"
            else
              tasmotaSwitch 0 "OFF"
            fi
          fi
        fi
      fi
    fi
  fi
  sleep 60 # every minute
done
