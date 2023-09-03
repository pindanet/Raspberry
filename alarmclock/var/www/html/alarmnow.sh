#!/bin/bash
. /var/www/html/data/alarmclock

mpg123 -f -$volume /var/www/html/data/bintro.mp3
#mpg123 -f -$volume /var/www/html/data/Old-alarm-clock-sound.mp3

url=$(curl --location --head --silent --write-out "%{url_effective}" --output /dev/null "$radio")
nohup mpg123 -f -$volume $url 2> /var/www/html/data/radio.log &
sleep 180 # 3 minuten wakker worden
sleep 180 # 3 minuten nekoefeningen
sleep 300 # 5 minuten rechtop zitten

#nohup mpg123 -f -$volume /var/www/html/data/Old-alarm-clock-sound.mp3 &

# get next alarm
now=$(date +%H:%M)
nextAlarm=$(cat /var/www/html/data/nextalarm)
tomorrowSec=$(date -u --date="next day" +%s)
tomorrow=$((tomorrowSec - (tomorrowSec % 86400)))
if [[ "$now" > "$nextAlarm" ]];then
  nextDay=$(date --date="next day" +%u)
  nextAlarm=${alarmtimes[$((nextDay - 1))]}
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
  echo /var/www/html/alarmnow.sh | at -M $nextAlarm $(date -u --date @$tomorrow +'%m%d%y')
fi
# update and reboot
apt-get clean
apt-get update
apt-get upgrade -y
shutdown -r now
