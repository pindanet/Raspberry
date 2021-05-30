#!/bin/bash
# GPIO 5 (29) > Button > Gnd (34)

# ToDo
# https://linuxize.com/post/at-command-in-linux/
#at 18:34 -M <<END
#nohup mpg123 -f -1000 $(curl -s -i http://icecast.vrtcdn.be/stubru-high.mp3 | grep Location | awk '{ print $2 }') 2> radio.log &
#END

alarmTime="07:30"

stubru="http://icecast.vrtcdn.be/stubru-high.mp3"

_button_pin=5

function playRadio () {
  nohup mpg123 -f -1000 $(curl -s -i $1 | grep Location | awk '{ print $2 }') 2> radio.log &
  sleep 5
}

raspi-gpio set $_button_pin ip pu # input pull up

timer=$(date +"%s")

while true; do
  clock=$(date -u +"%H:%M")
  localclock=$(date +"%H:%M")

  starttime=$(date +"%s")
  while [ $(($(date +"%s") - starttime)) -lt 55 ]; do
    sleepbutton=$(raspi-gpio get $_button_pin)
    echo "$(date): $sleepbutton)"
    if [[ $sleepbutton == *"level=0"* ]]; then
      if [[ $(raspi-gpio get $_button_pin) == *"level=0"* ]]; then
        if pgrep -x "mpg123" >/dev/null; then
          killall mpg123
          sleep 5
        else
	  playRadio $stubru
        fi
      fi
      timer=$(date +"%s")
    fi
    sleep 0.2
  done
done
