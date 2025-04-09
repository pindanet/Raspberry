#!/bin/bash
# AlarmClock Alarm

str=$(cat /var/www/html/data/radio.cmd)
cmd=();
delimiter=", "
s=$str$delimiter
while [[ $s ]]; do
  cmd+=( "${s%%"$delimiter"*}" );
  s=${s#*"$delimiter"};
done;
declare -p cmd

case ${cmd[0]} in
  "play")
    volume=${cmd[1]}
    interval=${cmd[2]}
    radio=${cmd[3]}

    rm /var/www/html/data/radio.stop
    rm /var/www/html/data/radio.log
    killall roc-recv

    curl -H "Icy-MetaData:1" --silent -L "$radio" 2>&1 | mpg123 --icy-interval $interval -f -$volume - 2> /var/www/html/data/radio.log &

    until [ -f /var/www/html/data/radio.stop ]
    do
      sleep 1
    done
    killall curl mpg123
    rm /var/www/html/data/radio.stop
    rm /var/www/html/data/radio.log
  ;;

  "alarm")
    volume=${cmd[1]}
    interval=${cmd[2]}
    radio=${cmd[3]}

    rm /var/www/html/data/radio.log

    mpg123 -f -${cmd[1]} /var/www/html/data/bintro.mp3

    curl -H "Icy-MetaData:1" --silent -L "$radio" 2>&1 | mpg123 --icy-interval $interval -f -$volume - 2> /var/www/html/data/radio.log &

    sleep 180 # 3 minuten wakker worden
    sleep 180 # 3 minuten nekoefeningen
    sleep 300 # 5 minuten rechtop zitten

    dpkg --configure -a
    apt-get clean
    apt autoremove -y
    apt-get update
    apt-get upgrade -y

    rm /var/www/html/data/radio.log

    shutdown -r now
  ;;
esac
