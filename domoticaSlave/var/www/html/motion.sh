#!/bin/bash
# Eerst definiëren we enkele instellingen (constanten)
motion=$(cat << EOF
{
    "motion_detect" :
    {
    "roi_x" : 0.1,
    "roi_y" : 0.1,
    "roi_width" : 0.8,
    "roi_height" : 0.8,
    "difference_m" : 0.1,
    "difference_c" : 10,
    "region_threshold" : 0.005,
    "frame_period" : 5,
    "hskip" : 2,
    "vskip" : 2,
    "verbose" : 1
    }
}
EOF
)
echo $motion > /tmp/postProcess.json
minBacklight=33
maxBacklight=128
timer=180

# Initialise flags
rm /tmp/timeTime
# Initialise touchscreen brightness
echo 0 > /sys/class/backlight/10-0045/brightness
# Daarna definiëren we enkele functies
# Background action on motion
action () {
  while :
  do
    endat=$(cat /tmp/timeTime)
    echo $endat $(printf '%(%s)T\n' -1)
    if (($(printf '%(%s)T\n' -1) > $endat)); then
      break
    fi
    sleep 3
    endat=$(cat /tmp/timeTime)
  done
  echo "Timeout"
  rm /tmp/timeTime
  echo 0 > /sys/class/backlight/10-0045/brightness
}
# Functie waarmee je wacht op beweging:
wait_for_motion () {
  while read -r line ; do
    if [[ "$line" == *"Motion detected"* ]]; then
      echo "Er is beweging."
      if ! [ -f /tmp/timeTime ]; then
        echo $(($(printf '%(%s)T\n' -1) + 10)) > /tmp/timeTime # Tijd + 10 seconden
        break
      fi
      # reset timer
      echo $(($(printf '%(%s)T\n' -1) + 10)) > /tmp/timeTime # Tijd + 10 seconden
    elif [[ "$line" == *"Motion stopped"* ]]; then
      echo "Er geen beweging."
    fi
  # We gebruiken --nopreview om zo onopvallend mogelijk beweging te detecteren.
  # Gebruik een preview om het detectiegebied te bekijken/af te regelen
  # Keep aspect ratio: 3280/16 = 205, 2464/16 = 154
  done < <(rpicam-hello -t 0 --nopreview --lores-width 205 --lores-height 154 --post-process-file /tmp/postProcess.json 2>&1)
}
# Hier begint ons programma
# Oneindig lang worden bewegingen gemeld
# Breek het programma af met Ctrl+c
while :
do
  wait_for_motion
  # Stop de bewegingsdetectie om de camera te gebruiken om een foto te maken
  pkill rpicam-hello
  echo "Foto nemen."
  bestandsnaam=$(date +"%Y-%m-%d_%H.%M.%S")
  lux=$(sudo /usr/bin/rpicam-still -v 0 -o /tmp/$bestandsnaam".jpg" --rotation 180 --nopreview  --immediate --metadata - | grep '"Lux":')
  lux=${lux%.*} # until colon
  lux=${lux//[!0-9]/} # extract integer
  echo "Lux: $lux"
  if ! [ -f /var/www/html/data/luxmax ]; then
    luxmax=0
  else
    luxmax=$(cat /var/www/html/data/luxmax)
  fi
  echo "Luxmax: $luxmax"
  if (($lux > $luxmax)); then
    echo $lux > /var/www/html/data/luxmax
  fi
  let backlight=$lux*$maxBacklight/$luxmax+$minBacklight
  echo "Backlight: $backlight"
  echo $backlight > /sys/class/backlight/10-0045/brightness

  find /var/www/html/motion -mmin +$((60*24)) -type f -delete
  /usr/bin/convert /tmp/$bestandsnaam".jpg" -resize 1920 /var/www/html/motion/$bestandsnaam".jpg"

  echo /tmp/$bestandsnaam".jpg"
  timerTime=$(printf '%(%s)T\n' -1)
  date --date @$timerTime

  action &
done
