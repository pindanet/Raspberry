declare -A status=()   
function tasmota () { # power name
  power=$1
  name=$2
  url=${IPs["$name"]}
  watt=${Watts["$name"]}
#  echo "Power: $power, Name: $name, Url: $url, Watt: $watt"
  if [ -z ${status["$name"]} ]; then # initialize
    status["$name"]=$(wget -qO- http://$url/cm?cmnd=Power)
    two=$(echo ${status["$name"]} | awk -F"\"" '{print $4}')
    twolower=${two,,}
    if [ $twolower == "on" ] || [ $twolower == "off" ]; then
      echo "$(date),$twolower,$watt" >> /var/www/html/data/$name.$logExt
    fi
  fi
  if [ $power == "on" ] && [ "${status["$name"]}" == '{"POWER":"OFF"}' ]; then
    status["$name"]=$(wget -qO- http://$url/cm?cmnd=Power%20On)
    echo "$(date),$power,$watt" >> /var/www/html/data/$name.$logExt
  elif [ $power == "off" ] && [ "${status["$name"]}" == '{"POWER":"ON"}' ]; then
    status["$name"]=$(wget -qO- http://$url/cm?cmnd=Power%20Off)
    echo "$(date),$power,$watt" >> /var/www/html/data/$name.$logExt
  elif [ "${status["$name"]}" != '{"POWER":"OFF"}' ] && [ "${status["$name"]}" != '{"POWER":"ON"}' ]; then
    status["$name"]=$(wget -qO- http://$url/cm?cmnd=Power)
    echo "$(date): Communication error. Tasmota $name" >> /tmp/PindaNetDebug.txt
  fi
}
