#!/bin/bash
# Get next alarm on boot

. /var/www/html/data/alarmclock

tomorrow=$(date --date="next day" +%u)
echo ${alarmtimes[$tomorrow]} > /var/www/html/data/nextalarm
