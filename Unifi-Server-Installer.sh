#!/bin/bash 

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
sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:certbot/certbot -y
sudo apt-get update
sudo apt-get install certbot -y

echo Install haveged
sudo apt-get install haveged -y

echo Unifi Installtion
sudo echo deb http://www.ubnt.com/downloads/unifi/debian unifi5 ubiquiti | tee -a /etc/apt/sources.list
sudo echo deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen | tee -a /etc/apt/sources.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv C0A52C50
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
sudo apt update
sudo apt install unifi -y
echo "JSVC_EXTRA_OPTS=\"\$JSVC_EXTRA_OPTS -Xss1280k\"" | sudo tee -a /etc/default/unifi
echo Congratulations UniFi is now installed.

echo spotipo Install
wget https://customer.spotipo.com/pro-download/0TWCHJHU38QJ2FXBNAPJXKUHME3Q9KSVT48TJU7OIR6DS87OAI/spotipo_latest-pro_amd64.deb
sudo dpkg -i spot*
sudo apt-get install -f -y
sudo apt-get install -f -y


sudo reboot
