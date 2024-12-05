#!/bin/bash
killall mpv
killall wayout
# Optional Force resolution
# sudo apt install wlr-randr -y
# Only for my EIZO monitor
#wlr-randr --output HDMI-A-1 --mode 1920x1200@59.950001Hz
# Activate DS18B20 temperature sensor power (Reset)
/usr/bin/pinctrl set 17 op dh
# PullUp 1-wire Data
/usr/bin/pinctrl set 4 ip pu
# Autostart VLC in Kiosk mode
#sleep 30
readarray -d '' videos < <(find /var/www/html/ -name "*.mp4" -print0)
#videos+=("aquarium1920.mp4")
#videos+=("haardvuur.mp4")
video=${videos[$(( $RANDOM % ${#videos[@]} ))]}
#if [ $video == "aquarium.mp4" ]; then
if [[ "$video" == *"aquarium"* ]]; then
  color="black"
else
  color="white"
fi
mpv --fs --loop --quiet ${video} &
#vlc --no-video-title-show --fullscreen --loop -Idummy ${video} &
# --alsa-audio-device default
while true; do
  echo "<span foreground=\"${color}\">$(date +%H:%M:%S)</span>"
  sleep 1
done | wayout --feed-line --width 800 --height 40 --layer overlay --position bottom --font "Monospace 22"
