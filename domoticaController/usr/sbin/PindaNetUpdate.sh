#!/bin/bash
if [ ! -f "/tmp/thermostatManual" ]; then
  apt-get clean
  apt-get update
  apt-get upgrade -y
  shutdown -r now
fi
