#!/bin/bash
# Scan the given network for Tasmota devices
# Prints the IP address and Hostname of the Tasmota device.
for ip in {1..254}; do
  # Stuur een door de gezochte apparaten herkend bericht.
  status=$(wget -qO- http://$1.$ip/cm?cmnd=status%205)
  # Filter uit het antwoord de hostname (enkel bruikbaar voor Tasmota apparaten).
  hostname=$(echo $status | grep -o '"Hostname":"[^"]*' | grep -o '[^"]*$')
  # Indien het apparaat een zinnig antwoord gaf, drukken we het IP adres en de hostname af.
  if [ "$?" -eq 0 ]; then
    echo $1.$ip $hostname
  fi
done
