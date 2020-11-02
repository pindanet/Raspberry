#!/bin/bash
# For Raspbian Buster Lite
# wget https://github.com/pindanet/Raspberry/raw/master/slave_install.sh
# bash slave_install.sh

# ToDo
# Setup Headless: https://www.raspberrypi.org/documentation/configuration/wireless/headless.md
# Activate ssh on boot partition

# Test if executed with Bash
case "$BASH_VERSION" in
  "") echo "usage: bash slave_install.sh"
      exit;;
esac

LOCALE="nl_BE.UTF-8"
TIMEZONE="Europe/Brussels"
COUNTRY="BE"

if [ $USER == "pi" ]; then
  # Change locale
  sudo raspi-config nonint do_change_locale "$LOCALE"

  # Change timezone
  sudo raspi-config nonint do_change_timezone "$TIMEZONE"

  # Change WiFi country
  #sudo raspi-config nonint do_wifi_country "$COUNTRY"

  # Change hostname
  read -p "Enter the new hostname [pindakeuken]: " NEW_HOSTNAME
  NEW_HOSTNAME=${NEW_HOSTNAME:-pindakeuken}
  sudo raspi-config nonint do_hostname "$NEW_HOSTNAME"

  # enable ssh
  #sudo raspi-config nonint do_ssh 0
  
  # enable i2c
  sudo raspi-config nonint do_i2c 0

  # Upgrade
  sudo apt-get update
  sudo apt-get dist-upgrade -y
  sudo apt-get autoremove -y

  # Change user
  read -p "Enter the new user [dany]: " NEW_USER
  NEW_USER=${NEW_USER:-dany}
  sudo adduser --disabled-password --gecos "" "$NEW_USER"
  while : ; do
    sudo passwd "$NEW_USER"
    [ $? = 0 ] && break
  done
  sudo usermod -a -G adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,netdev,spi,i2c,gpio "$NEW_USER"
  
  # Continue after reboot
  sudo mv slave_install.sh /home/$NEW_USER/
  echo "bash slave_install.sh" | sudo tee -a /home/$NEW_USER/.bashrc

  echo "Login as $NEW_USER"
  read -p "Press Return to Restart " key

else
  # Disable Continue after reboot
  sed -i '/^bash slave_install.sh/d' .bashrc

  # Enable PgUp, PgDn search in bash history
  echo "bind '\"\e[5~\": history-search-backward'" >> .bashrc
  echo "bind '\"\e[6~\": history-search-forward'" >> .bashrc
  
  # Remove pi user
  sudo userdel -r pi
  
  # mcp9808
  # Pi 3V3 (1) to sensor VIN orange
  # Pi GND (6) to sensor GND yellow
  # Pi SCL (5) to sensor SCK green
  # Pi SDA (3) to sensor SDA blue
  
  sudo apt-get install i2c-tools
  i2cdetect -y 1
  
  sudo apt install python3-pip
  sudo pip3 install adafruit-circuitpython-mcp9808
  sudo wget -O /usr/sbin/mcp9808.py https://github.com/pindanet/Raspberry/raw/master/domoticaSlave/usr/sbin/mcp9808.py
  sudo chmod +x /usr/sbin/mcp9808.py

  sudo mkdir -p /var/www/html/data/
  sudo wget -O /var/www/html/data/thermostat https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/data/thermostat
  sudo wget -O /usr/sbin/PindaNetSlave.sh https://github.com/pindanet/Raspberry/raw/master/domoticaSlave/usr/sbin/PindaNetSlave.sh
  sudo chmod +x /usr/sbin/PindaNetSlave.sh
  cat > PindaNetSlave.service <<EOF
[Unit]
Description=PindaNet Domotica Slave
Wants=network-online.target
After=network.target network-online.target
[Service]
ExecStart=/usr/sbin/PindaNetSlave.sh
Restart=always
RestartSec=60
[Install]
WantedBy=multi-user.target
EOF
  sudo mv PindaNetSlave.service /etc/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable PindaNetSlave.service

  printf "\033[1;37;40mOn the main computer: ssh-copy-id -i ~/.ssh/id_rsa.pub $HOSTNAME\n\033[0m" # Witte letters op zwarte achtergrond
  printf "\033[1;37;40mOn the domotica controller: ssh-keygen\n\033[0m" # Witte letters op zwarte achtergrond
  printf "\033[1;37;40mOn the domotica controller: ssh-copy-id -i ~/.ssh/id_rsa.pub $HOSTNAME\n\033[0m" # Witte letters op zwarte achtergrond
  printf '\033[1;32;40mPress key to secure ssh.\033[0m' # Groene letters op zwarte achtergrond
  read Keypress
#  sudo sed -i "s/^.*PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config

  exit
fi
# Restart Raspberry Pi
sudo shutdown -r now
