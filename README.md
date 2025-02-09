# Raspberry
My own All In One Raspberry Pi project.
## Brightness LCD Screen (0-255)
    sudo su
    echo 32 > /sys/class/backlight/rpi_backlight/brightness
## Flash Tasmota on Sonoff Basic
    Based on https://github.com/tasmota/docs-7.1/blob/master/Flash-Sonoff-using-Raspberry-Pi.md
    Start Raspberry Pi 3
    sudo apt install python-pip
    sudo pip install esptool
    sudo systemctl stop serial-getty@ttyS0.service
    sudo systemctl disable serial-getty@ttyS0.service
    sudo cp /boot/cmdline.txt /boot/cmdline.bak
    sudo nano /boot/cmdline.txt
    Remove "console=serial0,115200"
    sudo nano /boot/config.txt
    Add enable_uart=1
    Add dtoverlay=pi3-miniuart-bt
    Add dtoverlay=pi3-disable-bt
    Shutdown and Power off Raspberry Pi
    
    Open Sonoff Basic and solder connections (see: https://www.sigmdel.ca/michel/ha/sonoff/flashing_sonoff_en.html with PSU)
![Flashing Sonoff](/util/images/sonoff-rpi-2.jpg "Flashing Sonoff")
    
    Start Raspberry Pi
    wget http://ota.tasmota.com/tasmota/release/tasmota.bin
    
    Start Sonoff while holding the button for 10 seconds to start in flashing mode
    esptool.py --port /dev/ttyAMA0 read_flash 0x00000 0x100000 Sonoff_backup_01.bin
    Restart Sonoff while holding the button for 10 seconds to start in flashing mode
    esptool.py --port /dev/ttyAMA0 erase_flash
    Start Sonoff while holding the button for 10 seconds to start in flashing mode
    esptool.py --port /dev/ttyAMA0 write_flash -fm dout 0x0 tasmota.bin
    
    Shutdown and Power off Raspberry Pi
    Power off Sonoff
    Connect Sonoff to 220 V AC
    
    Scan for tasmota_XXXXXX-XXXX Wifi Acces Point
    Connect to tasmota_XXXXXX-XXXX
    Surf to http://192.168.4.1
    Configure Sonoff Wifi
    Save configuration, Sonoff will reboot and connect to your home AP
    
### Get latest version
    curl -s https://api.github.com/repos/arendst/Tasmota/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' | cut -d$'v' -f 2
    wget -qO- http://tasmota_8be4af-1199/cm?cmnd=Status%202 | python -c 'import sys, json; print(json.load(sys.stdin)["StatusFWR"]["Version"])' | cut -d$'(' -f 1
## HifiBerry miniAmp
    https://www.hifiberry.com/docs/data-sheets/datasheet-miniamp/
![MiniAmp](images/miniamp-connection.jpg "MiniAmp")

    https://www.hifiberry.com/docs/software/configuring-linux-3-18-x/
    sudo nano /boot/config.txt
        disable
            #dtparam=audio=on
        add
            dtoverlay=hifiberry-dac
    nano ~/.asoundrc #Software Volume adjustment
        pcm.softvol {
            type            softvol
            slave {
                pcm         "default"
            }
            control {
                name        "SoftMaster"
                card        0
            }
        }
    speaker-test -Dsoftvol -c2 -twav
    alsamixer

    # https://www.raspberrypi.org/forums/viewtopic.php?t=235519
    sudo apt-get install pulseaudio pulseaudio-module-bluetooth
    sudo usermod -a -G bluetooth pi
    sudo reboot
    sudo nano /etc/bluetooth/main.conf
        Class = 0x240414
        DiscoverableTimeout = 0
    sudo systemctl restart bluetooth
    bluetoothctl
        power on
        discoverable on
        pairable on
        agent on
    # starten na bluetooth
    pulseaudio --start
    sudo systemctl status bluetooth
    sudo journalctl -f -u bluetooth.service
    bluetoothctl
        scan on
        pair XX:XX:XX:XX:XX:XX
        trust XX:XX:XX:XX:XX:XX
        connect XX:XX:XX:XX:XX:XX
    # To be continued
## IQaudio DigiAMP+
    # https://datasheets.raspberrypi.org/iqaudio/iqaudio-product-brief.pdf
    sudo nano /boot/config.txt
        disable
            #dtparam=audio=on
        add
            dtoverlay=iqaudio-dacplus,auto_mute_amp
    alsamixer
    speaker-test -c2 -twav
    # https://www.raspberrypi.org/forums/viewtopic.php?t=247892
    sudo apt install bluealsa
    sudo nano -B -P /lib/systemd/system/bluealsa.service
        ExecStart=/usr/bin/bluealsa --profile=a2dp-sink
    
    sudo nano /etc/systemd/system/aplay.service
    [Unit]
    Description=BlueALSA aplay service
    After=bluetooth.service
    Requires=bluetooth.service

    [Service]
    ExecStart=/usr/bin/bluealsa-aplay 00:00:00:00:00:00 --pcm-buffer-time=10000

    [Install]
    WantedBy=multi-user.target
    
    sudo systemctl enable aplay
    sudo usermod -a -G bluetooth pi
    sudo nano /etc/bluetooth/main.conf
        Class = 0x240414
    sudo shutdown -r now
    bluetoothctl
        scan on
        pair XX:XX:XX:XX:XX:XX
        trust XX:XX:XX:XX:XX:XX
        connect XX:XX:XX:XX:XX:XX
## Audio streaming
### Compile and install on openSUSE Leap 15.2 x64 system
    #https://gavv.github.io/articles/roc-tutorial/
    sudo zypper install gcc-c++ pkg-config scons ragel gengetopt libuv-devel libunwind-devel libpulse-devel sox-devel libtool intltool autoconf automake make cmake git
    #sudo zypper addrepo https://download.opensuse.org/repositories/#home:malcolmlewis:TESTING/openSUSE_Leap_15.2/#home:malcolmlewis:TESTING.repo
    #sudo zypper refresh
    #sudo zypper install cpputest-devel
    git clone https://github.com/roc-streaming/roc-toolkit.git
    cd roc-toolkit
    scons -Q --build-3rdparty=openfec --disable-tests --disable-pulseaudio
    sudo scons -Q --build-3rdparty=openfec --disable-tests --disable-pulseaudio install
    sudo modprobe snd-aloop
    # Test
    roc-recv -vv -s rtp+rs8m::10001 -r rs8m::10002 -d alsa -o 'plughw:CARD=PCH,DEV=0'
    # Play some audio through virtual audio device
    roc-send -vv -s rtp+rs8m:127.0.0.1:10001 -r rs8m:127.0.0.1:10002 -d alsa -i 'plughw:CARD=Loopback,DEV=1'
#### Crosscompile for Raspberry Pi on openSUSE Leap 15.2 x64 system
    sudo zypper install docker
    sudo systemctl start docker.service
    cd
    # sourcecode in new directory
    rm -r -f roc-toolkit
    git clone https://github.com/roc-streaming/roc-toolkit.git
    cd roc-toolkit
    sudo docker run -t --rm -u "${UID}" -v "${PWD}:${PWD}" -w "${PWD}"     rocproject/cross-arm-linux-gnueabihf       scons -Q         --disable-pulseaudio         --disable-tests         --host=arm-linux-gnueabihf         --build-3rdparty=libuv,libunwind,openfec,alsa,sox
    scp ./bin/arm-linux-gnueabihf/roc-{recv,send} pindadomo:
#### Decrease latency to synchronise sound with video
    #https://github.com/roc-streaming/roc-toolkit/discussions/255
    ./roc-recv -vv -s rtp+rs8m::10001 -r rs8m::10002 -d alsa -o 'plughw:CARD=IQaudIODAC,DEV=0' --frame-size=320 --sess-latency=25ms
    roc-send -vv -s rtp+rs8m:192.168.1.38:10001 -r rs8m:192.168.1.38:10002 -d alsa -i 'plughw:CARD=Loopback,DEV=1' --nbsrc=5 --nbrpr=5 --frame-size=320
