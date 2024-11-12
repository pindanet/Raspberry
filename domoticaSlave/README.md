# Temperature sensor with Weather Forecast and IR lightswitch
For Raspberry Pi OS Bookworm Lite 64-bit
## Install

    wget https://github.com/pindanet/Raspberry/raw/master/domoticaSlave/install.sh
    bash install.sh

If you change the hostname, the Chromium Browser won't start.
To solve this you have to remove the Chromium profile Lock with:

    rm -rf ~/.config/chromium/Singleton*
