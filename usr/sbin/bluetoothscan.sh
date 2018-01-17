#!/bin/bash
#(sleep 1; echo "scan on"; sleep 59; echo "exit") | bluetoothctl > bluetoothscan.txt
grep -riF "[NEW]" bluetoothscan.txt
