#!/bin/bash
PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games';
openssl pkcs12 -export -in /etc/letsencrypt/live/dev-space.site/fullchain.pem -inkey /etc/letsencrypt/live/dev-space.site/privkey.pem -out /etc/letsencrypt/live/dev-space.site/cert_and_key.p12 -name tomcat -CAfile /etc/letsencrypt/live/dev-space.site/chain.pem -caname root -password pass:aaa;
rm -f /etc/letsencrypt/live/dev-space.site/keystore;
keytool -importkeystore -srcstorepass aaa -deststorepass aircontrolenterprise -destkeypass aircontrolenterprise -srckeystore /etc/letsencrypt/live/dev-space.site/cert_and_key.p12 -srcstoretype PKCS12 -alias tomcat -keystore /etc/letsencrypt/live/dev-space.site/keystore;
keytool -import -trustcacerts -alias unifi -deststorepass aircontrolenterprise -file /etc/letsencrypt/live/dev-space.site/chain.pem -noprompt -keystore /etc/letsencrypt/live/dev-space.site/keystore;
mv /var/lib/unifi/keystore /var/lib/unifi/keystore-`date -I`;
cp /etc/letsencrypt/live/dev-space.site/keystore /var/lib/unifi/keystore;
service unifi restart;
