#!/bin/bash
# Scan the given network for Tasmota devices
# Prints the IP address and Hostname of the Tasmota device.
untilIP=50
if [ -z "$1" ]; then
  set -- $(ip -o -f inet addr show | awk '/scope global/ {print $4}' | sed 's/\(.*\)\..*/\1/')
fi
if [[ ! $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Networkrange not accepted."
  echo "Use bash Tasmota\ Network\ Scanner.sh 123.123.123"
  exit
fi
#for ip in {1..50}; do
for (( ip=2; ip<=$untilIP; ip++)); do
  # Send Tasmota http command to device
  status=$(wget -qO- http://$1.$ip/cm?cmnd=status%205)
  # Extract the Hostname from the reply.
  hostname=$(echo $status | grep -o '"Hostname":"[^"]*' | grep -o '[^"]*$')
  # We found a Tasmota device if a Hostname could be extracted.
  if [ "$?" -eq 0 ]; then
    echo $1.$ip $hostname
  fi
done
