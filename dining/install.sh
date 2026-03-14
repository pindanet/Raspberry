#!/bin/bash
# For Raspberry Pi OS Trixie Lite
# wget https://github.com/pindanet/Raspberry/raw/master/dining/install.sh
# bash install.sh

# ToDo
# ====
# add video=HDMI-A-1:1920x1200M@60 at start of line in /boot/firmware/cmdline.txt + space, to force screen without active monitor

router="mymodem.home"

# DS18B20 Temperature Sensor
# GPIO4 (7) naar Data (Geel) naar 4k7 naar 3,3 V (Rood)(GPIO17)
# GND (9) naar GND (Zwart)
# GPIO17 (11) naar Vdd (Rood)
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
fi

echo "Shutdown/Boot button"
echo "===================="
echo 'dtoverlay=gpio-shutdown' | sudo tee -a /boot/firmware/config.txt

#echo "Install webserver"
#echo "================="
#sudo apt install apache2 libapache2-mod-fcgid php-bcmath php-bz2 php-common php-curl php-xml php-gd php-php-gettext php-gmp php-ldap php-mbstring php-mysql php-odbc php-pgsql php-snmp php-soap php-sqlite3 php-tokenizer libapache2-mod-php -y

if test -f master.zip; then rm master.zip; fi
echo "Download and extract Github Repository"
echo "======================================"
wget https://github.com/pindanet/Raspberry/archive/refs/heads/master.zip
unzip -q master.zip
rm master.zip
sudo mkdir -p /var/www/html
sudo cp -r Raspberry-master/dining/var/www/html/* /var/www/html/
rm -r Raspberry-master/

#sudo chown www-data:www-data /var/www/html/data

#sudo usermod -a -G gpio www-data
#sudo usermod -a -G video www-data

echo "Autostart fullscreen video"
echo "=========================="
#sudo apt install mpv -y
sudo apt install vlc -y
echo "/usr/bin/bash /var/www/html/autostart.sh &" >> .config/labwc/autostart

#echo "Configure SSH remote login"
#echo "=========================="
#ssh-keygen
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

# Disable Avahi, use router DNS
sudo systemctl disable --now avahi-daemon.service

# Check WiFi connection
#sudo apt install avahi-utils -y
sudo chmod +x /var/www/html/checkWiFi.sh
prompt="Enter your router name (ex: mymodem.home):"
while [ "$prompt" != "OK" ]; do
  read -p "$prompt " router;
  if ! ping -c 1 $router; then
    prompt="Network name does not exist or is unreachable. Try again:"
  else
    prompt="OK"
  fi
done
sudo sed -i "s/mymodem.home/$router/" /var/www/html/checkWiFi.sh
sudo mv /var/www/html/checkWiFi.timer /etc/systemd/system/
sudo mv /var/www/html/checkWiFi.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable --now checkWiFi.timer

sudo chmod +x /var/www/html/ds18b20.sh
sudo mv /var/www/html/ds18b20.timer /etc/systemd/system/
sudo mv /var/www/html/ds18b20.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable --now ds18b20.timer

# systemctl list-timers
# journalctl -u ds18b20.service

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
