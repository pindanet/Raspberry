#!/bin/bash
# Clean Chromium start
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/; s/"exit_type":"[^"]\+"/"exit_type":"Normal"/' /home/pi/.config/chromium/Default/Preferences
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /home/pi/.config/chromium/'Local State'

absent=$(cat /var/www/html/data/absent)
((absent++))

# Functie voor het zoeken naar een Smartphone
function sdptoolscan  {
  # bluetooth="94:0E:6B:F8:97:31$(sdptool browse 94:0E:6B:F8:97:31 | sed '/Withings/,+8d' | md5sum | awk '{ print $1 }')"
  # echo $bluetooth
  bluetooth="94:0E:6B:F8:97:31756e54a95c34f7ccf8c211995fb35559"
#  info=$(sdptool browse ${bluetooth:0:17} | sed '/Withings/,+8d' | md5sum)
#  if [ ${bluetooth:17:32} == ${info:0:32} ]; then # home
  sdptool browse ${bluetooth:0:17}
  if [ $? == 0 ]; then # home
    absent="0"
  fi
}
sdptoolscan
# Functie voor het zoeken naar een Nokia Steel Watch
function bluetoothctlscan {
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
}
# bluetoothctlscan

echo $absent > /var/www/html/data/absent

tail -999 /var/www/html/data/bluetoothscandebug.txt > /var/www/html/data/bluetoothscandebug.trunc
mv /var/www/html/data/bluetoothscandebug.trunc /var/www/html/data/bluetoothscandebug.txt
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

raspistill -n -w 800 -h 480 -o /var/www/html/motion/luminance.jpg # Take photo
luminance="$(/usr/bin/php7.0 /var/www/html/luminance.php)"
echo $luminance > /var/www/html/motion/luminance.txt

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

if [ "$absent" -gt "1" ]; then # not home
  if [ -f /var/www/html/motion/foto.png ]; then # Motion detection active
    mv /var/www/html/motion/foto1.png /var/www/html/motion/foto.png
    cp /var/www/html/motion/luminance.jpg /var/www/html/motion/foto1.png
#    raspistill -n -w 800 -h 480 -o /var/www/html/motion/foto1.png
    compare -fuzz 50% -metric ae /var/www/html/motion/foto.png /var/www/html/motion/foto1.png /var/www/html/motion/diff.png 2> /var/www/html/motion/foto_diff.txt
    DIFF="$(cat /var/www/html/motion/foto_diff.txt)"
# echo $DIFF
    if [ "$DIFF" -gt "20" ]; then

      # Hou enkel de 100 recenste foto's
      numfiles=(/var/www/html/motion/fotos/*)
      numfiles=${#numfiles[@]}
      while [ $((numfiles)) -gt 99 ]; do
        unset -v oldest
        for file in /var/www/html/motion/fotos/*; do
          [[ -z "$oldest" || "$file" -ot "$oldest" ]] && oldest="$file"
        done
        rm "$oldest"
        numfiles=(/var/www/html/motion/fotos/*)
        numfiles=${#numfiles[@]}
      done

      cp /var/www/html/motion/foto1.png "/var/www/html/motion/fotos/`date +"%Y %m %d %R"`.jpg"
      # Alarm laten afgaan
      echo "Alarm op $(date)" >> /var/www/html/data/bluetoothscandebug.txt
      python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "0B 11 00 00 01 25 4A AE 0D 01 0F 80"
    fi
  else # Activate motion detection
    cp /var/www/html/motion/luminance.jpg /var/www/html/motion/foto.png
#    raspistill -n -w 800 -h 480 -o /var/www/html/motion/foto.png
  fi
  # deactivate touchscreen and status led's
  echo 1 > /sys/class/backlight/rpi_backlight/bl_power
  echo 0 > /sys/class/leds/led0/brightness
  echo 0 > /sys/class/leds/led1/brightness
fi
