#!/bin/bash
# PiCam Motion Detection

home=`cat /sys/class/backlight/rpi_backlight/bl_power`
DIFF="$(cat /var/www/html/motion/foto_diff.txt)"
if [ "$DIFF" -gt "20" ]; then # Alarm uitschakelen
  python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "0B 11 00 01 01 41 53 86 0D 00 00 80"
  echo "0" > /var/www/html/motion/foto_diff.txt
fi
if [ $home == "1" ]; then # not home
  if [ -f /var/www/html/motion/foto.png ]; then # Motion detection active
    mv /var/www/html/motion/foto1.png /var/www/html/motion/foto.png
    raspistill -n -w 800 -h 480 -o /var/www/html/motion/foto1.png
    compare -fuzz 50% -metric ae /var/www/html/motion/foto.png /var/www/html/motion/foto1.png /var/www/html/motion/diff.png 2> /var/www/html/motion/foto_diff.txt
    DIFF="$(cat /var/www/html/motion/foto_diff.txt)"
#    echo $DIFF
    if [ "$DIFF" -gt "20" ]; then
      cp /var/www/html/motion/foto1.png "/var/www/html/motion/fotos/`date +"%Y %m %d %R"`.png"
      # Alarm laten afgaan
      python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "0B 11 00 00 01 41 53 86 0D 01 0F 80"
    fi
  else # Activate motion detection
    raspistill -n -w 800 -h 480 -o /var/www/html/motion/foto.png
  fi
else # home
  if [ -f /var/www/html/motion/foto.png ]; then # Deactivate Motion detection 
    rm -f /var/www/html/motion/foto.png
    rm -f /var/www/html/motion/foto1.png
  fi
fi
