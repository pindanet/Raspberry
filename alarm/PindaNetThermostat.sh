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

if [ $(cat /var/PindaNet/heating) == "on" ]; then
  heating on "manual"
  exit
elif [ $(cat /var/PindaNet/heating) == "off" ]; then
  heating off "manual"
  exit
fi

if [ ! -f /var/PindaNet/thermostat ]; then
  cat > /var/PindaNet/thermostat <<EOF
0;09:30;20.00 0;21:25;-off- \
1;09:30;20.00 1;21:25;-off- \
2;09:30;20.00 2;21:25;-off- \
3;09:30;20.00 3;21:25;-off- \
4;09:30;20.00 4;21:25;-off- \
5;09:30;20.00 5;21:25;-off- \
6;09:30;20.00 6;21:25;-off-
EOF
fi
thermostat=`cat /var/PindaNet/thermostat`
weekday=$(date +%u)
((weekday--))
now=$(date +%H:%M)

thermostatTemp=${thermostat: -5}

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

if [ "$thermostatTemp" == "-off-" ]; then
  heating off "auto"
else
  if [[ "$temp" < $thermostatTemp ]]; then
    heating on "auto ($temp)"
  else
    heating off "auto ($temp)"
  fi
fi
