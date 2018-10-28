#!/bin/bash
heating () {
  if [ $1 == "on" ] && [ $(gpio -g read 16) -eq 1 ]; then
    gpio -g mode 16 out
    gpio -g write 16 0
    echo "$(date): Heating $2 on" >> /var/PindaNet/debug.txt
  elif [ $1 == "off" ] && [ $(gpio -g read 16) -eq 0 ]; then
    gpio -g mode 16 out
    gpio -g write 16 1
    echo "$(date): Heating $2 off" >> /var/PindaNet/debug.txt
  fi
}

if [ $(cat /var/PindaNet/heating) == "on" ]; then
  heating on "manual"
  exit
elif [ $(cat /var/PindaNet/heating) == "off" ]; then
  heating off "manual"
  exit
fi

if [ ! -f /var/PindaNet/thermostat ]; then
  echo -n "0;09:30;20.00 0;21:25;-off- 1;09:30;20.00 1;21:25;-off- 2;09:30;20.00 2;21:25;-off- 3;09:30;20.00 3;21:25;-off- 4;09:30;20.00 4;21:25;-off- 5;09:30;20.00 5;21:25;-off- 6;09:30;20.00 6;21:25;-off-" > /var/PindaNet/thermostat
fi
thermostat=`cat /var/PindaNet/thermostat`
weekday=$(date +%w)
now=$(date +%H:%M)

thermostatTemp=${thermostat: -5}

data=${thermostat:0:13}
thermostat=${thermostat: 14}
while [ "$data" != "" ]; do
  if [[ "${data:0:1}" > "$weekday" ]]; then
    break
  elif [[ "${data:0:1}" < "$weekday" ]]; then
    thermostatTemp=${data:8:5}
  elif [[ "${data:2:5}" < "$now" ]]; then
    thermostatTemp=${data:8:5}
  fi 
  data=${thermostat:0:13}
  thermostat=${thermostat: 14}
done

temp=$(tail -1 /var/PindaNet/PresHumiTemp)
temp=${temp%% C*}

if [ "$thermostatTemp" == "-off-" ]; then
  heating off "auto"
else
  # remove leading whitespace characters
  temp="${temp#"${temp%%[![:space:]]*}"}"
  # normalise floats to compare them
  while [[ ${#temp} < ${#thermostatTemp} ]]; do
    temp="0$temp"
  done
  while [[ ${#thermostatTemp} < ${#temp} ]]; do
    thermostatTemp="0$thermostatTemp"
  done
  if [[ "$temp" < "$thermostatTemp" ]]; then
    heating on "auto ($temp)"
  else
    heating off "auto ($temp)"
  fi
fi
