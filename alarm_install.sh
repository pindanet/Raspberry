#!/bin/bash

LOCALE="nl_BE.UTF-8"
TIMEZONE="Europe/Brussels"
COUNTRY="BE"
NEW_HOSTNAME="rpialarm"

if [ $HOSTNAME != $NEW_HOSTNAME ]; then
# Configure  and upgrade
# https://github.com/raspberrypi-ui/rc_gui/blob/master/src/rc_gui.c#L23-L70
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
# Enable ssh
  sudo raspi-config nonint do_ssh 0
# Enable camera
  sudo raspi-config nonint do_camera 0
# Upgrade
  sudo apt update
  sudo apt dist-upgrade -y
  sudo apt autoremove -y

#sudo wget -P /var/www/html https://raw.githubusercontent.com/mourner/suncalc/master/suncalc.js

# Restart Raspberry Pi
  sudo shutdown -r now
  sleep 1m
fi
# SSH keydistribution
printf "\033[1;37;40mOn the main computer: ssh-copy-id -i ~/.ssh/id_rsa.pub pi@$NEW_HOSTNAME.local\n\033[0m" # Witte letters op zwarte achtergrond
printf "\033[1;37;40mOn the domotica controller: ssh-copy-id -i ~/.ssh/id_rsa.pub pi@$NEW_HOSTNAME.local\n\033[0m" # Witte letters op zwarte achtergrond
printf "\033[1;32;40mPress key to secure ssh.\033[0m" # Groene letters op zwarte achtergrond
read Keypress

#sudo sed -i "s/^.*PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config

cat > PindaNetBluetoothScan.timer <<EOF
[Unit]
Description=Bluetooth Detection Scan
[Timer]
OnBootSec=1min
OnUnitActiveSec=1min
Unit=PindaNetBluetoothScan.service
[Install]
WantedBy=multi-user.target
EOF
sudo mv PindaNetBluetoothScan.timer /etc/systemd/system/

cat > PindaNetBluetoothScan.service <<EOF
[Unit]
Description=Bluetooth Detection Scan
[Service]
Type=simple
ExecStart=/usr/sbin/PindaNetbluetoothscan.sh
EOF
sudo mv PindaNetBluetoothScan.service /etc/systemd/system/

sudo mkdir -p /var/PindaNet
sudo touch /var/PindaNet/bluetoothscandebug.txt
cat > PindaNetbluetoothscan.sh <<EOF
#!/bin/bash

absent="0"

tail -999 /var/PindaNet/bluetoothscandebug.txt > /var/PindaNet/bluetoothscandebug.trunc
mv /var/PindaNet/bluetoothscandebug.trunc /var/PindaNet/bluetoothscandebug.txt
if [ "\$absent" -gt "0" ]; then
  echo "Afwezig(\$absent) op \$(date)" >> /var/PindaNet/bluetoothscandebug.txt
else
  echo "Thuis(\$absent) op \$(date)" >> /var/PindaNet/bluetoothscandebug.txt
fi
EOF
sudo mv PindaNetbluetoothscan.sh /usr/sbin/
sudo chmod +x /usr/sbin/PindaNetbluetoothscan.sh

sudo systemctl daemon-reload
sudo systemctl enable PindaNetBluetoothScan.timer
sudo systemctl start PindaNetBluetoothScan.timer
systemctl list-timers

