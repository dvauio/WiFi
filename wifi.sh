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

echo IP rules
sudo apt install iptables-persistent -y
sudo apt-get install fail2ban -y
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -I INPUT 1 -i lo -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8081 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8443 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8880 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8843 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 27117 -j ACCEPT
sudo iptables -A INPUT -j DROP

echo Unifi Installtion
sudo echo deb http://www.ubnt.com/downloads/unifi/debian unifi5 ubiquiti | tee -a /etc/apt/sources.list
sudo echo deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen | tee -a /etc/apt/sources.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv C0A52C50
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
sudo apt update
sudo apt install unifi -y
echo Congratulations UniFi is now installed.
