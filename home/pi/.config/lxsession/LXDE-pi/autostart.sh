#!/bin/bash
# Start fullscreen browser
xte 'sleep 12' 'mousemove 400 240' 'sleep 1' 'key F11' 'sleep 1' 'key F5' &
firefox https://localhost &
# Disable Screensaver
xset s off
xset -dpms
xset s noblank
