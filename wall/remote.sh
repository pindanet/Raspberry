#!/bin/bash
command=$(cat $1)
cat $1 > /home/dany/remote.log
rm $1
case "$command" in
  halt)
    shutdown -h now
    ;;
  rsync)
    rsync -aAXv --delete --relative /home/dany/wall_install.sh /usr/sbin/background.sh /var/www/ pindabackup::backup/rpiwall
    touch /var/www/html/data/rsync.log
    ;;
  update)
    apt-get clean -y
    apt-get update -y
    apt-get upgrade -y
    cp /var/log/apt/history.log /var/www/html/data/update.log
    ;;
  clean)
    rm /var/www/html/data/rsync.log
    rm /var/www/html/data/update.log
    ;;
esac
