#!/bin/bash
# Scan the given network for Tasmota devices
# Prints the IP address and Hostname of the Tasmota device.

hostnames=( Computertafel-300 Schilderij-650 Canyon-650 \
            Eettafel-300 Zonsondergang-650 Tropen-650 \
            Eekhoorn-650 \
            Kerst-20 \
            Haardlamp-20 TVlamp-20 Livinglamp-24\
            Tandenborstel-10 Apotheek-20 \
            Keukenlamp-8 )

latest=$(curl -s https://api.github.com/repos/arendst/Tasmota/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' | cut -d$'v' -f 2)
echo "Recentste versie: $latest"

vercomp () { # compare versions
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

for hostname in "${hostnames[@]}"
do
  raw=$(wget -qO- http://$hostname/cm?cmnd=Status%202)
    if [ ${#raw} -eq 0 ]; then
      version=$latest
      echo "$hostname offline."
    else
      version=$(echo $raw | python3 -c 'import sys, json; print(json.load(sys.stdin)["StatusFWR"]["Version"])' | cut -d$'(' -f 1)

      vercomp $version $latest
      if [[ $? == 2 ]]; then
        printf '\033[1;32;40m' # Groene tekst
        read -p " Upgrade ${hostname} (${hostname}) van versie $version naar $latest? [Ny]: " answer
        printf '\033[0m' # Standaard kleuren
        answer=${answer:-n}
        if [ $answer == "y" ]; then
          hardware=$(echo $raw | python3 -c 'import sys, json; print(json.load(sys.stdin)["StatusFWR"]["Hardware"])' | cut -d$'(' -f 1)
          if [[ $hardware == "ESP8285"* ]]; then
#            wget -qO- http://${hostname}/cm?cmnd=OtaUrl%20http://ota.tasmota.com/tasmota/release/tasmota.bin
           echo "$hostname updaten als $hardware".
          fi
          if [[ $hardware == "ESP32-D0WDR2-V3"* ]]; then
#            wget -qO- http://${hostname}/cm?cmnd=OtaUrl%20http://ota.tasmota.com/tasmota32/release/tasmota32.bin
           echo "$hostname updaten als $hardware".
          fi
          if [[ $hardware == "ESP32-C3"* ]]; then
#            wget -qO- http://${hostname}/cm?cmnd=OtaUrl%20http://ota.tasmota.com/tasmota32/release/tasmota32c3.bin
           echo "$hostname updaten als $hardware".
          fi
#          wget -qO- http://${hostname}/cm?cmnd=Upgrade%20$latest
          echo
          firefox http://${hostname} &
        fi
      fi
    fi
done

