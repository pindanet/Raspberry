#!/bin/bash
temp=$(python /home/*/ds18b20.py)
LC_ALL=C printf "%.1f °C" "$temp" > /home/*/temp.txt
