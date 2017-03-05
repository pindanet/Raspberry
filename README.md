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

## User Access on non system partition
    sudo nano /etc/fstab
      /dev/mmcblk0p3  /media/data     ext4    defaults          0       0
    sudo mkdir /media/data
    sudo mount -a
    sudo mkdir -p /media/data/home/pi
    chown pi:pi /media/data/home/pi/
## Autostart fullscreen browser
    sudo apt-get install xautomation firefox-esr
    mkdir -p /media/data/home/pi/.config/lxsession/LXDE-pi/
    nano .config/lxsession/LXDE-pi/autostart
      @sh /media/data/home/pi/.config/lxsession/LXDE-pi/autostart.sh
## Webserver
    sudo apt-get install apache2
    sudo mkdir -p /media/data/var/www/html
    sudo rm -r /var/www/html/
    sudo ln -s /media/data/var/www/html/ /var/www/html
### Folder with background pictures
    sudo mkdir /media/data/var/www/html/background
    sudo mkdir -p /media/data/etc/systemd/system/
    sudo cp /media/data/etc/systemd/system/PindaNetWallpaper.timer /etc/systemd/system/PindaNetWallpaper.timer
    sudo cp /media/data/etc/systemd/system/PindaNetWallpaper.service /etc/systemd/system/PindaNetWallpaper.service
    sudo ln -s /media/data/home/pi/wallpaper.sh wallpaper.sh
    sudo chmod a+x /media/data/home/pi/wallpaper.sh
    sudo systemctl daemon-reload
    sudo systemctl enable PindaNetWallpaper.timer
    sudo systemctl start PindaNetWallpaper.timer
    systemctl list-timers
## Activate python3 and Bash CGI
    sudo a2enmod cgid
    sudo nano /etc/apache2/conf-enabled/pinda.conf
    <Directory /var/www/html>
        Options +ExecCGI
        AddHandler cgi-script .py .sh
    </Directory>
    
    sudo visudo
    www-data ALL = NOPASSWD: /sbin/shutdown -r now, /sbin/shutdown -h now, /usr/bin/apt-get update, /usr/bin/apt-get upgrade -y

    sudo nano /media/data/var/www/html/test.py
    #!/usr/bin/python3
    # -*- coding: UTF-8 -*-# enable debugging
    import cgitb
    cgitb.enable()
    print("Content-Type: text/html;charset=utf-8")
    print()
    print("Hello World!")

    sudo chmod +x /media/data/var/www/html/test.py
    
    sudo chmod +x /media/data/var/www/html/background.py
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
    
    sudo mv bme280.py /media/data/var/www/html/
    sudo adduser www-data i2c
## YouTube Live Video Stream
    # Account pictogram > Creator Studio > Live Streaming
    sudo apt-get install libmp3lame-dev libx264-dev
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
    raspivid -o - -t 0 -fps 30 -b 6000000 | ffmpeg -re -ar 44100 -ac 2 -acodec pcm_s16le -f s16le -ac 2 -i /dev/zero -f h264 -i - -vcodec copy -acodec aac -ab 128k -g 50 -strict experimental -f flv rtmp://a.rtmp.youtube.com/live2/<SESSIE>
