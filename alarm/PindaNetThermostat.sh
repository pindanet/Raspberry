#!/bin/bash
heating () {
  if [ $1 == "on" ] && [ $(gpio -g read 16) -eq 1 ]; then
    gpio -g mode 16 out
    gpio -g write 16 0
    echo "$(date): Heating $2 on" >> /var/PindaNet/debug.txt
  elif [ $(gpio -g read 16) -eq 0 ]; then
    gpio -g mode 16 out
    gpio -g write 16 1
    echo "$(date): Heating $2 off" >> /var/PindaNet/debug.txt
  fi
}

if [ ! -f /var/PindaNet/thermostat ]; then
  cat > /var/PindaNet/thermostat <<EOF
0;08:00;20.00 0;10:45;21.00 0;21:40;15.00 \
1;07:00;20.00 \
3;23:59;15.00 \
4;07:30;20.00
EOF
fi
thermostat=`cat /var/PindaNet/thermostat`
weekday=$(date +%u)
((weekday--))
now=$(date +%H:%M)

thermostatTemp=${thermostat: -4}

data=${thermostat:0:13}
thermostat=${thermostat: 14}
while [ "$data" != "" ]; do
  if [[ "${data:0:1}" > "$weekday" ]]; then
    break
  fi
  if [[ "${data:2:5}" < "$now" ]]; then
    thermostatTemp=${data:8:5}
  fi 
  data=${thermostat:0:13}
  thermostat=${thermostat: 14}
done

temp=$(tail -1 /var/PindaNet/PresHumiTemp)
temp=${temp%% C*}

if [ $(cat /var/PindaNet/heating) == "on" ]; then
  heating on "manual"
elif [ $(cat /var/PindaNet/heating) == "off" ]; then
  heating off "manual"
else
  if [[ "$temp" < $thermostatTemp ]]; then
    heating on "auto ($temp)"
  else
    heating off "auto ($temp)"
  fi
fi
