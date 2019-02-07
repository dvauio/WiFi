#!/bin/bash 

# To run on server type below
# wget -O - https://raw.githubusercontent.com/dvauio/WiFi/master/Unifi-Server-Installer.sh | bash

echo Update OS
sudo apt update
sudo apt upgrade -y
sudo apt dist-upgrade -y

echo Create SWAP file
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo echo /swapfile none swap sw 0 0 | tee -a /etc/fstab
sudo echo 10 | sudo tee /proc/sys/vm/swappiness
sudo echo vm.swappiness = 10 | sudo tee -a /etc/sysctl.conf
sudo sysctl vm.vfs_cache_pressure=50

echo Install Certbot
sudo add-apt-repository ppa:certbot/certbot -y
sudo apt update
sudo apt install certbot -y

echo Install haveged
sudo apt install haveged -y

echo Unifi Installtion
wget https://dl.ubnt.com/unifi/5.6.40/unifi_sysvinit_all.deb
sudo dpkg -i unifi_sysvinit_all.deb -y

sudo reboot
