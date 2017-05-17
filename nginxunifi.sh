 #!/bin/bash
    echo -n "Enter your domain name [my.fqdn.com]: "
    read NAME
    echo -n "Enter your email address [somebody@somewhere.com]: "
    read EMAIL
    echo "These parameters are used exclusively by LetsEncrypt. To register your SSL certificate and provide notifications."
    echo "Domain: $NAME"
    echo "E-Mail:  $EMAIL"
    read -p "Does this look OK?  [Y/N]: " -n 1 REPLY
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        echo "Please re-run $0 and re-enter the params."
        exit 1
    fi
    read -p "Have you configured a Firewall or NAT rule to permit LetsEncrypt to validate your domain name?  [Y/N]: " -n 1 REPLY
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        echo "Please setup your system accordingly and re-run this script."
        exit 1
    fi
    echo "Adding UniFi Repo to /etc/apt/sources.list.d/unifi.list"
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv C0A52C50
    echo 'deb http://www.ubnt.com/downloads/unifi/debian unifi5 ubiquiti' > /etc/apt/sources.list.d/unifi.list
    if [ -f "/etc/ssl/certs/dhparam.pem" ];
    then
    echo "PLEASE READ THE FOLLOWING CAREFULLY"
    echo "If you have not generated 4096 bit safe primes for your openSSL server this is recommended."
    read -p "Do you want to regenerate DHPARAMS (This will take a while if you dont know press Y) [Y/N]: " -n 1 REPLY
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        openssl dhparam -out /etc/ssl/certs/dhparam.pem 4096
    fi
    else
    echo "PLEASE READ THE FOLLOWING CAREFULLY"
    echo "We will now generate a new DHPARAMS 4096 bit safe primes for your openSSL server this is recommended."
    echo "This will take a while. A VERY long while. So go grab a coffee."
    openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
    fi

    echo    # (optional) move to a new line
    echo "Updating Package Lists"
    apt-get update
    echo "Downloading EFF Certbot and changing permissions"
    curl -o /usr/sbin/certbot-auto https://dl.eff.org/certbot-auto
    chmod a+x /usr/sbin/certbot-auto
    echo "Now Installing: OpenJDK 7"
    sleep 1
    echo y | apt-get install openjdk-7-jre
    echo "Now Installing: Python 2.7"
    sleep 5
    echo y | apt-get install python2.7-dev
    echo "Now Installing: nginx"
    sleep 5
    echo y | apt-get install nginx 
    echo "Now Installing: unifi"
    sleep 5
    echo y | apt-get install unifi 
    sleep 5
    
    echo "About to request your certificate for $NAME"
    service nginx stop
    echo y | certbot-auto certonly -d $NAME --standalone --standalone-supported-challenges http-01 --email $EMAIL
    service nginx start

    echo "Adding certificate to UniFi Controller for $NAME"
    service unifi stop
    echo aircontrolenterprise | openssl pkcs12 -export -inkey /etc/letsencrypt/live/$NAME/privkey.pem -in /etc/letsencrypt/live/$NAME/cert.pem -name unifi -out /etc/letsencrypt/live/$NAME/keys.p12 -password stdin
    echo y | keytool -importkeystore -srckeystore /etc/letsencrypt/live/$NAME/keys.p12 -srcstoretype pkcs12 -destkeystore /usr/lib/unifi/data/keystore -storepass aircontrolenterprise -srcstorepass aircontrolenterprise
    service unifi start

    echo "Writing nginx proxy configuration."
    service nginx stop
    echo -e "server {\n\
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
        ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:DHE-RSA-AES256-SHA;
        add_header Strict-Transport-Security max-age=31536000;\n\
        add_header X-Frame-Options DENY;\n\
        error_log /var/log/unifi/nginx.log;\n\
        proxy_cache off;\n\
        proxy_store off;\n\
        location / {\n\
        proxy_cookie_domain $NAME \$host;\n\
        sub_filter $NAME \$host;\n\
        proxy_set_header X-Real-IP \$remote_addr;\n\
        proxy_set_header HOST \$http_host;\n\
        proxy_pass https://localhost:8443;\n\
        }\n\
        }\n\
        " > /etc/nginx/sites-enabled/default
    echo "Waiting 10 seconds for nginx start"
    sleep 10
    service nginx start

    # THIS NEW BLOCK INSTALLS A CRONTAB INTO cron.monthly if this is not desired remove it
    # Automatic LE Ceritficate renewals.
    echo "Writing Crontab for LetsEncrypt renewals to /etc/cron.monthly/le-unifi-renew"
    echo -e "#!/bin/sh\n\
    service nginx stop\n\
    echo y | ./certbot-auto renew --standalone --standalone-supported-challenges http-01\n\
    service nginx start\n\
    service unifi stop\n\
    echo aircontrolenterprise | openssl pkcs12 -export -inkey /etc/letsencrypt/live/$NAME/privkey.pem -in /etc/letsencrypt/live/$NAME/cert.pem -name unifi -out /etc/letsencrypt/live/$NAME/keys.p12 -password stdin\n\
    echo y | keytool -importkeystore -srckeystore /etc/letsencrypt/live/$NAME/keys.p12 -srcstoretype pkcs12 -destkeystore /usr/lib/unifi/data/keystore -storepass aircontrolenterprise -srcstorepass aircontrolenterprise\n\
    service unifi start" > /etc/cron.monthly/le-unifi-renew
        chmod +x /etc/cron.monthly/le-unifi-renew

    echo -e "\n\n\n\nINSTALLATION COMPLETE \nYou will see a bad gateway error on https://$NAME/\nWhile the controller performs its first-time initialisation\n"
