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
# Configure WiFi
  read -p "WiFi SSID: " SSID
  read -p "WiFi Passphrase: " PASSPHRASE
  sudo raspi-config nonint do_wifi_ssid_passphrase "$SSID" "$PASSPHRASE"
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
sudo wget --output-document=/usr/sbin/PindaNetbluetoothscan.sh https://raw.githubusercontent.com/pindanet/Raspberry/master/alarm/PindaNetbluetoothscan.sh
sudo chmod +x /usr/sbin/PindaNetbluetoothscan.sh

sudo systemctl daemon-reload
sudo systemctl enable PindaNetBluetoothScan.timer
sudo systemctl start PindaNetBluetoothScan.timer
#systemctl list-timers

printf "\033[1;37;40mScan Bluetooth devices to disable alarm: hcitool scan\n\033[0m" # Witte letters op zwarte achtergrond
printf "\033[1;37;40mPut Bluetooth MAC adresses in script with: sudo nano /usr/sbin/PindaNetbluetoothscan.sh\n\033[0m" # Witte letters op zwarte achtergrond
printf "\033[1;32;40mPress key to secure ssh.\033[0m" # Groene letters op zwarte achtergrond
read Keypress

# Bluetooth OBEX Push file transfer
sudo apt install obexpushd -y
sudo sed -i /etc/systemd/system/dbus-org.bluez.service -e "s/^ExecStart=\/usr\/lib\/bluetooth\/bluetoothd.*/ExecStart=\/usr\/lib\/bluetooth\/bluetoothd -C/"
sudo systemctl daemon-reload
sudo systemctl restart bluetooth.service

cat > obexpush.service <<EOF
[Unit]
Description=OBEX Push service
After=bluetooth.service
Requires=bluetooth.service

[Service]
ExecStart=/usr/bin/obexpushd -B23 -o /bluetooth -n

[Install]
WantedBy=multi-user.target
EOF
sudo mv obexpush.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable obexpush.service
sudo systemctl start obexpush.service

printf "\033[1;37;40mActivate Bluetooth discovery on Controller with: sudo hciconfig hci0 piscan\n\033[0m" # Witte lette$
printf "\033[1;32;40mPress key to scan Bluetooth devices.\033[0m" # Groene letters op zwarte achtergrond
read Keypress

hcitool scan
read -p "Controller Bluetooth MAC_address: " MAC
(sleep 5; echo "scan on"; sleep 60; echo "pair $MAC"; sleep 1; echo "trust $MAC"; sleep 1; echo "exit") | sudo bluetoothctl

printf "\033[1;37;40mDeactivate Bluetooth discovery on Controller with: sudo hciconfig hci0 noscan\n\033[0m" # Witte lette$
printf "\033[1;37;40mSend file on Controller with: sudo obexftp --nopath --noconn --uuid none --bluetooth MAC_address_pialarm --channel 23 -p /home/pi/debug.txt\n\033[0m" # Witte lette$
printf "\033[1;32;40mPress key to continue.\033[0m" # Groene letters op zwarte achtergrond
read Keypress

# GPIO
# Buzzer
# BCM 23 - 2k2 - PN2222 (B)
#          Gnd - PN2222 (E)
#   Buzzer (-) - PN2222 (C)
#          +5V - Buzzer (+)
#https://startingelectronics.org/tutorials/arduino/modules/active-buzzer/
sudo apt install wiringpi -y
# Test buzzer
printf "\033[1;37;40mTest Buzzer\n\033[0m" # Witte lette$
gpio -g mode 23 out
gpio -g write 23 1
sleep 1
gpio -g write 23 0

# Relais BTE13
# BCM 16 - In1
#     5v - Vcc
#    Gnd - Gnd
printf "\033[1;37;40mRelais Off\n\033[0m" # Witte lette$
gpio -g mode 16 out
gpio -g write 16 1
