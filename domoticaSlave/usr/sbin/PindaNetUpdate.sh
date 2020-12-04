#!/bin/bash
apt-get clean
apt-get update
apt-get upgrade -y
shutdown -r now
