#!/bin/bash
# postProcess var
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
echo $motion > /var/www/html/postProcess.json
# Functie waarmee je wacht op beweging:
wait_for_motion () {
  while read -r line ; do
    if [[ "$line" == *"Motion detected"* ]]; then
      break
    fi
  # We gebruiken --nopreview om zo onopvallend mogelijk beweging te detecteren.
  # Gebruik een preview om het detectiegebied te bekijken/af te regelen.
  done < <(/usr/bin/rpicam-hello -t 0 --nopreview --lores-width 128 --lores-height 96 --post-process-file /var/www/html/postProcess.json 2>&1)
}
# Save Lux
saveLux () {
  one=${1#*: }
  lux=${one%.*}
  if (( $lux >= 0 )); then
    echo "Lux $lux"
    echo $lux > /var/www/html/data/lux
    if [ ! -f /var/www/html/data/luxmax ]; then
      echo 0 > /var/www/html/data/luxmax
    fi
    max=$(cat /var/www/html/data/luxmax)
    if (( $lux > $max )); then
      echo $lux > /var/www/html/data/luxmax
    fi
    echo "Max $(cat /var/www/html/data/luxmax)"
  fi
}
# Hier begint ons programma
# Oneindig lang worden bewegingen gemeld
# Breek het programma af met Ctrl+c
export -f wait_for_motion
while :
do
  end=$(date --date='1 minutes' +%s)
  timeout 60s bash -c wait_for_motion
  # Stop de bewegingsdetectie om de camera te gebruiken om een video te maken
  if [ $? -eq 124 ]; then # timeout
    pkill rpicam-hello
#    echo "Geen beweging."
    lux=$(/usr/bin/rpicam-still --nopreview --immediate --metadata - -o /dev/zero 2>&1 | grep Lux)
    saveLux "$lux"
  else # motion
    if [ ! -d /var/www/html/motion ]; then
      mkdir /var/www/html/motion
    fi
    pkill rpicam-hello
    find /var/www/html/motion -mmin +$((60*24)) -type f -delete
#    echo "Er is beweging."
    filename=$(date +"%Y-%m-%d_%H.%M.%S.jpg")
    lux=$(/usr/bin/rpicam-still --nopreview --immediate --metadata - -o /var/www/html/motion/$filename 2>&1 | grep Lux)
    saveLux "$lux"
    /usr/bin/convert /var/www/html/motion/$filename -rotate 90 /var/www/html/motion/$filename
#    /usr/bin/convert Foto.jpg -rotate 90 -crop 1920x1080+24+1512 Foto.jpg
  fi
  # Every minute
  rest=$(( $end - $(date +%s) ))
  if (( $rest > 0 )); then
    echo "Sleep $rest"
    sleep $rest
  fi
done
