#!/bin/bash
heating () {
  if [ ! -f /tmp/PindaNetHeating ]; then
    echo "off" > /tmp/PindaNetHeating
  fi
  if [ $1 == "on" ] && [ $(cat /tmp/PindaNetHeating) == "off" ]; then
    python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "0B 11 00 02 01 25 4A AE 0E 01 0F 80"
    echo "on" > /tmp/PindaNetHeating
    echo "$(date): Heating $2 on" >> /tmp/PindaNetDebug.txt
  elif [ $1 == "off" ] && [ $(cat /tmp/PindaNetHeating) == "on" ]; then
    python rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "0B 11 00 01 01 41 53 86 01 00 00 80"
    echo "off" > /tmp/PindaNetHeating
    echo "$(date): Heating $2 off" >> /tmp/PindaNetDebug.txt
  fi
}

# read pressure, humididy and temperature from sensor
#read_bme280 --i2c-address 0x77 > /var/PindaNet/PresHumiTemp

#if [ $(cat /var/PindaNet/heating) == "on" ]; then
#  heating on "manual"
#  exit
#elif [ $(cat /var/PindaNet/heating) == "off" ]; then
#  heating off "manual"
#  exit
#fi

#if [ ! -f /var/PindaNet/thermostat ]; then
#  echo -n "0;09:30;20.00 0;21:25;-off- 1;09:30;20.00 1;21:25;-off- 2;09:30;20.00 2;21:25;-off- 3;09:30;20.00 3;21:25;-off- 4;09:30;20.00 4;21:25;-off- 5;09:30;20.00 5;21:25;-off- 6;09:30;20.00 6;21:25;-off-" > /var/PindaNet/thermostat
#fi
thermostat=`cat /var/www/html/data/thermostat`
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

temp=$(tail -1 /var/www/html/data/PresHumiTemp)
temp=${temp%% C*}
  # remove leading whitespace characters
  temp="${temp#"${temp%%[![:space:]]*}"}"
  # normalise floats to compare them
  while [[ ${#temp} < ${#thermostatTemp} ]]; do
    temp="0$temp"
  done
  while [[ ${#thermostatTemp} < ${#temp} ]]; do
    thermostatTemp="0$thermostatTemp"
  done

thermostatTemp=$(php -r "echo number_format($thermostatTemp - 2, 2);")
#thermostatTemp=$((thermostatTemp - 2))
echo "$(date): weekday=$weekday now=$now temp=$temp thermostatTemp=$thermostatTemp" >> /tmp/PindaNetDebug.txt

if [ "$thermostatTemp" == "-off-" ]; then
  heating off "auto"
else
  if [[ "$temp" < "$thermostatTemp" ]]; then
    heating on "auto ($temp)"
  else
    heating off "auto ($temp)"
  fi
fi
