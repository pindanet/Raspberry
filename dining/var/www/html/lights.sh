#!/bin/bash
# Lights

# https://www.baeldung.com/linux/jq-command-json
# https://www.baeldung.com/linux/jq-passing-bash-variables
jsonConf=$(cat /var/www/html/data/conf.php.json)
room=$(echo $jsonConf | jq --arg jq_hostname_var $HOSTNAME -r '.rooms.[] | select(.Hostname==$jq_hostname_var)')
lights=$(echo $room | jq -r '.lights')

lightsStatus=()
lightsHostname=()
lightsChannel=()

while read -r json_record; do
  channel=$(echo $lights | jq -r ".$json_record.Channel")
  lightsChannel+=("$channel")
  lightsHostname+=($(echo $lights | jq -r ".$json_record.Hostname"))
  lightsStatus+=("undefined")
done < <(echo $lights | jq -r '. | keys[]')

echo "${lightsHostname[@]}"
echo "${lightsStatus[@]}"
echo "${lightsChannel[@]}"
