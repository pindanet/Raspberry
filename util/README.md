## Make a image of a SD-card and shrink it
       wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh
       mv pishrink.sh Documenten/SNT/Raspberry\ Pi/
       su
       cd Documenten/SNT/Raspberry\ Pi/
       chmod +x pishrink.sh
       
       dd bs=4M of=basisimage.img if=/dev/mmcblk0 status=progress conv=fsync
       ./pishrink.sh basisimage.img basisimage.shrunk.img
       dd bs=4M if=basisimage.shrunk.img of=/dev/mmcblk0 status=progress conv=fsync

## Make a image of a SD-card
      dd if=/dev/mmcblk0 bs=4M | gzip -c > basisimage.img.gz
      gunzip -c basisimage.img.gz | dd of=/dev/mmcblk0 bs=4M status=progress conv=fsync
      
      xzcat /home/dany/Downloads/2022-09-22-raspios-bullseye-armhf.img.xz | dd of=/dev/mmcblk0 bs=4M status=progress conv=fsync

## Make a image of a noresised SD-card
      dd bs=4M count=1273 of=basisimage.img if=/dev/mmcblk0 status=progress conv=fsync
      dd bs=4M count=1287 of=basisimage.img if=/dev/mmcblk0 status=progress conv=fsync (32-bit)
# Local Repository
## Create, Update local repository
    sudo mkdir /run/media/dany/0c1b4552-03cb-409b-9c8c-61c19bdd2723/raspbian.org
    sudo rsync -avHxh --numeric-ids --progress --delete archive.raspbian.org::archive/raspbian/ /run/media/dany/0c1b4552-03cb-409b-9c8c-61c19bdd2723/raspbian.org
## Add to Apache webserver configuration
    sudo mkdir /srv/www/htdocs/raspbian
    sudo joe /etc/apache2/vhosts.d/pinda.conf
        Alias /raspbian "/srv/www/htdocs/raspbian/"
        <Directory "/srv/www/htdocs/raspbian">
          Options None
          AllowOverride None
          Require all granted
        </Directory>
    sudo systemctl restart apache.service
## Mount local repository
    sudo mount /dev/sdb1 /srv/www/htdocs/raspbian
## Use local repository in Raspbian
    sudo nano /etc/apt/sources.list
        deb http://laptop.local/raspbian/raspbian.org/ jessie main contrib non-free rpi
        # deb http://mirrordirector.raspbian.org/raspbian/ jessie main contrib non-free rpi
