#!/bin/bash
(sleep 1; echo "scan on"; sleep 50; echo "exit") | bluetoothctl > bluetoothscan.txt
while read line
do
	var2=$(awk '{ print $2 }'  <<< "$line")
	testvar=$(echo -e '\015\033[K[\033[0;92mNEW\033[0m]')
#	echo "$var2" | hexdump -C -b
  if [ "$var2" == "$testvar" ]; then
    mac=$(awk '{ print $4 }'  <<< "$line")
    name=$(awk '{ print $5 " " $6 }'  <<< "$line")
    echo "$mac" "$name"
  fi
#	sleep 1
done < bluetoothscan.txt
(sleep 1; echo "remove $mac"; sleep 1; echo "exit") | bluetoothctl
