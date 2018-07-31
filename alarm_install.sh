#!/bin/bash

LOCALE="nl_BE.UTF-8"
TIMEZONE="Europe/Brussels"
COUNTRY="BE"
NEW_HOSTNAME="rpialarm"

if [ $HOSTNAME != $NEW_HOSTNAME ]; then
# Configure  and upgrade
# https://github.com/raspberrypi-ui/rc_gui/blob/master/src/rc_gui.c#L23-L70
# Change locale
  sudo raspi-config nonint do_change_locale "$LOCALE"
# Change timezone
  sudo raspi-config nonint do_change_timezone "$TIMEZONE"
# Change WiFi country
  sudo raspi-config nonint do_wifi_country "$COUNTRY"
# Change hostname
  sudo raspi-config nonint do_hostname "$NEW_HOSTNAME"
# Change password
  sudo raspi-config nonint do_change_pass
# Enable ssh
  sudo raspi-config nonint do_ssh 0
# Enable camera
  sudo raspi-config nonint do_camera 0
# Upgrade
  sudo apt update
  sudo apt dist-upgrade -y
  sudo apt autoremove -y

#sudo wget -P /var/www/html https://raw.githubusercontent.com/mourner/suncalc/master/suncalc.js

# Restart Raspberry Pi
  sudo shutdown -r now
  sleep 1m
fi
# SSH keydistribution
printf "\033[1;37;40mOn the main computer: ssh-copy-id -i ~/.ssh/id_rsa.pub pi@$NEW_HOSTNAME.local\n\033[0m" # Witte letters op zwarte achtergrond
printf "\033[1;37;40mOn the domotica controller: ssh-copy-id -i ~/.ssh/id_rsa.pub pi@$NEW_HOSTNAME.local\n\033[0m" # Witte letters op zwarte achtergrond
printf "\033[1;32;40mPress key to secure ssh.\033[0m" # Groene letters op zwarte achtergrond
read Keypress

#sudo sed -i "s/^.*PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config
