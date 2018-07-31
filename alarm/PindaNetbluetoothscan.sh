#!/bin/bash

home="1"

bluetooth=(94:0E:6B:F8:97:31 94:0E:6B:F8:97:30)
for i in ${bluetooth[@]}; do
  sdptool browse $i
  if [ $? == 0 ]; then # home
    home="0"
    break
  fi
done

tail -999 /var/PindaNet/bluetoothscandebug.txt > /var/PindaNet/bluetoothscandebug.trunc
mv /var/PindaNet/bluetoothscandebug.trunc /var/PindaNet/bluetoothscandebug.txt
if [ "$home" -gt "0" ]; then
  echo "Afwezig op $(date)" >> /var/PindaNet/bluetoothscandebug.txt
else
  echo "Thuis op $(date)" >> /var/PindaNet/bluetoothscandebug.txt
fi
