#!/bin/bash
# ToDo
# Activate Serial Hardware
# replace /home/dany by search default user

# Compensate temperature sensor
#tempOffset=0.5
tempfact=0.91

function broadcast() {
  current="$(cat /var/www/html/data/thermostat)"
#  current="${current}
#heatingLiving=\"off\""
  new=$(echo "$current" | sed "s/$1=.*/$1=\"$2\"/")
  if [ "$current" != "$new" ]; then
    echo "Broadcast new situation $1 $2"
  fi
}

function thermostatManualReset () {
  if [ -f /var/www/html/data/thermostatManualkitchen ]; then
    rm /var/www/html/data/thermostatManualkitchen
  fi
  if [ -f /var/www/html/data/thermostatManualliving ]; then
    rm /var/www/html/data/thermostatManualliving
  fi
}
#function tasmotaRF () {
#  if [[ "$1" == tasmota* ]]; then
#    tasmota $1 $2
#  else
#    sendRF $1 $2
#  fi
#}
function sendRF () {
  tempfile="/tmp/${1:0:6}${1:8:10}${1:22:2}"
  if [ ! -f "$tempfile" ]; then # initialize
    if [ "$2" == "off" ]; then
      echo 'on' > "$tempfile"
    else
      echo 'off' > "$tempfile"
    fi
  fi
#echo $tempfile $(cat "$tempfile") $2
  if [ $(cat "$tempfile") == "off" ] && [ "$2" == "on" ]; then
    if [ ! -f /var/www/html/data/mpc.txt ]; then # disable motion photo's
      touch /var/www/html/data/mpc.txt
    fi
    python /var/www/html/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "$1"
    echo 'on' > "$tempfile"
    echo "$(date): Heating $1 $2" >> /tmp/PindaNetDebug.txt
  elif [ $(cat "$tempfile") == "on" ] && [ "$2" == "off" ]; then
    if [ ! -f /var/www/html/data/mpc.txt ]; then # disable motion photo's
      touch /var/www/html/data/mpc.txt
    fi
    python /var/www/html/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "$1"
    echo 'off' > "$tempfile"
    echo "$(date): Heating $1 $2" >> /tmp/PindaNetDebug.txt
  fi
  if [ -f /var/www/html/data/mpc.txt ]; then
    if [ ! -s /var/www/html/data/mpc.txt ]; then
      rm /var/www/html/data/mpc.txt
    fi
  fi
}
function tasmota () {
  if [ ! -f /tmp/$1 ]; then # initialize
    echo $(wget -qO- http://$1/cm?cmnd=Power) > /tmp/$1
    two=$(wget -qO- http://$1/cm?cmnd=Power | awk -F"\"" '{print $4}')
    twolower=${two,,}
    if [ $twolower == "on" ] || [ $twolower == "off" ]; then
      echo "$(date -u +%s),$twolower" >> /var/www/html/data/$1.log
    fi
  fi
  if [ $2 == "on" ] && [ "$(cat /tmp/$1)" == '{"POWER":"OFF"}' ]; then
    dummy=$(wget -qO- http://$1/cm?cmnd=Power%20On)
    echo $(wget -qO- http://$1/cm?cmnd=Power) > /tmp/$1
    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
  elif [ $2 == "off" ] && [ "$(cat /tmp/$1)" == '{"POWER":"ON"}' ]; then
    dummy=$(wget -qO- http://$1/cm?cmnd=Power%20Off)
    echo $(wget -qO- http://$1/cm?cmnd=Power) > /tmp/$1
    echo "$(date -u +%s),$2" >> /var/www/html/data/$1.log
  elif [ "$(cat /tmp/$1)" != '{"POWER":"OFF"}' ] && [ "$(cat /tmp/$1)" != '{"POWER":"ON"}' ]; then
    echo $(wget -qO- http://$1/cm?cmnd=Power) > /tmp/$1
    echo "$(date): Communication error. Heating $1" >> /tmp/PindaNetDebug.txt
  fi
}
function thermostatOff {
  for switch in "${!heater[@]}"
  do
#   if [[ "$switch" == *Off ]]; then
     tasmota ${heater[$switch]} "off"
#     if [[ "${heater[$switch]}" == tasmota* ]]; then
#       tasmota ${heater[$switch]}
#     else
#       sendRF ${heater[$switch]}
#     fi
#   fi
  done
}

function thermostat {
#  # Received new configuration file
#  if [ -f /tmp/thermostat ]; then
#    mv -f /tmp/thermostat /var/www/html/data/thermostat
#  fi
#  . /var/www/html/data/thermostat
#
  temp=$(tail -1 $PresHumiTempfile)
  temp=${temp%% C*}
  # remove leading whitespace characters
  temp="${temp#"${temp%%[![:space:]]*}"}"

  IFS=$'\n' thermostatroom=($(sort <<<"${thermostatroomdefault[*]}"))
  unset IFS

#  printf "%s\n" "${thermostatroom[@]}"
  echo $now

  heatingRoom="off"
# Default times for heating
  for thermostatitem in "${thermostatroom[@]}"; do
    daytime=(${thermostatitem})
    if [[ "${daytime[0]}" < "$now" ]] && [[ "${daytime[1]}" > "$now" ]]; then
      heatingRoom="on"
      break
    fi
  done
# Exceptions with recurrent dates and times
  for thermostatitem in "${thermostatroomevent[@]}"; do
    daytime=(${thermostatitem})
    recevent=$(date -u --date "${daytime[0]}" +%s)
    timebetween=$((${daytime[1]} * 86400))
    nowSec=$(date -u +%s)
    today=$((nowSec - (nowSec % 86400)))
    if [[ "$timebetween" > "0" ]]; then # repeating event
      while  [ $recevent -lt $today ]; do
        recevent=$((recevent + timebetween))
      done
    fi
    if [ $today == $recevent ]; then
      echo "Event in $room on $(date -u --date @$recevent)"
      if [[ "${daytime[2]}" < "$now" ]] && [[ "${daytime[3]}" > "$now" ]]; then
        echo "Between ${daytime[2]} and ${daytime[3]}: heating: ${daytime[4]}"
        heatingRoom=${daytime[4]}
        break
      fi
    fi
  done

  tempWanted=$tempComfort

#  if [ -f /var/www/html/data/thermostatManual ]; then
#    read roomtemp < /var/www/html/data/thermostatManual
  roomtemp=$(cat /tmp/thermostatManual)
  if [ $? -gt 0 ]; then
    echo Auto
  else
    if [ "$roomtemp" == "off" ]; then
      echo "Heating Manual Off"
      heatingRoom="off"
    else
#      tempWanted=$(awk "BEGIN {print ($roomtemp + $tempOffset)}")
      tempWanted=$roomtemp
      echo "Manual temp $room: $tempWanted °C"
      heatingRoom="on"
    fi
  fi
  if [ "$heatingRoom" == "off" ]; then
#    tempWanted=$(awk "BEGIN {print ($tempComfort - 5)}")
    echo "Heating: off, $tempOff °C"
    tempWanted=$tempOff
  fi
  total=${#heaterRoom[@]}
  for (( i=0; i<$total; i++ )); do
    tempToggle=$(awk "BEGIN {print ($tempWanted - $hysteresis - $hysteresis * (2 * $i))}")
    echo "${heaterRoom[$i]} switch on at $tempToggle °C."
    if (( $(awk "BEGIN {print ($temp < $tempToggle)}") )); then
      echo "${heaterRoom[$i]} on at $temp °C."
      tasmota ${heater[${heaterRoom[$i]}]} on
    fi
    tempToggle=$(awk "BEGIN {print ($tempWanted + $hysteresis - $hysteresis * (2 * $i))}")
    echo "${heaterRoom[$i]} switch off at $tempToggle °C."
    if (( $(awk "BEGIN {print ($temp > $tempToggle)}") )); then
      echo "${heaterRoom[$i]} off at $temp °C."
      tasmota ${heater[${heaterRoom[$i]}]} off
    fi
  done
}

_pir_pin=4 # BCM4
 
# https://raspberrypi-aa.github.io/session2/bash.html
# Clean up on ^C and TERM, use 'gpio unexportall' to flush everything manually.
#trap "gpio unexport $_pir_pin" INT TERM
if [ -d "/sys/class/gpio/gpio$_pir_pin" ]; then
  echo $_pir_pin > /sys/class/gpio/unexport
fi
fotomap="/var/www/html/motion/fotos"
if [ ! -d "$fotomap" ]; then
  mkdir -p "$fotomap"
fi
 
#   Exports pin to userspace
echo $_pir_pin > /sys/class/gpio/export
# Sets pin as an input
echo "in" > /sys/class/gpio/gpio$_pir_pin/direction
 
# Let PIR settle to ambient IR to avoid false positives? 
# Uncomment line below.
#sleep 30

while true
do
  starttime=$(date +"%s") # complete cycle: 1 minute

  room="Living"
#  timerfile="/var/www/html/data/timer"
#  thermostatlivingfile="/var/www/html/data/thermostatliving"
  PresHumiTempfile="/var/www/html/data/PresHumiTemp"
  stderrLogfile="/var/www/html/stderr.log"

  # Received new configuration file
  if [ -f /tmp/thermostat ]; then
    mv -f /tmp/thermostat /var/www/html/data/thermostat
  fi
  . /var/www/html/data/thermostat

  thermostatroomdefault=("${thermostatlivingdefault[@]}")
  thermostatroomevent=("${thermostatlivingevent[@]}")
  tempOffset=$livingTempOffset
  tempComfort=$(awk "BEGIN {print ($tempComfort + $tempOffset)}")

  declare -A heater
  unset heaterRoom
  declare -a heaterRoom
  for heateritem in "${heaters[@]}"; do
    line=(${heateritem})
    heater[${line[0]}]=${line[1]}
    if [ ${heateritem:0:6} == "$room" ]; then
      heaterRoom+=(${line[0]})
    fi
  done
#  printf '%s\n' "${heaterRoom[@]}"

  if [ -f /var/www/html/data/thermostatReset ]; then
    # copy to DomoticaSlave
#    sudo -u dany scp /var/www/html/data/thermostatReset pindakeuken:/tmp/
#    sudo -u dany scp /var/www/html/data/thermostat pindakeuken:/tmp/

    echo "Resetting thermostat"
    for switch in "${!heater[@]}"
    do
      heateritem=${heater[$switch]}
      if [[ "$heateritem" == tasmota* ]]; then
          tempfile="/tmp/${heateritem:0:19}"
      else
          tempfile="/tmp/${heateritem:0:6}${heateritem:8:10}${heateritem:22:2}"
      fi
      if [ -f $tempfile ]; then
        rm $tempfile
      fi
    done
#    thermostatManualReset
    rm /var/www/html/data/thermostatReset
  fi
  # Collect sensordata
  # BME280 I2C Temperature and Pressure Sensor
  # 3v3 - Vin
  # Gnd - Gnd
  # BCM 3 (SCL) - SCK (White)
  # BCM 2 (SDA) - SDI (Brown)
  # read pressure, humididy and temperature from sensor
  error_file=$(mktemp)
  PresHumiTempVar=$(read_bme280 --i2c-address 0x77 2>$error_file)
  if [ "$?" -ne 0 ]; then # skip faulty reading
      echo "___________________________" >> $stderrLogfile
      echo "$(date)" >> $stderrLogfile
      echo "$(< $error_file)" >> $stderrLogfile
    else
      temp=${PresHumiTempVar##*$'\n'}
      temp=${temp%% C*}
      temp="${temp#"${temp%%[![:space:]]*}"}"
      newtemp=$(awk "BEGIN {printf \"%0.2f\", ($temp * $tempfact)}")
      PresHumiTempVar=${PresHumiTempVar/$temp/$newtemp}
      echo "$PresHumiTempVar" > $PresHumiTempfile
  fi
  rm $error_file

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
  correctionTableIndex=$(awk "BEGIN {printf \"%.0f\", 255 - ($rellux * 255)}")
  correctionTableValue=${correction[$correctionTableIndex]}
  correctionTableBrightness=$(awk "BEGIN {printf $correctionTableValue / ${correction[0]}}")
  #echo CorrectionTable Relatief omgevingslicht: $correctionTableBrightness
  rellux=$correctionTableBrightness

  #echo Relatief omgevingslicht: $rellux

  backlight=$(awk "BEGIN {printf \"%.0f\", 15 + $rellux * 110}") # 25 230
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

  weekday=$(date +%w)
  now=$(date +%H:%M)

  thermostat

#  broadcast "heatingLiving" $heatingLiving

  state="sleep"
  if [ $heatingRoom == "on" ] || ( [[ $now < $lightevening ]] && [[ $now > $lightmorning ]] ); then
    state="awake"
  fi

  echo $state
  if [ $state == "awake" ]; then
    echo 0 > /sys/class/backlight/rpi_backlight/bl_power
  #  echo 255 > /sys/class/leds/led0/brightness
  #  echo 255 > /sys/class/leds/led1/brightness
  else
    # deactivate backlight touchscreen
    echo 1 > /sys/class/backlight/rpi_backlight/bl_power
    # disable status led's
    echo 0 > /sys/class/leds/led0/brightness
    echo 0 > /sys/class/leds/led1/brightness
    # Stop Musisc Player
    if [ -f /var/www/html/data/mpc.txt ]; then
      mpc stop
      rm /var/www/html/data/mpc.txt
    fi
    if (echo > /dev/tcp/rpiwall/22) >/dev/null 2>&1; then
      # shutdown RPIWall
      wget --post-data="command=halt" --quiet http://rpiwall/remote.php
      sleep 30
      # Power off RPIWall
      dummy=$(wget -qO- http://tasmota_4fd8ee-6382/cm?cmnd=Power%20Off)
#      python /var/www/html/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "0B 11 00 00 01 25 4A AE 0D 00 00 80"
    fi
#    thermostatOff
#    thermostatManualReset
  fi

# PIR detector for 1 minute
#  starttime=$(date +"%s") # moved to start while true loop
  while [ $(($(date +"%s") - starttime)) -lt 56 ]; do
    _ret=$( cat /sys/class/gpio/gpio$_pir_pin/value )
    if [ $_ret -eq 1 ]; then
      echo "[!] PIR is tripped, Smile ..."

      find "$fotomap/" -mindepth 1 -maxdepth 1 -mtime +0 -exec rm {} \;
      DATE=$(date +"%Y %m %d %H:%M:%S") # 2020 05 05 07:05:03.jpg
      raspistill --width 800 --height 480 --nopreview --rotation 90 -o "$fotomap/$DATE.jpg"
    elif [ $_ret -eq 0 ]; then
#       echo "Geen beweging"
       sleep 3 # time to reset PIR
    fi
#    echo $(($(date +"%s") - starttime))
  done
done
