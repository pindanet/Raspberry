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
    echo 128 > /sys/class/backlight/rpi_backlight/brightness

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
    # Rsync backup
    sudo rsync -aAXv --delete --exclude="/dev/" --exclude="/proc/" --exclude="/sys/" --exclude="/tmp/" --exclude="/run/" --exclude="/mnt/" --exclude="/media/" --exclude="/lost+found/" / backup.local::backup/raspberrypi

## Webserver
    sudo apt-get install apache2
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
    sudo apt-get install xautomation firefox-esr
    nano .config/lxsession/LXDE-pi/autostart
      @sh /home/pi/.config/lxsession/LXDE-pi/autostart.sh
### Folder with background pictures
    sudo mkdir /var/www/html/background
    sudo mv PindaNetWallpaper.timer /etc/systemd/system/PindaNetWallpaper.timer
    sudo mv PindaNetWallpaper.service /etc/systemd/system/PindaNetWallpaper.service
    sudo apt-get install imagemagick
    # copy wallpaper.sh to /usr/sbin/
    sudo chmod a+x wallpaper.sh
    sudo systemctl daemon-reload
    sudo systemctl enable PindaNetWallpaper.timer
    sudo systemctl start PindaNetWallpaper.timer
    systemctl list-timers
## Activate Bash CGI
    sudo a2enmod cgid
    sudo nano /etc/apache2/conf-enabled/pinda.conf
    <Directory /var/www/html>
        Options +ExecCGI
        AddHandler cgi-script .sh
    </Directory>
    
    sudo visudo
    www-data ALL = NOPASSWD: /sbin/shutdown -r now, /sbin/shutdown -h now

    sudo chmod +x /media/data/var/www/html/background.sh
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
    sudo systemctl daemon-reload
    sudo systemctl enable PindaNetThermostat.timer
    sudo systemctl start PindaNetThermostat.timer
    systemctl list-timers
## Bluetooth Detection
    hcitool scan
    echo -n "MA:C-:ad:dr:es:s0" > bluetooth.detection
    sudo hcitool info MA:C-:ad:dr:es:s0 | md5sum | awk '{ print $1 }' >> bluetooth.detection
    sudo mv bluetooth.detection /var/www/html/ /var/www/html/data/
    sudo chmod +x /usr/sbin/bluetooth-detection.sh
    sudo systemctl daemon-reload
    sudo systemctl enable PindaNetBluetoothDetection.timer
    sudo systemctl start PindaNetBluetoothDetection.timer
    systemctl list-timers
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
-->
    wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-armhf-32bit-static.tar.xz
    tar -xvf ffmpeg-release-armhf-32bit-static.tar.xz
    
    raspivid -o - -t 0 -fps 30 -b 6000000 | ffmpeg-3.3-armhf-32bit-static/ffmpeg -re -ar 44100 -ac 2 -acodec pcm_s16le -f s16le -ac 2 -i /dev/zero -f h264 -i - -vcodec copy -acodec aac -ab 128k -g 50 -strict experimental -f flv rtmp://a.rtmp.youtube.com/live2/<SESSIE>
