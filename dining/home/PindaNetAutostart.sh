#!/bin/bash
# Optional Force resolution
# sudo apt install wlr-randr -y
# Only for my EIZO monitor
#wlr-randr --output HDMI-A-1 --mode 1920x1200@59.950001Hz
# Activate DS18B20 temperature sensor power (Reset)
/usr/bin/pinctrl set  op dh
# PullUp 1-wire Data
/usr/bin/pinctrl set 4 ip pu
# Autostart Chromium in Kiosk & Debug mode
#/bin/chromium --autoplay-policy=no-user-gesture-required --remote-debugging-port=9222 --kiosk --ozone-platform=wayland --start-maximized --noerrdialogs --disable-infobars --enable-features=OverlayScrollbar  http://localhost/ &
# Give Chromium time to start
sleep 30
ffplay -hide_banner -loglevel error -fs -loop 0 /var/www/html/haardvuur.mp4
# Check if Chromium is running
#until ps -ax | grep kiosk | grep -v grep
#do
#  # After a hostname change, chromium refuses to start, correct this
#  rm -rf /home/dany/.config/chromium/Singleton*
#  # Restart chromium
#  /bin/chromium --autoplay-policy=no-user-gesture-required --remote-debugging-port=9222 --kiosk --ozone-platform=wayland --start-maximized --noerrdialogs --disable-infobars --enable-features=OverlayScrollbar  http://localhost/ &
#  sleep 30
#done
