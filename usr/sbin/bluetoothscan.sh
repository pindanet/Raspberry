#!/bin/bash
absent=$(cat /var/www/html/data/absent)
((absent++))
(sleep 1; echo "scan on"; sleep 50; echo "exit") | bluetoothctl > /var/www/html/data/bluetoothscan.txt
maccounter=0
while read line
do
  var2=$(awk '{ print $3 }'  <<< "$line")
  testvar=$(echo -e '\015[\033[0;92mNEW\033[0m]')
#  echo "$var2" | hexdump -C -b >> /var/www/html/data/bluetoothscanDdebug.txt
  if [ "$var2" == "$testvar" ]; then
    mac=$(awk '{ print $5 }'  <<< "$line")
    name=$(awk '{ print $6 " " $7 }'  <<< "$line")
    namemac=$(awk '{ print $6 }'  <<< "$line")
    if [ "$name" == "Activite C8" ] || [ "$namemac" == "$mac" ]; then
      absent="0"
      mac[$maccounter]=$mac
      ((maccounter++))
    fi
  fi
done < /var/www/html/data/bluetoothscan.txt
for i in "${mac[@]}"
do
  (sleep 1; echo "remove $i"; sleep 1; echo "exit") | bluetoothctl
done
echo $absent > /var/www/html/data/absent
if [ "$absent" -gt "0" ]; then
  echo "$absent op $(date)" >> /var/www/html/data/bluetoothscanDdebug.txt
fi
