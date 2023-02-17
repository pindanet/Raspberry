#!/bin/bash
# GPIO 5 (29) > Button > Gnd (34)

# ToDo

echo 15 > /sys/class/backlight/rpi_backlight/brightness

_button_pin=5

function playRadio () {
  # $1 = radio URL
  # $2 = volume
  nohup mpg123 -f -$2 $(curl -s -i $1 | grep Location | awk '{ print $2 }') 2> /var/www/html/data/radio.log &
  sleep 5
}

raspi-gpio set $_button_pin ip pu # input pull up

## get next alarm
#. /var/www/html/data/alarmclock
#now=$(date +%H:%M)
#nextAlarm=$(cat /var/www/html/data/nextalarm)
#if [[ "$now" > "$nextAlarm" ]];then
#  tomorrow=$(date --date="next day" +%u)
#  nextAlarm=${alarmtimes[$((tomorrow - 1))]}
#  # Exceptions with recurrent dates
#  for alarmitem in "${alarmevent[@]}"; do
#    daytime=(${alarmitem})
#    recevent=$(date -u --date "${daytime[0]}" +%s)
#    tomorrowSec=$(date -u --date="next day" +%s)
#    tomorrow=$((tomorrowSec - (tomorrowSec % 86400)))
#    if [[ "${#daytime[@]}" > "2" ]]; then # recurrent alarm event
#       timebetween=$((${daytime[2]} * 86400))
#       while  [ $recevent -lt $tomorrow ]; do
#         recevent=$((recevent + timebetween))
#       done
#    fi
#    if [ $tomorrow == $recevent ]; then
#      echo "Alarm Event on $(date -u --date @$recevent +'%a %d %b %Y'): ${daytime[1]}"
#      nextAlarm=${daytime[1]}
#    fi
#  done
#  echo $nextAlarm > /var/www/html/data/nextalarm
#  # remove all alarms
#  for i in `atq | awk '{print $1}'`;do atrm $i;done
#  echo /var/www/html/alarmnow.sh | at -M $nextAlarm
#fi

while true; do
  # Received new configuration file
  if [ -f /tmp/thermostat ]; then
    mv -f /tmp/thermostat /var/www/html/data/alarmclock
  fi
  . /var/www/html/data/alarmclock

  clock=$(date -u +"%H:%M")
  localclock=$(date +"%H:%M")

  starttime=$(date +"%s")
  while [ $(($(date +"%s") - starttime)) -lt 55 ]; do
    sleepbutton=$(raspi-gpio get $_button_pin)
    if [[ $sleepbutton == *"level=0"* ]]; then
      if [[ $(raspi-gpio get $_button_pin) == *"level=0"* ]]; then
        if pgrep -x "mpg123" >/dev/null; then
          killall mpg123
          sleep 5
        else
          # Exceptions with recurrent dates and times
          for sleepitem in "${sleepevent[@]}"; do
            now=$(date +%H:%M)
            daytime=(${sleepitem})
            recevent=$(date -u --date "${daytime[0]}" +%s)
            timebetween=$((${daytime[1]} * 86400))
            nowSec=$(date -u +%s)
            today=$((nowSec - (nowSec % 86400)))
            while  [ $recevent -lt $today ]; do
              recevent=$((recevent + timebetween))
            done
            if [ $today == $recevent ]; then
              if [[ "${daytime[2]}" < "$now" ]] && [[ "${daytime[3]}" > "$now" ]]; then
                echo "Sleep Event on $(date -u --date @$recevent +'%a %d %b %Y') between ${daytime[2]} and ${daytime[3]}: Radio: ${daytime[4]}, Volume: ${daytime[5]}"
                radio=${daytime[4]}
                volume=${daytime[5]}
                break
              fi
            fi
          done
	  playRadio $radio $volume
        fi
      fi
    fi
    sleep 0.2
  done
done
