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
    status["$name"]=$(wget -qO- http://$url/cm?cmnd=$cmnd%20Off)
    echo "$(date),$power,$watt" >> /var/www/html/data/$name.$logExt
  elif [ "${status["$name"]}" != '{"'$cmnd'":"off"}' ] && [ "${status["$name"]}" != '{"'$cmnd'":"on"}' ]; then
    status["$name"]=$(wget -qO- http://$url/cm?cmnd=$cmnd)
    echo "$(date): Communication error. Tasmota $name" >> /tmp/PindaNetDebug.txt
  fi
}
