#!/bin/bash
# Start fullscreen browser
xte 'sleep 10' 'key F11' &
firefox localhost &
# Disable Screensaver
xset s off
xset -dpms
xset s noblank
