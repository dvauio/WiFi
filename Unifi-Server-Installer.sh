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
wget https://dl.ubnt.com/unifi/5.9.29/unifi_sysvinit_all.deb

sudo apt install mongodb-server
sudo apt install mongodb-10gen
sudo apt install mongodb-org-server
sudo apt install ./unifi_sysvinit_all.deb



sudo reboot
