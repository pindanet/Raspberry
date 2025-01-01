#!/bin/bash
brightness=$(cat /sys/class/backlight/10-0045/brightness)
if [ $? -ne 0 ]; then # error
  echo "error"
  exit
fi
if [ $brightness  -gt 0 ]; then
  if [ ! -d /var/www/html/motion ]; then
    mkdir /var/www/html/motion
  fi
  find /var/www/html/motion -mmin +$((60*24)) -type f -delete
  filename=$(date +"%Y-%m-%d_%H.%M.%S.jpg")
  /usr/bin/rpicam-still -o /var/www/html/motion/$filename --rotation 180 --nopreview
  /usr/bin/convert /var/www/html/motion/$filename -resize 1920 /var/www/html/motion/$filename
fi
