#!/bin/bash
while true
do
  starttime=$(date +"%s") # complete cycle: 1 minute

  temp=$(python /home/*/ds18b20.py)
  LC_ALL=C printf "%.1f °C" "$temp" > /home/*/temp.txt

  sleepSec=$((60 - ($(date +"%s") - starttime)))
  sleep $sleepSec
done
