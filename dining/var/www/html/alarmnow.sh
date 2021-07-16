#!/bin/bash
. /var/www/html/data/thermostat

sleep 660 # wait 11 minutes to wake up

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

# Lights on  in the evening
#echo "wget -qO- http://tasmota_e7b609-5641/cm?cmnd=Power%20Off" | at 19:07

# update and reboot
apt-get clean
apt-get update
apt-get upgrade -y
sudo apt-get autoremove -y
shutdown -r now
