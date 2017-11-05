#!/bin/bash
echo -e "Content-type: text/html\n"
if [ -f /var/www/html/data/thermostat.json ]; then
  json=`cat /var/www/html/data/thermostat.json | openssl base64 -d`
else
  json='[[{"time":"08:00","temp":"20"},{"time":"10:45","temp":"21"},{"time":"21:40","temp":"15"}],[{"time":"07:00","temp":"20"}],[],[{"time":"23:59","temp":"15"}],[{"time":"07:30","temp":"20"}],[],[],{"manual":"Off","heating":"Off","controltemp":"20","roomtemp":"32.72"}]'
fi

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

controltemp=`echo $json | jq --raw-output ".[7] | .controltemp"`
json="${json/controltemp\":\"$controltemp\"/controltemp\":\"$temp\"}"

sensorTemp=`python /var/www/html/bme280.py | tail -3 | head -1 | awk '{ print $3 }'`
roomtemp=`echo $json | jq --raw-output ".[7] | .roomtemp"`
json="${json/roomtemp\":\"$roomtemp\"/roomtemp\":\"$sensorTemp\"}"

cd data
manual=`echo $json | jq --raw-output ".[7] | .manual"`
if [ $manual == "Off" ]; then
  heating=$(awk 'BEGIN{ print '$temp'<'$sensorTemp' }')
  if [ "$heating" -eq 1 ]; then
    python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "0B 11 00 00 01 41 53 86 01 00 00 80" &
    json="${json/heating\":\"On/heating\":\"Off}"
  else
    python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "0B 11 00 00 01 41 53 86 01 01 0F 80" &
    json="${json/heating\":\"Off/heating\":\"On}"
  fi
else
  heating=`echo $json | jq --raw-output ".[7] | .heating"`
  if [ "$heating" == "Off" ]; then
    python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "0B 11 00 00 01 41 53 86 01 00 00 80" &
    json="${json/heating\":\"On/heating\":\"Off}"
  else
    python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "0B 11 00 00 01 41 53 86 01 01 0F 80" &
    json="${json/heating\":\"Off/heating\":\"On}"
  fi
fi
cd ..
printf $json | openssl base64 -A > /var/www/html/data/thermostat.json
echo >> /var/www/html/data/thermostat.json
cat /var/www/html/data/thermostat.json
