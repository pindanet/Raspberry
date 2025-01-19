# Clone Raspberry Pi OS
## Make a clone of a SD-card
       curl https://raw.githubusercontent.com/geerlingguy/rpi-clone/master/install | sudo bash
### Clone to USB Card reader      
       sudo rpi-clone sda
## Make in Debian a clone to file
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
