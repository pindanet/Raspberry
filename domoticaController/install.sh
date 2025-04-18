#!/bin/bash
# For Raspberry Pi OS Bookworm Lite
# wget https://github.com/pindanet/Raspberry/raw/master/domoticaController/install.sh
# bash install.sh

# ToDo
# SSL communication LMI_261-22 p62
# Activate Serial Hardware
# Activate PiCamera

router="mymodem.home"

# Hardware
# DS18B20 Temperature Sensor
# GPIO4 (7) naar Data (Geel) naar 4k7 naar 3,3 V (Rood)(GPIO17)
# GND (9) naar GND (Zwart)
# GPIO17 (11) naar Vdd (Rood)
powergpio=17

# BH1750 Light Sensor
# 3.3 V (1) naar VIN (Rood)
# SDA (3) naar SDA   (Grijs)
# SCL (5) naar SCL   (Wit)
# GND (6) naar GND   (Bruin)

# Test if executed with Bash
case "$BASH_VERSION" in
  "") echo "usage: bash install.sh"
      exit;;
esac

cat /sys/firmware/devicetree/base/model

echo -e "\nFull Upgrade"
echo "============"
sudo apt update && sudo apt -y full-upgrade

echo "Install Wayland"
echo "==============="
sudo apt install labwc seatd xdg-user-dirs libgl1-mesa-dri
mkdir -p .config/labwc
sudo raspi-config nonint do_boot_behaviour "B2"  # https://www.raspberrypi.com/documentation/computers/configuration.html
echo 'if [[ "$(who am i)" == *\(*\) ]]; then' >> .bashrc
echo '  tail /var/www/html/data/debug.txt' >> .bashrc
#echo '  echo "SSH"' >> .bashrc
echo 'else' >> .bashrc
echo '  # Disable Power led' >> .bashrc
echo '  echo 0 | sudo tee /sys/class/leds/PWR/brightness' >> .bashrc
echo '  # Disable Activity led' >> .bashrc
echo '  echo none | sudo tee /sys/class/leds/ACT/trigger' >> .bashrc
echo '  labwc' >> .bashrc
echo 'fi' >> .bashrc

grep ^dtoverlay=w1-gpio /boot/firmware/config.txt
if [ $? == 1 ]; then
  echo "Activate 1-Wire and DS18B20 Temperature Sensor"
  # Activate 1-Wire
  echo 'dtoverlay=w1-gpio' | sudo tee -a /boot/firmware/config.txt
  # Activate DS18B20 Temperature Sensor
  echo 'w1-gpio' | sudo tee -a /etc/modules
  echo 'w1-therm' | sudo tee -a /etc/modules
  # Set IQaudIODAC DigiAMP+ default
  sudo sed -i 's/^dtparam=audio=on/#&/' /boot/firmware/config.txt
  echo "Activate I2C and BH1750 Light Sensor"
  # Activate I2C
  sudo sed -i 's/^#dtparam=i2c_arm=on/dtparam=i2c_arm=on/' /boot/firmware/config.txt
  echo 'i2c-dev' | sudo tee -a /etc/modules
  # Activate BH1750 Light Sensor
  echo 'dtoverlay=i2c-sensor,bh1750' | sudo tee -a /boot/firmware/config.txt
fi

echo "Shutdown/Boot button"
echo "===================="
echo 'dtoverlay=gpio-shutdown' | sudo tee -a /boot/firmware/config.txt

echo "Install webserver"
echo "================="
sudo apt install apache2 libapache2-mod-fcgid php-bcmath php-bz2 php-common php-curl php-xml php-gd php-php-gettext php-gmp php-ldap php-mbstring php-mysql php-odbc php-pgsql php-snmp php-soap php-sqlite3 php-tokenizer libapache2-mod-php -y
sudo apt install mpg123 -y

if test -f master.zip; then rm master.zip; fi
echo "Download and extract Github Repository"
echo "======================================"
wget https://github.com/pindanet/Raspberry/archive/refs/heads/master.zip
unzip -q master.zip
rm master.zip
sudo cp -r Raspberry-master/domoticaController/var/www/html/* /var/www/html/
rm -r Raspberry-master/

sudo chmod +x /var/www/html/ds18b20.sh
sudo chown -R www-data:www-data /var/www/html/data
# Enable set touchscreen brightness
sudo usermod -a -G video www-data
sudo tee /etc/udev/rules.d/99-brightness.rules > /dev/null <<EOF
# allow brightness power control for everyone
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="10-0045", RUN+="/bin/chmod a+w /sys/class/backlight/10-0045/bl_power"
EOF
# Test with: udevadm test /sys/class/backlight/10-0045
# Activate without restart with: sudo udevadm trigger --verbose --action=add /sys/class/backlight/10-0045
# Enable set audio volume
sudo usermod -a -G audio www-data
# Enable GPIO use
sudo usermod -a -G gpio www-data

echo "Autostart fullscreen browser" # https://core-electronics.com.au/guides/raspberry-pi-kiosk-mode-setup/
echo "============================"
sudo apt install chromium -y

cat > PindaNetAutostart.sh <<EOF
#!/bin/bash
# Activate DS18B20 temperature sensor power (Reset)
/usr/bin/pinctrl set $powergpio op dh
# PullUp 1-wire Data
/usr/bin/pinctrl set 4 ip pu
# Autostart Chromium in Kiosk & Debug mode
/bin/chromium --disable-gpu --remote-debugging-port=9222 --kiosk --start-maximized --noerrdialogs --disable-infobars --enable-features=OverlayScrollbar http://localhost/ &
# Give Chromium time to start
sleep 30
# Check if Chromium is running
until ps -ax | grep kiosk | grep -v grep
do
  # After a hostname change, chromium refuses to start, correct this
  rm -rf $HOME/.config/chromium/Singleton*
  # Restart chromium
  /bin/chromium --disable-gpu --remote-debugging-port=9222 --kiosk --start-maximized --noerrdialogs --disable-infobars --enable-features=OverlayScrollbar http://localhost/ &
  sleep 30
done
EOF
echo "/usr/bin/bash ~/PindaNetAutostart.sh &" >> .config/labwc/autostart

echo "Configure SSH remote login"
echo "=========================="
ssh-keygen
# ssh-copy-id -i $HOME/.ssh/id_rsa.pub $(ls /home)@pindadomo
# sudo cp .ssh/id_rsa /var/www/html/data/
#sudo chown www-data:www-data /var/www/html/data/id_rsa

echo "Activate daily update"
echo "====================="

sudo tee /usr/sbin/PindaNetUpdate.sh > /dev/null <<EOF
#!/bin/bash
sudo dpkg --configure -a
apt-get clean
apt autoremove -y
apt-get update
apt-get upgrade -y
shutdown -r now
EOF
sudo chmod +x /usr/sbin/PindaNetUpdate.sh

sudo tee /etc/systemd/system/PindaNetUpdate.timer > /dev/null <<EOF
[Unit]
Description=Update and Reset
[Timer]
OnCalendar=*-*-* 03:30:00
Unit=PindaNetUpdate.service
[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/PindaNetUpdate.service > /dev/null <<EOF
[Unit]
Description=Update and Reset
[Service]
Type=simple
ExecStart=/usr/sbin/PindaNetUpdate.sh
EOF

sudo systemctl daemon-reload
sudo systemctl enable PindaNetUpdate.timer
sudo systemctl start PindaNetUpdate.timer

# Check Avahi hostname
sudo apt install avahi-utils -y
sudo tee /usr/sbin/checkAvahi.sh > /dev/null <<EOF
#!/bin/bash
# Check WiFi connection
if ! ping -c 1 $router; then
  echo "\$(date) Restart Network" >> /var/www/html/data/debug.txt
  systemctl restart NetworkManager.service
#  /sbin/shutdown -r now
  sleep 10
fi
# Check Avahi conflict
if [ \$(avahi-resolve -a \$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}') | cut -f 2) != \${HOSTNAME}.local ]; then
  echo Restart avahi
  systemctl restart avahi-daemon.service
fi
EOF
sudo chmod +x /usr/sbin/checkAvahi.sh

sudo tee /etc/systemd/system/checkAvahi.timer > /dev/null <<EOF
[Unit]
Description=Check Avahi hostname
[Timer]
OnBootSec=5min
OnUnitActiveSec=1h
Unit=checkAvahi.service
[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/checkAvahi.service > /dev/null <<EOF
[Unit]
Description=Check Avahi hostname
[Service]
Type=simple
ExecStart=/usr/sbin/checkAvahi.sh
EOF

sudo systemctl daemon-reload
sudo systemctl enable checkAvahi.timer
sudo systemctl start checkAvahi.timer
# systemctl list-timers

sudo tee /etc/systemd/system/mqtt_log.service > /dev/null <<EOF
[Unit]
Description=Log MQTT Power
[Service]
Type=simple
ExecStart=/var/www/html/mqtt_log.sh
[Install]
WantedBy=multi-user.target
EOF
sudo chmod +x /var/www/html/mqtt_log.sh

sudo systemctl daemon-reload
sudo systemctl enable mqtt_log.service
sudo systemctl start mqtt_log.service

sudo tee /etc/systemd/system/websocket.service > /dev/null <<EOF
[Unit]
Description=WebSocket Server Daemon
After=network-online.target

[Service]
ExecStart=/usr/bin/php /var/www/html/websocket.php
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable websocket.service
sudo systemctl start websocket.service

# Play Radio stream with ICY-META (stderr) output logging
sudo tee /etc/systemd/system/PindaNetRadio.path > /dev/null <<EOF
[Unit]
Description=Monitor the /var/www/html/data/radio.cmd file for changes
[Path]
PathModified=/var/www/html/data/radio.cmd
Unit=PindaNetRadio.service
[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/PindaNetRadio.service > /dev/null <<EOF
[Unit]
Description=Execute the script with Radio commands
[Service]
ExecStart=/bin/bash /var/www/html/PindaNetRadio.sh
EOF

sudo systemctl daemon-reload
sudo systemctl enable PindaNetRadio.path
sudo systemctl start PindaNetRadio.path

# Install Roc Network Audio
sudo apt install g++ pkg-config scons ragel gengetopt libuv1-dev libunwind-dev libspeexdsp-dev libsox-dev libsndfile1-dev libssl-dev libpulse-dev git -y
sudo apt install libtool intltool autoconf automake make cmake meson -y
git clone https://github.com/roc-streaming/roc-toolkit.git
cd roc-toolkit
scons -Q --build-3rdparty=openfec
sudo scons -Q --build-3rdparty=openfec install
cd

exit

KEYMAP="be"
LOCALE="nl_BE.UTF-8"
TIMEZONE="Europe/Brussels"
COUNTRY="BE"
FULLCALENDAR="4.4.0"

if [ $USER == "pi" ]; then
  # rotate Touchscreen
  #echo 'lcd_rotate=2' | sudo tee -a /boot/config.txt

  # Enable Touchscreen brightness control for user
  echo 'SUBSYSTEM=="backlight",RUN+="/bin/chmod 666 /sys/class/backlight/%k/brightness /sys/class/backlight/%k/bl_power"' | sudo tee -a /etc/udev/rules.d/backlight-permissions.rules
  
  # disable ethernet LED's (Raspberry Pi 3B+)
#  echo 'dtparam=eth_led0=14' | sudo tee -a /boot/config.txt
#  echo 'dtparam=eth_led1=14' | sudo tee -a /boot/config.txt
  # disable ethernet LED's (Raspberry Pi 4B)
  echo 'dtparam=eth_led0=4' | sudo tee -a /boot/config.txt
  echo 'dtparam=eth_led1=4' | sudo tee -a /boot/config.txt

# Change keyboard
  sudo raspi-config nonint do_configure_keyboard "$KEYMAP"

  # Change locale
  sudo raspi-config nonint do_change_locale "$LOCALE"

  # Change timezone
  sudo raspi-config nonint do_change_timezone "$TIMEZONE"

  # Change WiFi country
  sudo raspi-config nonint do_wifi_country "$COUNTRY"

  # Change hostname
  read -p "Enter the new hostname [pindadomo]: " NEW_HOSTNAME
  NEW_HOSTNAME=${NEW_HOSTNAME:-pindadomo}
  sudo raspi-config nonint do_hostname "$NEW_HOSTNAME"

  # enable ssh
  sudo raspi-config nonint do_ssh 0

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
  sudo mv domoticaController_install.sh /home/$NEW_USER/
  echo "bash domoticaController_install.sh" | sudo tee -a /home/$NEW_USER/.bashrc

  echo "Login as $NEW_USER"
  read -p "Press Return to Restart " key

else
  # Disable Continue after reboot
  sed -i '/^bash domoticaController_install.sh/d' .bashrc

  # Enable PgUp, PgDn search in bash history
  echo "bind '\"\e[5~\": history-search-backward'" >> .bashrc
  echo "bind '\"\e[6~\": history-search-forward'" >> .bashrc
  
  # Remove pi user
  sudo userdel -r pi

  sudo wget -O /usr/sbin/PindaNetUpdate.sh https://github.com/pindanet/Raspberry/raw/master/domoticaController/usr/sbin/PindaNetUpdate.sh
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
  #sudo a2enmod ssl
  #sudo a2ensite default-ssl
  sudo systemctl restart apache2.service

  #sudo mkdir /etc/apache2/ssl
  #sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt -subj "/C=BE/ST=West Vlaanderen/L=Brugge/O=PinDaNet/OU=Raspberry/CN=Dany Pinoy"
  #sudo chmod 600 /etc/apache2/ssl/*
  #sudo sed -i "/ServerAdmin webmaster@localhost/a\                ServerName $NEW_HOSTNAME.local:443" /etc/apache2/sites-enabled/default-ssl.conf
  #sudo sed -i "s/SSLCertificateFile\t.*$/SSLCertificateFile\t\/etc\/apache2\/ssl\/apache.crt/g" /etc/apache2/sites-enabled/default-ssl.conf
  #sudo sed -i "s/SSLCertificateKeyFile .*$/SSLCertificateKeyFile \/etc\/apache2\/ssl\/apache.key/g" /etc/apache2/sites-enabled/default-ssl.conf
  #sudo systemctl restart apache2.service
  #openssl s_client -connect 127.0.0.1:443
  #sudo sed -i "/<VirtualHost \*:80>/a\        Redirect \"\/\" \"https:\/\/$NEW_HOSTNAME.local\/\"" /etc/apache2/sites-available/000-default.conf
  #sudo systemctl restart apache2.service
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
  echo "chromium-browser --incognito --kiosk --check-for-update-interval=31536000 http://localhost/index.html &" >> $HOME/.config/openbox/autostart

  sudo wget -O /var/www/html/index.html https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/index.html
  sudo wget -O /var/www/html/index.css https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/index.css
  sudo wget -O /var/www/html/index.js https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/index.js
  sudo wget -O /var/www/html/suncalc.js https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/suncalc.js
  sudo mkdir /var/www/html/emoji/
  sudo wget -O /var/www/html/emoji/medicinecabinet.png https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/medicinecabinet.png
  sudo wget -O /var/www/html/emoji/christmassspheres.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/christmassspheres.svg
  sudo wget -O /var/www/html/emoji/fireplace.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/fireplace.svg
  sudo wget -O /var/www/html/emoji/kitchen.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/kitchen.svg
  sudo wget -O /var/www/html/emoji/lcdmonitor.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/lcdmonitor.svg
  sudo wget -O /var/www/html/emoji/calendar.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/calendar.svg
  sudo wget -O /var/www/html/emoji/framed_picture.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/framed_picture.svg
  sudo wget -O /var/www/html/emoji/logout.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/logout.svg
  sudo wget -O /var/www/html/emoji/monitor.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/monitor.svg
  sudo wget -O /var/www/html/emoji/network-wireless.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/network-wireless.svg
  sudo wget -O /var/www/html/emoji/radio.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/radio.svg
  sudo wget -O /var/www/html/emoji/reboot.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/reboot.svg
  sudo wget -O /var/www/html/emoji/refresh.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/refresh.svg
  sudo wget -O /var/www/html/emoji/shutdown.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/shutdown.svg
  sudo wget -O /var/www/html/emoji/surveillance-camera.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/surveillance-camera.svg
  sudo wget -O /var/www/html/emoji/thermometer.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/thermometer.svg
  sudo wget -O /var/www/html/emoji/thermostat.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/thermostat.svg
  sudo wget -O /var/www/html/emoji/timelapse.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/timelapse.svg
  sudo wget -O /var/www/html/emoji/weather.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/weather.svg
  sudo wget -O /var/www/html/emoji/keyring.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/keyring.svg
  sudo wget -O /var/www/html/emoji/light_bulb.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/light_bulb.svg
  sudo wget -O /var/www/html/emoji/ledlamp.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/ledlamp.svg
  sudo wget -O /var/www/html/emoji/ledlampzij.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/ledlampzij.svg
  sudo wget -O /var/www/html/emoji/sleep.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/emoji/sleep.svg
  sudo wget -O /var/www/html/background.php https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/background.php
  sudo wget -O /var/www/html/openssl.php https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/openssl.php
  sudo wget -O /var/www/html/photoframe.sh https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/photoframe.sh

# Fetch background images
  sudo apt-get install imagemagick -y
  sudo apt-get install hdate -y
# tar cvzf - background | split -b 20m - background.tar.gz
  wget https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/background.tar.gzaa
  wget https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/background.tar.gzab
  wget https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/background.tar.gzac
  wget https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/background.tar.gzad
  wget https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/background.tar.gzae
  cat background.tar.* | sudo tar xzvf - -C /var/www/html
  rm background.tar.*

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

  sudo wget -O /usr/sbin/background.sh https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/usr/sbin/background.sh
  sudo chmod +x /usr/sbin/background.sh

  echo "www-data ALL = NOPASSWD: /bin/bash remote.sh clean" | sudo tee -a /etc/sudoers
  echo "www-data ALL = NOPASSWD: /bin/bash remote.sh update" | sudo tee -a /etc/sudoers
  echo "www-data ALL = NOPASSWD: /bin/bash remote.sh rsync" | sudo tee -a /etc/sudoers

  echo "www-data ALL = NOPASSWD: /sbin/shutdown -r now" | sudo tee -a /etc/sudoers
  echo "www-data ALL = NOPASSWD: /sbin/shutdown -h now" | sudo tee -a /etc/sudoers
  echo "www-data ALL = NOPASSWD: /bin/systemctl start hostapd.service" | sudo tee -a /etc/sudoers
  echo "www-data ALL = NOPASSWD: /bin/systemctl stop hostapd.service" | sudo tee -a /etc/sudoers
  echo "www-data ALL = NOPASSWD: /usr/bin/tee /sys/class/backlight/rpi_backlight/bl_power" | sudo tee -a /etc/sudoers

  echo "www-data ALL = NOPASSWD: /usr/bin/killall roc-recv" | sudo tee -a /etc/sudoers

  sudo wget -O /var/www/html/system.php https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/system.php
  sudo wget -O /var/www/html/remote.sh https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/remote.sh
  sudo wget -O /var/www/html/upload.php https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/upload.php
  
  wget https://github.com/fullcalendar/fullcalendar/releases/download/v$FULLCALENDAR/fullcalendar-$FULLCALENDAR.zip
  unzip -l fullcalendar-$FULLCALENDAR.zip
  sudo mkdir /var/www/html/fullcalendar
  sudo unzip fullcalendar-$FULLCALENDAR.zip -d /var/www/html/fullcalendar/
  rm fullcalendar-$FULLCALENDAR.zip
  
  sudo wget -O /var/www/html/fullcalendar/ical.js https://github.com/mozilla-comm/ical.js/releases/download/v1.3.0/ical.js
  sudo wget -O /var/www/html/fullcalendar/basic.ics https://www.google.com/calendar/ical/feestdagenbelgie%40gmail.com/public/basic.ics
  sudo chown www-data:www-data /var/www/html/fullcalendar/basic.ics
  sudo wget -O /var/www/html/fullcalendar/snt.ics https://www.google.com/calendar/ical/feestdagenbelgie%40gmail.com/public/basic.ics
  sudo chown www-data:www-data /var/www/html/fullcalendar/snt.ics

  sudo wget -O /var/www/html/state.php https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/state.php
  sudo wget -O /var/www/html/forecast.php https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/forecast.php
  sudo apt-get install inkscape
  
  sudo wget -O /var/www/html/exportthermostat.php https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/exportthermostat.php
  sudo wget -O /var/www/html/thermostatcommand.php https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/thermostatcommand.php
#  sudo apt-get -y install python-pip
#  sudo pip install bme280
  echo 'dtoverlay=i2c-sensor,bme280,addr=0x77' | sudo tee -a /boot/config.txt
  
  sudo wget -O /var/www/html/tls2591.py https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/tls2591.py
  sudo usermod -a -G i2c www-data
  
  wget https://github.com/ssjoholm/rfxcmd_gc/archive/master.zip
  unzip master.zip
  sudo mv rfxcmd_gc-master /var/www/html/
  rm master.zip
  sudo apt-get -y install python-serial
  sudo usermod -a -G dialout www-data
  
  # ToDo
  # sudo raspi-config
  # enable serial hardware
  # enable picamera
  
  sudo wget -O /var/www/html/data/conf.json https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/data/conf.json
#  sudo wget -O /usr/sbin/PindaNetDomo.sh https://github.com/pindanet/Raspberry/raw/master/domoticaController/usr/sbin/PindaNetDomo.sh
#  sudo chmod +x /usr/sbin/PindaNetDomo.sh
#  cat > PindaNetDomo.service <<EOF
#[Unit]
#Description=PindaNetDomotica
#Wants=network-online.target
#After=network.target network-online.target
#[Service]
#ExecStart=/usr/sbin/PindaNetDomo.sh
#Restart=always
#RestartSec=60
#[Install]
#WantedBy=multi-user.target
#EOF
#  sudo mv PindaNetDomo.service /etc/systemd/system/
#  sudo systemctl daemon-reload
#  sudo systemctl enable PindaNetDomo.service

#  sudo wget -O /usr/sbin/PindaNetLights.sh https://github.com/pindanet/Raspberry/raw/master/domoticaController/usr/sbin/PindaNetLights.sh
#  sudo chmod +x /usr/sbin/PindaNetLights.sh
#  cat > PindaNetLights.service <<EOF
#[Unit]
#Description=PindaNetDomotica Lights
#Wants=network-online.target
#After=network.target network-online.target
#[Service]
#ExecStart=/usr/sbin/PindaNetLights.sh
#Restart=always
#RestartSec=60
#[Install]
#WantedBy=multi-user.target
#EOF
#  sudo mv PindaNetLights.service /etc/systemd/system/
#  sudo systemctl daemon-reload
#  sudo systemctl enable PindaNetLights.service

  sudo wget -O /var/www/html/sun.sh https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/sun.sh
  sudo wget -O /var/www/html/nextalarm.sh https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/nextalarm.sh
  sudo wget -O /var/www/html/dateconvert.sh https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/dateconvert.sh
  sudo wget -O /var/www/html/tasmota.sh https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/tasmota.sh
  sudo wget -O /var/www/html/daylymotion.php https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/daylymotion.php

  sudo apt install -y python3-gpiozero

  sudo apt install mpg123 at -y
  sudo usermod -a -G audio www-data
  sudo wget -O /var/www/html/mpc.php https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/mpc.php
  sudo wget -O /var/www/html/playRadio.sh https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/playRadio.sh
  sudo chmod +x /var/www/html/playRadio.sh

  # Set Volume manually
  # alsamixer

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
  
  ssh-copy-id pindadining
  ssh-copy-id pindakeuken
  ssh-copy-id localhost
  sudo cp .ssh/id_rsa /var/www/html/data/
  sudo chown www-data:www-data /var/www/html/data/id_rsa

  sudo wget -O /var/www/html/ssh.php https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/ssh.php

# cd /var/www/html
# sudo -u www-data php genkeys.php
# sudo rm /var/www/html/genkeys.php
# read -p "cp /var/www/html/data/public.key to your remote website and press Return to continue " key

fi
# Restart Raspberry Pi
sudo shutdown -r now
