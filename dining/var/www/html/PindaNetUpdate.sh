#!/bin/bash
dpkg --configure -a
apt-get clean
apt autoremove -y
apt-get update
apt-get upgrade -y
systemctrl reboot
