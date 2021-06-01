#!/bin/bash
# GPIO 5 (29) > Button > Gnd (34)

# ToDo
# https://linuxize.com/post/at-command-in-linux/
#at 18:34 -M <<END
#nohup mpg123 -f -1000 $(curl -s -i http://icecast.vrtcdn.be/stubru-high.mp3 | grep Location | awk '{ print $2 }') 2> radio.log &
#END

_button_pin=5

function playRadio () {
  # $1 = radio URL
  # $2 = volume
  nohup mpg123 -f -$2 $(curl -s -i $1 | grep Location | awk '{ print $2 }') 2> /var/www/html/data/radio.log &
  sleep 5
}

raspi-gpio set $_button_pin ip pu # input pull up

#timer=$(date +"%s")

# get next alarm
. /var/www/html/data/alarmclock
tomorrow=$(date --date="next day" +%u)
echo ${alarmtimes[$tomorrow]} > /var/www/html/data/nextalarm

while true; do
  . /var/www/html/data/alarmclock

  clock=$(date -u +"%H:%M")
  localclock=$(date +"%H:%M")

  starttime=$(date +"%s")
  while [ $(($(date +"%s") - starttime)) -lt 55 ]; do
    sleepbutton=$(raspi-gpio get $_button_pin)
#    echo "$(date): $sleepbutton)"
    if [[ $sleepbutton == *"level=0"* ]]; then
      if [[ $(raspi-gpio get $_button_pin) == *"level=0"* ]]; then
        if pgrep -x "mpg123" >/dev/null; then
          killall mpg123
          sleep 5
        else
          # Exceptions with recurrent dates and times
          for sleepitem in "${sleepevent[@]}"; do
            now=$(date +%H:%M)
            daytime=(${sleepitem})
            recevent=$(date -u --date "${daytime[0]}" +%s)
            timebetween=$((${daytime[1]} * 86400))
            nowSec=$(date -u +%s)
            today=$((nowSec - (nowSec % 86400)))
            while  [ $recevent -lt $today ]; do
              recevent=$((recevent + timebetween))
            done
            if [ $today == $recevent ]; then
              if [[ "${daytime[2]}" < "$now" ]] && [[ "${daytime[3]}" > "$now" ]]; then
                echo "Sleep Event on $(date -u --date @$recevent +'%a %d %b %Y') between ${daytime[2]} and ${daytime[3]}: Radio: ${daytime[4]}, Volume: ${daytime[5]}"
                radio=${daytime[4]}
                volume=${daytime[5]}
                break
              fi
            fi
          done
	  playRadio $radio $volume
        fi
      fi
#      timer=$(date +"%s")
    fi
    sleep 0.2
  done
done
