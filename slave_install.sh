#!/bin/bash
# For Raspbian Buster Lite
# wget https://github.com/pindanet/Raspberry/raw/master/slave_install.sh
# bash slave_install.sh

# ToDo
# Setup Headless: https://www.raspberrypi.org/documentation/configuration/wireless/headless.md
# Activate ssh on boot partition

# Test if executed with Bash
case "$BASH_VERSION" in
  "") echo "usage: bash domoticaController_install.sh"
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

  sudo mkdir -p /var/www/html/data/
  sudo wget -O /var/www/html/data/thermostat https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/data/thermostat
  sudo wget -O /usr/sbin/PindaNetSlave.sh https://github.com/pindanet/Raspberry/raw/master/domoticaController/usr/sbin/PindaNetDomo.sh
  sudo chmod +x /usr/sbin/PindaNetDomo.sh
  cat > PindaNetDomo.service <<EOF
[Unit]
Description=PindaNetDomotica
Wants=network-online.target
After=network.target network-online.target
[Service]
ExecStart=/usr/sbin/PindaNetDomo.sh
Restart=always
RestartSec=60
[Install]
WantedBy=multi-user.target
EOF
  sudo mv PindaNetDomo.service /etc/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable PindaNetDomo.service

exit

#  read -s -p "Typ bindelings de encryptie wachtzin: " passphrase
#  sudo sed -i "s|^\(\$passphrase =\).*$|\1 \'$passphrase\';|" /var/www/html/genkeys.php
#  sudo sed -i "s|^\(\$passphrase =\).*$|\1 \'$passphrase\';|" /var/www/html/curl.php
  while true; do
    read -s -p  "Typ blindelings de gebruikersnaam voor de remote webpagina: " user
    echo
    read -s -p  "Typ blindelings de gebruikersnaam voor de remote webpagina (nogmaals): " user2
    echo
    [ "$user" = "$user2" ] && break
    echo "Please try again"
  done
  sudo sed -i "s|^\(\$user =\).*$|\1 \'$user\';|" /var/www/html/curl.php
  while true; do
    read -s -p "Typ bindelings het wachtwoord voor de remote webpagina: " password
    echo
    read -s -p "Typ bindelings het wachtwoord voor de remote webpagina (nogmaals): " password2
    echo
    [ "$password" = "$password2" ] && break
    echo "Please try again"
  done
  sudo sed -i "s|^\(\$password =\).*$|\1 \'$password\';|" /var/www/html/curl.php
  
# Remote LAN commands
  sudo mkdir /var/www/html/remote
  sudo chown -R www-data:www-data /var/www/html/remote
  sudo wget -O /var/www/html/remote.php https://raw.githubusercontent.com/pindanet/Raspberry/master/wall/remote.php
  sudo wget -O /var/www/html/remote.sh https://raw.githubusercontent.com/pindanet/Raspberry/master/wall/remote.sh
  sudo apt install incron -y
  echo root | sudo tee /etc/incron.allow
  echo '/var/www/html/remote    IN_CLOSE_WRITE  /bin/bash /var/www/html/remote.sh "$@/$#"' | sudo tee /var/spool/incron/root
  sudo chmod go-rwx /var/spool/incron/root # enkel rw user blijft over
  sudo systemctl start incron
  sudo systemctl enable incron

  printf '\033[1;37;40mOn the main computer: ssh-copy-id -i ~/.ssh/id_rsa.pub rpiwall.local\n\033[0m' # Witte letters op zwarte achtergrond
  printf '\033[1;37;40mOn the domotica controller: ssh-copy-id -i ~/.ssh/id_rsa.pub rpiwall.local\n\033[0m' # Witte letters op zwarte achtergrond
  printf '\033[1;32;40mPress key to secure ssh.\033[0m' # Groene letters op zwarte achtergrond
  read Keypress
  sudo sed -i "s/^.*PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config

# cd /var/www/html
# sudo -u www-data php genkeys.php
# sudo rm /var/www/html/genkeys.php
# read -p "cp /var/www/html/data/public.key to your remote website and press Return to continue " key

fi
# Restart Raspberry Pi
sudo shutdown -r now
