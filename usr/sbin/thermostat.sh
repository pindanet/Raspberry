#!/bin/bash
json=`cat /var/www/html/data/thermostat.json | openssl base64 -d`
temp="5"
weekday=`date +%w`
currenttime=`date +%H:%M`

for (( day=0; day < $weekday; day++ )) ; do
  timetemp=0
  thermostatTime=`echo $json | jq --raw-output ".[$day] | .[$timetemp] | .time"`
  echo thermostatTime
  while [ ! thermostatTime == "null" ]; do
    echo $day
    timetemp=$((timetemp+1))
    thermostatTime=`echo $json | jq --raw-output ".[$day] | .[$timetemp] | .time"`
  done
done

echo $json | jq --raw-output ".[$weekday] | .[0] | .time"
