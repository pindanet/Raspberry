#!/bin/bash
# Gebruikte BCM poorten
Relais=(14 15 18 23 24 25 8 7)

gebruik () {
  echo "Gebruik: relais.sh relais/aantal mode "
  echo "                   0-7           in/uit/loop"
  echo "Voorbeeld: ./relais.sh 0 uit"
  exit
}

inschakelen () {
  gpio -g mode ${Relais[$1]} out
  gpio -g write ${Relais[$1]} 0
}

uitschakelen () { 
  gpio -g mode ${Relais[$1]} out
  gpio -g write ${Relais[$1]} 1
}

loop () {
  for aantal in $(seq $1); do
    for i in {0..7}; do
      inschakelen $i
      sleep 1
      uitschakelen $i
      sleep 1
    done
  done
}

if [[ $# -ne 2 ]]; then
  gebruik
fi

if [[ $1 -lt 0 ]]; then
  gebruik
elif [[ $1 -gt 7 ]]; then
  gebruik
fi

if [ $2 == "in" ]; then
  inschakelen $1
elif [ $2 == "uit" ]; then
  uitschakelen $1
elif [ $2 == "loop" ]; then
  loop $1
else
  gebruik
fi
