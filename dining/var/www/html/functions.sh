#!/bin/bash
# Functions 

# ToDo
readonly binDir="/var/www/html/"
readonly dataDir="${binDir}data/"
readonly memDir="/dev/shm/"
readonly confFile="${dataDir}conf.php.json"

confDate=$(stat $confFile | grep Modify)
# https://www.baeldung.com/linux/jq-command-json
# https://www.baeldung.com/linux/jq-passing-bash-variables
jsonConf=$(cat $confFile)
room=$(echo $jsonConf | jq --arg jq_hostname_var $HOSTNAME -r '.rooms.[] | select(.Hostname==$jq_hostname_var)')

latitude=$(echo $jsonConf | jq -r ".location.Latitude")
longitude=$(echo $jsonConf | jq -r ".location.Longitude")

# declare -A switchesStatus
# declare -A switchesHostname
# declare -A switchesChannel
switchesStatus=()
switchesHostname=()
switchesChannel=()
declare -A timeVar

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
  timeVar[sunrise]=${sunrise#* }
  sunset=$(echo "$sunriseSet" | grep "sunset")
  timeVar[sunset]=${sunset#* }

  read -r timeVar[Alarmtime] < <(echo $jsonConf | jq -r '[ .Alarmtime] | join(" ")')
  read -r timeVar[wakeupTime] < <(echo $jsonConf | jq -r '[ .wakeupTime] | join(" ")')
  read -r timeVar[awakeTime] < <(echo $jsonConf | jq -r '[ .awakeTime] | join(" ")')

  dateToday=$(date +'%F')
  timeVar[preHeating]=$(date -d "${timeVar[Alarmtime]} $dateToday -60 minutes" +'%H:%M')
  timeVar[wakeup]=$(date -d "${timeVar[Alarmtime]} $dateToday +${timeVar[wakeupTime]} minutes" +'%H:%M')
  timeVar[awake]=$(date -d "${timeVar[wakeup]} $dateToday +${timeVar[awakeTime]} minutes" +'%H:%M')
  if [[ ${timeVar[awake]} < ${timeVar[sunrise]} ]]; then
    timeVar[awake]=${timeVar[sunrise]}
  fi
  timeVar[bedtime]="24:00"
}
