#!/bin/bash
echo -e "Content-disposition: attachment; filename=thermostat.json\n"
json=`cat /var/www/html/data/thermostat.json | openssl base64 -d`
echo $json
