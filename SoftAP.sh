#!/bin/bash

# Controleer of het script de bash shell gebruikt
if [ -z ${BASH+x} ]; then
   echo "Dit is een bash script."
   echo "Gebruik: sudo bash SoftAP.sh"
   exit 1
fi

# Controleer of het script met root rechten is gestart
if [ $EUID != 0 ]; then
   echo "Dit script heeft rootrechten nodig."
   echo "Gebruik: sudo bash SoftAP.sh"
   exit 1
fi

WANIF="eth0"     # Netwerkverbinding naar het internet
LANIF="wlan0"    # Netwerkverbinding naar het LAN (WiFi).
MODE="g"         # WiFi mode a,b,g
CHANNEL="6"      # Te gebruiken WiFi kanaal
ESSID="SoftAP"   # SSID (zichtbare naam) van de Hotspot
KEY="snt+-456"   # Wachtwoord

# Controleer de aanwezigheid van een WiFi netwerk interface
ip a show dev $LANIF
if [ $? != 0 ]; then
   echo "Geen WiFi interface gevonden."
   exit 1
fi
# indien nodig hostapd en installeren
if [ ! -e /usr/sbin/hostapd ]; then
  apt-get update
  apt-get upgrade -y
  apt-get install -y hostapd
fi

GATEWAY=`ip route | grep default | awk '{print $3}'`

# SoftAP starten
IPWAN=`ip addr show $WANIF | grep "inet " | awk '{print $2}'`
BRDWAN=`ip addr show $WANIF | grep "inet " | awk '{print $4}'`

ip link set dev $LANIF up
#ip addr del $IPWAN dev $WANIF
dhclient eth0 -r
ip link add name br0 type bridge
ip link set br0 up
#ip addr add $IPWAN broadcast $BRDWAN dev $WANIF
ip link set $WANIF master br0

mv /etc/hostapd.conf /etc/hostapd.conf.ori
cat > /etc/hostapd.conf <<:end
interface=$LANIF
driver=nl80211
channel=$CHANNEL
ssid=$ESSID
hw_mode=$MODE
auth_algs=1
# Wireless Multimedia Extension/Wi-Fi Multimedia needed for
# IEEE 802.11n (HT)
wmm_enabled=1
# 1 to enable 802.11n
ieee80211n=1
#ht_capab=[HT40-][SHORT-GI-20][SHORT-GI-40]

# WEP/WPA/WPA2 bitmask, 0 for open/WEP, 1 for WPA, 2 for WPA2
wpa=2

# WPA2 settings
wpa_passphrase=$KEY
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP CCMP
rsn_pairwise=CCMP

bridge=br0
:end
systemctl start hostapd.service
#ip addr add $IPWAN broadcast $BRDWAN dev br0
dhclient br0
#ip addr del $IPWAN dev $WANIF
ip route add default via $GATEWAY

echo Access Point $ESSID is in de lucht
echo Het IP adres van deze computer is $IPWAN

printf '\033[1;32;40mDruk Return om het Access Point af te sluiten.\033[0;37;40m' # Groene letters op zwarte achtergrond
read Keypress

# SoftAP stoppen
IPWAN=`ip addr show br0 | grep "inet " | awk '{print $2}'`
BRDWAN=`ip addr show br0 | grep "inet " | awk '{print $4}'`
ip link set br0 down
systemctl stop hostapd.service
mv /etc/hostapd.conf.ori /etc/hostapd.conf
ip link set eth0 nomaster
ip link delete br0 type bridge
#ip addr add $IPWAN broadcast $BRDWAN dev $WANIF
dhclient eth0
ip route add default via $GATEWAY
ip link set dev $LANIF down

echo Access Point $ESSID is niet meer in de lucht

exit
