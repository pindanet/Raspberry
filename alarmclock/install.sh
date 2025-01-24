#!/bin/bash
# For Raspberry Pi OS Bookworm Lite
# wget https://github.com/pindanet/Raspberry/raw/master/alarmclock/install.sh
# bash install.sh

# Hardware
# Shutdown/Reboot button
# Gray to GPIO3 (5)
# Black to Gnd (6)
# DS18B20 Temperature Sensor Power
# GPIO4 (7) to Data (Yellow) to 4k7 to 3,3 V (Red)(GPIO17)
# GND (9) to GND (Black)
# GPIO17 (11) to Vdd (Redd)
powergpio=17

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
sudo apt install labwc seatd xdg-user-dirs libgl1-mesa-dri -y
mkdir -p .config/labwc
sudo raspi-config nonint do_boot_behaviour "B2"  # https://www.raspberrypi.com/documentation/computers/configuration.html
echo 'if [[ "$(who am i)" == *\(*\) ]]; then' >> .bashrc
echo '  echo "SSH"' >> .bashrc
echo 'else' >> .bashrc
echo '  labwc' >> .bashrc
echo 'fi' >> .bashrc
# Optional: Disable Touch
echo 'disable_touchscreen=1' | sudo tee -a /boot/firmware/config.txt

grep ^dtoverlay=w1-gpio /boot/firmware/config.txt
if [ $? == 1 ]; then
  echo "Activate 1-Wire and DS18B20 Temperature Sensor"
  # Activate 1-Wire
  echo 'dtoverlay=w1-gpio' | sudo tee -a /boot/firmware/config.txt
  # Activate DS18B20 Temperature Sensor
  echo 'w1-gpio' | sudo tee -a /etc/modules
  echo 'w1-therm' | sudo tee -a /etc/modules
fi

echo "Shutdown/Boot button"
echo "===================="
echo 'dtoverlay=gpio-shutdown' | sudo tee -a /boot/firmware/config.txt

echo "Install webserver"
echo "================="
sudo apt install apache2 libapache2-mod-fcgid php-bcmath php-bz2 php-common php-curl php-xml php-gd php-php-gettext php-gmp php-ldap php-mbstring php-mysql php-odbc php-pgsql php-snmp php-soap php-sqlite3 php-tokenizer libapache2-mod-php -y

if test -f master.zip; then rm master.zip; fi
echo "Download and extract Github Repository"
echo "======================================"
wget https://github.com/pindanet/Raspberry/archive/refs/heads/master.zip
unzip -q master.zip
rm master.zip
sudo cp -r Raspberry-master/alarmclock/var/www/html/* /var/www/html/
rm -r Raspberry-master/

sudo chown www-data:www-data /var/www/html/data
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
/bin/chromium --remote-debugging-port=9222 --kiosk --ozone-platform=wayland --start-maximized --noerrdialogs --disable-infobars --enable-features=OverlayScrollbar  http://localhost/ &
# Give Chromium time to start
sleep 30
# Check if Chromium is running
until ps -ax | grep kiosk | grep -v grep
do
  # After a hostname change, chromium refuses to start, correct this
  rm -rf $HOME/.config/chromium/Singleton*
  # Restart chromium
  /bin/chromium --remote-debugging-port=9222 --kiosk --ozone-platform=wayland --start-maximized --noerrdialogs --disable-infobars --enable-features=OverlayScrollbar  http://localhost/ &
  sleep 30
done
EOF
echo "/usr/bin/bash ~/PindaNetAutostart.sh &" >> .config/labwc/autostart

echo "Configure SSH remote login"
echo "=========================="
ssh-keygen
# ssh-copy-id -i $HOME/.ssh/id_rsa.pub $(ls /home)@localhost
# sudo cp .ssh/id_rsa /var/www/html/data/
# sudo chown www-data:www-data /var/www/html/data/id_rsa

# Check Avahi hostname
cat > checkAvahi.sh <<EOF
#!/bin/bash
if [ \$(avahi-resolve -a \$(ip -4 addr show wlan0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}') | cut -f 2) != \${HOSTNAME}.local ]; then
  echo Restart avahi
  systemctl restart avahi-daemon.service
fi
EOF
sudo mv checkAvahi.sh /usr/sbin/
sudo chmod +x /usr/sbin/checkAvahi.sh

cat > checkAvahi.timer <<EOF
[Unit]
Description=Check Avahi hostname
[Timer]
OnBootSec=5min
OnUnitActiveSec=1h
Unit=checkAvahi.service
[Install]
WantedBy=multi-user.target
EOF
sudo mv checkAvahi.timer /etc/systemd/system/

cat > checkAvahi.service <<EOF
[Unit]
Description=Check Avahi hostname
[Service]
Type=simple
ExecStart=/usr/sbin/checkAvahi.sh
EOF
sudo mv checkAvahi.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable checkAvahi.timer
sudo systemctl start checkAvahi.timer
# systemctl list-timers

echo "Ready, please restart"
echo "====================="
echo "sudo shutdown -r now"
