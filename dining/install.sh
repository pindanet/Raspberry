#!/bin/bash
# For Raspberry Pi OS Bookworm Lite
# wget https://github.com/pindanet/Raspberry/raw/master/dining/install.sh
# bash install.sh

# Hardware

# DS18B20 Temperature Sensor
# GPIO4 (7) naar Data (Geel) naar 4k7 naar 3,3 V (Rood)(GPIO17)
# GND (9) naar GND (Zwart)
# GPIO17 (11) naar Vdd (Rood)
powergpio=17

# Shutdown/Boot button
# Gnd (39) > Gnd (Black)
# GPIO26 > Shutdown button (white)
# GPIO3 > Boot button (Gray)

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
echo 'dtoverlay=gpio-shutdown,gpio_pin=26' | sudo tee -a /boot/firmware/config.txt

echo "Install webserver"
echo "================="
sudo apt install apache2 libapache2-mod-fcgid php-bcmath php-bz2 php-common php-curl php-xml php-gd php-php-gettext php-gmp php-ldap php-mbstring php-mysql php-odbc php-pgsql php-snmp php-soap php-sqlite3 php-tokenizer libapache2-mod-php -y

if test -f master.zip; then rm master.zip; fi
echo "Download and extract Github Repository"
echo "======================================"
wget https://github.com/pindanet/Raspberry/archive/refs/heads/master.zip
unzip -q master.zip
rm master.zip
sudo cp -r Raspberry-master/dining/var/www/html/* /var/www/html/
rm -r Raspberry-master/

sudo chown www-data:www-data /var/www/html/data

sudo usermod -a -G gpio www-data
sudo usermod -a -G video www-data

echo "Autostart fullscreen video"
echo "=========================="
sudo apt install mpv -y
echo "/usr/bin/bash /var/www/html/autostart.sh &" >> .config/labwc/autostart

echo "Configure SSH remote login"
echo "=========================="
ssh-keygen
# ssh-copy-id -i $HOME/.ssh/id_rsa.pub $(ls /home)@localhost
# sudo cp .ssh/id_rsa /var/www/html/data/
# sudo chown www-data:www-data /var/www/html/data/id_rsa

echo "Activate daily update"
echo "====================="

cat > PindaNetUpdate.sh <<EOF
#!/bin/bash
sudo dpkg --configure -a
apt-get clean
apt autoremove -y
apt-get update
apt-get upgrade -y
shutdown -r now
EOF
sudo mv PindaNetUpdate.sh /usr/sbin/
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
# journalctl -u checkAvahi.service

#sudo apt install wayout
sudo apt install build-essential meson ninja-build scdoc git wayland-protocols libwayland-dev libcairo-dev libpango1.0-dev
git clone https://git.sr.ht/~proycon/wayout
cd wayout
meson build
ninja -C build
sudo ninja -C build install
cd

echo "Ready, please restart"
echo "====================="
echo "sudo shutdown -r now"
