#!/bin/bash
# For Raspbian Buster Lite
# wget https://github.com/pindanet/Raspberry/raw/master/slave_install.sh
# bash slave_install.sh

# ToDo
# Setup Headless: https://www.raspberrypi.org/documentation/configuration/wireless/headless.md
# Activate ssh on boot partition

# PIR 1
# -----
# Gnd (14) > Gnd (Brown)
# GPIO 4 (7) > Output (Orange)
# 5 V (4) > Vcc (Red)

# PIR 2
# -----
# Gnd (25) > Gnd (Black)
# GPIO 7 (26) > Output (Brown)
# 5 V (4) > Vcc (Red)

# Touchscreen
# -----------
# Gnd (6) > Gnd (Black)
# 5 V (4) > 5 V (Red)

# BTE13-003 Relaiskaart
# ---------------------
# 5v (2) - Red - RVcc
# Gnd (20) - Black - Gnd
# Gnd (39) - Black - Gnd
# GPIO 13 (33) - Blue - In1
# GPIO 19 (35) - Green - In2
# 3.3v (17) - Yellow - Vcc
  
# mcp9808
# Pi 3V3 (1) to sensor VIN orange
# Pi GND (9) to sensor GND yellow
# Pi SCL (5) to sensor SCK green
# Pi SDA (3) to sensor SDA blue

# Test if executed with Bash
case "$BASH_VERSION" in
  "") echo "usage: bash slave_install.sh"
      exit;;
esac

LOCALE="nl_BE.UTF-8"
TIMEZONE="Europe/Brussels"
COUNTRY="BE"

# Lower Brightness Touchscreen
echo 128 | sudo tee /sys/class/backlight/rpi_backlight/brightness

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
  
  # rotate LCD screen 90°
  echo "display_rotate=1 90" | sudo tee -a /boot/config.txt
  sudo sed -i '/.*MatchIsTouchscreen "on".*/a\ \ \ \ \ \ \ \ Option "TransformationMatrix" "0 1 0 -1 0 1 0 0 1"' /usr/share/X11/xorg.conf.d/40-libinput.conf
  # echo "dtoverlay=rpi-ft5406,touchscreen-swapped-x-y=1,touchscreen-inverted-x=1,touchscreen-inverted-y=1" | sudo tee -a /boot/config.txt
  
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
  
  sudo apt-get install i2c-tools bc -y
  i2cdetect -y 1

# Werkt niet in Buster
#  sudo nano /boot/config.txt
#     dtparam=i2c_arm=on
#     dtoverlay=i2c-sensor,jc42
# Alternatief voor Buster
  sudo apt install python3-pip -y
  sudo pip3 install adafruit-circuitpython-mcp9808
  sudo wget -O /usr/sbin/mcp9808.py https://github.com/pindanet/Raspberry/raw/master/domoticaSlave/usr/sbin/mcp9808.py
  sudo chmod +x /usr/sbin/mcp9808.py
  sudo wget -O /var/www/html/mcp9808.sh https://github.com/pindanet/Raspberry/raw/master/domoticaSlave/var/www/html/mcp9808.sh
  sudo chmod +x /var/www/html/mcp9808.sh
  
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

  sudo wget -O /usr/sbin/PindaNetDaily.sh https://github.com/pindanet/Raspberry/raw/master/domoticaSlave/usr/sbin/PindaNetDaily.sh
  sudo chmod +x /usr/sbin/PindaNetDaily.sh
  cat > PindaNetDaily.service <<EOF
[Unit]
Description= Execute once a day

[Service]
Type= simple

ExecStart= /usr/sbin/PindaNetDaily.sh

[Install]
WantedBy= multi-user.target
EOF
  sudo mv PindaNetDaily.service /etc/systemd/system/
  
  cat > PindaNetDaily.timer <<EOF
[Unit]
Description= Execute once a day

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF
  sudo mv PindaNetDaily.timer /etc/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable PindaNetDaily.timer

  sudo apt-get install hdate -y
  sudo wget -O /usr/sbin/PindaNetMotion.sh https://github.com/pindanet/Raspberry/raw/master/domoticaSlave/usr/sbin/PindaNetMotion.sh
  sudo chmod +x /usr/sbin/PindaNetMotion.sh
  cat > PindaNetMotion.service <<EOF
[Unit]
Description=PindaNet Domotica Motion detection and actions
Wants=network-online.target
After=network.target network-online.target
[Service]
ExecStart=/usr/sbin/PindaNetMotion.sh
Restart=always
RestartSec=60
[Install]
WantedBy=multi-user.target
EOF
  sudo mv PindaNetMotion.service /etc/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable PindaNetMotion.service

  printf "\033[1;37;40mOn the main computer: ssh-copy-id -i ~/.ssh/id_rsa.pub $HOSTNAME\n\033[0m" # Witte letters op zwarte achtergrond
  printf "\033[1;37;40mOn the domotica controller: ssh-keygen\n\033[0m" # Witte letters op zwarte achtergrond
  printf "\033[1;37;40mOn the domotica controller: ssh-copy-id -i ~/.ssh/id_rsa.pub $HOSTNAME\n\033[0m" # Witte letters op zwarte achtergrond
  printf '\033[1;32;40mPress key to secure ssh.\033[0m' # Groene letters op zwarte achtergrond
  read Keypress
#  sudo sed -i "s/^.*PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config

  sudo wget -O /usr/sbin/PindaNetUpdate.sh https://github.com/pindanet/Raspberry/raw/master/domoticaSlave/usr/sbin/PindaNetUpdate.sh
  sudo chmod +x /usr/sbin/PindaNetUpdate.sh
  cat > PindaNetUpdate.timer <<EOF
[Unit]
Description=Update and Reset
[Timer]
OnCalendar=*-*-* 03:30:00
Unit=PindaNetUpdate.service
[Install]
WantedBy=multi-user.target
EOF
  sudo mv PindaNetUpdate.timer /etc/systemd/system/

  cat > PindaNetUpdate.service <<EOF
[Unit]
Description=Update and Reset
[Service]
Type=simple
ExecStart=/usr/sbin/PindaNetUpdate.sh
EOF
  sudo mv PindaNetUpdate.service /etc/systemd/system/

  sudo systemctl daemon-reload
  sudo systemctl enable PindaNetUpdate.timer
  sudo systemctl start PindaNetUpdate.timer
# systemctl list-timers

# Webserver
  sudo apt-get install apache2 php libapache2-mod-php php-ssh2 php-gd php-xml php-curl php-mbstring -y
  sudo systemctl restart apache2.service
  sudo mkdir /var/www/html/data
  sudo chown -R www-data:www-data /var/www/html/data/
  
# Muiscursor verbergen
  sudo apt-get install unclutter -y

# Autostart Chromium browser
  sudo apt-get install chromium-browser lightdm openbox xterm fonts-symbola -y
  
  sudo raspi-config nonint do_boot_behaviour "B4"
  mkdir -p $HOME/.config/openbox
  echo "# Hide mouse when not moving the mouse" >> $HOME/.config/openbox/autostart
  echo "unclutter -idle 0.1 &" >> $HOME/.config/openbox/autostart
  
  echo "# Disable Screensaver" >> $HOME/.config/openbox/autostart
  echo "xset s off" >> $HOME/.config/openbox/autostart
  echo "xset -dpms" >> $HOME/.config/openbox/autostart
  echo "xset s noblank" >> $HOME/.config/openbox/autostart

  echo "# Start fullscreen browser" >> $HOME/.config/openbox/autostart
  echo "chromium-browser --incognito --kiosk http://localhost/ &" >> $HOME/.config/openbox/autostart
  
  sudo wget -O /var/www/html/index.html https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaSlave/var/www/html/index.html
  sudo wget -O /var/www/html/index.css https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaSlave/var/www/html/index.css
  sudo wget -O /var/www/html/index.js https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaSlave/var/www/html/index.js
  sudo wget -O /var/www/html/tasmota.php https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaSlave/var/www/html/tasmota.php
#  sudo apt-get install aha -y
  sudo wget -O /var/www/html/weather.php https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaSlave/var/www/html/weather.php
  wget https://github.com/pindanet/Raspberry/raw/master/domoticaSlave/var/www/html/weathericons.zip
  # nog uitpakken naar /var/www/html/
  sudo usermod -a -G gpio "www-data"
  
  sudo mkdir /var/www/html/emoji
  sudo wget -O /var/www/html/emoji/infrared-off.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaSlave/var/www/html/emoji/infrared-off.svg
  sudo wget -O /var/www/html/emoji/infrared-on.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaSlave/var/www/html/emoji/infrared-on.svg
  sudo wget -O /var/www/html/emoji/infrared-auto.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaSlave/var/www/html/emoji/infrared-auto.svg
  sudo wget -O /var/www/html/emoji/light-bulb-off.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaSlave/var/www/html/emoji/light-bulb-off.svg
  sudo wget -O /var/www/html/emoji/light-bulb-on.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaSlave/var/www/html/emoji/light-bulb-on.svg
  sudo wget -O /var/www/html/emoji/weather.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaSlave/var/www/html/emoji/weather.svg

  sudo wget -O /var/www/html/lightswitch.sh https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaSlave/var/www/html/lightswitch.sh
  sudo chmod +x /var/www/html/lightswitch.sh
fi
# Restart Raspberry Pi
sudo shutdown -r now
