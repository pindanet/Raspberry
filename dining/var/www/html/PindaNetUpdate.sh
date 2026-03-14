#!/bin/bash
dpkg --configure -a
apt-get clean
apt-get autoremove -y
apt-get update
apt-get upgrade -y
systemctl reboot
