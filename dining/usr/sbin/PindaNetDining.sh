#!/bin/bash
temp=$(python /home/dany/ds18b20.py)
LC_ALL=C printf "%.1f °C" "$temp" > /home/dany/temp.txt
