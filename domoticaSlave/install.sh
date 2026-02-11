#!/bin/bash
# For Raspberry Pi OS Lite (64-bit) Trixie
# wget https://github.com/pindanet/Raspberry/raw/master/domoticaSlave/install.sh
# bash install.sh

router="mymodem.home"

# Hardware
# DS18B20 Temperature Sensor Power
# GPIO17 (11) naar Vdd (Rood)
powergpio=17
pir1gpio=14
pir2gpio=24

# Test if executed with Bash
case "$BASH_VERSION" in
  "") echo "usage: bash install.sh"
      exit;;
esac

# Print RPI Model
cat /sys/firmware/devicetree/base/model
echo

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
echo 'else' >> .bashrc
echo '  labwc' >> .bashrc
echo 'fi' >> .bashrc
# Rotate the Touch Display 270°
sudo apt install wlr-randr -y
echo "wlr-randr --output DSI-1 --transform 270" >> .config/labwc/autostart
# Rotate Touch 270°
sudo sed -i 's/^display_auto_detect=1/#&/' /boot/firmware/config.txt
sudo sed -i '/display_auto_detect=1/adtoverlay=vc4-kms-dsi-7inch,invx,swapxy' /boot/firmware/config.txt
# Optional: Rotate the console
sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.ori
sudo sed -i ' 1 s/.*/& video=DSI-1:800x480@60,rotate=270/' /boot/firmware/cmdline.txt
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
echo 'dtoverlay=gpio-shutdown,gpio_pin=26' | sudo tee -a /boot/firmware/config.txt

echo "Install webserver"
echo "================="
sudo apt install apache2 libapache2-mod-fcgid php-bcmath php-bz2 php-common php-curl php-xml php-gd php-gmp php-ldap php-mbstring php-mysql php-odbc php-pgsql php-snmp php-soap php-sqlite3 php-tokenizer libapache2-mod-php -y
sudo apt install imagemagick -y

if test -f master.zip; then rm master.zip; fi
echo "Download and extract Github Repository"
echo "======================================"
wget https://github.com/pindanet/Raspberry/archive/refs/heads/master.zip
unzip -q master.zip
rm master.zip
sudo cp -r Raspberry-master/domoticaSlave/var/www/html/* /var/www/html/
rm -r Raspberry-master/

sudo mkdir -p /var/www/html/motion/
sudo chown www-data:www-data /var/www/html/motion
sudo chown www-data:www-data /var/www/html/data

sudo usermod -a -G gpio www-data
sudo usermod -a -G video www-data

echo "Autostart fullscreen browser" # https://core-electronics.com.au/guides/raspberry-pi-kiosk-mode-setup/
echo "============================"
sudo apt install chromium -y
echo "/usr/bin/bash /var/www/html/PindaNetAutostart.sh &" >> .config/labwc/autostart

echo "Activate daily update"
echo "====================="

sudo chmod +x /var/www/html/PindaNetUpdate.sh
sudo mv /var/www/html/PindaNetUpdate.timer /etc/systemd/system/
sudo mv /var/www/html/PindaNetUpdate.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now PindaNetUpdate.timer
# Check Upgrade history
# tail -3 /var/log/apt/history.log

# Disable Avahi, use router DNS
sudo systemctl disable --now avahi-daemon.service

# Disable NetworkManager mDNS (Avahi conflict)
# https://feeding.cloud.geek.nz/posts/proper-multicast-dns-handling-network-manager-systemd-resolved/
#activeConnection=$(nmcli con show --active | grep -v loopback | tail -1 | awk '{print $1}')
#sudo nmcli connection modify $activeConnection connection.mdns 1
#nmcli connection show $activeConnection | grep "connection.mdns"

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
# systemctl list-timers

# PHP Motion
sudo mv /var/www/html/PindaPHPMotion.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now PindaPHPMotion.service

# PHP Websocket
sudo mv /var/www/html/PindaWebsocket.service /etc/systemd/system/
sed "s/User=dany/User=$USER/" /etc/systemd/system/PindaWebsocket.service
sed "s/Group=dany/Group=$(id -gn)/" /etc/systemd/system/PindaWebsocket.service
sudo systemctl daemon-reload
sudo systemctl enable --now PindaWebsocket.service

cat <<"EOF"
Update the following data files from a backup:
sudo mv conf.json conf.php.json luxmax temp.log /var/www/html/data/
Restore the data files owner and group
sudo chown -R www-data:www-data /var/www/html/data/*
EOF

echo "Ready, please restart"
echo "====================="
echo "sudo systemctl reboot"
