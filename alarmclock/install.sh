#!/bin/bash
# For Raspberry Pi OS Bookworm Lite
# wget https://github.com/pindanet/Raspberry/raw/master/alarmclock/install.sh
# bash install.sh

router="mymodem.home"

# Hardware
# Touch Screen power
# 5v Power (4) to 5v (Red)
# Gnd (14) to Gnd (Black)

# Shutdown/Reboot button
# Brown to GPIO3 (5)
# Brown to Gnd (6)

# DS18B20 Temperature Sensor Power
# GPIO 17 (11) (switchable 3,3 V) to Vdd (Rood)
# GPIO4 (7) to Data (Geel) to 4k7 naar 3,3 V (Orange)(GPIO27)(13)
# GND (9) to GND (Zwart)
powergpio=17

# Start/Stop Radio button
# Gray to GPIO5 (29)
# Black to Gnd (30)
radiogpio=5

# HiFiBerry MiniAmp
# GPIO18 (12) Sound Interface
# GPIO19 (35) Sound Interface
# GPIO20 (38) Sound Interface
# GPIO21 (40) Sound Interface
# GPIO16 (36) Mute Power Stage
# GPIO26 (37) Shutdown Power Stage
echo 'dtoverlay=hifiberry-dac' | sudo tee -a /boot/firmware/config.txt

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
sudo apt install mpg123 -y

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
# Enable set touchscreen brightness
sudo usermod -a -G video www-data
# Enable Radio and MP3 play
#sudo usermod -a -G audio www-data

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
# PullUp Input Radio Button
/usr/bin/pinctrl set $radiogpio ip pu
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
# Check WiFi connection
if ! ping -c 1 $router; then
  echo "Restart NetworkManager"
  systemctl restart NetworkManager.service
  sleep 10
fi
# Check Avahi conflict
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

# Play Radio stream with ICY-META (stderr) output logging
cat > PindaNetRadio.path <<EOF
[Unit]
Description=Monitor the /var/www/html/data/radio.cmd file for changes
[Path]
PathModified=/var/www/html/data/radio.cmd
Unit=PindaNetRadio.service
[Install]
WantedBy=multi-user.target
EOF
sudo mv PindaNetRadio.path /etc/systemd/system/

cat > PindaNetRadio.service <<EOF
[Unit]
Description=Execute the script with Radio commands
[Service]
ExecStart=/bin/bash /var/www/html/PindaNetRadio.sh
EOF
sudo mv PindaNetRadio.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable PindaNetRadio.path
sudo systemctl start PindaNetRadio.path

echo "Ready, please restart"
echo "====================="
echo "sudo shutdown -r now"
