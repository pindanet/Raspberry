#!/bin/bash
. /var/www/html/data/alarmclock

nohup mpg123 -f -$volume $(curl -s -i $radio | grep Location | awk '{ print $2 }') 2> /var/www/html/data/radio.log &
#nohup mpg123 -f -$volume /var/www/html/data/Old-alarm-clock-sound.mp3 &
sleep 180 # 3 minuten wakker worden
#nohup mpg123 -f -$volume /var/www/html/data/Old-alarm-clock-sound.mp3 &
sleep 180 # 3 minuten nekoefeningen
#nohup mpg123 -f -$volume /var/www/html/data/Old-alarm-clock-sound.mp3 &
sleep 300 # 5 minuten rechtop zitten
#nohup mpg123 -f -$volume /var/www/html/data/Old-alarm-clock-sound.mp3 &

# update and reboot
apt-get clean
apt-get update
apt-get upgrade -y
shutdown -r now
