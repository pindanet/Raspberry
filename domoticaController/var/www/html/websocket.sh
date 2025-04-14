#!/bin/bash
rm /var/www/html/data/websocket.stop
rm /var/www/html/data/websocket.log

(/usr/bin/php /var/www/html/websocket.php | tee /var/www/html/data/websocket.log) &

until [ -f /var/www/html/data/websocket.stop ]
  do
    sleep 1
  done

rm /var/www/html/data/websocket.stop
rm /var/www/html/data/websocket.log
