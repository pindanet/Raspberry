#!/bin/bash
# For Raspbian Buster Lite
# wget https://github.com/pindanet/Raspberry/raw/master/dining_install.sh
# bash dining_install.sh

# ToDo
# ====
# Copy large video files directly on SDCard and check with md5sum of sha256sum
# Werkt ook (desnoods meermaals): rsync -Pa --checksum --inplace --no-whole-file /mnt/lente.mp4 lente.mp4
# raspi-config configure WiFi connection

# Hardware
# ========
# DS18B20 temperature sensor
# --------------------------
# 3.3v - red
# 3.3v - 4k7 - yellow - GPIO 4 (7)
# Gnd (9) - black

# BTE13-005 Relaiskaart
# ---------------------
# 5v (4) - Red - RVcc
# Gnd (6) - Black - Gnd
# Gnd (39) - Black - Gnd
# GPIO 13 (33) - Blue - In1
# GPIO 19 (35) - Green - In2
# GPIO 26 (37) - Yellow - In3
# 3.3v (17) - orange - Vcc

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
  
  # Disable LED's
  echo "# Disable the ACT LED." | sudo tee -a /boot/config.txt
  echo "dtparam=act_led_trigger=none" | sudo tee -a /boot/config.txt
  echo "dtparam=act_led_activelow=off" | sudo tee -a /boot/config.txt
  echo "# Disable the PWR LED." | sudo tee -a /boot/config.txt
  echo "dtparam=pwr_led_trigger=none" | sudo tee -a /boot/config.txt
  echo "dtparam=pwr_led_activelow=off" | sudo tee -a /boot/config.txt

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
# Werkt ook (desnoods meermaals): rsync -Pa --checksum --inplace --no-whole-file /mnt/lente.mp4 lente.mp4
  cp Amapola.mp4 aquarium.mp4
  cp Amapola.mp4 haardvuur.mp4
  mv Amapola.mp4 lente.mp4
  ln -s lente.mp4 video.mp4
  
  wget https://github.com/AndrewFromMelbourne/raspidmx/archive/refs/heads/master.zip
  unzip master.zip
  rm master.zip
  cd raspidmx-master/
  make
  cd
# get random video (videofiles must exist) from array
  sudo wget -O /var/www/html/randomvideo.sh https://github.com/pindanet/Raspberry/raw/master/dining/var/www/html/randomvideo.sh

  sudo sed -i "/^exit 0/i# Start video" /etc/rc.local
  sudo sed -i "/^exit 0/ibash /var/www/html/randomvideo.sh" /etc/rc.local
  sudo sed -i "/^exit 0/iomxplayer --aspect-mode fill --loop /home/dany/video.mp4 &" /etc/rc.local

  sudo apt-get install hdate -y
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

  sudo wget -O /var/www/html/lightswitch.sh https://github.com/pindanet/Raspberry/raw/master/dining/var/www/html/lightswitch.sh

fi
# Restart Raspberry Pi
sudo shutdown -r now
