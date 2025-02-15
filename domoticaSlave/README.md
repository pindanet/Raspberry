# Temperature sensor with Weather Forecast and PIR motion sensors
For Raspberry Pi OS Bookworm Lite 64-bit
## Hardware

### Touch Display (https://www.raspberrypi.com/documentation/accessories/display.html)
5v (2) > Vcc<br>
GND (14) > Gnd

### DS18B20 Temperature Sensor
GPIO4 (7) > Data (Yellow) > 4k7 > 3,3 V (Orange)(GPIO27)<br>
GND (9) > GND (Black)<br>
GPIO17 (11) > Vdd (Red)

### PIR1 AM312
3v3 (1) > Vcc (Orange)<br>
Gnd (6) > Gnd (Brown)<br>
GPIO14 (8) > Output (Green)

### PIR2 AM312
3v3 (1) > Vcc (Orange)<br>
Gnd (6) > Gnd (Brown)<br>
GPIO24 (18) > Output (Green)

### Raspberry Pi Camera (https://www.raspberrypi.com/documentation/accessories/camera.html)

### Shutdown/Boot button
Gnd (39) > Gnd (Blue)<br>
GPIO26 (37) > Shutdown button (Blue)<br>
GPIO3 > Boot button ()

## Install

    wget https://github.com/pindanet/Raspberry/raw/master/domoticaSlave/install.sh
    bash install.sh

Easy SSH login with key, from any computer.
Add Raspberry Pi sensor SSH key to your computer with:

    ssh-copy-id -i $HOME/.ssh/id_rsa.pub pi@raspberrypi.local
Then you can disable password SSH login (more secure) on the Raspberry Pi Sensor SSH server:

    sudo sed -i "s/^.*PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config
You can configure the domoticaSlave by editing /var/www/html/data/conf.json

    sudo nano -P -B -l /var/www/html/data/conf.json
