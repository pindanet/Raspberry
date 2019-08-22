#!/bin/bash
command=$(cat $1)
cat $1 > /root/remote.log
if [ ${#command}  -lt 7 ]; then
  rm $1
  case "$command" in
    halt)
      shutdown -h now
      ;;
    rsync)
      rsync -aAXv --delete --relative /home/dany/wall_install.sh /usr/sbin/background.sh /var/www/ pindabackup::backup/rpiwall > /root/rsync.log 2>&1
      mv /root/rsync.log /var/www/html/remote/rsync.log
      ;;
    update)
      apt-get clean -y > /root/update.log 2>&1
      apt-get update -y >> /root/update.log 2>&1
      apt-get upgrade -y >> /root/update.log 2>&1
      mv /root/update.log /var/www/html/remote/update.log
      ;;
    clean)
      rm /var/www/html/remote/rsync.log
      rm /var/www/html/remote/update.log
      ;;
  esac
fi
