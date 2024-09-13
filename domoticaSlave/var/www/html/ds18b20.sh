#!/bin/bash
# DS18B20
# GPIO 17 (11) (switchable 3,3 V) naar Vdd (Rood)
# GPIO4 (7) naar Data (Geel) naar 4k7 naar 3,3 V (Rood)
# GND (9) naar GND (Zwart)

powergpio=17

if ! test -d /sys/bus/w1/devices/28-*; then
  # Reset DS18B20
  # Power off
  pinctrl set $powergpio op dl
  sleep 3
  # Power on
  pinctrl set $powergpio op dh
  sleep 5
fi
cat /sys/bus/w1/devices/28-*/temperature
