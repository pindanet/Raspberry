#!/bin/bash
# Clean Chromium start
#sed -i 's/"exited_cleanly":false/"exited_cleanly":true/; s/"exit_type":"[^"]\+"/"exit_type":"Normal"/' /home/pi/.config/chromium/Default/Preferences
#sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /home/pi/.config/chromium/'Local State'

# Cleanup missed received bluetooth files
find /var/www/html/data/bluetooth -mmin +5 -type f -delete

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
