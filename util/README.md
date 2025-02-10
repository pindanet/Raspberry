# Clone Raspberry Pi OS
## Make a clone of a SD-card
       curl https://raw.githubusercontent.com/geerlingguy/rpi-clone/master/install | sudo bash
### Clone to USB Card reader      
       sudo rpi-clone sda
## Make in Debian a clone to file
[Raspberry Pi OS klonen en Tasmota scanner](https://linux.pindanet.be/faq/tips25/rpi-tasmota.html)

      sudo apt install fsarchiver cifs-utils
      sudo mount -t cifs //hostnaamNAS/netwerkmap /mnt
      ls -lh /mnt/
Place SD-card/USB stick with Raspberry Pi Project
      
      sudo dmesg -T
      su
      /sbin/sfdisk -d /dev/sdX > /mnt/rpiproject.sdX.partition.table.txt
      /sbin/fsarchiver savefs /mnt/rpiproject.fsa /dev/sdX1 /dev/sdX2
      exit
      ls -lh /mnt/
Edit partition table info to restore Raspberry Pi Project to media with different capacity.

      sudo nano /mnt/rpiproject.sdX.partition.table.txt
Remove size = xxxxxxxxxx from second partition.

      /dev/sdX2 : start=     1056768, size=   119107584, type=83
Change to:

      /dev/sdX2 : start=     1056768, type=83
Save the partition table and stop editor.<br>
Remove source Raspberry Pi Project SD-card/USB stick.<br>
Place target SD-card/USB stick.

       sudo dmesg -T
       sudo sfdisk /dev/sdX < /mnt/rpiproject.sdX.partition.table.txt
       sudo fsarchiver restfs /mnt/rpiproject.fsa id=0,dest=/dev/sdX1 id=1,dest=/dev/sdX2
       sudo umount /mnt/
## Brightness LCD Screen (0-255)
    sudo su
    echo 32 > /sys/class/backlight/rpi_backlight/brightness
## Flash Tasmota on Sonoff Basic
Based on [https://github.com/tasmota/docs-7.1/blob/master/Flash-Sonoff-using-Raspberry-Pi.md](https://github.com/tasmota/docs-7.1/blob/master/Flash-Sonoff-using-Raspberry-Pi.md)

    https://github.com/tasmota/docs-7.1/blob/master/Flash-Sonoff-using-Raspberry-Pi.md
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
    
Open Sonoff Basic and solder connections (see: [https://www.sigmdel.ca/michel/ha/sonoff/flashing_sonoff_en.html](https://www.sigmdel.ca/michel/ha/sonoff/flashing_sonoff_en.html) with PSU)
![Flashing Sonoff](images/sonoff-rpi-2.jpg "Flashing Sonoff")
    
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
    
## HifiBerry miniAmp
[https://www.hifiberry.com/docs/data-sheets/datasheet-miniamp/](https://www.hifiberry.com/docs/data-sheets/datasheet-miniamp/)
![MiniAmp](images/miniamp-connection.jpg "MiniAmp")

[https://www.hifiberry.com/docs/software/configuring-linux-3-18-x/](https://www.hifiberry.com/docs/software/configuring-linux-3-18-x/)
## IQaudio DigiAMP+
[https://www.raspberrypi.com/documentation/accessories/audio.html](https://www.raspberrypi.com/documentation/accessories/audio.html)
## Audio streaming
[https://linux.pindanet.be/faq/tips24/netwerkaudio.html](https://linux.pindanet.be/faq/tips24/netwerkaudio.html)
