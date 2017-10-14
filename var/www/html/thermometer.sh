#!/bin/bash
echo -e "Content-type: text/html\n"

#!/bin/bash
bme=`python /var/www/html/bme280.py`

temp=${bme#*Temperature :}
temp=${temp%C*}

pres=${bme#*Pressure :}
pres=${pres%hPa*}

humi=${bme#*Humidity :}
humi=${humi% %*}

LANG=C printf '<span id="temp">%.*f °C</span><br><span id="date">Luchtdruk: %.*f hPa Vochtigheid: %.*f %%</span>' 1 $temp 0 $pres 0 $humi
