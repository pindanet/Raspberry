#!/bin/bash
# Functions 

# ToDo

readonly confFile="/var/www/html/data/conf.php.json"

confDate=$(stat $confFile | grep Modify)
# https://www.baeldung.com/linux/jq-command-json
# https://www.baeldung.com/linux/jq-passing-bash-variables
jsonConf=$(cat $confFile)
room=$(echo $jsonConf | jq --arg jq_hostname_var $HOSTNAME -r '.rooms.[] | select(.Hostname==$jq_hostname_var)')

latitude=$(echo $jsonConf | jq -r ".location.Latitude")
longitude=$(echo $jsonConf | jq -r ".location.Longitude")

declare -A switchesStatus
declare -A switchesHostname
declare -A switchesChannel

function writeLog () { # log message $1
  echo $(date): $1
}

function timeVariables () {
  timeZone=$(date +%-z)
  trim=${timeZone%0}
  while [[ ${timeZone} != ${trim} ]]
  do
    timeZone=${trim}
    trim=${timeZone%0}
  done

  sunriseSet=$(hdate --sun --latitude $latitude --longitude $longitude --timezone $timeZone --not-sunset-aware)
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
