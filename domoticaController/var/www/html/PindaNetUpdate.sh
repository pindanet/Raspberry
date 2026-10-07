#!/bin/bash
dpkg --configure -a
apt --fix-broken install
apt-get clean
apt autoremove -y
apt-get update
apt-get upgrade -y
systemctl reboot
