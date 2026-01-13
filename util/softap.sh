# rfkill list
# sudo raspi-config
sudo nmcli connection del Wired\ connection\ 1
sudo nmcli connection add type bridge con-name 'Bridge' ifname br0
sudo nmcli connection add type ethernet slave-type bridge con-name 'Ethernet' ifname eth0 master br0
sudo nmcli connection add con-name 'PindaDomo' \
  ifname wlan0 type wifi slave-type bridge master br0 \
  wifi.mode ap wifi.ssid Proximus-Limited-388355 wifi-sec.key-mgmt wpa-psk \
  wifi-sec.proto rsn wifi-sec.pairwise ccmp \
  wifi-sec.psk ywbzbunxr9p5jw5m

sudo nmcli connection modify PindaDomo 802-11-wireless.band bg
sudo nmcli connection modify PindaDomo 802-11-wireless.channel 11

#sudo nmcli connection modify PindaDomo 802-11-wireless.band a
#sudo nmcli connection modify PindaDomo 802-11-wireless.channel 40

sudo nmcli connection up Bridge
sudo nmcli connection up PindaDomo
nmcli con show --active

# echo 16 | sudo tee /sys/class/backlight/10-0045/brightness
