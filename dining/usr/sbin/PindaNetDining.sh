#!/bin/bash
tempfact=1.08  # Zomer, omgevingstemp: 1.00, Winter, IR temp: 1.03
function relayGPIO () {
  _r1_pin=${1#*relayGPIO}

  if [ ! -f /tmp/$1 ]; then # initialize
    echo '{"POWER":"ON"}' > /tmp/$1
    echo "$(date -u +%s),off" >> /var/www/html/data/$1.log
  fi
  if [ $2 == "on" ] && [ "$(cat /tmp/$1)" == '{"POWER":"OFF"}' ]; then
    raspi-gpio set $_r1_pin op dl
    echo '{"POWER":"ON"}' > /tmp/$1
    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
  elif [ $2 == "off" ] && [ "$(cat /tmp/$1)" == '{"POWER":"ON"}' ]; then
    raspi-gpio set $_r1_pin op dh
    echo '{"POWER":"OFF"}' > /tmp/$1
    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
  elif [ "$(cat /tmp/$1)" != '{"POWER":"OFF"}' ] && [ "$(cat /tmp/$1)" != '{"POWER":"ON"}' ]; then
    echo '{"POWER":"ON"}' > /tmp/$1
    echo "$(date): Relay error. Heating $1" >> /tmp/PindaNetDebug.txt
  fi
}
declare -A status=()
function tasmota () {
  if [[ $1 == *"relayGPIO"* ]]; then
    relayGPIO $1 $2
    return
  fi
  if [ -z ${status["$1"]} ]; then # initialize
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power)
    two=$(echo ${status["$1"]} | awk -F"\"" '{print $4}')
    twolower=${two,,}
    if [ $twolower == "on" ] || [ $twolower == "off" ]; then
      echo "$(date -u +%s),$twolower" >> /var/www/html/data/$1.log
    fi
  fi
  if [ $2 == "on" ] && [ "${status["$1"]}" == '{"POWER":"OFF"}' ]; then
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power%20On)
    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
  elif [ $2 == "off" ] && [ "${status["$1"]}" == '{"POWER":"ON"}' ]; then
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power%20Off)
    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
  elif [ "${status["$1"]}" != '{"POWER":"OFF"}' ] && [ "${status["$1"]}" != '{"POWER":"ON"}' ]; then
    status["$1"]=$(wget -qO- http://$1/cm?cmnd=Power)
    echo "$(date): Communication error. Heating $1" >> /tmp/PindaNetDebug.txt
  fi
#  if [ ! -f /tmp/$1 ]; then # initialize
#    echo $(wget -qO- http://$1/cm?cmnd=Power) > /tmp/$1
#    two=$(wget -qO- http://$1/cm?cmnd=Power | awk -F"\"" '{print $4}')
#    twolower=${two,,}
#    if [ $twolower == "on" ] || [ $twolower == "off" ]; then
#      echo "$(date -u +%s),$twolower" >> /var/www/html/data/$1.log
#    fi
#  fi
#  if [ $2 == "on" ] && [ "$(cat /tmp/$1)" == '{"POWER":"OFF"}' ]; then
#    dummy=$(wget -qO- http://$1/cm?cmnd=Power%20On)
#    echo $(wget -qO- http://$1/cm?cmnd=Power) > /tmp/$1
#    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
#  elif [ $2 == "off" ] && [ "$(cat /tmp/$1)" == '{"POWER":"ON"}' ]; then
#    dummy=$(wget -qO- http://$1/cm?cmnd=Power%20Off)
#    echo $(wget -qO- http://$1/cm?cmnd=Power) > /tmp/$1
#    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
#  elif [ "$(cat /tmp/$1)" != '{"POWER":"OFF"}' ] && [ "$(cat /tmp/$1)" != '{"POWER":"ON"}' ]; then
#    echo $(wget -qO- http://$1/cm?cmnd=Power) > /tmp/$1
#    echo "$(date): Communication error. Heating $1" >> /tmp/PindaNetDebug.txt
#  fi
}
function thermostat {
  temp=$(tail -1 $PresHumiTempfile)
  temp=${temp%% C*}
  temp=${temp%% °C*}
  # remove leading whitespace characters
  temp="${temp#"${temp%%[![:space:]]*}"}"

   unset thermostatdefault
   DOW=$(date +%u)
#   echo $DOW
   for thermostatday in "${thermostatdiningweek[@]}"; do
     daytime=(${thermostatday})
     if [ "$DOW" == "${daytime[0]}" ]; then
       thermostatdefault+=("${daytime[1]} ${daytime[2]} ${daytime[3]} ")
     fi
   done

  IFS=$'\n' thermostatroom=($(sort <<<"${thermostatdefault[*]}"))
  unset IFS

  heatingRoom="off"
# Default times for heating
  for thermostatitem in "${thermostatroom[@]}"; do
    daytime=(${thermostatitem})
    if [[ "${daytime[0]}" < "$now" || "${daytime[0]}" == "$now" ]] && [[ "${daytime[1]}" > "$now" ]]; then
      heatingRoom="on"
      if [[ -v "daytime[2]" ]] ; then
#        echo "tempComfort: ${daytime[2]}"
        tempComfort=${daytime[2]}
      fi
      break
    fi
  done
# Exceptions with recurrent dates and times
#  eventTemp=$tempComfort
  for thermostatitem in "${thermostatroomevent[@]}"; do
    daytime=(${thermostatitem})
    recevent=$(date -u --date "${daytime[0]}" +%s)
    timebetween=$((${daytime[1]} * 86400))
    nowSec=$(date -u +%s)
    today=$((nowSec - (nowSec % 86400)))
    if [[ "$timebetween" > "0" ]]; then # repeating event
      while  [ $recevent -lt $today ]; do
        recevent=$((recevent + timebetween))
      done
    fi
    if [ $today == $recevent ]; then
      echo "Event in $room on $(date -u --date @$recevent)"
      if [[ "${daytime[2]}" < "$now" || "${daytime[2]}" == "$now" ]] && [[ "${daytime[3]}" > "$now" ]]; then
        heatingRoom=${daytime[4]}
        if [[ -v "daytime[5]" ]] ; then
          tempComfort=${daytime[5]}
        fi
        echo "Between ${daytime[2]} and ${daytime[3]}: heating: ${daytime[4]}, temp: $tempComfort °C"
        break
      fi
    fi
  done

  tempWanted=$tempComfort
  roomtemp=$(cat /tmp/thermostatManual)
  if [ $? -gt 0 ]; then
    echo Auto
  else
    if [ "$roomtemp" == "off" ]; then
      echo "Heating Manual Off"
      heatingRoom="off"
    else
      tempWanted=$(awk "BEGIN {print ($roomtemp + $tempOffset)}")
      echo "Manual temp kichen: $tempWanted °C"
      heatingRoom="on"
    fi
  fi
  if [ "$heatingRoom" == "off" ]; then
    if [[ "$tempNightTime" > "$now" ]]; then
      echo "Heating: off at night, $tempNight °C"
      tempWanted=$tempNight
    else
      echo "Heating: Off, $tempOff °C"
      tempWanted=$tempOff
    fi
  fi
  total=${#heaterRoom[@]}
  for (( i=0; i<$total; i++ )); do
    tempToggle=$(awk "BEGIN {print ($tempWanted - $hysteresis - $hysteresis * (2 * $i))}")
    echo "${heaterRoom[$i]} switch on at $tempToggle °C."
    if (( $(awk "BEGIN {print ($temp < $tempToggle)}") )); then
      echo "${heaterRoom[$i]} on at $temp °C."
      tasmota ${heater[${heaterRoom[$i]}]} on
    fi
    tempToggle=$(awk "BEGIN {print ($tempWanted + $hysteresis - $hysteresis * (2 * $i))}")
    echo "${heaterRoom[$i]} switch off at $tempToggle °C."
    if (( $(awk "BEGIN {print ($temp > $tempToggle)}") )); then
      echo "${heaterRoom[$i]} off at $temp °C."
      tasmota ${heater[${heaterRoom[$i]}]} off
    fi
  done
}

. /var/www/html/data/thermostat
# Calculated configs
## domoOn
#today=$(date +%u)
#domoOn=${alarmtimes[$((today - 1))]}
#
#for alarmitem in "${alarmevent[@]}"; do
#  daytime=(${alarmitem})
#  recevent=$(date -u --date "${daytime[0]}" +%s)
#  todaySec=$(date -u +%s)
#  today=$((todaySec - (todaySec % 86400)))
##  date -u -d @$today
#  if [[ "${#daytime[@]}" > "2" ]]; then # recurrent alarm event
#    timebetween=$((${daytime[2]} * 86400))
#    while  [ $recevent -lt $today ]; do
#      recevent=$((recevent + timebetween))
#    done
#  fi
#  if [ $today == $recevent ]; then
#    echo "Domoticasystem wakes up on $(date -u --date @$recevent +'%a %d %b %Y') at ${daytime[1]}"
#    domoOn=${daytime[1]}
#  fi
#done
#echo $domoOn > /var/www/html/data/domoOn

# get next alarm
now=$(date +%H:%M)
nextAlarm=$(cat /var/www/html/data/nextalarm)
if [[ "$now" > "$nextAlarm" ]];then
  tomorrow=$(date --date="next day" +%u)
  nextAlarm=${alarmtimes[$((tomorrow - 1))]}
  # Exceptions with recurrent dates
  for alarmitem in "${alarmevent[@]}"; do
    daytime=(${alarmitem})
    recevent=$(date -u --date "${daytime[0]}" +%s)
    tomorrowSec=$(date -u --date="next day" +%s)
    tomorrow=$((tomorrowSec - (tomorrowSec % 86400)))
    if [[ "${#daytime[@]}" > "2" ]]; then # recurrent alarm event
       timebetween=$((${daytime[2]} * 86400))
       while  [ $recevent -lt $tomorrow ]; do
         recevent=$((recevent + timebetween))
       done
    fi
    if [ $tomorrow == $recevent ]; then
      echo "Alarm Event on $(date -u --date @$recevent +'%a %d %b %Y'): ${daytime[1]}"
      nextAlarm=${daytime[1]}
    fi
  done
  echo $nextAlarm > /var/www/html/data/nextalarm
fi

# remove all alarms
for i in `atq | awk '{print $1}'`;do atrm $i;done

# Lights on in the morning 
#echo "raspi-gpio set $diningLight op dl" | at -M $nextAlarm
echo "sleep 660; wget -qO- http://tasmota-c699b5-6581/cm?cmnd=Power%20On" | at -M $nextAlarm
if [ ! -z ${christmasLight+x} ]; then
  echo "sleep 660; wget -qO- http://$christmasLight/cm?cmnd=Power%20On" | at -M $nextAlarm
fi

# Lights out in the morning
# From UTC
lightsOut=$(date -d "$nextAlarm" +"%s")
lightsOut=$((lightsOut + 60 * 60)) # 1 hour after wakeup
lightsOut=$(date -d @$lightsOut +%H:%M)

sunrise=$(hdate -s -l N51 -L E3 -z0 -q | grep sunrise | tail -c 6)
sunriseSec=$(date -d "$sunrise" +"%s")
localToUTC=$(($(date +"%k") - $(date -u +"%k")))
sunriseLocalSec=$((sunriseSec + localToUTC * 3600))
# to Local
sunrise=$(date -d @$sunriseLocalSec +"%H:%M")
if [[ $lightsOut > $sunrise ]]; then # sun shines
#  echo "raspi-gpio set $diningLight op dh" | at $lightsOut
  echo "wget -qO- http://tasmota-c699b5-6581/cm?cmnd=Power%20Off" | at -M $lightsOut
#  echo "wget -qO- http://$diningLight/cm?cmnd=Power%20Off" | at $lightsOut
else # still dark
#  echo "raspi-gpio set $diningLight op dh" | at $sunrise
  echo "wget -qO- http://tasmota-c699b5-6581/cm?cmnd=Power%20Off" | at -M $sunrise
#  echo "wget -qO- http://$diningLight/cm?cmnd=Power%20Off" | at $sunrise
fi
if [ ! -z ${christmasLight+x} ]; then
  echo "wget -qO- http://$christmasLight/cm?cmnd=Power%20Off" | at -M $sunrise
fi

# Lights on in the evening
# From UTC
echo "wget -qO- http://tasmota-c699b5-6581/cm?cmnd=Power%20On" | at -M 22:24
sunset=$(hdate -s -l N51 -L E3 -z0 -q | tail -c 6)
sunsetSec=$(date -d "$sunset" +"%s")
sunsetLocalSec=$((sunsetSec + localToUTC * 3600))
# to Local
sunset=$(date -d @$sunsetLocalSec +"%H:%M")
if [[ $eveningShutterDown > $sunset ]]; then # already dark
#  echo "raspi-gpio set $diningLight op dl" | at $sunset
  echo "wget -qO- http://$Haardlamp/cm?cmnd=Power%20On" | at -M $sunset
  if [ ! -z ${TVlamp+x} ]; then
    echo "wget -qO- http://$TVlamp/cm?cmnd=Power%20On" | at $sunset
  fi
  if [ ! -z ${christmasLight+x} ]; then
    echo "wget -qO- http://$christmasLight/cm?cmnd=Power%20On" | at $sunset
  fi
else # still daylight
#  echo "raspi-gpio set $diningLight op dl" | at $eveningShutterDown
  echo "wget -qO- http://$Haardlamp/cm?cmnd=Power%20On" | at -M $eveningShutterDown
  if [ ! -z ${TVlamp+x} ]; then
    echo "wget -qO- http://$TVlamp/cm?cmnd=Power%20On" | at $eveningShutterDown
  fi
  if [ ! -z ${christmasLight+x} ]; then
    echo "wget -qO- http://$christmasLight/cm?cmnd=Power%20On" | at $eveningShutterDown
  fi
fi
# All lights out
#echo "raspi-gpio set $diningLight op dh" | at $lightevening
echo "wget -qO- http://tasmota-c699b5-6581/cm?cmnd=Power%20Off" | at -M $lightevening
echo "wget -qO- http://$Haardlamp/cm?cmnd=Power%20Off" | at -M $lightevening
if [ ! -z ${christmasLight+x} ]; then
  echo "wget -qO- http://$christmasLight/cm?cmnd=Power%20Off" | at $lightevening
fi
# Tandenborstel opladen
echo "wget -qO- http://tasmota-a943fa-1018/cm?cmnd=Power%20On" | at -M 16:00
echo "wget -qO- http://tasmota-a943fa-1018/cm?cmnd=Power%20Off" | at -M 22:15

# Update and reboot, 1 minute later
echo "apt-get clean; apt-get update; apt-get upgrade -y; sudo apt-get autoremove -y; shutdown -r now" | at $(date -d @$(($(date -d $lightevening +"%s") + 60)) +"%H:%M")

while true
do
  starttime=$(date +"%s") # complete cycle: 1 minute

  temp=$(python /home/*/ds18b20.py)
  newtemp=$(awk "BEGIN {printf \"%0.2f\", ($temp * $tempfact)}")
  LC_ALL=C printf "%.1f °C" "$newtemp" > /home/*/temp.txt

  room="Dining"
  PresHumiTempfile="/home/*/temp.txt"

  # Received new configuration file
  if [ -f /tmp/thermostat ]; then
    mv -f /tmp/thermostat /var/www/html/data/thermostat
  fi
  . /var/www/html/data/thermostat

  # Lightswitch
  if [ -f /tmp/light ]; then
    if [ "$(cat /tmp/light)" == 'on' ]; then
      raspi-gpio set $diningLight op dl
    else
      raspi-gpio set $diningLight op dh
    fi
    rm /tmp/light
  fi

#  thermostatroomdefault=("${thermostatdiningdefault[@]}")
  thermostatroomevent=("${thermostatdiningevent[@]}")
  tempOffset=$diningTempOffset

  # compensate position temperature sensor
#  hysteresis=$(awk "BEGIN {print ($hysteresis * 2)}")
  tempComfort=$(awk "BEGIN {print ($tempComfort + $tempOffset)}")

  declare -A heater
  unset heaterRoom
  declare -a heaterRoom
  for heateritem in "${heaters[@]}"; do
    line=(${heateritem})
    heater[${line[0]}]=${line[1]}
    if [ ${heateritem:0:6} == "$room" ]; then
      heaterRoom+=(${line[0]})
    fi
  done

  if [ -f /tmp/thermostatReset ]; then
    echo "Resetting thermostat"
    for switch in "${!heater[@]}"
    do
      heateritem=${heater[$switch]}
      if [[ "$heateritem" == tasmota* ]]; then
          tempfile="/tmp/${heateritem:0:19}"
      fi
      if [ -f $tempfile ]; then
        rm $tempfile
      fi
    done
    rm /tmp/thermostatReset
  fi

  weekday=$(date +%w)
  now=$(date +%H:%M)

  thermostat

  sudo pkill -9 pngview
#  convert -size 1920x70 xc:none -font /usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf -pointsize 32 -fill black -gravity center -draw "text 0,0 '$(date +"%A, %e %B %Y   %k:%M")   $(cat /home/*/temp.txt)'" /home/*/image.png
#  convert -size 1920x70 xc:none -font /usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf -pointsize 48 -fill black -gravity center -draw "text 0,0 '$(date +"%A, %e %B %Y   %k:%M")   $(cat /home/*/temp.txt)'" /home/*/image.png
  convert -size 1920x70 xc:none -font /usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf -pointsize 48 -fill $subtitleColor -gravity center -draw "text 0,0 '$(date +"%A, %e %B %Y   %k:%M")   $(cat /home/*/temp.txt)'" /home/*/image.png
  /home/*/raspidmx-master/pngview/pngview -b 0 -l 3 -y 1130 /home/*/image.png &

  sleepSec=$((60 - ($(date +"%s") - starttime)))
  sleep $sleepSec
done
