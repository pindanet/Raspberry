#!/bin/bash
LivingZuidOn="0B 11 00 01 01 41 53 86 01 01 0F 80"
LivingZuidOff="0B 11 00 00 01 41 53 86 01 00 00 80"
LivingNoordOn="0B 11 00 00 01 41 53 86 02 01 0F 80"
LivingNoordOff="0B 11 00 01 01 41 53 86 02 00 00 80"
sendRF () {
  if [ ! -f /var/www/html/data/mpc.txt ]; then
    touch /var/www/html/data/mpc.txt
  fi
  python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "$1"
  if [ -s /var/www/html/data/mpc.txt ]; then
    rm /var/www/html/data/mpc.txt
  fi
}
heating () {
  if [ ! -f /var/www/html/data/heating ]; then
    echo "off" > /var/www/html/data/heating
    chown www-data:www-data /var/www/html/data/heating
  fi
  if [ ! -f /var/www/html/data/thermostatmode ]; then
    echo "auto" > /var/www/html/data/thermostatmode
    chown www-data:www-data /var/www/html/data/thermostatmode
  fi
#echo "on/off=$1 heating=$(cat /var/www/html/data/heating) mode=$(cat /var/www/html/data/thermostatmode)" >> /tmp/PindaNetDebug.txt
  if [ $(cat /var/www/html/data/thermostatmode) == "auto" ]; then
    if [ $1 == "on" ] && [ $(cat /var/www/html/data/heating) == "off" ]; then
#      sendRF "0B 11 00 01 01 41 53 86 01 01 0F 80" # Living Zuid
#      sendRF "0B 11 00 00 01 41 53 86 02 01 0F 80" # Living Noord
      sendRF "$LivingZuidOn"
      sendRF "$LivingNoordOn"
#      python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "0B 11 00 01 01 41 53 86 01 01 0F 80"
      echo "on" > /var/www/html/data/heating
      echo "$(date): Heating $2 on" >> /tmp/PindaNetDebug.txt
    elif [ $1 == "off" ] && [ $(cat /var/www/html/data/heating) == "on" ]; then
#      sendRF "0B 11 00 00 01 41 53 86 01 00 00 80" # LivingZuidOff
#      sendRF "0B 11 00 01 01 41 53 86 02 00 00 80" # LivingNoordOff
      sendRF "$LivingZuidOff"
      sendRF "$LivingNoordOff"
#      python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "0B 11 00 00 01 41 53 86 01 00 00 80"
      echo "off" > /var/www/html/data/heating
      echo "$(date): Heating $2 off" >> /tmp/PindaNetDebug.txt
    fi
  fi
}

# BME280 I2C Temperature and Pressure Sensor
# 3v3 - Vin
# Gnd - Gnd
# BCM 3 (SCL) - SCK (White)
# BCM 2 (SDA) - SDI (Brown)
# read pressure, humididy and temperature from sensor
read_bme280 --i2c-address 0x77 > /var/www/html/data/PresHumiTemp

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

#echo "temp=$temp thermostatTemp=$thermostatTemp" >> /tmp/PindaNetDebug.txt
hysteresis="0.1"
if (( $(awk "BEGIN {print ($temp < $thermostatTemp - $hysteresis)}") )); then
#  echo "temp=$temp thermostatTemp=$thermostatTemp Verwarming aan" #>> /tmp/PindaNetDebug.txt 
  heating on "auto ($temp)"
elif (( $(awk "BEGIN {print ($temp > $thermostatTemp + $hysteresis)}") )); then
#  echo "temp=$temp thermostatTemp=$thermostatTemp Verwarming uit" #>> /tmp/PindaNetDebug.txt 
  heating off "auto ($temp)"
fi
exit

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
#  thermostatTemp=$(php -r "echo number_format($thermostatTemp - 2, 2);")
  # normalise floats to compare them
#  while [[ ${#thermostatTemp} < ${#temp} ]]; do
#    thermostatTemp="0$thermostatTemp"
#  done
#echo "temp=$temp thermostatTemp=$thermostatTemp" >> /tmp/PindaNetDebug.txt
  if [[ "$temp" < "$thermostatTemp" ]]; then
    heating on "auto ($temp)"
  elif [[ "$temp" > "$thermostatTemp" ]]; then
    heating off "auto ($temp)"
  fi
fi
