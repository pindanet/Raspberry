#!/bin/bash
if [ -f "/tmp/thermostatManual" ]; then
  mv /tmp/thermostatManual /root/thermostatManual
fi
sudo dpkg --configure -a
apt-get clean
apt-get update
apt-get upgrade -y
shutdown -r now
