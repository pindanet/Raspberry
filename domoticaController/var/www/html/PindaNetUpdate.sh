#!/bin/bash
apt-get --fix-broken install -y
apt-get clean -y
apt-get autoremove -y
apt-get update -y
apt-get upgrade -y
systemctl reboot
