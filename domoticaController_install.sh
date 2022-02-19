#!/bin/bash
# For Raspbian Buster Lite
# wget https://github.com/pindanet/Raspberry/raw/master/domoticaController_install.sh
# bash domoticaController_install.sh

# ToDo
# Activate Serial Hardware
# Activate PiCamera

# Hardware
# BME280 I2C Temperature and Pressure Sensor
# 3v3 - Vin (Bordeau)
# Gnd (6) - Gnd (Gray)
# BCM 3 (SCL) (5) - SCK (White)
# BCM 2 (SDA) (3) - SDI (Blue)

# TLS2591 I2C High Dynamic Range Digital Light Sensor
# 3v3 (1) () - Vin (Bordeau)
# Gnd (6) > Gnd (6) (Gray)
# BCM 3 (SCL) (5) - SCL (White)
# BCM 2 (SDA) (3) - SDA (Blue)

# PIR
# BCM 4 (7) - output (Brown)
# 5V (4) - Vdd (Red)
# Gnd (9) - Gnd (Black)

# Test if executed with Bash
case "$BASH_VERSION" in
  "") echo "usage: bash domoticaController_install.sh"
      exit;;
esac

KEYMAP="be"
LOCALE="nl_BE.UTF-8"
TIMEZONE="Europe/Brussels"
COUNTRY="BE"
FULLCALENDAR="4.4.0"

if [ $USER == "pi" ]; then
  # rotate Touchscreen
  #echo 'lcd_rotate=2' | sudo tee -a /boot/config.txt
  
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
OnCalendar=*-*-* 23:10:00
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
  echo "chromium-browser --incognito --kiosk --check-for-update-interval=31536000 http://localhost/staand.html &" >> $HOME/.config/openbox/autostart

  sudo wget -O /var/www/html/index.html https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/index.html
  sudo wget -O /var/www/html/index.css https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/index.css
  sudo mkdir /var/www/html/emoji/
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
  sudo apt-get -y install python-pip
  sudo pip install bme280
  
  sudo wget -O /var/www/html/tls2591.py https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/tls2591.py
  
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
  
  sudo wget -O /var/www/html/data/thermostat https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/data/thermostat
  sudo wget -O /usr/sbin/PindaNetDomo.sh https://github.com/pindanet/Raspberry/raw/master/domoticaController/usr/sbin/PindaNetDomo.sh
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

  sudo wget -O /var/www/html/daylymotion.php https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/daylymotion.php

  sudo apt install -y python3-gpiozero

  sudo apt install mpc mpd at -y
  sudo usermod -a -G audio www-data
  sudo wget -O /var/www/html/mpc.php https://raw.githubusercontent.com/pindanet/Raspberry/master/domoticaController/var/www/html/mpc.php
  mpc add http://icecast.vrtcdn.be/radio1-high.mp3
  mpc add http://icecast.vrtcdn.be/ra2wvl-high.mp3
  mpc add http://icecast.vrtcdn.be/klara-high.mp3
  mpc add http://icecast.vrtcdn.be/klaracontinuo-high.mp3
  mpc add http://icecast.vrtcdn.be/stubru-high.mp3
  mpc add http://icecast.vrtcdn.be/mnm-high.mp3
  mpc add http://icecast.vrtcdn.be/mnm_hits-high.mp3
  mpc add http://progressive-audio.lwc.vrtcdn.be/content/fixed/11_11niws-snip_hi.mp3 
  mpc add http://icecast.vrtcdn.be/ketnetradio-high.mp3
  mpc add http://streams.crooze.fm:8000
  mpc add http://stream.vbro.be:9100/vbro
  mpc add http://icecast-qmusic.cdp.triple-it.nl/JOEfm_be_live_128.mp3
  mpc add http://icecast-qmusic.cdp.triple-it.nl/Qmusic_be_live_128.mp3
  mpc add https://playerservices.streamtheworld.com/api/livestream-redirect/WILLY.mp3
  # USB sound
  sudo mv /etc/mpd.conf /etc/mpd.conf.ori
  sudo chmod +r /etc/mpd.conf.ori
  while IFS='' read -r LINE || [ -n "${LINE}" ]; do
    echo "${LINE}" | sudo tee -a /etc/mpd.conf
    if [ "${LINE}" == "audio_output {" ]; then
#      echo "        device          \"hw:1,0\""  | sudo tee -a /etc/mpd.conf
#      echo "        mixer_type      \"software\""  | sudo tee -a /etc/mpd.conf
      echo "        type          \"alsa\""  | sudo tee -a /etc/mpd.conf
      echo "        name          \"ALSADevice\""  | sudo tee -a /etc/mpd.conf
      echo "        mixer_control      \"Digital\""  | sudo tee -a /etc/mpd.conf
    fi
  done < /etc/mpd.conf.ori
  sudo chmod +r /etc/mpd.conf
  
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
