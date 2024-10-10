#!/bin/bash
if [ ! -d motion ]; then
  mkdir motion
fi
find ./motion -mtime +1 -type f -delete
filename=$(date +"%Y-%m-%d_%H.%M.%S.jpg")
rpicam-still -o motion/$filename --rotation 180
