#!/bin/bash

LOCALE="nl_BE.UTF-8"
TIMEZONE="Europe/Brussels"
COUNTRY="BE"
NEW_HOSTNAME="snt-guest"

# Change locale
if ! LOCALE_LINE="$(grep "^$LOCALE " /usr/share/i18n/SUPPORTED)"; then
  printf '\033[1;31;40mLOCALE %s not supported.\n\033[0m' $LOCALE # Rode letters op zwarte achtergrond
  exit
fi
ENCODING="$(echo $LOCALE_LINE | cut -f2 -d " ")"
echo "$LOCALE $ENCODING" | sudo tee /etc/locale.gen
sudo sed -i "s/^\s*LANG=\S*/LANG=$LOCALE/" /etc/default/locale

sudo dpkg-reconfigure -f noninteractive locales

# Change timezone
if [ ! -f "/usr/share/zoneinfo/$TIMEZONE" ]; then
  printf '\033[1;31;40mTIMEZONE %s not supported.\n\033[0m' $TIMEZONE # Rode letters op zwarte achtergrond
  exit
fi
sudo rm /etc/localtime
echo "$TIMEZONE" | sudo tee /etc/timezone
sudo dpkg-reconfigure -f noninteractive tzdata

# Change WiFi country
if [ -e /etc/wpa_supplicant/wpa_supplicant.conf ]; then
  if sudo grep -q "^country=" /etc/wpa_supplicant/wpa_supplicant.conf ; then
    sudo sed -i --follow-symlinks "s/^country=.*/country=$COUNTRY/g" /etc/wpa_supplicant/wpa_supplicant.conf
  else
    sudo sed -i --follow-symlinks "1i country=$COUNTRY" /etc/wpa_supplicant/wpa_supplicant.conf
  fi
else
  echo "country=$COUNTRY" | sudo tee /etc/wpa_supplicant/wpa_supplicant.conf
fi

# Change hostname
CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
echo $NEW_HOSTNAME | sudo tee /etc/hostname
sudo sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts

# Change password
passwd

# enable ssh
sudo update-rc.d ssh enable
sudo invoke-rc.d ssh start

# Upgrade
sudo apt-get update
sudo apt-get dist-upgrade -y
sudo apt-get autoremove -y

# SoftAP
sudo sed -i '/^#.*net\.ipv4\.ip_forward=/s/^#//' /etc/sysctl.conf
sudo sed -i '/^#.*net\.ipv6\.conf\.all\.forwarding=/s/^#//' /etc/sysctl.conf

# Webserver
sudo apt-get install apache2 php libapache2-mod-php -y
sudo systemctl restart apache2.service

sudo wget -O /var/www/html/index.html https://raw.githubusercontent.com/pindanet/Raspberry/master/softap/index.html
sudo wget -O /var/www/html/pinda.png https://raw.githubusercontent.com/pindanet/Raspberry/master/softap/pinda.png

# Restart Raspberry Pi
sudo shutdown -r now
