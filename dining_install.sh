#!/bin/bash
# For Raspbian Buster Lite
# wget https://github.com/pindanet/Raspberry/raw/master/dining_install.sh
# bash dining_install.sh

# ToDo
# Copy large video files directly on SDCard and check with md5sum
# raspi-config configure WiFi connection

# Test if executed with Bash
case "$BASH_VERSION" in
  "") echo "usage: bash wall_install.sh"
      exit;;
esac

KEYMAP="be"
LOCALE="nl_BE.UTF-8"
TIMEZONE="Europe/Brussels"
COUNTRY="BE"

if [ $USER == "pi" ]; then
  # Change keyboard
  sudo raspi-config nonint do_configure_keyboard "$KEYMAP"

  # Change locale
  sudo raspi-config nonint do_change_locale "$LOCALE"

  # Change timezone
  sudo raspi-config nonint do_change_timezone "$TIMEZONE"

  # Change WiFi country
  sudo raspi-config nonint do_wifi_country "$COUNTRY"

  # Change hostname
  read -p "Enter the new hostname [pindadining]: " NEW_HOSTNAME
  NEW_HOSTNAME=${NEW_HOSTNAME:-pindadining}
  sudo raspi-config nonint do_hostname "$NEW_HOSTNAME"

  # enable ssh
  sudo raspi-config nonint do_ssh 0

  # enable 1-wire
  sudo raspi-config nonint do_onewire 0
  
  # increase GPU Memory
  sudo raspi-config nonint do_memory_split 256

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
  sudo mv wall_install.sh /home/$NEW_USER/
  echo "bash wall_install.sh" | sudo tee -a /home/$NEW_USER/.bashrc

  echo "Login as $NEW_USER"
  read -p "Press Return to Restart " key

else
  # Disable Continue after reboot
  sed -i '/^bash wall_install.sh/d' .bashrc
  
  # Remove pi user
  sudo userdel -r pi

  # PgUp, PgDn Bash History
  echo '"\e[5~": history-search-backward' > .inputrc
  echo '"\e[6~": history-search-forward' >> .inputrc
  
  sudo mkdir -p /var/www/html/data
  
  # Muiscursor verbergen
#  sudo apt-get install unclutter -y

#  # Autostart Chromium browser
#  sudo apt-get install chromium-browser lightdm openbox xterm fonts-symbola -y
#  sudo raspi-config nonint do_boot_behaviour "B4"
#  mkdir -p $HOME/.config/openbox
#  echo "# Hide mouse when not moving the mouse" >> $HOME/.config/openbox/autostart
#  echo "unclutter -idle 0.1 &" >> $HOME/.config/openbox/autostart

#  echo "# Disable Screensaver" >> $HOME/.config/openbox/autostart
#  echo "xset s off" >> $HOME/.config/openbox/autostart
#  echo "xset -dpms" >> $HOME/.config/openbox/autostart
#  echo "xset s noblank" >> $HOME/.config/openbox/autostart

#  sudo apt install ddcutil -y
#  sudo wget -O brightness.sh https://raw.githubusercontent.com/pindanet/Raspberry/master/dining/brightness.sh
#  sudo chmod +x brightness.sh
#  echo "dtparam=i2c2_iknowwhatimdoing" | sudo tee -a /boot/config.txt
#  echo "# Start auto brightness script" >> $HOME/.config/openbox/autostart
#  echo "bash $HOME/brightness.sh &" >> $HOME/.config/openbox/autostart

#  echo "chromium-browser --start-fullscreen --autoplay-policy=no-user-gesture-required --allow-file-access-from-files --app=file:///home/dany/index.html" >> $HOME/.config/openbox/autostart
  
  sudo apt install omxplayer imagemagick -y
  sudo wget -O Amapola.mp4 https://raw.githubusercontent.com/pindanet/Raspberry/master/dining/Amapola.mp4
# Copy large video files directly on SDCard and check with md5sum
  ln -s Amapola.mp4 video.mp4
  
  wget https://github.com/AndrewFromMelbourne/raspidmx/archive/refs/heads/master.zip
  unzip master.zip
  rm master.zip
  cd raspidmx-master/
  make
  cd
  sudo sed -i "/^exit 0/i# Start video" /etc/rc.local
  sudo sed -i "/^exit 0/iomxplayer --aspect-mode fill --loop /home/dany/video.mp4 &" /etc/rc.local
  
  sudo wget -O ds18b20.py https://raw.githubusercontent.com/pindanet/Raspberry/master/dining/ds18b20.py
  sudo touch $HOME/temp.txt
  sudo touch $HOME/image.png
  sudo wget -O /usr/sbin/PindaNetDining.sh https://github.com/pindanet/Raspberry/raw/master/dining/usr/sbin/PindaNetDining.sh
  sudo chmod +x /usr/sbin/PindaNetDining.sh
  cat > PindaNetDining.service <<EOF
[Unit]
Description=PindaNet Domotica Dining Room
Wants=network-online.target
After=network.target network-online.target
[Service]
ExecStart=/usr/sbin/PindaNetDining.sh
Restart=always
RestartSec=60
[Install]
WantedBy=multi-user.target
EOF
  sudo mv PindaNetDining.service /etc/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable PindaNetDining.service

  sudo apt install at -y
  sudo wget -O /var/www/html/data/alarmnow.sh https://raw.githubusercontent.com/pindanet/Raspberry/master/dining/var/www/html/data/alarmnow.sh
  sudo chmod +x /var/www/html/alarmnow.sh
  sudo /var/www/html/pindaalarmclock

# HIER
  
echo "# Start fullscreen browser" >> $HOME/.config/openbox/autostart
  echo "chromium-browser --incognito --kiosk http://localhost/ &" >> $HOME/.config/openbox/autostart

  echo "# Start fullscreen video" >> $HOME/.config/openbox/autostart
  echo "#omxplayer --loop --no-osd ~/video.mp4" >> $HOME/.config/openbox/autostart
  
  echo "# Start fullscreen video with Pimoroni Speaker pHAT" >> $HOME/.config/openbox/autostart
  echo "#amixer sset 'Master' 46%" >> $HOME/.config/openbox/autostart
  echo "#omxplayer -o alsa --loop --no-osd ~/video.mp4" >> $HOME/.config/openbox/autostart
  echo "amixer -c 0 set HDMI 81%" >> $HOME/.config/openbox/autostart
  echo '#vlc --fullscreen --loop --no-video-title-show --no-osd ~/video.mp4 --aout=alsa --alsa-audio-device="sysdefault:CARD=b1"' >> $HOME/.config/openbox/autostart
  #sudo apt-get install omxplayer
  #curl -sS https://get.pimoroni.com/speakerphat | bash
  # Disable Pimoroni Speaker pHAT LED-bar
  #sudo sed -i.ori "s/brightness .*/brightness 0/" /etc/asound.conf

  sudo wget -O /var/www/html/index.html https://raw.githubusercontent.com/pindanet/Raspberry/master/wall/index.html
  sudo wget -O /var/www/html/random_pic.php https://raw.githubusercontent.com/pindanet/Raspberry/master/wall/random_pic.php
  sudo wget -O /var/www/html/nocursor.gif https://raw.githubusercontent.com/pindanet/Raspberry/master/wall/nocursor.gif
#sudo wget -P /var/www/html https://raw.githubusercontent.com/mourner/suncalc/master/suncalc.js
  sudo wget -O /var/www/html/getPresHumiTemp.php https://raw.githubusercontent.com/pindanet/Raspberry/master/wall/getPresHumiTemp.php
#sudo wget -P /var/www/html https://raw.githubusercontent.com/pindanet/Raspberry/master/wall/getBrightness.php
  sudo wget -O /var/www/html/getLux.php https://raw.githubusercontent.com/pindanet/Raspberry/master/wall/getLux.php
#sudo wget -P /var/www/html https://raw.githubusercontent.com/pindanet/Raspberry/master/wall/getWeather.php
  sudo wget -O /var/www/html/curl.php https://raw.githubusercontent.com/pindanet/Raspberry/master/wall/curl.php
#sudo wget -P /var/www/html https://raw.githubusercontent.com/pindanet/Raspberry/master/wall/genkeys.php

  echo "www-data ALL = NOPASSWD: /sbin/shutdown -r now" | sudo tee -a /etc/sudoers

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

  wget https://raw.githubusercontent.com/pindanet/Raspberry/master/wall/background.tar.gz
  sudo tar xzvf background.tar.gz -C /var/www/html
  rm background.tar.gz

  cat > background.service <<EOF
[Unit]
Description=Get background image
Wants=network-online.target
After=network.target network-online.target
[Service]
ExecStart=/usr/sbin/background.sh
[Install]
WantedBy=multi-user.target
EOF
  sudo mv background.service /etc/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable background.service

  sudo wget -O /usr/sbin/background.sh https://raw.githubusercontent.com/pindanet/Raspberry/master/wall/background.sh
  sudo chmod +x /usr/sbin/background.sh

  printf '\033[1;37;40mOn the main computer: ssh-copy-id -i ~/.ssh/id_rsa.pub rpiwall.local\n\033[0m' # Witte letters op zwarte achtergrond
  printf '\033[1;37;40mOn the domotica controller: ssh-copy-id -i ~/.ssh/id_rsa.pub rpiwall.local\n\033[0m' # Witte letters op zwarte achtergrond
  printf '\033[1;32;40mPress key to secure ssh.\033[0m' # Groene letters op zwarte achtergrond
  read Keypress
#  sudo sed -i "s/^.*PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config
  
# cd /var/www/html
# sudo -u www-data php genkeys.php
# sudo rm /var/www/html/genkeys.php
# read -p "cp /var/www/html/data/public.key to your remote website and press Return to continue " key

fi
# Restart Raspberry Pi
sudo shutdown -r now
