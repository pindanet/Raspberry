declare -A -l status=()
function tasmota () { # power name
  power=$1
  name=$2
  url=${IPs["$name"]}
  watt=${Watts["$name"]}
  declare -l cmnd=${Cmnds["$name"]}
#  echo "Power: $power, Name: $name, Url: $url, Watt: $watt, Cmnd: $cmnd"
  if [ -z ${status["$name"]} ]; then # initialize
    status["$name"]=$(wget -qO- http://$url/cm?cmnd=$cmnd)
    two=$(echo ${status["$name"]} | awk -F"\"" '{print $4}')
    if [ $two == "on" ] || [ $two == "off" ]; then
      echo "$(date),$twolower,$watt" >> /var/www/html/data/$name.$logExt
    fi
  fi
  if [ $power == "on" ] && [ "${status["$name"]}" == '{"'$cmnd'":"off"}' ]; then
    status["$name"]=$(wget -qO- http://$url/cm?cmnd=$cmnd%20On)
    echo "$(date),$power,$watt" >> /var/www/html/data/$name.$logExt
  elif [ $power == "off" ] && [ "${status["$name"]}" == '{"'$cmnd'":"on"}' ]; then
    if [ $name == "SwitchBacklight" ]; then
      # dim to max and back to normal
      for i in {4..255}
      do
        color="%20$(printf '%02x%02x%02x\n' $i $i $i)"
        allcolor=""
        for ii in {0..27}
        do
          allcolor=$allcolor$color
        done
#  echo http://192.168.129.41/cm?cmnd=Led$allcolor
        wget -qO- http://192.168.129.41/cm?cmnd=Led$allcolor
      done
      for i in {255..4}
      do
        color="%20$(printf '%02x%02x%02x\n' $i $((i-1)) $((i-4)))"
        allcolor=""
        for ii in {0..27}
        do
          allcolor=$allcolor$color
        done
#  echo http://192.168.129.41/cm?cmnd=Led$allcolor
        wget -qO- http://192.168.129.41/cm?cmnd=Led$allcolor
      done
    fi
    status["$name"]=$(wget -qO- http://$url/cm?cmnd=$cmnd%20Off)
    echo "$(date),$power,$watt" >> /var/www/html/data/$name.$logExt
  elif [ "${status["$name"]}" != '{"'$cmnd'":"off"}' ] && [ "${status["$name"]}" != '{"'$cmnd'":"on"}' ]; then
    status["$name"]=$(wget -qO- http://$url/cm?cmnd=$cmnd)
    echo "$(date): Communication error. Tasmota $name" >> /tmp/PindaNetDebug.txt
  fi
}
