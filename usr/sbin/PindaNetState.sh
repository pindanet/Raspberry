#!/bin/bash
# Clean Chromium start
#sed -i 's/"exited_cleanly":false/"exited_cleanly":true/; s/"exit_type":"[^"]\+"/"exit_type":"Normal"/' /home/pi/.config/chromium/Default/Preferences
#sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /home/pi/.config/chromium/'Local State'

# Cleanup missed received bluetooth files
#find /var/www/html/data/bluetooth -mmin +5 -type f -delete

if [ ! -d /var/www/html/motion/day ]; then
  mkdir -p /var/www/html/motion/day;
fi
now=$(date +%H:%M)
raspistill -vf -hf -n -w 800 -h 480 -o /var/www/html/motion/day/$now.jpg
find /var/www/html/motion/day/*.jpg -mtime +0 -type f -delete

# Calculate brightness for screen backlight adjustment
brightness=$(convert /var/www/html/motion/day/$now.jpg -colorspace gray -format "%[fx:100*mean]" info:)
backlight=$(echo $brightness 1.27 | awk '{printf "%.0f\n",$1*$2}')
echo $backlight | sudo tee /sys/class/backlight/rpi_backlight/brightness

# deactivate status led's
echo 0 > /sys/class/leds/led0/brightness
echo 0 > /sys/class/leds/led1/brightness

#BTController="B8:27:EB:49:17:03"
# Array bluetooth MAC addresses
# Scan with: hcitool scan
#bluetooth=(94:0E:6B:F8:97:31 7C:67:A2:C1:F8:F8)

#home="1"
#for i in ${bluetooth[@]}; do
#  sdptool browse $i
#  if [ $? == 0 ]; then # home
#    home="0"
#    break
#  fi
#done

#if [ "$home" -gt "0" ]; then
  # Sleep state
#  if [ $(cat /var/www/html/data/state) == "awake" ]; then
#    echo "sleep" > /var/www/html/data/state
#  fi
#else
  # Awake state
#  if [ $(cat /var/www/html/data/state) == "sleep" ]; then
#    echo "awake" > /var/www/html/data/state
#  fi
#fi

#state=$(cat /var/www/html/data/state)

#if [ "$state" == "awake" ]; then
  # activate touchscreen and status led's
#  echo 0 > /sys/class/backlight/rpi_backlight/bl_power
#  echo 255 > /sys/class/leds/led0/brightness
#  echo 255 > /sys/class/leds/led1/brightness
#  exit
#elif [ "$state" == "sleep" ]; then
  # deactivate touchscreen and status led's
#  echo 1 > /sys/class/backlight/rpi_backlight/bl_power
#  echo 0 > /sys/class/leds/led0/brightness
#  echo 0 > /sys/class/leds/led1/brightness
#fi
