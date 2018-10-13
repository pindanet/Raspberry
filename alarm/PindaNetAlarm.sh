#!/bin/bash

# ToDo
# awake/sleep

buzzer_gpio="23"
reed_gpio="26"
# Array bluetooth MAC addresses, scan with: hcitool scan
bluetooth=(94:0E:6B:F8:97:31 6C:24:83:B8:98:7B)

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

gpio -g mode $reed_gpio up
while [ 1 ]; do
  # Wait for reed sensor interrupt
  gpio -g wfi $reed_gpio rising
  # check nearby bluetooth devices while reedsensor stabelizes (remove noise)
  /usr/sbin/PindaNetbluetoothscan.sh
#  sleep 1 # remove noise
  if [ $(cat /var/PindaNet/state) == "sleep" ]; then # sleep/awake
    reedsensor=$(gpio -g read $reed_gpio)
    if [ $reedsensor == "1" ]; then # open
      # Activate buzzer
      buzzer &
      buzzer_pid=$!

      #Add a trap incase of unexpected interruptions
      trap 'killsub ${buzzer_pid}; exit' INT TERM EXIT

      sleep 2

      #Kill buzzer after finished
      killsub ${buzzer_pid}

      #Reset trap
      trap - INT TERM EXIT

      # Buzzer off
      gpio -g write $buzzer_gpio 0
    fi
  fi
done
