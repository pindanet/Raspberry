#!/bin/bash

# ToDo
# Reed Sensor Interrupt
# gpio -g wfi 26 rising

buzzer_gpio="23"

#Kills the sub process quietly
function killsub() 
{
  kill -9 ${1} 2>/dev/null
  wait ${1} 2>/dev/null
}
buzzer() { # Activate Buzzer
  gpio -g mode $buzzer_gpio out
  while [ 1 ]; do
    gpio -g write $buzzer_gpio 1
    sleep 1
    gpio -g write $buzzer_gpio 0
    sleep 1
  done
}

buzzer &
buzzer_pid=$!

#Add a trap incase of unexpected interruptions
trap 'killsub ${buzzer_pid}; exit' INT TERM EXIT

sleep 4

#Kill buzzer after finished
killsub ${buzzer_pid}

#Reset trap
trap - INT TERM EXIT

# Buzzer off
gpio -g write $buzzer_gpio 0
