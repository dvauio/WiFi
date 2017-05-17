#!/bin/sh
# Script source used from https://community.ubnt.com/t5/UniFi-Wireless/UniFi-Ubuntu-16-04-fully-automatic-Installation-NGINX-Proxy-amp/td-p/1596848

# Edit these following 2 lines:
NAME="my.fqdn.com"
EMAIL="my@email.add"

# Comment out the following 4 lines if you already have the UniFi software installed.
# Note - the UniFi software requires at-least 20GiB disk space.
echo "deb http://www.ubnt.com/downloads/unifi/debian unifi5 ubiquiti" > /etc/apt/sources.list.d/unifi.list
echo y | apt-key adv --keyserver keyserver.ubuntu.com --recv C0A52C50
apt update
echo y | apt install unifi

# Script Start...
apt update
echo y | apt upgrade
apt -f install
echo y | apt install nginx letsencrypt

service nginx stop
echo y | letsencrypt certonly -d $NAME --standalone --standalone-supported-challenges http-01 --email $EMAIL
service nginx start

service unifi stop
echo aircontrolenterprise | openssl pkcs12 -export -inkey /etc/letsencrypt/live/$NAME/privkey.pem -in /etc/letsencrypt/live/$NAME/cert.pem -name unifi -out /etc/letsencrypt/live/$NAME/keys.p12 -password stdin
echo y | keytool -importkeystore -srckeystore /etc/letsencrypt/live/$NAME/keys.p12 -srcstoretype pkcs12 -destkeystore /usr/lib/unifi/data/keystore -storepass aircontrolenterprise -srcstorepass aircontrolenterprise
service unifi start
openssl dhparam -out /etc/ssl/certs/dhparam.pem 4096

#NGINX PROXY
service nginx stop
printf "server_tokens off;\n\
add_header X-Frame-Options SAMEORIGIN;\n\
add_header X-XSS-Protection \"1; mode=block\";\n\
server {\n\
	listen 80;\n\
	server_name $NAME;\n\
	return 301 https://$NAME\$request_uri;\n\
}\n\
server {\n\
	listen 443 ssl default_server http2;\n\
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
		proxy_set_header Host \$host;\n\
		proxy_set_header X-Real-IP \$remote_addr;\n\
		proxy_set_header X-Forward-For \$proxy_add_x_forwarded_for;\n\
		proxy_http_version 1.1;\n\
		proxy_set_header Upgrade \$http_upgrade;\n\
		proxy_set_header Connection \"upgrade\";\n\
	}\n\
}\n\" > /etc/nginx/sites-enabled/default
service nginx start
