# Temperature sensor with Weather Forecast and IR lightswitch
For Raspberry Pi OS Bookworm Lite 64-bit
## Hardware

### Touch Display (https://www.raspberrypi.com/documentation/accessories/display.html)
5v (2) > Vcc<br>
GND (14) > Gnd

### DS18B20 Temperature Sensor
GPIO4 (7) > Data (Yellow) > 4k7 > 3,3 V (Red)(GPIO17)<br>
GND (9) > GND (Black)<br>
GPIO17 (11) > Vdd (Red)

### PIR1 AM312
3v3 (1) > Vcc (Orange)<br>
Gnd (6) > Gnd (Brown)<br>
GPIO14 (8) > Output (Red)

### PIR2 AM312
3v3 (17) > Vcc (Blue)<br>
Gnd (20) > Gnd (Gray)<br>
GPIO24 (18) > Output (White)

### Shutdown/Boot button
Gnd (39) > Gnd (Black)<br>
GPIO26 > Shutdown button (white)<br>
GPIO3 > Boot button (Gray)

## Install

    wget https://github.com/pindanet/Raspberry/raw/master/domoticaSlave/install.sh
    bash install.sh

Easy SSH login with key, from any computer.
Add Raspberry Pi sensor SSH key to your computer with:

    ssh-copy-id -i $HOME/.ssh/id_rsa.pub pi@raspberrypi.local
Then you can disable password SSH login (more secure) on the Raspberry Pi Sensor SSH server:

    sudo sed -i "s/^.*PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config

If you change the hostname to for example "domoticaslave", the Chromium Browser will not start.
To solve this you have to remove the Chromium profile Lock with:

    rm -rf ~/.config/chromium/Singleton*
