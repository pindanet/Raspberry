#!/bin/bash
# Automatisch expansie uitschakelen en manueel expanderen naar 5 GB

# Controleer of het script door de systeembeheerder werd gestart
if [[ ! $(whoami) =~ "root" ]]; then
  echo ""
  echo "************************************"
  echo "*** Root moet dit script starten ***"
  echo "************************************"
  echo ""
  exit
fi
# Controleer of er een optie werd meegegeven
if [[ -z $1 ]]; then
  echo "Gebruik: ./raspbian-noresize.sh /dev/mmcblk0"
  exit
fi
# Controleer of de optie een blok apparaat is
if [[ ! -e $1 || ! $(file $1) =~ "block special" ]]; then
  echo "Fout : Geen blok apparaat, of onbestaand apparaat"
  exit
fi
# Koppel de SD kaart aan een map
mount $1p1 /mnt/
# Maak indien nodig een reservekopie van de originele opstart opdrachten
if [ -f /mnt/cmdline.txt.ori ]; then
  cp /mnt/cmdline.txt.ori /mnt/cmdline.txt
else # Herstel de originele opstartopdrachten
  cp /mnt/cmdline.txt /mnt/cmdline.txt.ori
fi
# Verwijder uit de originele opstart opdrachten het automatisch expanderen van de opslagruimte
sed -i 's/ init=\/usr\/lib\/raspi-config\/init_resize.sh//' /mnt/cmdline.txt
# Geef de aangepaste opstart opdrachten weer
cat /mnt/cmdline.txt
# activeer eenmalig SSH toegang
touch /mnt/ssh
# Koppel de SD kaart los van de /mnt/ map
umount /mnt/

# Bepaal het startpunt van de tweede partitie
PART_START=$(parted $1 -ms unit s p | grep "^2" | cut -f 2 -d: | sed 's/[^0-9]//g')
echo $PART_START
[ "$PART_START" ] || return 1
  # Breek het script af bij een foumelding
# Bepaal het eindpunt van de tweede partitie
PART_END=$(parted $1 -ms unit s p | grep "^2" | cut -f 3 -d: | sed 's/[^0-9]//g')
# Bereken het eindpunt van een 1 GB grotere partitie
PART_END=$((PART_END + 2097152))
echo $PART_END
# Verwijder de tweede partitie en maak deze opnieuw aan, maar nu 1 GB groter
fdisk $1 <<EOF
p
d
$PART_NUM
n
p
2
$PART_START
$PART_END
p
w
EOF
# Controleer de tweede partitie op eventuele fouten en indien moegelijk herstel de fouten
e2fsck -f $1p2
# Maak de extra 1 GB schijfruimte beschikbaar
resize2fs $1p2
