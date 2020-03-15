#!/bin/bash
# Clean Chromium start
#sed -i 's/"exited_cleanly":false/"exited_cleanly":true/; s/"exit_type":"[^"]\+"/"exit_type":"Normal"/' /home/pi/.config/chromium/Default/Preferences
#sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /home/pi/.config/chromium/'Local State'

# Cleanup missed received bluetooth files
#find /var/www/html/data/bluetooth -mmin +5 -type f -delete

if [ ! -d /var/www/html/motion/day ]; then
  mkdir -p /var/www/html/motion/day;
fi

# https://ledshield.wordpress.com/2012/11/13/led-brightness-to-your-eye-gamma-correction-no/
correction=(65535 65508 65479 65451 65422 65394 65365 65337
    65308 65280 65251 65223 65195 65166 65138 65109
    65081 65052 65024 64995 64967 64938 64909 64878
    64847 64815 64781 64747 64711 64675 64637 64599
    64559 64518 64476 64433 64389 64344 64297 64249
    64200 64150 64099 64046 63992 63937 63880 63822
    63763 63702 63640 63577 63512 63446 63379 63310
    63239 63167 63094 63019 62943 62865 62785 62704
    62621 62537 62451 62364 62275 62184 62092 61998
    61902 61804 61705 61604 61501 61397 61290 61182
    61072 60961 60847 60732 60614 60495 60374 60251
    60126 59999 59870 59739 59606 59471 59334 59195
    59053 58910 58765 58618 58468 58316 58163 58007
    57848 57688 57525 57361 57194 57024 56853 56679
    56503 56324 56143 55960 55774 55586 55396 55203
    55008 54810 54610 54408 54203 53995 53785 53572
    53357 53140 52919 52696 52471 52243 52012 51778
    51542 51304 51062 50818 50571 50321 50069 49813
    49555 49295 49031 48764 48495 48223 47948 47670
    47389 47105 46818 46529 46236 45940 45641 45340
    45035 44727 44416 44102 43785 43465 43142 42815
    42486 42153 41817 41478 41135 40790 40441 40089
    39733 39375 39013 38647 38279 37907 37531 37153
    36770 36385 35996 35603 35207 34808 34405 33999
    33589 33175 32758 32338 31913 31486 31054 30619
    30181 29738 29292 28843 28389 27932 27471 27007
    26539 26066 25590 25111 24627 24140 23649 23153
    22654 22152 21645 21134 20619 20101 19578 19051
    18521 17986 17447 16905 16358 15807 15252 14693
    14129 13562 12990 12415 11835 11251 10662 10070
    9473 8872 8266 7657 7043 6424 5802 5175
    4543 3908 3267 2623 1974 1320 662 0)

now=$(date +%H:%M)
# Raspistill disturbs playing audio stream
if false; then # Disable  commented condition
#if [ ! -f /var/www/html/data/mpc.txt ]; then
  raspistill -n -w 800 -h 480 -o /var/www/html/motion/day/$now.jpg
  find /var/www/html/motion/day/*.jpg -mtime +0 -type f -delete

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
fi # End Photo Brightness 

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

#echo "Omgevingslicht: $lux"
#echo Maximaal gemeten omgevingslicht: $luxmax
#echo Minimaal gemeten omgevingslicht: $luxmin
rangelux=$(awk "BEGIN {printf \"%.2f\", $luxmax - $luxmin}")
#echo Bereik gemeten omgevingslicht: $rangelux
rellux=$(awk "BEGIN {printf \"%.2f\", ($lux - $luxmin) / $rangelux}")

#rellux=$(awk "BEGIN {printf sqrt($rellux)}")

correctionTableIndex=$(awk "BEGIN {printf \"%.0f\", 255 - ($rellux * 255)}")
correctionTableValue=${correction[$correctionTableIndex]}
correctionTableBrightness=$(awk "BEGIN {printf $correctionTableValue / ${correction[0]}}")
#echo CorrectionTable Relatief omgevingslicht: $correctionTableBrightness
rellux=$correctionTableBrightness

#echo Relatief omgevingslicht: $rellux

backlight=$(awk "BEGIN {printf \"%.0f\", 25 + $rellux * 230}")
current=$(cat /sys/class/backlight/rpi_backlight/brightness)
# Smooth backlight adjustment
echo "Brightness from $current to $backlight"
if [ $current -lt $backlight ]; then
  for i in $(seq $current $backlight); do
    echo $i > /sys/class/backlight/rpi_backlight/brightness
  done
else
  for i in $(seq $current -1 $backlight); do
    echo $i > /sys/class/backlight/rpi_backlight/brightness
  done
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
