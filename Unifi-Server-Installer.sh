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
echo 'deb http://www.ui.com/downloads/unifi/debian stable ubiquiti' | sudo tee /etc/apt/sources.list.d/100-ubnt-unifi.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
sudo apt update
sudo wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ui.com/unifi/unifi-repo.gpg 
sudo apt update
sudo apt-get install apt-transport-https
sudo apt install unifi

sudo reboot
