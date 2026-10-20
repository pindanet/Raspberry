#!/bin/bash
# Lights

# ToDo
# Shedule
# disabled

function writeLog () { # log message $1
  echo $(date): $1
}

function tasmotaChannelSwitch () { # switch $1 cmd $2
echo "Tasmota $1 $2"
  if [[ ${switchesChannel[$1]} == "null" ]]; then
    switchesStatus[$1]=$(wget -qO- http://${switchesHostname[$1]}/cm?cmnd=Power%20${2})
  else
    switchesStatus[$1]=$(wget -qO- http://${switchesHostname[$1]}/cm?cmnd=Power${switchesChannel[$1]}%20${2})
  fi
}

function tasmotaSwitch () { # switch $1 cmd $2
  if [[ ${switchesStatus[$1]} != *":\"OFF\"}"* ]] && [[ ${switchesStatus[$1]} != *":\"ON\"}"* ]]; then
    tasmotaChannelSwitch $1 "OFF"
    if [[ ${switchesStatus[$1]} != *":\"OFF\"}"* ]]; then  # Persistent Connection error
      switchesStatus[$1]='{"POWER":"OFF"}'
      writeLog "Recreate power after persistent error for ${switchesHostname[$1]}"
    fi
  fi
  if [[ ${switchesStatus[$1]} == *":\"OFF\"}"* ]] && [[ $2 == "ON" ]]; then
    tasmotaChannelSwitch $1 $2
  elif [[ ${switchesStatus[$1]} == *":\"ON\"}"* ]] && [[ $2 == "OFF" ]]; then
    tasmotaChannelSwitch $1 $2
  fi
}

function timeVar() {
  if [[ "$1" == "bedTime" ]]; then
    echo "22:50"
  elif [[ "${1:2:1}" != ":" ]]; then
    echo ${!1}
  else
    echo $1
  fi
}

function timeVariables () {
  timeZone=$(date +%-z)
  trim=${timeZone%0}
  while [[ ${timeZone} != ${trim} ]]
  do
    timeZone=${trim}
    trim=${timeZone%0}
  done

  sunriseSet=$(hdate --sun --latitude 51.1853335 --longitude 3.2401705 --timezone $timeZone --not-sunset-aware)
  sunrise=$(echo "$sunriseSet" | grep "sunrise")
  sunrise=${sunrise#* }
  sunset=$(echo "$sunriseSet" | grep "sunset")
  sunset=${sunset#* }

  read -r Alarmtime < <(echo $jsonConf | jq -r '[ .Alarmtime] | join(" ")')
  read -r wakeupTime < <(echo $jsonConf | jq -r '[ .wakeupTime] | join(" ")')
  read -r awakeTime < <(echo $jsonConf | jq -r '[ .awakeTime] | join(" ")')

  dateToday=$(date +'%F')
  wakeup=$(date -d "$Alarmtime $dateToday +$wakeupTime minutes" +'%H:%M')
  awake=$(date -d "$wakeup $dateToday +$awakeTime minutes" +'%H:%M')
  if [[ $awake < ${sunrise} ]]; then
    awake=${sunrise}
  fi
}

# https://www.baeldung.com/linux/jq-command-json
# https://www.baeldung.com/linux/jq-passing-bash-variables
jsonConf=$(cat /var/www/html/data/conf.php.json)
room=$(echo $jsonConf | jq --arg jq_hostname_var $HOSTNAME -r '.rooms.[] | select(.Hostname==$jq_hostname_var)')
lights=$(echo $room | jq -r '.lights')

declare -A switchesStatus
declare -A switchesHostname
declare -A switchesChannel

while read -r json_record; do
  channel=$(echo $lights | jq -r ".$json_record.Channel")
  switchesChannel["$json_record"]="$channel"
  switchesHostname["$json_record"]=$(echo $lights | jq -r ".$json_record.Hostname")
  tasmotaSwitch $json_record "OFF" # Initialise
done < <(echo $lights | jq -r '. | keys[]')

timeVariables

while :; do
  now=$(date +"%H:%M")
  while read -r json_record; do
    while read -r json_event; do
      startTime=($(echo $lights | jq -r ".$json_record.events[$json_event].startTime"))
      startTime=$(timeVar $startTime)
# now="20:30"
# echo "$now $startTime"
      if [[ "$startTime" < "$now" || "$startTime" == "$now" ]]; then
        stopTime=($(echo $lights | jq -r ".$json_record.events[$json_event].stopTime"))
        stopTime=$(timeVar $stopTime)
# echo "$now $startTime $stopTime"
        if [[ "$stopTime" > "$now" ]]; then
          switchCmd="ON"
          break
        else
          switchCmd="OFF"
        fi
      else
        switchCmd="OFF"
      fi
    done < <(echo $lights | jq -r ".$json_record.events | keys[]")
# echo $json_record $switchCmd
    tasmotaSwitch $json_record $switchCmd
  done < <(echo $lights | jq -r '. | keys[]')
  sleep 60 # every minute
done
# echo "${switchesChannel[@]}"
