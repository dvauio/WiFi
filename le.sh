#!/bin/sh
NAME="my.fqdn.com"
EMAIL="my@email.add"
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
