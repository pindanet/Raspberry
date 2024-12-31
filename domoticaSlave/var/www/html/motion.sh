#!/bin/bash
if [ ! -d motion ]; then
  mkdir motion
fi
find ./motion -mmin +$((60*24)) -type f -delete
filename=$(date +"%Y-%m-%d_%H.%M.%S.jpg")
rpicam-still -o motion/$filename --rotation 180 --immediate
convert motion/$filename -resize 1920 motion/$filename
