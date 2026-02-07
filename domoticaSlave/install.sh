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
mkdir -p .config/kanshi
echo '{' > .config/kanshi/config
echo '  output DSI-1 transform 270' >> .config/kanshi/config
echo '}' >> .config/kanshi/config
echo "kanshi &" >> .config/labwc/autostart
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
cat > PindaNetAutostart.sh <<EOF
#!/bin/bash
# Disable Power led
echo 0 | sudo tee /sys/class/leds/PWR/brightness
# Disable Activity led
echo none | sudo tee /sys/class/leds/ACT/trigger
# Activate DS18B20 temperature sensor power (Reset)
/usr/bin/pinctrl set $powergpio op dh
# PullUp 1-wire Data
/usr/bin/pinctrl set 4 ip pu
# PullDown PIR1 and PIR2
/usr/bin/pinctrl set $pir1gpio,$pir2gpio ip pd
# Autostart Chromium in Kiosk & Debug mode
/bin/chromium --remote-debugging-port=9222 --kiosk --disable-extensions --noerrdialogs --disable-infobars --enable-features=OverlayScrollbar  http://localhost/ &
# Give Chromium time to start
sleep 30
# Check if Chromium is running
until ps -ax | grep kiosk | grep -v grep
do
  # After a hostname change, chromium refuses to start, correct this
  rm -rf $HOME/.config/chromium/Singleton*
  # Restart chromium
  /bin/chromium --remote-debugging-port=9222 --kiosk --disable-extensions --noerrdialogs --disable-infobars --enable-features=OverlayScrollbar  http://localhost/ &
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

# Disable NetworkManager mDNS (Avahi conflict)
# https://feeding.cloud.geek.nz/posts/proper-multicast-dns-handling-network-manager-systemd-resolved/
activeConnection=$(nmcli con show --active | grep -v loopback | tail -1 | awk '{print $1}')
sudo nmcli connection modify $activeConnection connection.mdns 1
nmcli connection show $activeConnection | grep "connection.mdns"
# Should also work
#sudo tee -a /etc/NetworkManager/NetworkManager.conf > /dev/null <<EOF
#[connection]
#connection.mdns=1
#EOF

# Check Avahi hostname
sudo apt install avahi-utils -y
cat > checkAvahi.sh <<EOF
#!/bin/bash
# Check WiFi connection
if ! ping -c 1 $router; then
  echo "\$(date) Restart Network" >> /var/www/html/data/debug.txt
#  systemctl restart NetworkManager.service
  /sbin/shutdown -r now
  sleep 10
fi
# Check Avahi conflict
if [ \$(avahi-resolve -a \$(ip -4 addr show wlan0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}') | cut -f 2) != \${HOSTNAME}.local ]; then
  echo Restart avahi
  systemctl restart avahi-daemon.socket
fi
EOF
sudo mv checkAvahi.sh /usr/sbin/
sudo chmod +x /usr/sbin/checkAvahi.sh

cat > checkAvahi.timer <<EOF
[Unit]
Description=Check Avahi hostname
[Timer]
OnBootSec=1h
OnUnitActiveSec=1h
Unit=checkAvahi.service
[Install]
WantedBy=basic.target
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

sudo chmod +x /var/www/html/motion.sh

cat > PindaMotion.timer <<EOF
[Unit]
Description=Take picture
[Timer]
OnBootSec=5min
OnUnitActiveSec=1min
Unit=PindaMotion.service
[Install]
WantedBy=multi-user.target
EOF
sudo mv PindaMotion.timer /etc/systemd/system/

cat > PindaMotion.service <<EOF
[Unit]
Description=Take picture
[Service]
Type=simple
ExecStart=/var/www/html/motion.sh
EOF
sudo mv PindaMotion.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable PindaMotion.timer
sudo systemctl start PindaMotion.timer

# PHP Motion
sudo tee /etc/systemd/system/PindaPHPMotion.service > /dev/null <<EOF
[Unit]
Description=PHP Motion Service
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/php /var/www/html/motion.php
Restart=always
RestartSec=5

User=www-data
Group=www-data

WorkingDirectory=/var/www/html/
ExecStop=/bin/kill \$MAINPID

[Install]
WantedBy=network-online.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable PindaPHPMotion.service
sudo systemctl start PindaPHPMotion.service

# PHP Websocket
sudo tee /etc/systemd/system/PindaWebsocket.service > /dev/null <<EOF
[Unit]
Description=PHP Websocket Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/php /var/www/html/websocket.php
Restart=always
RestartSec=5

User=$USER
Group=$(id -gn)

ExecStop=/bin/kill \$MAINPID

[Install]
WantedBy=network-online.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable PindaWebsocket.service
sudo systemctl start PindaWebsocket.service

#sudo chmod +x /var/www/html/ds18b20.sh
#sudo tee /etc/systemd/system/ds18b20.timer > /dev/null <<EOF
#[Unit]
#Description=Read DS18B20 Temperature sensor
#[Timer]
#OnBootSec=1min
#OnUnitActiveSec=1min
#Unit=ds18b20.service
#[Install]
#WantedBy=multi-user.target
#EOF

#sudo tee /etc/systemd/system/ds18b20.service > /dev/null <<EOF
#[Unit]
#Description=Read DS18B20 Temperature sensor
#[Service]
#Type=simple
#ExecStart=/var/www/html/ds18b20.sh
#EOF

#sudo systemctl daemon-reload
#sudo systemctl enable ds18b20.timer
#sudo systemctl start ds18b20.timer

# systemctl list-timers

echo "Ready, please restart"
echo "====================="
echo "sudo shutdown -r now"
