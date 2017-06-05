#!/bin/bash
echo -e "Content-type: text/html\n"
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
json="${json/controltemp\":\"[^\"]*\"/controltemp\":\"$temp\"}"

cd data
manual=`echo $json | jq --raw-output ".[7] | .manual"`
if [ $manual == "Off" ]; then
  sensorTemp=`python /var/www/html/bme280.py | tail -3 | head -1 | awk '{ print $3 }'`
  heating=$(awk 'BEGIN{ print "'$temp'"<"'$sensorTemp'" }')
  if [ "$heating" -eq 1 ]; then
    python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s 0B1100010141538601000080
    json="${json/heating\":\"On/heating\":\"Off}"
  else
    python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s 0B1100000141538601010F80
    json="${json/heating\":\"Off/heating\":\"On}"
  fi
else
  heating=`echo $json | jq --raw-output ".[7] | .heating"`
  if [ "$heating" == "Off" ]; then
    python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s 0B1100010141538601000080
    json="${json/heating\":\"On/heating\":\"Off}"
  else
    python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s 0B1100000141538601010F80
    json="${json/heating\":\"Off/heating\":\"On}"
  fi
fi
cd ..
printf $json | openssl base64 -A > /var/www/html/data/thermostat.json
echo >> /var/www/html/data/thermostat.json
cat /var/www/html/data/thermostat.json
