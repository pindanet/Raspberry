#!/bin/bash

# Controleer of er twee opties werden meegegeven
if [[ -z $1 || -z $2 ]]; then
  echo 'Gebruik: bash sdcformat.sh /dev/mmcblk0 "SNT Stick"'
  exit
fi

# Controleer of je root rechten hebt
if [[ ! $(whoami) =~ "root" ]]; then
  echo ""
  echo "************************************"
  echo "*** Uitvoeren als root gebruiker ***"
  echo "************************************"
  echo ""
  exit
fi

# Controleer of het apparaat een opslagmedia-apparaat is
if [[ ! -e $1 || ! $(file $1) =~ "block special" ]]; then
  echo "Fout: Geen opslagmedia of apparaat bestaat niet"
  exit
fi

DEVICE=$(echo "$1" | cut -d'/' -f3)
# Formatteer enkel verwisselbare apparaten
#if [ $(cat /sys/block/$DEVICE/removable) == "1" ] ; then 
    # Bereken de opslagruimte van de USB Stick
    DISK_SIZE=$(parted $1 print | head -2 | tail -1 | awk '{ print $3; }')
    
    echo "Aanmaken partitietabel op $1"
    parted $1 mklabel msdos
    sync

    echo "Aanmaken partitie op $1"
    parted $1 mkpart primary fat32 0% 100%
    sync

    echo "Partitie formatteren met FAT32 en naam geven"
    mkfs.vfat -n "$2" $1p1
    # Gebruik enkel de volgende opdracht om zonder partities de volledige USB Stick opslagruimte te formatteren
    # sudo mkfs.vfat -I -n "SNT Stick" /dev/sdb
    sync

    echo "Overzicht:"
    parted $1 print
#fi
