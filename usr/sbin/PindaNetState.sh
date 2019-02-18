#!/bin/bash
# Clean Chromium start
#sed -i 's/"exited_cleanly":false/"exited_cleanly":true/; s/"exit_type":"[^"]\+"/"exit_type":"Normal"/' /home/pi/.config/chromium/Default/Preferences
#sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /home/pi/.config/chromium/'Local State'

# Cleanup missed received bluetooth files
#find /var/www/html/data/bluetooth -mmin +5 -type f -delete

BTController="B8:27:EB:49:17:03"
# Array bluetooth MAC addresses
# Scan with: hcitool scan
bluetooth=(94:0E:6B:F8:97:31 6C:24:83:B8:98:7B)

home="1"
for i in ${bluetooth[@]}; do
  sdptool browse $i
  if [ $? == 0 ]; then # home
    home="0"
    break
  fi
done

if [ "$home" -gt "0" ]; then
  # Sleep state
  if [ $(cat /var/www/html/data/state) == "awake" ]; then
    echo "sleep" > /var/www/html/data/state
  fi
else
  # Awake state
  if [ $(cat /var/www/html/data/state) == "sleep" ]; then
    echo "awake" > /var/www/html/data/state
  fi
fi

state=$(cat /var/www/html/data/state)

if [ "$state" == "awake" ]; then
  # activate touchscreen and status led's
  echo 0 > /sys/class/backlight/rpi_backlight/bl_power
  echo 255 > /sys/class/leds/led0/brightness
  echo 255 > /sys/class/leds/led1/brightness
  exit
elif [ "$state" == "sleep" ]; then
  # deactivate touchscreen and status led's
  echo 1 > /sys/class/backlight/rpi_backlight/bl_power
  echo 0 > /sys/class/leds/led0/brightness
  echo 0 > /sys/class/leds/led1/brightness
fi
