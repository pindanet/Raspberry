#!/bin/bash
# Check WiFi connection
if ! ping -c 1 mymodem.home; then
  echo "$(date) Restart Network" >> /var/www/html/data/debug.txt
#  systemctl restart NetworkManager.service
  systemctl reboot
  sleep 10
fi
# Check Avahi conflict
#if [ $(avahi-resolve -a $(ip -4 addr show wlan0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}') | cut -f 2) != ${HOSTNAME}.local ]; then
#  echo Restart avahi
#  systemctl restart avahi-daemon.socket
#fi
