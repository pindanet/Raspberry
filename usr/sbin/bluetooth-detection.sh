#!/bin/bash
# Bluetooth Proximity Detection

# hcitool scan
# echo -n "MA:C-:ad:dr:es:BT" > bluetooth.detection
# sudo hcitool info MA:C-:ad:dr:es:BT | md5sum | awk '{ print $1 }' >> bluetooth.detection
# sudo mv bluetooth.detection /var/www/html/ /var/www/html/data/

# alarm indien nodig uitschakelen
if [ -f /var/www/html/motion/foto_diff.txt ]; then
  DIFF="$(cat /var/www/html/motion/foto_diff.txt)"
  if [ "$DIFF" -gt "20" ]; then # Alarm uitschakelen
    python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "0B 11 00 01 01 41 53 86 0D 00 00 80"
    echo "0" > /var/www/html/motion/foto_diff.txt
  fi
  rm -f /var/www/html/motion/foto_diff.txt
fi

while IFS='' read -r bluetooth || [[ -n "$bluethooth" ]]; do
# bluetooth=`cat /var/www/html/data/bluetooth.detection`
  info=`hcitool info ${bluetooth:0:17} | md5sum`
  if [ ${bluetooth:17:32} == ${info:0:32} ]; then # home
    if [ -f /var/www/html/motion/foto.png ]; then # Deactivate Motion detection 
      rm -f /var/www/html/motion/foto.png
      rm -f /var/www/html/motion/foto1.png
    fi
    # activate touchscreen and status led's
    echo 0 > /sys/class/backlight/rpi_backlight/bl_power
    echo 255 > /sys/class/leds/led0/brightness
    echo 255 > /sys/class/leds/led1/brightness
    exit
  fi
done < "/var/www/html/data/bluetooth.detection"
# not home
if [ -f /var/www/html/motion/foto.png ]; then # Motion detection active
  mv /var/www/html/motion/foto1.png /var/www/html/motion/foto.png
  raspistill -n -w 800 -h 480 -o /var/www/html/motion/foto1.png
  compare -fuzz 50% -metric ae /var/www/html/motion/foto.png /var/www/html/motion/foto1.png /var/www/html/motion/diff.png 2> /var/www/html/motion/foto_diff.txt
  DIFF="$(cat /var/www/html/motion/foto_diff.txt)"
#  echo $DIFF
  if [ "$DIFF" -gt "20" ]; then
    cp /var/www/html/motion/foto1.png "/var/www/html/motion/fotos/`date +"%Y %m %d %R"`.png"
    # Alarm laten afgaan
    python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "0B 11 00 00 01 41 53 86 0D 01 0F 80"
  fi
else # Activate motion detection
  raspistill -n -w 800 -h 480 -o /var/www/html/motion/foto.png
fi
# deactivate touchscreen and status led's
echo 1 > /sys/class/backlight/rpi_backlight/bl_power
echo 0 > /sys/class/leds/led0/brightness
echo 0 > /sys/class/leds/led1/brightness
