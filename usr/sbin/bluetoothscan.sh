#!/bin/bash
absent=$(cat /var/www/html/data/absent)
((absent++))
(sleep 1; echo "scan on"; sleep 50; echo "exit") | bluetoothctl > /var/www/html/data/bluetoothscan.txt
maccounter=0
while read line
do
  var2=$(awk '{ print $3 }'  <<< "$line")
  testvar=$(echo -e '\015[\033[0;92mNEW\033[0m]')
#  echo "$var2" | hexdump -C -b >> /var/www/html/data/bluetoothscandebug.txt
  if [ "$var2" == "$testvar" ]; then
    mac=$(awk '{ print $5 }'  <<< "$line")
    name=$(awk '{ print $6 " " $7 }'  <<< "$line")
    namemac=$(awk '{ print $6 }'  <<< "$line")
    if [ "$name" == "Activite C8" ] || [ "$namemac" == "$mac" ]; then
      mac[$maccounter]=$mac
      ((maccounter++))
      absent="0"
    fi
  fi
done < /var/www/html/data/bluetoothscan.txt
for i in "${mac[@]}"
do
  (sleep 1; echo "remove $i"; sleep 1; echo "exit") | bluetoothctl
done
echo $absent > /var/www/html/data/absent

if [ "$absent" -gt "0" ]; then
  echo "Afwezig($absent) op $(date)" >> /var/www/html/data/bluetoothscandebug.txt
else
  echo "Thuis($absent) op $(date)" >> /var/www/html/data/bluetoothscandebug.txt
fi

# alarm indien nodig uitschakelen
if [ -f /var/www/html/motion/foto_diff.txt ]; then
  DIFF="$(cat /var/www/html/motion/foto_diff.txt)"
  if [ "$DIFF" -gt "20" ]; then # Alarm uitschakelen
    python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "0B 11 00 00 01 25 4A AE 0D 00 00 80"
    echo "0" > /var/www/html/motion/foto_diff.txt
  fi
  rm -f /var/www/html/motion/foto_diff.txt
fi

if [ "$absent" -eq "0" ]; then # home
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
if [ "$absent" -gt "5" ]; then # not home
  if [ -f /var/www/html/motion/foto.png ]; then # Motion detection active
    mv /var/www/html/motion/foto1.png /var/www/html/motion/foto.png
    raspistill -n -w 800 -h 480 -o /var/www/html/motion/foto1.png
    compare -fuzz 50% -metric ae /var/www/html/motion/foto.png /var/www/html/motion/foto1.png /var/www/html/motion/diff.png 2> /var/www/html/motion/foto_diff.txt
    DIFF="$(cat /var/www/html/motion/foto_diff.txt)"
# echo $DIFF
    if [ "$DIFF" -gt "20" ]; then
      cp /var/www/html/motion/foto1.png "/var/www/html/motion/fotos/`date +"%Y %m %d %R"`.png"
      # Alarm laten afgaan
      python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "0B 11 00 00 01 25 4A AE 0D 01 0F 80"
    fi
  else # Activate motion detection
    raspistill -n -w 800 -h 480 -o /var/www/html/motion/foto.png
  fi
  # deactivate touchscreen and status led's
  echo 1 > /sys/class/backlight/rpi_backlight/bl_power
  echo 0 > /sys/class/leds/led0/brightness
  echo 0 > /sys/class/leds/led1/brightness
fi
