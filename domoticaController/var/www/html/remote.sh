#!/bin/bash
#command=$(cat $1)
command=$1
#cat $1 > /root/remote.log
echo $1 > /root/remote.log
[[ -d /var/www/html/remote ]] || mkdir -p /var/www/html/remote
if [ ${#command}  -lt 7 ]; then
#  rm $1
  case "$command" in
#    halt)
#      shutdown -h now
#      ;;
    rsync)
      rsync -aAXv --delete --relative /usr/sbin/background.sh /etc/systemd/system/background.service /usr/sbin/PindaNetDomo.sh /etc/systemd/system/PindaNetDomo.service /var/www/ pindabackup::backup/pindadomo > /root/rsync.log 2>&1
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
