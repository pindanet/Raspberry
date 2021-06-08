#!/bin/bash
. /var/www/html/data/alarmclock

nohup mpg123 -f -$volume $(curl -s -i $radio | grep Location | awk '{ print $2 }') 2> /var/www/html/data/radio.log &
#nohup mpg123 -f -$volume /var/www/html/data/Old-alarm-clock-sound.mp3 &
sleep 180 # 3 minuten wakker worden
#nohup mpg123 -f -$volume /var/www/html/data/Old-alarm-clock-sound.mp3 &
sleep 180 # 3 minuten nekoefeningen
#nohup mpg123 -f -$volume /var/www/html/data/Old-alarm-clock-sound.mp3 &
sleep 300 # 5 minuten rechtop zitten
#nohup mpg123 -f -$volume /var/www/html/data/Old-alarm-clock-sound.mp3 &

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
  # remove all alarms
  for i in `atq | awk '{print $1}'`;do atrm $i;done
  echo /var/www/html/alarmnow.sh | at -M $nextAlarm
fi

# update and reboot
apt-get clean
apt-get update
apt-get upgrade -y
shutdown -r now
