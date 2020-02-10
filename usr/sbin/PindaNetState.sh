#!/bin/bash
# Clean Chromium start
#sed -i 's/"exited_cleanly":false/"exited_cleanly":true/; s/"exit_type":"[^"]\+"/"exit_type":"Normal"/' /home/pi/.config/chromium/Default/Preferences
#sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /home/pi/.config/chromium/'Local State'

# Cleanup missed received bluetooth files
#find /var/www/html/data/bluetooth -mmin +5 -type f -delete

if [ ! -d /var/www/html/motion/day ]; then
  mkdir -p /var/www/html/motion/day;
fi
now=$(date +%H:%M)
# Raspistill disturbs playing audio stream
if [ ! -f /var/www/html/data/mpc.txt ]; then
  raspistill -n -w 800 -h 480 -o /var/www/html/motion/day/$now.jpg
  find /var/www/html/motion/day/*.jpg -mtime +0 -type f -delete

# Calculate lux tls2591
  lux=$(python3 /var/www/html/tls2591.py | awk '{print $1}')
  echo $lux  > /var/www/html/data/luxtls
  if [ ! -f /var/www/html/data/luxmaxtls ]; then
    echo 0 > /var/www/html/data/luxmaxtls
  fi
  luxmax=$(cat /var/www/html/data/luxmaxtls)
  if [ ! -f /var/www/html/data/luxmintls ]; then
    echo 1000000 > /var/www/html/data/luxmintls
  fi
  luxmin=$(cat /var/www/html/data/luxmintls)
  if [ ${lux%.*} -eq ${luxmax%.*} ] && [ ${lux#*.} \> ${luxmax#*.} ] || [ ${lux%.*} -gt ${luxmax%.*} ]; then
    luxmax=$lux
  fi
  if [ ${lux%.*} -eq ${luxmin%.*} ] && [ ${lux#*.} \< ${luxmin#*.} ] || [ ${lux%.*} -lt ${luxmin%.*} ]; then
    luxmin=$lux
  fi
  echo $luxmax > /var/www/html/data/luxmaxtls
  echo $luxmin > /var/www/html/data/luxmintls

# Calculate lux photo
  jpginfo=$(identify -verbose /var/www/html/motion/day/$now.jpg)
  FNumber=$(grep FNumber <<< "$jpginfo" | awk '{print $2}')
  ExposureTime=$(grep ExposureTime <<< "$jpginfo" | awk '{print $2}')
  ISOSpeedRatings=$(grep ISOSpeedRatings <<< "$jpginfo" | awk '{print $2}')
  lux=$(awk "BEGIN {printf \"%.2f\", ($FNumber * $FNumber) / ($ISOSpeedRatings * $ExposureTime)}")
  echo $lux  > /var/www/html/data/lux
  if [ ! -f /var/www/html/data/luxmax ]; then
    echo 0 > /var/www/html/data/luxmax
  fi
  luxmax=$(cat /var/www/html/data/luxmax)
  if [ ! -f /var/www/html/data/luxmin ]; then
    echo 1000000 > /var/www/html/data/luxmin
  fi
  luxmin=$(cat /var/www/html/data/luxmin)
  if [ ${lux%.*} -eq ${luxmax%.*} ] && [ ${lux#*.} \> ${luxmax#*.} ] || [ ${lux%.*} -gt ${luxmax%.*} ]; then
    luxmax=$lux
  fi
  if [ ${lux%.*} -eq ${luxmin%.*} ] && [ ${lux#*.} \< ${luxmin#*.} ] || [ ${lux%.*} -lt ${luxmin%.*} ]; then
    luxmin=$lux
  fi
  echo $luxmax > /var/www/html/data/luxmax 
  echo $luxmin > /var/www/html/data/luxmin

# Kalibrate for screen backlight
  luxrange=$(awk "BEGIN {printf \"%.2f\", $luxmax - $luxmin}")
  luxrel=$(awk "BEGIN {printf \"%.2f\", ($lux - $luxmin) / $luxrange}")
  backlight=$(awk "BEGIN {printf \"%.0f\", 25 + $luxrel * 230}")
  current=$(cat /sys/class/backlight/rpi_backlight/brightness)

# Smooth backlight adjustment
  if [ $current -lt $backlight ]; then
    for i in $(seq $current $backlight); do
      echo $i > /sys/class/backlight/rpi_backlight/brightness
    done
  else
    for i in $(seq $current -1 $backlight); do
      echo $i > /sys/class/backlight/rpi_backlight/brightness
    done
  fi

# Calculate brightness for screen backlight adjustment
  brightness=$(convert /var/www/html/motion/day/$now.jpg -colorspace gray -format "%[fx:100*mean]" info:)
  echo $brightness > /var/www/html/data/brightness
#backlight=$(echo $brightness 1.27 | awk '{printf "%.0f\n",$1*$2}')
#backlight=$(( $backlight > 24 ? $backlight : 24 ))
#echo $backlight > /sys/class/backlight/rpi_backlight/brightness
fi
# deactivate status led's
echo 0 > /sys/class/leds/led0/brightness
echo 0 > /sys/class/leds/led1/brightness


#BTController="B8:27:EB:49:17:03"
# Array bluetooth MAC addresses
# Scan with: hcitool scan
#bluetooth=(94:0E:6B:F8:97:31 7C:67:A2:C1:F8:F8)

#home="1"
#for i in ${bluetooth[@]}; do
#  sdptool browse $i
#  if [ $? == 0 ]; then # home
#    home="0"
#    break
#  fi
#done

#if [ "$home" -gt "0" ]; then
  # Sleep state
#  if [ $(cat /var/www/html/data/state) == "awake" ]; then
#    echo "sleep" > /var/www/html/data/state
#  fi
#else
  # Awake state
#  if [ $(cat /var/www/html/data/state) == "sleep" ]; then
#    echo "awake" > /var/www/html/data/state
#  fi
#fi

#state=$(cat /var/www/html/data/state)

#if [ "$state" == "awake" ]; then
  # activate touchscreen and status led's
#  echo 0 > /sys/class/backlight/rpi_backlight/bl_power
#  echo 255 > /sys/class/leds/led0/brightness
#  echo 255 > /sys/class/leds/led1/brightness
#  exit
#elif [ "$state" == "sleep" ]; then
  # deactivate touchscreen and status led's
#  echo 1 > /sys/class/backlight/rpi_backlight/bl_power
#  echo 0 > /sys/class/leds/led0/brightness
#  echo 0 > /sys/class/leds/led1/brightness
#fi
