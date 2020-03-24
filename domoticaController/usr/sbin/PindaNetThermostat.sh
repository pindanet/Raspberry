#!/bin/bash
heating () {
  if [ ! -f /tmp/PindaNetHeating ]; then
    echo "off" > /tmp/PindaNetHeating
  fi
  if [ $1 == "on" ] && [ $(cat /tmp/PindaNetHeating) == "off" ]; then
#    python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "0B 11 00 02 01 25 4A AE 0E 01 0F 80"
    echo "on" > /tmp/PindaNetHeating
    echo "$(date): Heating $2 on" >> /tmp/PindaNetDebug.txt
  elif [ $1 == "off" ] && [ $(cat /tmp/PindaNetHeating) == "on" ]; then
#    python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "0B 11 00 01 01 41 53 86 01 00 00 80"
    echo "off" > /tmp/PindaNetHeating
    echo "$(date): Heating $2 off" >> /tmp/PindaNetDebug.txt
  fi
}

# BME280 I2C Temperature and Pressure Sensor
# 3v3 - Vin
# Gnd - Gnd
# BCM 3 (SCL) - SCK (White)
# BCM 2 (SDA) - SDI (Brown)
# read pressure, humididy and temperature from sensor
read_bme280 --i2c-address 0x77 > /var/www/html/data/PresHumiTemp
if [ $? -ne 0 ]; then
  echo -e "1017.58 hPa\n  50.55 ％\n  19.03 ℃" > /var/www/html/data/PresHumiTemp
fi

#if [ $(cat /var/PindaNet/heating) == "on" ]; then
#  heating on "manual"
#  exit
#elif [ $(cat /var/PindaNet/heating) == "off" ]; then
#  heating off "manual"
#  exit
#fi

thermostat=`cat /var/www/html/data/thermostat`
if [ $? -ne 0 ]; then
  echo -n "0;07:20;19.00 0;22:30;-off- 1;07:20;19.00 1;22:30;-off- 2;07:20;19.00 2;22:30;-off- 3;07:20;19.00 3;22:30;-off- 4;07:20;19.00 4;22:30;-off- 5;07:20;19.00 5;22:30;-off- 6;07:20;19.00 6;22:30;-off-" > /var/PindaNet/thermostat
  thermostat=`cat /var/www/html/data/thermostat`
fi
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

#echo "$(date): weekday=$weekday now=$now temp=$temp thermostatTemp=$thermostatTemp" >> /tmp/PindaNetDebug.txt

if [ "$thermostatTemp" == "-off-" ]; then
  heating off "auto"
else
  thermostatTemp=$(php -r "echo number_format($thermostatTemp - 2, 2);")
  # normalise floats to compare them
  while [[ ${#thermostatTemp} < ${#temp} ]]; do
    thermostatTemp="0$thermostatTemp"
  done
  if [[ "$temp" < "$thermostatTemp" ]]; then
    heating on "auto ($temp)"
  else
    heating off "auto ($temp)"
  fi
fi
