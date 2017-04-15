#!/bin/bash
json=`cat /var/www/html/data/thermostat.json | openssl base64 -d`
temp="5"
weekday=`date +%w`
currenttime=`date +%H:%M`

day=0
while [ $day -lt $weekday ]; do
  timetemp=0
  thermostatTime=`echo $json | jq --raw-output ".[$day] | .[$timetemp] | .time"`
  thermostatTemp=`echo $json | jq --raw-output ".[$day] | .[$timetemp] | .temp"`
  until [ $thermostatTemp == "null" ]; do
    temp=$thermostatTemp
    let timetemp=timetemp+1
    thermostatTemp=`echo $json | jq --raw-output ".[$day] | .[$timetemp] | .temp"`
  done
  let day=day+1
done

timetemp=0
thermostatTime=`echo $json | jq --raw-output ".[$weekday] | .[$timetemp] | .time"`
until [[ $thermostatTime == "null" || $thermostatTime > $currenttime ]]; do
  temp=`echo $json | jq --raw-output ".[$weekday] | .[$timetemp] | .temp"`
  let timetemp=timetemp+1
  thermostatTime=`echo $json | jq --raw-output ".[$weekday] | .[$timetemp] | .time"`
done
echo $temp
