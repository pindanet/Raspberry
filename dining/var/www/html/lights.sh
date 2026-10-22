#!/bin/bash
# Lights and Switches

# ToDo

readonly confFile="/var/www/html/data/conf.php.json"

function writeLog () { # log message $1
  echo $(date): $1
}

function tasmotaChannelSwitch () { # switch $1 cmd $2
  if [[ ${switchesChannel[$1]} == "null" ]]; then
    wgetCmd="wget -qO- http://${switchesHostname[$1]}/cm?cmnd=Power"
  else
    wgetCmd="wget -qO- http://${switchesHostname[$1]}/cm?cmnd=Power${switchesChannel[$1]}"
  fi
  if [[ $# == 2 ]]; then
    wgetCmd+="%20${2}"
  fi
  switchesStatus[$1]=$($wgetCmd)
}

function tasmotaSwitch () { # switch $1 cmd $2
  if [[ ${switchesStatus[$1]} != *":\"OFF\"}"* ]] && [[ ${switchesStatus[$1]} != *":\"ON\"}"* ]]; then
    tasmotaChannelSwitch $1
    if [[ ${switchesStatus[$1]} != *":\"OFF\"}"* ]] && [[ ${switchesStatus[$1]} != *":\"ON\"}"* ]]; then  # Persistent Connection error
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
  if [[ "$1" == "bedtime" ]]; then
    if [ -f /dev/shm/sleep ]; then
      data +"%H:%M"
    else
      echo "23:59"
    fi
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

function processSwitches () { # $1 JSON switches
  local JSONSwitches=("$@")
  while read -r json_record; do  # lights
    disabled=$(echo $JSONSwitches | jq -r ".$json_record.disabled")
    if [[ "$disabled" == "true" || "$disabled" == "null" ]]; then
      continue
    fi
    while read -r json_timeslot; do
      startTime=($(echo $JSONSwitches | jq -r ".$json_record.schedule[$json_timeslot].startTime"))
      startTime=$(timeVar $startTime)
# now="17:30"
      if [[ "$startTime" < "$now" || "$startTime" == "$now" ]]; then
        stopTime=($(echo $JSONSwitches | jq -r ".$json_record.schedule[$json_timeslot].stopTime"))
        stopTime=$(timeVar $stopTime)
        if [[ "$stopTime" > "$now" ]]; then
          switchCmd="ON"
          break
        else
          switchCmd="OFF"
        fi
      else
        switchCmd="OFF"
      fi
    done < <(echo $JSONSwitches | jq -r ".$json_record.schedule | keys[]")
# echo ${LINENO} $json_record $switchCmd
    tasmotaSwitch $json_record $switchCmd
  done < <(echo $JSONSwitches | jq -r '. | keys[]')
}

confDate=$(stat $confFile | grep Modify)
# https://www.baeldung.com/linux/jq-command-json
# https://www.baeldung.com/linux/jq-passing-bash-variables
jsonConf=$(cat $confFile)
room=$(echo $jsonConf | jq --arg jq_hostname_var $HOSTNAME -r '.rooms.[] | select(.Hostname==$jq_hostname_var)')
lights=$(echo $room | jq -r '.lights')
switches=$(echo $room | jq -r '.switches')

declare -A switchesStatus
declare -A switchesHostname
declare -A switchesChannel

while read -r json_record; do # lights
  channel=$(echo $lights | jq -r ".$json_record.Channel")
  switchesChannel["$json_record"]="$channel"
  switchesHostname["$json_record"]=$(echo $lights | jq -r ".$json_record.Hostname")
done < <(echo $lights | jq -r '. | keys[]')

while read -r json_record; do # switches
  channel=$(echo $switches | jq -r ".$json_record.Channel")
  switchesChannel["$json_record"]="$channel"
  switchesHostname["$json_record"]=$(echo $switches | jq -r ".$json_record.Hostname")
done < <(echo $switches | jq -r '. | keys[]')

timeVariables

while :; do
  now=$(date +"%H:%M")
  processSwitches "${lights[@]}"
  processSwitches "${switches[@]}"
  sleep 60 # every minute
  if [[ "$(stat $confFile | grep Modify)" != "$confDate" ]]; then
    exit
  fi
done
