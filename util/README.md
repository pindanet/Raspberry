## Make a image of a noresised SD-card
      dd bs=4M count=1159 of=basisimage.img if=/dev/mmcblk0 status=progress conv=fsync
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
