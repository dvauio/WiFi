#!/bin/sh

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
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
sudo apt install iptables-persistent -y
sudo apt-get install fail2ban -y
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

NAME="dev-space.site"
EMAIL="davidvaughan556@gmail.com"
apt-get update
echo y | apt-get upgrade
cd /opt
rm unifi_sysvinit_all.deb
rm certbot-auto
wget http://dl.ubnt.com/unifi/5.0.7/unifi_sysvinit_all.deb
wget https://dl.eff.org/certbot-auto
chmod a+x certbot-auto
dpkg -i unifi_sysvinit_all.deb
apt-get -f install
echo y | apt-get install nginx

service nginx stop
echo y | ./certbot-auto certonly -d $NAME --standalone --standalone-supported-challenges http-01 --email $EMAIL
service nginx start

service unifi stop
echo aircontrolenterprise | openssl pkcs12 -export -inkey /etc/letsencrypt/live/$NAME/privkey.pem -in /etc/letsencrypt/live/$NAME/cert.pem -name unifi -out /etc/letsencrypt/live/$NAME/keys.p12 -password stdin
echo y | keytool -importkeystore -srckeystore /etc/letsencrypt/live/$NAME/keys.p12 -srcstoretype pkcs12 -destkeystore /usr/lib/unifi/data/keystore -storepass aircontrolenterprise -srcstorepass aircontrolenterprise
service unifi start
openssl dhparam -out /etc/ssl/certs/dhparam.pem 4096

#NGINX PROXY
service nginx stop
echo "server {\n\
	listen 80;\n\
	server_name $NAME;\n\
	return 301 https://$NAME$request_uri;\n\
	}\n\
	server {\n\
	listen 443 ssl default_server;\n\
	server_name $NAME;\n\
	ssl_dhparam /etc/ssl/certs/dhparam.pem;\n\
	ssl_certificate /etc/letsencrypt/live/$NAME/fullchain.pem;\n\
    ssl_certificate_key /etc/letsencrypt/live/$NAME/privkey.pem;\n\
	ssl_session_cache   shared:SSL:10m;\n\
	ssl_session_timeout 10m;\n\
	keepalive_timeout   300;\n\
	ssl_protocols TLSv1 TLSv1.1 TLSv1.2;\n\
	ssl_prefer_server_ciphers on;\n\
	ssl_stapling on;\n\
	ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:DHE-RSA-AES256-SHA;
	add_header Strict-Transport-Security max-age=31536000;\n\
	add_header X-Frame-Options DENY;\n\
	error_log /var/log/unifi/nginx.log;\n\
	proxy_cache off;\n\
	proxy_store off;\n\
	location / {\n\
	proxy_set_header Referer \"\";\n\
	proxy_pass https://localhost:8443;\n\
	}\n\
	}\n\
	" > /etc/nginx/sites-enabled/default
service nginx start
