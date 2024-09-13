#!/bin/bash
# For Raspberry Pi OS Bookworm Lite
# wget https://github.com/pindanet/Raspberry/raw/master/domoticaSlave/install.sh
# bash install.sh

# ToDo
# SSL communication LMI_261-22 p62

# Hardware
# DS18B20 Temperature Sensor
# GPIO4 (7) naar Data (Geel) naar 4k7 naar 3,3 V (Rood)(GPIO17)
# GND (9) naar GND (Zwart)
# GPIO17 (11) naar Vdd (Rood)

# PIR
# 5v (4) > Vcc (Red)
# Gnd (6) > Gnd (Brown)
# GPIO14 (8) > Output (Orange)

# Test if executed with Bash
case "$BASH_VERSION" in
  "") echo "usage: bash install.sh"
      exit;;
esac

cat /sys/firmware/devicetree/base/model

echo -e "\nFull Upgrade"
echo "============"
sudo apt update && sudo apt -y full-upgrade

echo "Install Wayland" # https://gist.github.com/seffs/2395ca640d6d8d8228a19a9995418211
echo "==============="
sudo apt install wayfire seatd xdg-user-dirs libgl1-mesa-dri -y
mkdir .config
touch ~/.config/wayfire.init
sudo raspi-config nonint do_boot_behaviour "B2"  # https://www.raspberrypi.com/documentation/computers/configuration.html
echo 'if [[ "$(who am i)" == *\(*\) ]]; then' >> .bashrc
echo '  echo "SSH"' >> .bashrc
echo 'else' >> .bashrc
echo '  wayfire' >> .bashrc
echo 'fi' >> .bashrc

grep ^dtoverlay=w1-gpio /boot/firmware/config.txt
if [ $? == 1 ]; then
  echo "Activate 1-Wire and DS18B20 Temperature Sensor"
  # Activate 1-Wire
  echo 'dtoverlay=w1-gpio' | sudo tee -a /boot/firmware/config.txt
  # Activate DS18B20 Temperature Sensor
  echo 'w1-gpio' | sudo tee -a /etc/modules
  echo 'w1-therm' | sudo tee -a /etc/modules
fi

echo "Install webserver"
sudo apt install apache2 libapache2-mod-fcgid php-bcmath php-bz2 php-common php-curl php-xml php-gd php-php-gettext php-gmp php-ldap php-mbstring php-mysql php-odbc php-pgsql php-snmp php-soap php-sqlite3 php-tokenizer libapache2-mod-php -y

if test -f master.zip; then rm master.zip; fi
echo "Download and extract Github Repository"
wget https://github.com/pindanet/Raspberry/archive/refs/heads/master.zip
unzip -q master.zip
rm master.zip
sudo cp -r Raspberry-master/domoticaController/var/www/html/* /var/www/html/
rm -r Raspberry-master/

sudo chmod +x /var/www/html/ds18b20.sh

echo "Autostart fullscreen browser" # https://core-electronics.com.au/guides/raspberry-pi-kiosk-mode-setup/
echo '[autostart]' >> .config/wayfire.ini
echo 'screensaver = false' >> .config/wayfire.ini
echo 'dpms = false' >> .config/wayfire.ini
echo 'kiosk = /bin/chromium-browser  --kiosk --ozone-platform=wayland --start-maximized --noerrdialogs --disable-infobars --enable-features=OverlayScrollbar  http://localhost/ &' >> .config/wayfire.ini

# Debug, Test, Demo
echo "Configure Debug/Test/Demo"
echo '127.0.0.1       pindadomo' | sudo tee -a /etc/hosts
echo '127.0.0.1       pindadining' | sudo tee -a /etc/hosts
echo '127.0.0.1       pindakeuken' | sudo tee -a /etc/hosts

echo "Configure SSH remote login"
ssh-keygen
ssh-copy-id -i $HOME/.ssh/id_rsa.pub $(ls /home)@pindadomo
sudo cp .ssh/id_rsa /var/www/html/data/
sudo chown www-data:www-data /var/www/html/data/id_rsa

exit

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

# DS18B20 Temperature Sensor
# GPIO17 (11) naar Vdd (Rood)
# GPIO27 (13) naar Data (Geel) naar 4k7 naar 3,3 V (Rood)(GPIO17)
# GND (9) naar GND (Zwart)

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
