#!/bin/bash

# Array bluetooth MAC addresses
# Scan with: hcitool scan
bluetooth=(94:0E:6B:F8:97:31 94:0E:6B:F8:97:30)

heating () {
  if [ $1 == "on" ] && [ $(gpio -g read 16) -eq 1 ]; then
    gpio -g mode 16 out
    gpio -g write 16 0
    echo "$(date): Heating $2 on" >> /var/PindaNet/debug.txt
  elif [ $(gpio -g read 16) -eq 0 ]; then
    gpio -g mode 16 out
    gpio -g write 16 1
    echo "$(date): Heating $2 off" >> /var/PindaNet/debug.txt
  fi
}

home="1"
for i in ${bluetooth[@]}; do
  sdptool browse $i
  if [ $? == 0 ]; then # home
    home="0"
    break
  fi
done

tail -999 /var/PindaNet/debug.txt > /var/PindaNet/debug.trunc
mv /var/PindaNet/debug.trunc /var/PindaNet/debug.txt
if [ "$home" -gt "0" ]; then
  # Disable Pi Zero ACT LED
  echo none > /sys/class/leds/led0/trigger
  echo 1 > /sys/class/leds/led0/brightness
  # Heating off
  heating off "in empty room"
else
  # Activate Pi Zero ACT LED
  echo none rc-feedback kbd-scrolllock kbd-numlock kbd-capslock kbd-kanalock kbd-shiftlock kbd-altgrlock kbd-ctrllock kbd-altlock kbd-shiftllock kbd-shiftrlock kbd-ctrlllock kbd-ctrlrlock timer oneshot heartbeat backlight gpio cpu cpu0 default-on input panic mmc1 [mmc0] rfkill-any rfkill0 rfkill1 > /sys/class/leds/led0/trigger
  echo 0 > /sys/class/leds/led0/brightness
  read_bme280 --i2c-address 0x77 > /var/PindaNet/PresHumiTemp

  if [ $(tail -1 /var/PindaNet/PresHumiTemp) == "on" ]; then
    heating on "manual"
  elif [ $(cat /var/PindaNet/heating) == "off" ]; then
    heating off "manual"
  else
    temp=$(cat /var/PindaNet/temp)
    if [ "$res2" -lt 20 ]; then
      heating on "auto"
    else
      heating off "auto"
    fi
  fi
fi
