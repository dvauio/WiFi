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
wget https://dl.ubnt.com/unifi/5.9.29/unifi_sysvinit_all.deb

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list
sudo apt update


sudo apt install mongodb-server -y
sudo apt install mongodb-10gen -y
sudo apt install mongodb-org-server -y
sudo apt install ./unifi_sysvinit_all.deb -y



sudo reboot
