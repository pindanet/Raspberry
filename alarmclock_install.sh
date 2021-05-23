#!/bin/bash
# For Raspbian Buster Lite
# wget https://github.com/pindanet/Raspberry/raw/master/alarmclock_install.sh
# bash alarmclock_install.sh

# ToDo

# Test if executed with Bash
case "$BASH_VERSION" in
  "") echo "usage: bash wall_install.sh"
      exit;;
esac

KEYMAP="be"
LOCALE="nl_BE.UTF-8"
TIMEZONE="Europe/Brussels"
COUNTRY="BE"

if [ $USER == "pi" ]; then
  # Configure Waveshare 5inch HDMI LCD: https://www.waveshare.com/wiki/5inch_HDMI_LCD
  echo -e '\nmax_usb_current=1\nhdmi_group=2\nhdmi_mode=87\nhdmi_cvt 800 480 60 6 0 0 0\nhdmi_drive=1' | sudo tee -a /boot/config.txt
  
  # Change keyboard
  sudo raspi-config nonint do_configure_keyboard "$KEYMAP"

  # Change locale
  sudo raspi-config nonint do_change_locale "$LOCALE"

  # Change timezone
  sudo raspi-config nonint do_change_timezone "$TIMEZONE"

  # Change WiFi country
  sudo raspi-config nonint do_wifi_country "$COUNTRY"

  # Change hostname
  read -p "Enter the new hostname [pindaalarmclock]: " NEW_HOSTNAME
  NEW_HOSTNAME=${NEW_HOSTNAME:-pindaalarmclock}
  sudo raspi-config nonint do_hostname "$NEW_HOSTNAME"

  # enable ssh
  sudo raspi-config nonint do_ssh 0

  # Upgrade
  sudo apt-get update
  sudo apt-get dist-upgrade -y
  sudo apt-get autoremove -y

  # Change user
  read -p "Enter the new user [dany]: " NEW_USER
  NEW_USER=${NEW_USER:-dany}
  sudo adduser --disabled-password --gecos "" "$NEW_USER"
  while : ; do
    sudo passwd "$NEW_USER"
    [ $? = 0 ] && break
  done
  sudo usermod -a -G adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,netdev,spi,i2c,gpio "$NEW_USER"
  
  # Continue after reboot
  sudo mv alarmclock_install.sh /home/$NEW_USER/
  echo "bash alarmclock_install.sh" | sudo tee -a /home/$NEW_USER/.bashrc

  echo "Login as $NEW_USER"
  read -p "Press Return to Restart " key

else
  # Disable Continue after reboot
  sed -i '/^bash alarmclock_install.sh/d' .bashrc
  
  # Remove pi user
  sudo userdel -r pi

  # PgUp, PgDn Bash History
  echo '"\e[5~": history-search-backward' > .inputrc
  echo '"\e[6~": history-search-forward' >> .inputrc
  
  # Muiscursor verbergen
  sudo apt-get install unclutter -y

  # Autostart Chromium browser
  sudo apt-get install chromium-browser lightdm openbox xterm fonts-symbola -y
  sudo raspi-config nonint do_boot_behaviour "B4"
  mkdir -p $HOME/.config/openbox
  echo "# Hide mouse when not moving the mouse" >> $HOME/.config/openbox/autostart
  echo "unclutter -idle 0.1 &" >> $HOME/.config/openbox/autostart

  echo "# Disable Screensaver" >> $HOME/.config/openbox/autostart
  echo "xset s off" >> $HOME/.config/openbox/autostart
  echo "xset -dpms" >> $HOME/.config/openbox/autostart
  echo "xset s noblank" >> $HOME/.config/openbox/autostart

#  sudo apt install ddcutil -y
#  sudo wget -O /var/www/html/brightness.sh https://raw.githubusercontent.com/pindanet/Raspberry/master/wall/brightness.sh
#  echo "dtparam=i2c2_iknowwhatimdoing" | sudo tee -a /boot/config.txt
#  echo "# Start auto brightness script" >> $HOME/.config/openbox/autostart
#  echo "bash /var/www/html/brightness.sh &" >> $HOME/.config/openbox/autostart

  echo "# Start fullscreen browser" >> $HOME/.config/openbox/autostart
  echo "chromium-browser --incognito --kiosk http://localhost/ &" >> $HOME/.config/openbox/autostart

  sudo wget -O /var/www/html/index.html https://raw.githubusercontent.com/pindanet/Raspberry/master/alarmclock/index.html

  printf "\033[1;37;40mOn the main computer: ssh-copy-id -i ~/.ssh/id_rsa.pub $HOSTNAME\n\033[0m" # Witte letters op zwarte achtergrond
  printf "\033[1;37;40mOn the domotica controller: ssh-copy-id -i ~/.ssh/id_rsa.pub $HOSTNAME\n\033[0m" # Witte letters op zwarte achtergrond
  printf '\033[1;32;40mPress key to secure ssh.\033[0m' # Groene letters op zwarte achtergrond
  read Keypress
#  sudo sed -i "s/^.*PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config

  # Touchscreen driver
#  wget https://github.com/waveshare/LCD-show/archive/master.zip
#  unzip master.zip
#  rm master.zip
#  cd LCD-show-master/
#  chmod +x LCD5-show
#  ./LCD5-show
fi
# Restart Raspberry Pi
sudo shutdown -r now
