#!/bin/bash
# Activate DS18B20 temperature sensor power (Reset)
/usr/bin/pinctrl set 17 op dh
# PullUp 1-wire Data
/usr/bin/pinctrl set 4 ip pu
# Give www-data access to Wayland
setfacl -R -m u:www-data:wx /run/user/1000
# Autostart Chromium in Kiosk & Debug mode
# --kiosk can be replaced by --start-fullscreen
# --disable-gpu: remove's dmesg errors, but much slower interface
# --start-maximized seems not neccessary
/bin/chromium --remote-debugging-port=9222 --kiosk --disable-extensions --noerrdialogs --disable-infobars --enable-features=OverlayScrollbar http://localhost/ &
# Give Chromium time to start
sleep 30
# Check if Chromium is running
until ps -ax | grep kiosk | grep -v grep
do
  # After a hostname change, chromium refuses to start, correct this
  rm -rf /home/dany/.config/chromium/Singleton*
  # Restart chromium
  /bin/chromium --remote-debugging-port=9222 --kiosk --disable-extensions --noerrdialogs --disable-infobars --enable-features=OverlayScrollbar http://localhost/ &
  sleep 30
done
