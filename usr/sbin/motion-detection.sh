#!/bin/bash
# PiCam Motion Detection

home=`cat /sys/class/backlight/rpi_backlight/bl_power`
if [ $home == "1" ]; then # not home
  mv /var/www/html/motion/foto1.png /var/www/html/motion/foto.png
  raspistill -n -w 800 -h 480 -o /var/www/html/motion/foto1.png
  compare -fuzz 50% -metric ae /var/www/html/motion/foto.png /var/www/html/motion/foto1.png /var/www/html/motion/diff.png 2> /var/www/html/motion/foto_diff.txt
  DIFF="$(cat /var/www/html/motion/foto_diff.txt)"
  echo $DIFF
  if [ "$DIFF" -gt "20" ]; then
#    echo "Alarm"
    cp /var/www/html/motion/foto1.png "/var/www/html/motion/fotos/`date +"%R %d %m %Y"`.png"
#  else
#    echo "No Alarm"
  fi
else
#  echo "HOME"
  raspistill -n -w 800 -h 480 -o /var/www/html/motion/foto.png
fi
