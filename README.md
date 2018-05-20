# Raspberry
My own All In One Raspberry Pi project.
## Headless configuration
Place a file named 'ssh', without any extension, onto the boot partition of the SD card for a one time SSH server start
## Update
    sudo apt-get update
    sudo apt-get upgrade
## Rotate LCD Screen
    sudo nano /boot/config.txt
    lcd_rotate=2
## Brightness LCD Screen (0-255)
    sudo su
    echo 32 > /sys/class/backlight/rpi_backlight/brightness

## Start VNC server
    sudo systemctl start vncserver-x11-serviced.service
## Raspberry Pi Configuration
    sudo raspi-config
    Localisation Options
      nl_BE.UTF-8 UTF-8 (Locale: nl (Dutch), BE (Belgium))
      Timezone: Europe, Brussels
      WiFi Country Code: BE Belgium
    Hostname
    Interfacing Options
      Enable Camera
      Enable SSH
      I2C Enable
## Security
    passwd
    ssh-copy-id -i ~/.ssh/id_rsa.pub pi@raspberrypi.local
    sudo nano /etc/ssh/sshd_config
      PasswordAuthentication no
### SSH rpiwall command execution
    ssh-keygen -t rsa -C dany.pinoy@rpipindanet.local
    ssh-copy-id -i ~/.ssh/id_rsa.pub pi@rpiwall.local
    sudo mkdir /var/www/html/.newssh_keys
    sudo cp .ssh/id_rsa* /var/www/html/.newssh_keys/
    sudo chmod +r /var/www/html/.newssh_keys/id_rsa
### Rsync backup
    sudo rsync -aAXv --delete --exclude="/dev/" --exclude="/proc/" --exclude="/sys/" --exclude="/tmp/" --exclude="/run/" --exclude="/mnt/" --exclude="/media/" --exclude="/lost+found/" / backup.local::backup/raspberrypi

## Webserver
    sudo apt-get install apache2 php libapache2-mod-php php-ssh2 php-gd
    sudo a2enmod ssl
    sudo a2ensite default-ssl
    sudo systemctl restart apache2.service
    
    sudo mkdir /etc/apache2/ssl
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt
    sudo chmod 600 /etc/apache2/ssl/*
    sudo nano /etc/apache2/sites-enabled/default-ssl.conf
      ServerAdmin webmaster@localhost
      ServerName rpipindanet.local:443
      
      SSLCertificateFile      /etc/apache2/ssl/apache.crt         
      SSLCertificateKeyFile /etc/apache2/ssl/apache.key
    sudo systemctl restart apache2.service
    openssl s_client -connect 127.0.0.1:443
    
    sudo nano /etc/apache2/sites-available/000-default.conf
      Redirect "/" "https://rpipindanet.local/"
    sudo systemctl restart apache2.service
    
    sudo mkdir /var/www/html/data
    sudo chown -R www-data:www-data /var/www/html/data/
    
## Autostart fullscreen browser
    nano .config/lxsession/LXDE-pi/autostart
      @chromium-browser --kiosk --disable-infobars https://localhost/
      # Disable Screensaver
      xset s off
      xset -dpms
      xset s noblank
## Folder with background pictures
    sudo mkdir /var/www/html/background
    sudo chown -R www-data:www-data  background
    sudo apt-get install imagemagick
## Activate Bash CGI
    sudo a2enmod cgid
    sudo nano /etc/apache2/conf-enabled/pinda.conf
    <Directory /var/www/html>
        Options +ExecCGI
        AddHandler cgi-script .sh
    </Directory>
    
    sudo visudo
    www-data ALL = NOPASSWD: /sbin/shutdown -r now, /sbin/shutdown -h now, /bin/systemctl start hostapd.service, /bin/systemctl stop hostapd.service

    sudo chmod +x /var/www/html/background.sh
    sudo chmod +x /var/www/html/bash.sh
    sudo chmod +x /var/www/html/motion.sh
## BME280 I2C Temperature and Pressure Sensor
    Vin > 3v3 (1) (Red)
    GND > Ground (6) (Black)
    SCK > BCM 3 (SCL) (5) (White)
    SDI > BCM 2 (SDA) (3) (Brown)
    
    sudo apt-get install i2c-tools python-smbus
    wget https://bitbucket.org/MattHawkinsUK/rpispy-misc/raw/master/python/bme280.py
    i2cdetect -y 1
    nano bme280.py
      DEVICE = 0x77 # Default device I2C address
    python bme280.py
    
    sudo mv bme280.py /var/www/html/
    sudo adduser www-data i2c
    sudo chmod +x /var/www/html/bme280.sh
## RFXtrx433E
    wget https://github.com/ssjoholm/rfxcmd_gc/archive/master.zip
    unzip master.zip
    Listen: python rfxcmd_gc-master/rfxcmd.py -l -v -d /dev/ttyUSB0
    Send: python rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s Received (without spaces)
    sudo adduser www-data dialout
## Thermostat
    sudo apt-get install jq
    sudo chmod +x /var/www/html/thermostat.sh
    sudo chmod +x /var/www/html/exportthermostat.sh
    sudo chown www-data:www-data /var/www/html/data/thermostat.json
## Weather forecast
    sudo apt-get install libxml2-utils
    sudo chmod +x /var/www/html/forecast.sh
## Bluetooth Detection
### Bluetooth SmartPhone or Nokia Steel Watch
    sudo chmod +x /usr/sbin/bluetoothscan.sh
    sudo systemctl daemon-reload
    sudo systemctl enable PindaNetBluetoothScan.timer
    sudo systemctl start PindaNetBluetoothScan.timer
    systemctl list-timers
### Bluetooth GSM (old version)
    hcitool scan
    echo -n "MA:C-:ad:dr:es:s0" > bluetooth.detection
    sudo hcitool info MA:C-:ad:dr:es:s0 | md5sum | awk '{ print $1 }' >> bluetooth.detection
    sudo mv bluetooth.detection /var/www/html/data/
    sudo chmod +x /usr/sbin/bluetooth-detection.sh
    sudo systemctl daemon-reload
    sudo systemctl enable PindaNetBluetoothDetection.timer
    sudo systemctl start PindaNetBluetoothDetection.timer
    systemctl list-timers
## Motion Detection
    sudo mkdir -p /var/www/html/motion/fotos
script included in /usr/sbin/bluetooth-detection.sh
## Radio
    alsamixer # set volume
    sudo apt-get install mpd mpc
    sudo nano /etc/mpd.conf
<pre>audio_output {
        type            "alsa"
        name            "My ALSA Device"
#       device          "hw:0,0"        # optional
#       mixer_type      "hardware"      # optional
        mixer_type      "software"      # optional
#       mixer_device    "default"       # optional
#       mixer_control   "PCM"           # optional
#       mixer_index     "0"             # optional
}</pre>
    sudo systemctl restart mpd.service
    mpc add http://icecast.vrtcdn.be/radio1-high.mp3
    mpc add http://icecast.vrtcdn.be/ra2wvl-high.mp3
    mpc add http://icecast.vrtcdn.be/klara-high.mp3
    mpc add http://icecast.vrtcdn.be/klaracontinuo-high.mp3
    mpc add http://icecast.vrtcdn.be/stubru-high.mp3
    mpc add http://icecast.vrtcdn.be/mnm-high.mp3
    mpc add http://icecast.vrtcdn.be/mnm_hits-high.mp3
    mpc add http://progressive-audio.lwc.vrtcdn.be/content/fixed/11_11niws-snip_hi.mp3 
    mpc add http://icecast.vrtcdn.be/ketnetradio-high.mp3
    mpc add http://77.92.64.44:8045/stream
    mpc add http://stream.vbro.be:9100/vbro
    mpc add http://icecast-qmusic.cdp.triple-it.nl/JOEfm_be_live_128.mp3
    mpc add http://icecast-qmusic.cdp.triple-it.nl/Qmusic_be_live_128.mp3
    mpc play 1
    mpc volume 100
    mpc stop
    mpc play 2
    mpc stop    
    sudo chmod +x /var/www/html/mpc.sh
## Software Access Point
    sudo apt-get install hostapd bridge-utils
    sudo nano /etc/hostapd.conf
<pre>interface=wlan0
driver=nl80211
channel=6
ssid=SoftAP
hw_mode=g
auth_algs=1
# Wireless Multimedia Extension/Wi-Fi Multimedia needed for
# IEEE 802.11n (HT)
wmm_enabled=1
# 1 to enable 802.11n
ieee80211n=1
ht_capab=[HT20][SHORT-GI-20][DSSS_CK-HT40]

# WEP/WPA/WPA2 bitmask, 0 for open/WEP, 1 for WPA, 2 for WPA2
wpa=2

# WPA2 settings
wpa_passphrase=snt+-456
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP CCMP
rsn_pairwise=CCMP

bridge=br0</pre>
    sudo nano /etc/default/hostapd
<pre>DAEMON_CONF="/etc/hostapd.conf"</pre>
    sudo nano /etc/network/interfaces
<pre># interfaces(5) file used by ifup(8) and ifdown(8)

# Please note that this file is written to be used with dhcpcd
# For static IP, consult /etc/dhcpcd.conf and 'man dhcpcd.conf'

# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d

# Create a bridge with dynamic IP
auto br0
iface br0 inet dhcp
        bridge_ports eth0</pre>

### Enable ip_forward
    sudo nano /etc/sysctl.conf    
<pre>net.ipv4.ip_forward=1</pre>
    sudo systemctl disable hostapd.service 
    sudo systemctl stop hostapd.service
## YouTube Live Video Stream
    # Account pictogram > Creator Studio > Live Streaming
    # Werkt ook voor Facebook Live Video
<!---    sudo apt-get install libmp3lame-dev libx264-dev
    mkdir software
    cd software
    wget http://ffmpeg.org/releases/ffmpeg-3.1.4.tar.bz2
    cd ..
    mkdir src
    cd src/
    tar xvjf ../software/ffmpeg-3.1.4.tar.bz2
    cd ffmpeg-3.1.4/
    ./configure --enable-gpl --enable-nonfree --enable-libx264 --enable-libmp3lame
    make
    sudo make install
    sudo /sbin/ldconfig

    wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-armhf-32bit-static.tar.xz
    tar -xvf ffmpeg-release-armhf-32bit-static.tar.xz
--> 
    sudo apt-get install ffmpeg
    raspivid -o - -t 0 -fps 30 -b 6000000 | ffmpeg -re -ar 44100 -ac 2 -acodec pcm_s16le -f s16le -ac 2 -i /dev/zero -f h264 -i - -vcodec copy -acodec aac -ab 128k -g 50 -strict experimental -f flv rtmp://a.rtmp.youtube.com/live2/<SESSIE>
