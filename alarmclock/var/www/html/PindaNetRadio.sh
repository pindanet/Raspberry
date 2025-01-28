#!/bin/bash
# AlarmClock Alarm

radio2="http://icecast.vrtcdn.be/ra2wvl-high.mp3"
klara="http://icecast.vrtcdn.be/klara-high.mp3"
stubru="http://icecast.vrtcdn.be/stubru-high.mp3"

radio=$klara
sleepradio=$radio2

volume=500

mpg123 -f -$volume /var/www/html/data/bintro.mp3

interval="8192"
curl -H "Icy-MetaData:1" --silent -L "$radio" 2>&1 | mpg123 --icy-interval $interval -f -$volume - 2> /var/www/html/data/radio.log &

sleep 180 # 3 minuten wakker worden
sleep 180 # 3 minuten nekoefeningen
sleep 300 # 5 minuten rechtop zitten

sudo dpkg --configure -a
apt-get clean
apt autoremove -y
apt-get update
apt-get upgrade -y

rm /var/www/html/data/radio.log

shutdown -r now
