#!/bin/bash
# Lights

# https://www.baeldung.com/linux/jq-command-json
# https://www.baeldung.com/linux/jq-passing-bash-variables
jsonConf=$(cat /var/www/html/data/conf.php.json)
room=$(echo $jsonConf | jq --arg jq_hostname_var $HOSTNAME -r '.rooms.[] | select(.Hostname==$jq_hostname_var)')
lights=$(echo $room | jq -r '.lights')

switchesStatus=()
switchesHostname=()
switchesChannel=()
switchesEvents=()
eventsStartTimes=()
eventsStopTimes=()
eventIndex=0

while read -r json_record; do
  channel=$(echo $lights | jq -r ".$json_record.Channel")
  switchesChannel+=("$channel")
  switchesHostname+=($(echo $lights | jq -r ".$json_record.Hostname"))
  switchesStatus+=("undefined")
  switchesEvents+=("$eventIndex")
  while read -r json_event; do
    eventsStartTimes+=($(echo $lights | jq -r ".$json_record.events[$json_event].startTime"))
    eventsStopTimes+=($(echo $lights | jq -r ".$json_record.events[$json_event].stopTime"))
    ((eventIndex++))
  done < <(echo $(echo $lights | jq -r ".$json_record.events | keys[]"))
done < <(echo $lights | jq -r '. | keys[]')

echo "${switchesEvents[@]}"
echo "${eventsStartTimes[@]}"
echo "${eventsStopTimes[@]}"

exit

# Get schedule
times=()
while read -r json_record; do
  IFS=' ' read -r -a array <<< "$json_record"
  times+=(${array[0]})
done < <(echo $lights | jq -r '.schedule | keys[] as $k | "\($k) \(.[$k])"')

writeLog () { # log message $1
  echo $(date): $1
}


tasmotaChannelSwitch () { # switch $1 cmd $2
  if [[ ${switchesChannel[$1]} == "null" ]]; then
    switchesStatus[$1]=$(wget -qO- http://${switchesHostname[$1]}/cm?cmnd=Power%20OFF)
  else
    switchesStatus[$1]=$(wget -qO- http://${switchesHostname[$1]}/cm?cmnd=Power${switchesChannel[$1]}%20OFF)
  fi
}
tasmotaSwitch () { # switch $1 cmd $2
  if [[ ${switchesStatus[$1]} != *":\"OFF\"}"* ]] && [[ ${switchesStatus[$1]} != *":\"ON\"}"* ]]; then
    tasmotaChannelSwitch $1 $2
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

tasmotaSwitch 0 "OFF"
tasmotaSwitch 1 "OFF"

echo "${switchesHostname[@]}"
echo "${switchesStatus[@]}"
echo "${switchesChannel[@]}"
