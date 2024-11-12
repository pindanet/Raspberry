# Temperature sensor with Weather Forecast and IR lightswitch
For Raspberry Pi OS Bookworm Lite 64-bit
## Hardware
See install.sh

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
