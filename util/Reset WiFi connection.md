## More stability with Power Save Off and 2.4 GHz force
[Stay Connected: Enhancing Raspberry Pi Wi-Fi Stability by Turning Off Power Management](https://www.thedigitalpictureframe.com/stay-connected-enhancing-raspberry-pi-wi-fi-stability-by-turning-off-power-management/)

[Why the 2.4 GHz WiFi band is faster and more stable for your digital picture frame than 5 GHz](https://www.thedigitalpictureframe.com/why-the-2-4-ghz-wifi-band-is-faster-and-more-stable-for-your-digital-picture-frame-than-5-ghz/)
## Reset WiFi connection
    nmcli connection show
    sudo nmcli connection delete "connection name"
    sudo nmcli device wifi connect "SSID" password "P@ssword"
