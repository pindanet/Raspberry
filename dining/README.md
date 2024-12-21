# Movie frame with Temperature sensor
For Raspberry Pi OS Bookworm Lite 64-bit
## Hardware

### HDMI Display

### DS18B20 Temperature Sensor
GPIO4 (7) > Data (Yellow) > 4k7 > 3,3 V (Red)(GPIO17)<br>
GND (9) > GND (Black)<br>
GPIO17 (11) > Vdd (Red)

### Shutdown/Boot button
Gnd (6) > Gnd (Blue)<br>
GPIO3 (5) > Shutdown/Boot button (Blue)

## Install

    wget https://github.com/pindanet/Raspberry/raw/master/dining/install.sh
    bash install.sh

Easy SSH login with key, from any computer.
Add Raspberry Pi sensor SSH key to your computer with:

    ssh-copy-id -i $HOME/.ssh/id_rsa.pub pi@raspberrypi.local
Then you can disable password SSH login (more secure) on the Raspberry Pi Sensor SSH server:

    sudo sed -i "s/^.*PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config
You can configure the domoticaSlave by editing /var/www/html/data/conf.json

    sudo nano -P -B -l /var/www/html/data/conf.json
