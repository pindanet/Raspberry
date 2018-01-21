#!/bin/bash
absent=$(cat /var/www/html/data/absent)
((absent++))
echo "Debug $absent" # >> /var/www/html/data/bluetoothscanDdebug.txt
(sleep 1; echo "scan on"; sleep 50; echo "exit") | bluetoothctl > /var/www/html/data/bluetoothscan.txt
maccounter=0
while read line
do
  echo $(awk '{ print $2 }'  <<< "$line")
  var2=$(awk '{ print $2 }'  <<< "$line")
  testvar=$(echo -e '\015\033[K[\033[0;92mNEW\033[0m]')
#  echo "$var2" | hexdump -C -b >> /var/www/html/data/bluetoothscanDdebug.txt
  if [ "$var2" == "$testvar" ]; then
    mac[$maccounter]=$(awk '{ print $4 }'  <<< "$line")
    name=$(awk '{ print $5 " " $6 }'  <<< "$line")
    if [ "$name" == "Activite C8" ]; then
      absent="0"
    fi
    name=$(awk '{ print $5 }'  <<< "$line")
    if [ "$name" == "$mac[$maccounter]" ]; then
      absent="0"
    fi
  fi
  ((maccounter++))
done < /var/www/html/data/bluetoothscan.txt
for i in "${mac[@]}"
do
  (sleep 1; echo "remove $i"; sleep 1; echo "exit") | bluetoothctl
done
echo $absent > /var/www/html/data/absent
