#!/bin/bash
# Disable Power led
echo 0 | sudo tee /sys/class/leds/PWR/brightness
# Disable Activity led
echo none | sudo tee /sys/class/leds/ACT/trigger
# Autostart Chromium in Kiosk & Debug mode
/bin/chromium --remote-debugging-port=9222 --kiosk --disable-extensions --noerrdialogs --disable-infobars --enable-features=OverlayScrollbar  http://localhost/ &
# Give Chromium time to start
sleep 30
# Check if Chromium is running
until ps -ax | grep kiosk | grep -v grep
do
  # After a hostname change, chromium refuses to start, correct this
  rm -rf /home/dany/.config/chromium/Singleton*
  # Restart chromium
  /bin/chromium --remote-debugging-port=9222 --kiosk --disable-extensions --noerrdialogs --disable-infobars --enable-features=OverlayScrollbar  http://localhost/ &
  sleep 30
done
