# get next alarm
now=$(date +%H:%M)
alarmDay=$(date +%u)
nextAlarm="${alarmtimes[$alarmDay-1]}"
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
fi
