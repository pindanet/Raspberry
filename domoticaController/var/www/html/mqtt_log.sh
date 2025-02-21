#!/bin/bash
# sudo apt install -y mosquitto mosquitto-clients
## sudo systemctl enable mosquitto.service
# sudo nano /etc/mosquitto/mosquitto.conf
#   listener 1883 0.0.0.0
#   allow_anonymous true
# sudo systemctl restart mosquitto.service


topic_name="stat/tasmota_159CA5/POWER/#"
while read topic
do
    # Append timestamp to the message
    timestamp=$(date)
    echo "$timestamp: $topic" >> /var/www/html/data/MQTT.log
done < <(mosquitto_sub -t $topic_name)

