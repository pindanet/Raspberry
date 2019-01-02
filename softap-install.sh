#!/bin/bash
# wget https://raw.githubusercontent.com/pindanet/Raspberry/master/softap-install.sh

KEYMAP="be"
LOCALE="nl_BE.UTF-8"
TIMEZONE="Europe/Brussels"
COUNTRY="BE"
NEW_HOSTNAME="snt-guest"

# Change Keyboard
sudo raspi-config nonint do_configure_keyboard "$KEYMAP"

# Change locale
sudo raspi-config nonint do_change_locale "$LOCALE"

# Change timezone
sudo raspi-config nonint do_change_timezone "$TIMEZONE"

# Change WiFi country
sudo raspi-config nonint do_wifi_country "$COUNTRY"

# Change hostname
sudo raspi-config nonint do_hostname "$NEW_HOSTNAME"

# Change password
sudo raspi-config nonint do_change_pass

# enable ssh
sudo raspi-config nonint do_ssh 0

# Upgrade
sudo apt update
sudo apt dist-upgrade -y
sudo apt autoremove -y

# SoftAP
sudo apt install hostapd bridge-utils -y
sudo systemctl stop hostapd

echo "denyinterfaces wlan0" | sudo tee -a /etc/dhcpcd.conf
echo "denyinterfaces eth0" | sudo tee -a /etc/dhcpcd.conf
sudo brctl addbr br0
sudo brctl addif br0 eth0
echo "# Bridge setup" | sudo tee -a /etc/network/interfaces
echo "auto br0" | sudo tee -a /etc/network/interfaces
echo "iface br0 inet manual" | sudo tee -a /etc/network/interfaces
echo "bridge_ports eth0 wlan0" | sudo tee -a /etc/network/interfaces

cat > hostapd.conf <<EOF
interface=wlan0
bridge=br0
#driver=nl80211
ssid=snt-guest
country_code=BE
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=snt-guest
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF
sudo mv hostapd.conf /etc/hostapd/hostapd.conf

sudo systemctl disable hostapd
cat > hostapd.service <<EOF
[Unit]
Description=advanced IEEE 802.11 management
Wants=network-online.target
After=network.target network-online.target

[Service]
ExecStart=/usr/sbin/hostapd  /etc/hostapd/hostapd.conf
PIDFile=/run/hostapd.pid
RestartSec=5
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
sudo mv hostapd.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable hostapd.service

#sudo sed -i 's/^#DAEMON_OPTS=""/DAEMON_OPTS="\/etc\/hostapd\/hostapd.conf"/' /etc/default/hostapd

#sudo sed -i '/^#.*net\.ipv4\.ip_forward=/s/^#//' /etc/sysctl.conf
#sudo sed -i '/^#.*net\.ipv6\.conf\.all\.forwarding=/s/^#//' /etc/sysctl.conf

# Webserver
sudo apt install apache2 php libapache2-mod-php -y
sudo systemctl restart apache2.service

sudo wget -O /var/www/html/index.html https://raw.githubusercontent.com/pindanet/Raspberry/master/softap/index.html
sudo wget -O /var/www/html/pinda.png https://raw.githubusercontent.com/pindanet/Raspberry/master/softap/pinda.png
sudo wget -O /var/www/html/koffer.png https://raw.githubusercontent.com/pindanet/Raspberry/master/softap/koffer.png
sudo wget -O /var/www/html/brugge.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/softap/brugge.svg
sudo wget -O /var/www/html/system.php https://raw.githubusercontent.com/pindanet/Raspberry/master/softap/system.php

echo "www-data ALL = NOPASSWD: /sbin/shutdown -h now" | sudo tee -a /etc/sudoers

# Automount
echo 'ACTION=="add", KERNEL=="sd*", TAG+="systemd", ENV{SYSTEMD_WANTS}="usbstick-handler@%k"' | sudo tee /etc/udev/rules.d/usbstick.rules
sudo wget -O /lib/systemd/system/usbstick-handler@.service https://raw.githubusercontent.com/pindanet/Raspberry/master/softap/usbstick-handler
sudo wget -O /usr/local/bin/automount https://raw.githubusercontent.com/pindanet/Raspberry/master/softap/automount
sudo chmod +x /usr/local/bin/automount
sudo apt install exfat-fuse -y

# Share automounted USB-sticks
sudo apt install samba samba-common-bin -y
echo "[Media]" | sudo tee -a /etc/samba/smb.conf
echo "  comment = SoftAP-Network-Attached Storage" | sudo tee -a /etc/samba/smb.conf
echo "  path = /media" | sudo tee -a /etc/samba/smb.conf
echo "  public = yes" | sudo tee -a /etc/samba/smb.conf
echo "  force user = pi" | sudo tee -a /etc/samba/smb.conf
sudo systemctl restart smbd.service

# Restart Raspberry Pi
sudo shutdown -r now
