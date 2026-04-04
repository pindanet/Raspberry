#!/bin/bash

# depends on jq
# apt install jq

# https://www.raspberrypi.com/documentation/computers/camera_software.html#post-processing-with-rpicam-apps
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

# https://www.baeldung.com/linux/jq-command-json
# https://www.baeldung.com/linux/jq-passing-bash-variables
jsonConf=$(cat /var/www/html/data/conf.php.json)
room=$(echo $jsonConf | jq --arg jq_hostname_var $HOSTNAME -r '.rooms.[] | select(.Hostname==$jq_hostname_var)')
read -r minBacklight maxBacklight timer< <(echo $room | jq -r '[ .minBacklight, .maxBacklight, .Motion.timer] | join(" ")')
backlight=$minBacklight

# Initialise flags
if [ -f /tmp/timeTime ]; then
  rm /tmp/timeTime
fi
# Initialise touchscreen brightness
echo 0 > /sys/class/backlight/10-0045/brightness
# Background action on motion
action () {
  while :
  do
    endat=$(cat /tmp/timeTime)
    if (($(printf '%(%s)T\n' -1) > $endat)); then
      break
    fi
    sleep 3
    endat=$(cat /tmp/timeTime)
  done
  echo "Timeout" $(date +"%Y-%m-%d_%H.%M.%S")
  rm /tmp/timeTime
  echo 0 > /sys/class/backlight/10-0045/brightness
}
# Functie waarmee je wacht op beweging:
wait_for_motion () {
  while read -r line ; do
    if [[ "$line" == *"Motion detected"* ]]; then
      echo "Motion detected" $(date +"%Y-%m-%d_%H.%M.%S")
      if ! [ -f /tmp/timeTime ]; then
        echo $(($(printf '%(%s)T\n' -1) + $timer)) > /tmp/timeTime # Tijd + 180 seconden
        break
      fi
      # reset timer
      echo $(($(printf '%(%s)T\n' -1) + $timer)) > /tmp/timeTime # Tijd + 180 seconden
      echo "Reset timer" $(date +"%Y-%m-%d_%H.%M.%S")
#    elif [[ "$line" == *"Motion stopped"* ]]; then
#      echo "Er geen beweging."
    fi
  # We gebruiken --nopreview om zo onopvallend mogelijk beweging te detecteren.
  # Gebruik een preview om het detectiegebied te bekijken/af te regelen
  # Keep aspect ratio: 3280/16 = 205, 2464/16 = 154
  done < <(rpicam-hello -t 0 --nopreview --lores-width 205 --lores-height 154 --post-process-file /tmp/postProcess.json 2>&1)
}

while :
do
  wait_for_motion
  # Temporary backlight
  echo $backlight > /sys/class/backlight/10-0045/brightness
  # Update weather
  XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 wtype weather -k return
  # Stop de bewegingsdetectie om de camera te gebruiken om een foto te maken
  pkill rpicam-hello
#  echo "Take photo."
  bestandsnaam=$(date +"%Y-%m-%d_%H:%M:%S")
  lux=$(sudo /usr/bin/rpicam-still -v 0 -o /tmp/$bestandsnaam".jpg" --rotation 180 --nopreview  --immediate --metadata - | grep '"Lux":')
  lux=${lux%.*} # until colon
  lux=${lux//[!0-9]/} # extract integer
  echo "Lux: $lux"
  if ! [ -f /var/www/html/data/luxmax ]; then
    luxmax=0
  else
    luxmax=$(cat /var/www/html/data/luxmax)
  fi
#  echo "Luxmax: $luxmax"
  if (($lux > $luxmax)); then
    echo $lux > /var/www/html/data/luxmax
  fi
  let backlight=$lux*$maxBacklight/$luxmax+$minBacklight
  echo $backlight > /sys/class/backlight/10-0045/brightness

  find /var/www/html/motion -mmin +$((60*24)) -type f -delete
  /usr/bin/convert /tmp/$bestandsnaam".jpg" -resize 1920 /var/www/html/motion/$bestandsnaam".jpg"

  rm /tmp/$bestandsnaam".jpg"

  action &
done
