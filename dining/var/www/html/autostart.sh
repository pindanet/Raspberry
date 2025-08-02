#!/bin/bash
killall vlc
killall wayout
# Optional Force resolution
# sudo apt install wlr-randr -y
# Only for my EIZO monitor
#wlr-randr --output HDMI-A-1 --mode 1920x1200@59.950001Hz
# Disable Power led
echo 0 | sudo tee /sys/class/leds/PWR/brightness
# Disable Activity led
echo none | sudo tee /sys/class/leds/ACT/trigger
# Activate DS18B20 temperature sensor power (Reset)
/usr/bin/pinctrl set 17 op dh
/usr/bin/pinctrl set 27 op dh
# PullUp 1-wire Data
/usr/bin/pinctrl set 4 ip pu
readarray -d '' videos < <(find /var/www/html/ -name "*.mp4" -print0)
video=${videos[$(( $RANDOM % ${#videos[@]} ))]}
if [[ "$video" == *"aquarium"* ]]; then
  color="black"
else
  color="white"
fi

#video="/var/www/html/haardvuur.mp4"
#color="white"

days=("maandag" "dinsdag" "woensdag" "donderdag" "vrijdag" "zaterdag" "zondag")
months=("januari" "februari" "maart" "april", "mei", "juni", "juli", "augustus", "september", "october", "november", "december")

while true; do
  # Wait for active HDMI
  if [ $(cat /sys/class/drm/card?-HDMI-A-1/enabled) == "enabled" ]; then
    echo "Start VLC"
    # Start VLC met Wayland in Kiosk mode
    unset DISPLAY
    QT_QPA_PLATFORM=wayland vlc --no-video-title-show --fullscreen --loop -Idummy ${video} &
    locDate=${days[$(($(date +'%-u') - 1))]}$(date "+, %-d ${months[$(($(date +'%-m') - 1))]} %Y")
    counter=$(((33 - ${#locDate}) / 2))
    while [ $counter -gt 0 ]
    do
      locDate=" $locDate"
      ((counter=counter-1))
    done
    while [ $(cat /sys/class/drm/card?-HDMI-A-1/enabled) == "enabled" ]; do
#      text="$(LANG=nl_BE.UTF-8 date '+%A, %e %B %Y %H:%M:%S')     $(printf ' %.1f   C' $((10**1 * $(($(cat /var/www/html/data/temp) + 700))/1000))e-1)"
      text="${locDate}   $(date '+ %H:%M:%S')   $(printf ' %.1f \u00B0C' $((10**1 * $(($(cat /var/www/html/data/temp) + 700))/1000))e-1)"
      echo "<b><span foreground=\"${color}\">${text}</span></b>"
      sleep 1
    done | wayout --feed-line --width 1920 --height 80 --layer overlay --position bottom --font "Monospace 44"
    echo "Stop VLC"
    killall vlc
  fi
  sleep 1
done
