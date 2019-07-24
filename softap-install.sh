#!/bin/bash
# For Raspbian Stretch Lite
# wget https://raw.githubusercontent.com/pindanet/Raspberry/master/softap-install.sh

# ToDo

KEYMAP="be"
LOCALE="nl_BE.UTF-8"
TIMEZONE="Europe/Brussels"
COUNTRY="BE"

if [ $USER == "pi" ]; then

  read -p "Enter the new hostname [snt-guest]: " NEW_HOSTNAME
  NEW_HOSTNAME=${NEW_HOSTNAME:-snt-guest}

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

  # Change user
  read -p "Enter the new user [dany]: " NEW_USER
  NEW_USER=${NEW_USER:-dany}
  sudo adduser --disabled-password --gecos "" "$NEW_USER"
  sudo passwd "$NEW_USER"
  sudo usermod -a -G adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,netdev,spi,i2c,gpio "$NEW_USER"
  
  # Continue after reboot
  sudo mv softap-install.sh /home/$NEW_USER/
  echo "bash softap-install.sh" | sudo tee -a /home/$NEW_USER/.bashrc

  echo "Login as $NEW_USER"
  read -p "Press Return to Restart " key

else
  # Disable Continue after reboot
  sed -i '/^bash softap-install.sh/d' .bashrc
  
  # Remove pi user
  sudo userdel -r pi
  
  # Webserver
  sudo apt install apache2 php libapache2-mod-php -y
  sudo systemctl restart apache2.service

  sudo wget -O /var/www/html/index.html https://raw.githubusercontent.com/pindanet/Raspberry/master/softap/index.html
  sudo sed -i.ori "s/snt-guest/$HOSTNAME/g" /var/www/html/index.html
  sudo wget -O /var/www/html/pinda.png https://raw.githubusercontent.com/pindanet/Raspberry/master/softap/pinda.png
  sudo wget -O /var/www/html/koffer.png https://raw.githubusercontent.com/pindanet/Raspberry/master/softap/koffer.png
  sudo wget -O /var/www/html/brugge.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/softap/brugge.svg
  sudo wget -O /var/www/html/fileshare.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/softap/fileshare.svg
  sudo wget -O /var/www/html/guest_wifi.svg https://raw.githubusercontent.com/pindanet/Raspberry/master/softap/guest_wifi.svg
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
  echo "  force user = $USER" | sudo tee -a /etc/samba/smb.conf
  sudo systemctl restart smbd.service
  # Patch for Windows Web Service Discovery
  wget https://raw.githubusercontent.com/christgau/wsdd/master/src/wsdd.py
  sudo mv wsdd.py /usr/bin/wsdd
  sudo chmod +x /usr/bin/wsdd
  wget https://raw.githubusercontent.com/christgau/wsdd/master/etc/systemd/wsdd.service
  sudo mv wsdd.service /etc/systemd/system/
  sudo sed -i.ori "s/User=nobody/User=$USER/g" /etc/systemd/system/wsdd.service
  UserGroup=$(id -gn)
  sudo sed -i "s/Group=nobody/Group=$UserGroup/g" /etc/systemd/system/wsdd.service
  sudo systemctl daemon-reload
  sudo systemctl start wsdd.service
  sudo systemctl enable wsdd.service

  # SoftAP
  while true; do
    read -s -p "WiFi Access Point Password: " password
    echo
    read -s -p "WiFi Access Point Password (again): " password2
    echo
    [ "$password" = "$password2" ] && break
    echo "Please try again"
  done
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
ssid=$HOSTNAME
country_code=BE
hw_mode=g
channel=7
# Wireless Multimedia Extension/Wi-Fi Multimedia needed for
# IEEE 802.11n (HT)
wmm_enabled=1
# 1 to enable 802.11n
ieee80211n=1
ht_capab=[HT20][SHORT-GI-20][DSSS_CK-HT40]
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$password
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

fi
# Restart Raspberry Pi
sudo shutdown -r now
