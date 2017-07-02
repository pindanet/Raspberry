#!/bin/bash
# PiCam Motion Detection

home=`cat /sys/class/backlight/rpi_backlight/bl_power`
if [ $home == "1" ]; then # not home
  mv /var/www/html/alarm/foto1.png /var/www/html/alarm/foto.png
  raspistill -n -w 800 -h 480 -o /var/www/html/alarm/foto1.png
  compare -fuzz 70% -metric ae /var/www/html/alarm/foto.png /var/www/html/alarm/foto1.png /var/www/html/alarm/diff.png 2> /var/www/html/alarm/foto_diff.txt
  DIFF="$(cat /var/www/html/alarm/foto_diff.txt)"
  echo $DIFF
  if [ "$DIFF" -gt "1000" ]; then
    echo "Alarm"
    cp /var/www/html/alarm/foto1.png "/var/www/html/alarm/fotos/`date +"%R %d %m %Y"`.png"
  else
    echo "No Alarm"
  fi
else
  echo "HOME"
  raspistill -n -w 800 -h 480 -o /var/www/html/alarm/foto.png
fi
