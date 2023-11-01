#!/bin/bash
# ToDo
# .source functions, config
# split PindaNetSwitches - PindaNetLights

logExt="log"

sunrise=$(hdate -s -l N51 -L E3 -z0 -q | grep sunrise | tail -c 6)
sunriseSec=$(date -d "$sunrise" +"%s")
localToUTC=$(($(date +"%k") - $(date -u +"%k")))
sunriseLocalSec=$((sunriseSec + localToUTC * 3600))
# to Local
sunrise=$(date -d @$sunriseLocalSec +"%H:%M")

sunset=$(hdate -s -l N51 -L E3 -z0 -q | tail -c 6)
sunsetSec=$(date -d "$sunset" +"%s")
sunsetLocalSec=$((sunsetSec + localToUTC * 3600))
# to Local
sunset=$(date -d @$sunsetLocalSec +"%H:%M")

eveningShutterDown="22:20"

unset alarmtimes
alarmtimes+=("07:30") # maandag date '+%u'
alarmtimes+=("07:30")
alarmtimes+=("07:30")
alarmtimes+=("07:30")
alarmtimes+=("07:30")
alarmtimes+=("07:30")
alarmtimes+=("07:30")

unset alarmevent
# alarmevent+=("2022-08-03 07:00 14") # Laura
# alarmevent+=("2023-02-27 07:00 7") # MaVm Internet
# alarmevent+=("2023-03-02 06:30 7") # DoVm Blankenberge
# alarmevent+=("2023-03-03 06:30 7") # VrVm Blankenberge

alarmevent+=("2023-06-20 07:00") # PCB
# alarmevent+=("2021-06-17 06:30") # Hepatitis Vaccinatie
alarmevent+=("2024-05-24 07:00") # Tandarts Fanny Decloedt

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

lightsOut=$(date -d "$nextAlarm" +"%s")
lightsOut=$((lightsOut + 74 * 60)) # 1 hour 14 min after wakeup
lightsOut=$(date -d @$lightsOut +%H:%M)

#echo "NextAlarm: $nextAlarm, LightsOut: $lightsOut"

declare -A IPs
IPs[Haardlamp]="192.168.129.18"
IPs[Tandenborstel]="192.168.129.7"
IPs[Apotheek]="192.168.129.19"
IPs[TVlamp]="192.168.129.11"

# echo ${IPs["Tandenborstel"]}

declare -A Watts
Watts[Haardlamp]="20"
Watts[Tandenborstel]="10"
Watts[Apotheek]="20"
Watts[TVlamp]="20"

unset lights
# Name URL Power On Off

# Lights in the morning
if [[ $(date -d "$lightsOut" +'%Y%m%d%H%M%S') > $(date -d "$sunrise" +'%Y%m%d%H%M%S') ]]; then # sun shines
  lights+=("Haardlamp $(date -d "$nextAlarm 11 minutes" +'%H:%M') $lightsOut")
  lights+=("Apotheek $(date -d "$nextAlarm 11 minutes" +'%H:%M') $lightsOut")
else # still dark
  lights+=("Haardlamp $(date -d "$nextAlarm 11 minutes" +'%H:%M') $sunrise")
  lights+=("Apotheek $(date -d "$nextAlarm 11 minutes" +'%H:%M') $sunrise")
fi
lights+=("Tandenborstel 16:00 22:15")
#lights+=("Apotheek $sunset $(date -d "$sunset 15 minutes" +'%H:%M')")
lights+=("Apotheek 22:24 bedtime")

# in the evening
if [[ $(date -d "$eveningShutterDown" +'%Y%m%d%H%M%S') > $(date -d "$sunset" +'%Y%m%d%H%M%S') ]]; then # already dark
  lights+=("Haardlamp $sunset bedtime")
  lights+=("TVlamp $sunset bedtime")
else # still daylight
  lights+=("Haardlamp $eveningShutterDown bedtime")
  lights+=("TVlamp $eveningShutterDown bedtime")
fi

#lights+=("TVlamp 16:19 16:20")

# debug
#for light in "${lights[@]}"; do
#  echo $light
#done

# convert to comparable dates
sunrise=$(date -d "$sunrise" +'%Y%m%d%H%M%S')
sunset=$(date -d "$sunset" +'%Y%m%d%H%M%S')
eveningShutterDown=$(date -d "$eveningShutterDown" +'%Y%m%d%H%M%S')
toprocess=("${lights[@]}")
unset lights
for light in "${toprocess[@]}"; do
  lightProperties=(${light})
  date -d "${lightProperties[1]}" &> /dev/null
  if [ $? == 0 ]; then
    lightProperties[1]=$(date -d "${lightProperties[1]}" +'%Y%m%d%H%M%S')
  fi
  date -d "${lightProperties[2]}" &>/dev/null
  if [ $? == 0 ]; then 
    lightProperties[2]=$(date -d "${lightProperties[2]}" +'%Y%m%d%H%M%S')
  fi
  lights+=("${lightProperties[0]} ${lightProperties[1]} ${lightProperties[2]}")
done

declare -A status=()
function tasmota () { # power name
  power=$1
  name=$2
  url=${IPs["$name"]}
  watt=${Watts["$name"]}
#  echo "Power: $power, Name: $name, Url: $url, Watt: $watt"
  if [ -z ${status["$name"]} ]; then # initialize
    status["$name"]=$(wget -qO- http://$url/cm?cmnd=Power)
    two=$(echo ${status["$name"]} | awk -F"\"" '{print $4}')
    twolower=${two,,}
    if [ $twolower == "on" ] || [ $twolower == "off" ]; then
      echo "$(date),$twolower,$watt" >> /var/www/html/data/$name.$logExt
    fi
  fi
  if [ $power == "on" ] && [ "${status["$name"]}" == '{"POWER":"OFF"}' ]; then
    status["$name"]=$(wget -qO- http://$url/cm?cmnd=Power%20On)
    echo "$(date),$power,$watt" >> /var/www/html/data/$name.$logExt
  elif [ $power == "off" ] && [ "${status["$name"]}" == '{"POWER":"ON"}' ]; then
    status["$name"]=$(wget -qO- http://$url/cm?cmnd=Power%20Off)
    echo "$(date),$power,$watt" >> /var/www/html/data/$name.$logExt
  elif [ "${status["$name"]}" != '{"POWER":"OFF"}' ] && [ "${status["$name"]}" != '{"POWER":"ON"}' ]; then
    status["$name"]=$(wget -qO- http://$url/cm?cmnd=Power)
    echo "$(date): Communication error. Tasmota $name" >> /tmp/PindaNetDebug.txt
  fi
}

while true
do
  declare -A process=()
  declare -A processed=()
  starttime=$(date +"%s") # complete cycle: 1 minute
  now=$(date +'%Y%m%d%H%M%S')
  if [[ $(cat /sys/class/backlight/rpi_backlight/bl_power) == "1" ]]; then # LCD backlight off
    bedtime="$now"
  else
    bedtime=$(date -d "2 minutes" +'%Y%m%d%H%M%S')
  fi
  for light in "${lights[@]}"; do
    lightProperties=(${light})
    if [ -z ${processed["${lightProperties[0]}"]} ]; then # not yet processed
      if [[ "${lightProperties[2]}" == "bedtime" ]]; then
        endDate="$bedtime"
      else
        endDate="${lightProperties[2]}"
      fi
      startDate="${lightProperties[1]}"
      if [[ "$startDate" < "$now" ]] && [[ "$now" < "$endDate" ]]; then
        process["${lightProperties[0]}"]="${lightProperties[0]} on"
        processed["${lightProperties[0]}"]="on"
      else
        process["${lightProperties[0]}"]="${lightProperties[0]} off"
      fi
    fi
  done
  for key in "${!process[@]}"; do
    lightProperties=(${process[$key]})
    tasmota ${lightProperties[1]} ${lightProperties[0]}
    echo "$key: ${lightProperties[1]}"
  done
#  echo ${process[@]}
#  echo ${!process[@]}

  sleepSec=$((60 - ($(date +"%s") - starttime)))
  sleep $sleepSec
done
