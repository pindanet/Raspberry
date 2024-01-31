#!/bin/bash
# ToDo
# .source functions, config
# split PindaNetSwitches - PindaNetLights

logExt="log"

. /var/www/html/sun.sh

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

. /var/www/html/nextalarm.sh

lightsOut=$(date -d "$nextAlarm" +"%s")
lightsOut=$((lightsOut + 79 * 60)) # 1 hour 19 min after wakeup
lightsOut=$(date -d @$lightsOut +%H:%M)

#echo "NextAlarm: $nextAlarm, LightsOut: $lightsOut"

declare -A IPs
IPs[Haardlamp]="192.168.129.18"
IPs[Tandenborstel]="192.168.129.7"
IPs[Apotheek]="192.168.129.19"
IPs[TVlamp]="192.168.129.11"
#IPs[SwitchBacklight]="192.168.129.41"
IPs[Kerst]="192.168.129.44"
IPs[LivingVoor]="192.168.129.41"

# echo ${IPs["Tandenborstel"]}

declare -A Watts
Watts[Haardlamp]="20"
Watts[Tandenborstel]="10"
Watts[Apotheek]="20"
Watts[TVlamp]="20"
#Watts[SwitchBacklight]="1"
Watts[Kerst]="15"
Watts[LivingVoor]="16"

declare -A Cmnds
Cmnds[Haardlamp]="Power"
Cmnds[Tandenborstel]="Power"
Cmnds[Apotheek]="Power"
Cmnds[TVlamp]="Power"
#Cmnds[SwitchBacklight]="Power3"
Cmnds[Kerst]="Power"
Cmnds[LivingVoor]="Power2"

unset lights
# Name URL Power On Off

# Lights in the morning
# lights+=("Kerst $(date -d "$nextAlarm 11 minutes" +'%H:%M') $sunrise")
# lights+=("LivingVoor $(date -d "$nextAlarm 11 minutes" +'%H:%M') $sunrise")
if [[ $(date -d "$lightsOut" +'%Y%m%d%H%M%S') > $(date -d "$sunrise" +'%Y%m%d%H%M%S') ]]; then # sun shines
  lights+=("Haardlamp $(date -d "$nextAlarm 11 minutes" +'%H:%M') $lightsOut")
  lights+=("Apotheek $(date -d "$nextAlarm 11 minutes" +'%H:%M') $lightsOut")
#  lights+=("SwitchBacklight $(date -d "$nextAlarm 11 minutes" +'%H:%M') $lightsOut")
else # still dark
  lights+=("Haardlamp $(date -d "$nextAlarm 11 minutes" +'%H:%M') $sunrise")
  lights+=("Apotheek $(date -d "$nextAlarm 11 minutes" +'%H:%M') $sunrise")
#  lights+=("SwitchBacklight $(date -d "$nextAlarm 11 minutes" +'%H:%M') $sunrise")
fi
lights+=("Tandenborstel 16:00 22:15")
#lights+=("Apotheek $sunset $(date -d "$sunset 15 minutes" +'%H:%M')")
lights+=("Apotheek 22:24 bedtime")

# in the evening
# lights+=("Kerst $sunset bedtime")
# lights+=("LivingVoor $sunset bedtime")
if [[ $(date -d "$eveningShutterDown" +'%Y%m%d%H%M%S') > $(date -d "$sunset" +'%Y%m%d%H%M%S') ]]; then # already dark
  lights+=("Haardlamp $sunset bedtime")
  lights+=("TVlamp $sunset bedtime")
#  lights+=("SwitchBacklight $sunset bedtime")
else # still daylight
  lights+=("Haardlamp $eveningShutterDown bedtime")
  lights+=("TVlamp $eveningShutterDown bedtime")
#  lights+=("SwitchBacklight $eveningShutterDown bedtime")
fi

#lights+=("TVlamp 18:45 18:46")

# debug
#for light in "${lights[@]}"; do
#  echo $light
#done

. /var/www/html/dateconvert.sh

. /var/www/html/tasmota.sh

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
#    echo "$key: ${lightProperties[1]}"
  done
#  echo ${process[@]}
#  echo ${!process[@]}

  sleepSec=$((60 - ($(date +"%s") - starttime)))
  sleep $sleepSec
done
