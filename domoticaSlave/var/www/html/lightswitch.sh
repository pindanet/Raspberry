. /var/www/html/data/thermostat
lightstatus=$(raspi-gpio get $diningLight)
if [[ $1 == "toggle" ]]; then
  if [[ $lightstatus == *"level=1"* ]]; then
    raspi-gpio set $diningLight op dl
    echo "Switch Light On"
  else
    raspi-gpio set $diningLight op dh
    echo "Switch Light off"
  fi
else
  raspi-gpio set $diningLight op dh
  echo "Switch Light off"
fi
