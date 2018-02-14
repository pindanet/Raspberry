#!/bin/bash

LOCALE="nl_BE.UTF-8"
NEW_HOSTNAME="rpiwall"

# Change locale
if ! LOCALE_LINE="$(grep "^$LOCALE " /usr/share/i18n/SUPPORTED)"; then
  printf '\033[1;31;40mLOCALE %s not supported.\n\033[0m' $LOCALE # Rode letters op zwarte achtergrond
  exit
fi
ENCODING="$(echo $LOCALE_LINE | cut -f2 -d " ")"
echo "$LOCALE $ENCODING" | sudo tee /etc/locale.gen
sudo sed -i "s/^\s*LANG=\S*/LANG=$LOCALE/" /etc/default/locale

sudo dpkg-reconfigure -f noninteractive locales

exit

# Change timezone
sudo dpkg-reconfigure tzdata
# Change WiFi country
IFS="/"
value=$(cat /usr/share/zoneinfo/iso3166.tab | tail -n +26 | tr '\t' '/' | tr '\n' '/')
COUNTRY=$(whiptail --menu "Select the country in which the Pi is to be used" 20 60 10 ${value} 3>&1 1>&2 2>&3)
if [ -e /etc/wpa_supplicant/wpa_supplicant.conf ]; then
  if sudo grep -q "^country=" /etc/wpa_supplicant/wpa_supplicant.conf ; then
    sudo sed -i --follow-symlinks "s/^country=.*/country=$COUNTRY/g" /etc/wpa_supplicant/wpa_supplicant.conf
  else
    sudo sed -i --follow-symlinks "1i country=$COUNTRY" /etc/wpa_supplicant/wpa_supplicant.conf
  fi
else
  sudo echo "country=$COUNTRY" > /etc/wpa_supplicant/wpa_supplicant.conf
fi
# Change hostname
CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
sudo echo $NEW_HOSTNAME > /etc/hostname
sudo sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
# Change password
passwd

# enable ssh
sudo update-rc.d ssh enable
sudo invoke-rc.d ssh start

printf '\033[1;37;40mOn the main computer: ssh-copy-id -i ~/.ssh/id_rsa.pub pi@rpiwall.local\n\033[0m' # Witte letters op zwarte achtergrond
printf '\033[1;32;40mPress key to continue.\033[0m' # Groene letters op zwarte achtergrond
read Keypress
