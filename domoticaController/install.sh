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
# Touch Display (https://www.raspberrypi.com/documentation/accessories/display.html)
# 5v (2) > Vcc
# GND (14) > Gnd

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
echo '  while [ "$(hostname -I)" = "" ]; do' >> .bashrc
echo '    echo "Waiting for the network..."' >> .bashrc
echo '    sleep 1' >> .bashrc
echo '  done' >> .bashrc
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
# --kiosk can be replaced by --fullscreen
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

sudo chmod +x /var/www/html/ds18b20.sh
sudo tee /etc/systemd/system/ds18b20.timer > /dev/null <<EOF
[Unit]
Description=Read DS18B20 Temperature sensor
[Timer]
OnBootSec=1min
OnUnitActiveSec=1min
Unit=ds18b20.service
[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/ds18b20.service > /dev/null <<EOF
[Unit]
Description=Read DS18B20 Temperature sensor
[Service]
Type=simple
ExecStart=/var/www/html/ds18b20.sh
EOF

sudo systemctl daemon-reload
sudo systemctl enable ds18b20.timer
sudo systemctl start ds18b20.timer

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

# Restart Raspberry Pi
sudo shutdown -r now
