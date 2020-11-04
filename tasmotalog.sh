#!/bin/bash
verbruik=0
prijs=27 # per kWh in centimen

function samenvatting () {
start=$1
stop=$2
duur=$((stop - start))
if [ "$start" -gt "$(date  -d "1 week ago" +%s)" ]; then
  echo "$(date --date @$start) - $(date --date @$stop): $((duur / 3600)) uren, $(((duur % 3600) / 60)) minuten"
fi
#echo "Duur: $((duur / 3600)) uren"

# Deze week
for dag in {0..7}; do
  dagdate=$((today - (dag * 86400))) 
  if [ "$start" -gt "$dagdate" ]; then
    dagen[$dag]=$((dagen[$dag] + duur))
    break
  fi
done
for week in {0..1}; do
  weekdate=$(date -d "$((week + 1)) week ago" -u +%s)
  weekdate=$((weekdate - (weekdate % 86400)))
  if [ "$start" -lt "$today" ]; then
    if [ "$start" -gt "$weekdate" ]; then
      weken[$week]=$((weken[$week] + duur))
      break
    fi
  fi
done
for maand in {0..12}; do
  maanddate=$(date -u +%s -d $(date -d "$nowmonth $maand month ago" "+%Y/%m/01"))
#  maanddate=$(date -u +%s -d $(date -d "$maand month ago" "+%Y/%m/01"))
  if [ "$start" -ge "$maanddate" ]; then
    maanden[$maand]=$((maanden[$maand] + duur))
#  jaardate=$(date -u +%s -d "$(date -d "@$maanddate" "+%Y/%m/01") -1 year")
#  date -u --date @$jaardate
    if [ "$maand" -gt "0" ]; then
      jaren[0]=$((jaren[0] + duur))
    fi
    break
  fi
done
vandate=$(date -u +%s -d "$(date "+%Y/%m/01") -2 year")
#date -u --date @$vandate
totdate=$(date -u +%s -d "$(date -d "1 month ago" "+%Y/%m/01") -1 year")
#date -u --date @$totdate
if [ "$start" -ge "$vandate" ]; then
  if [ "$start" -le "$totdate" ]; then
    jaren[1]=$((jaren[1] + duur))
    break
  fi
fi
}

#raw=$(curl -s http://pindadomo/data/thermostat | grep "heaters\[")
raw=$(curl -s http://pindadomo/data/thermostat | grep "heaters+=(")
mapfile -t heaters <<< "$raw"

nowSec=$(date -u +%s)
nowmonth=$(date +%Y/%m/15)
today=$((nowSec - (nowSec % 86400)))

dagen=(0 0 0 0 0 0 0 0)
weken=(0 0)
maanden=(0 0 0 0 0 0 0 0 0 0 0 0 0)
jaren=(0 0)
start=0
for heateritem in "${heaters[@]}"; do
  heater=(${heateritem})
  if [[ "${heater[1]}" == tasmota* ]]; then
    echo "${heater[0]#*\"}"
    start=0
    if [[ ${heater[0]} == *"Keuken"* ]]; then
      scp pindakeuken:/var/www/html/data/${heater[1]:0:-2}.log .
      raw=$(cat ${heater[1]:0:-2}.log)
      rm ${heater[1]:0:-2}.log
    else
      raw=$(curl -s http://pindadomo/data/${heater[1]:0:-2}.log)
    fi
    mapfile -t heaterlog <<< "$raw"
#    printf '%s\n' "${heaterlog[@]}"
    for heaterlogitem in "${heaterlog[@]}"; do
      IFS=',' read -ra heaterlogline <<< "${heaterlogitem}"
#      echo $(date -u --date @${heaterlogline[0]}) ${heaterlogline[1]}
      if [ ${heaterlogline[1]} == "on" ] && [ "$start" -eq "0" ]; then
        start=${heaterlogline[0]}
#        echo "Start: $(date -u --date @$start)"
      elif [ ${heaterlogline[1]} == "off" ] && [ "$start" -gt "0" ]; then
        stop=${heaterlogline[0]}
#        echo "Stop: $(date -u --date @$stop)"
        samenvatting $start $stop
        start=0
      fi
    done
  fi
done

#start=$(date -u +%s -d $(date -d "12 month ago" "+%Y/%m/01"))
#stop=$((start + ( 7 * 3600) + 3656))
#echo "Start: $(date -u --date @$start)"
#echo "Stop: $(date -u --date @$stop)"

#samenvatting $start $stop

printf "%13s %9s %8s %6s \n" "Periode" "Verbruik" "Duur" "Prijs"
tabelscheiding="---------------------------------------"
echo $tabelscheiding
for dag in {0..7}; do
  dagdate=$((today - (dag * 86400)))
  # 3600 seconden in een uur, 500 watt verbruik of 1/2 kWh
  kwh=$((dagen[dag] / 7200))
  tijdspanne=$((dagen[dag] / 3600))
  kostprijs=$(((dagen[dag] * prijs) / 720000))
  printf "%13s %5s kWh %4s uur %4s €\n" $(date -u --date @$dagdate +"%A") $kwh $tijdspanne $kostprijs
done
echo $tabelscheiding
# Vorige week
kwh=$((weken[0] / 7200))
tijdspanne=$((weken[0] / 3600))
kostprijs=$(((weken[0] * prijs) / 720000))
printf "%13s %5s kWh %4s uur %4s €\n" "Vorige week" $kwh $tijdspanne $kostprijs
# Week daarvoor
kwh=$((weken[1] / 7200))
tijdspanne=$((weken[1] / 3600))
kostprijs=$(((weken[1] * prijs) / 720000))
printf "%13s %5s kWh %4s uur %4s €\n" "Week daarvoor" $kwh $tijdspanne $kostprijs
echo $tabelscheiding
for maand in {0..12}; do
  maanddate=$(date -u +%s -d $(date -d "$nowmonth $maand month ago" "+%Y/%m/01"))
  # 3600 seconden in een uur, 500 watt verbruik of 1/2 kWh
  kwh=$((maanden[maand] / 7200))
  tijdspanne=$((maanden[maand] / 3600))
  kostprijs=$(((maanden[maand] * prijs) / 720000))
  printf "%13s %5s kWh %4s uur %4s €\n" $(date -u --date @$maanddate +"%B") $kwh $tijdspanne $kostprijs
done
echo $tabelscheiding
# Vorig jaan
kwh=$((jaren[0] / 7200))
tijdspanne=$((jaren[0] / 3600))
kostprijs=$(((jaren[0] * prijs) / 720000))
printf "%13s %5s kWh %4s uur %4s €\n" "Vorig jaar" $kwh $tijdspanne $kostprijs
# Jaar daarvoor
kwh=$((jaren[1] / 7200))
tijdspanne=$((jaren[1] / 3600))
kostprijs=$(((jaren[1] * prijs) / 720000))
printf "%13s %5s kWh %4s uur %4s €\n" "Jaar daarvoor" $kwh $tijdspanne $kostprijs
echo $tabelscheiding

#echo ${jaren[@]}

exit

echo "Vorige week in dagen:"
for i in {6..1}; do
  yesterday=$((today - (i * 86400)))
  date -u --date @$yesterday +"%A %d/%m/%Y"
done
echo "Vandaag:"
date -u --date @$today +"%A %d/%m/%Y"
echo "Vorige week:"
week=$((today - (7 * 86400)))
date -u --date @$week +"%A %d/%m/%Y"
echo "Vorig jaar in maanden:"
for i in {11..1}; do
  lastmonth=$(date -u +%s -d $(date -d "$i month ago" "+%Y/%m/01"))
  date -u --date @$lastmonth +"%A %d/%m/%Y"
done
echo "Dit jaar:"
year=$(date -u +%s -d $(date -d "1 year ago" "+%Y/%m/01"))
date -u --date @$year +"%A %d/%m/%Y"
echo "Vorig jaar:"
lastyear=$(date -u +%s -d $(date -d "2 year ago" "+%Y/%m/01"))
date -u --date @$lastyear +"%A %d/%m/%Y"
