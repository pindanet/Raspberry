#!/bin/bash
echo -e "Content-type: text/html\n"
bme=`python /var/www/html/bme280.py`

temp=${bme#*Temperature :}
temp=${temp%C*}

pres=${bme#*Pressure :}
pres=${pres%hPa*}

humi=${bme#*Humidity :}
humi=${humi% %*}

LANG=C printf 'Temperatuur: %.*f °C, Luchtdruk: %.*f hPa, Vochtigheid: %.*f %%' 1 $temp 0 $pres 0 $humi
