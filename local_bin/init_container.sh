#!/bin/bash

# set -e

php -v

# setup server root
test ! -d "$HOME_SITE" && echo "INFO: $HOME_SITE not found. creating..." && mkdir -p $HOME_SITE
if [ ! $WEBSITES_ENABLE_APP_SERVICE_STORAGE ]; then
    echo "INFO: NOT in Azure, chown for "$HOME_SITE  
    chown -R www-data:www-data $HOME_SITE 
fi 

echo "Setup openrc ..." && openrc && touch /run/openrc/softlevel

# setup nginx log dir
# http://nginx.org/en/docs/ngx_core_module.html#error_log
# sed -i "s|error_log /var/log/error.log;|error_log stderr;|g" /etc/nginx/nginx.conf

echo "INFO: creating /run/php/php-fpm.sock ..."
test -e /run/php/php-fpm.sock && rm -f /run/php/php-fpm.sock
mkdir -p /run/php
touch /run/php/php-fpm.sock
if [ ! $WEBSITES_ENABLE_APP_SERVICE_STORAGE ]; then
    echo "INFO: NOT in Azure, chown for /run/php/php-fpm.sock"  
    chown -R www-data:www-data /run/php/php-fpm.sock 
fi 
chmod 777 /run/php/php-fpm.sock

# log rotate will hung with web app, only start it with other environments.
if [ ! $WEBSITES_ENABLE_APP_SERVICE_STORAGE ]; then
    echo "NOT in AZURE, Start crond, log rotate..."
    crond
fi 

test ! -d "$SUPERVISOR_LOG_DIR" && echo "INFO: $SUPERVISOR_LOG_DIR not found. creating ..." && mkdir -p "$SUPERVISOR_LOG_DIR"
test ! -d "$NGINX_LOG_DIR" && echo "INFO: Log folder for nginx/php not found. creating..." && mkdir -p "$NGINX_LOG_DIR"
test ! -e /home/50x.html && echo "INFO: 50x file not found. createing..." && cp /usr/share/nginx/html/50x.html /home/50x.html

sed -i "s/SSH_PORT/$SSH_PORT/g" /etc/ssh/sshd_config
# echo "Starting SSH ..."
echo "Starting php-fpm ..."
echo "Starting Nginx ..."

#Configure keys for ssh server
if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
  # generate fresh rsa key
  ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
fi

if [ ! -f "/etc/ssh/ssh_host_dsa_key" ]; then
  # generate fresh dsa key
  ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
fi

if [ ! -f "/etc/ssh/ssh_host_ecdsa_key" ]; then
  # generate fresh ecdsa key
  ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t dsa
fi

if [ ! -f "/etc/ssh/ssh_host_ed25519_key" ]; then
  # generate fresh ecdsa key
  ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -N '' -t dsa
fi

#prepare run dir
if [ ! -d "/var/run/sshd" ]; then
  mkdir -p /var/run/sshd
fi

cd /usr/bin/
supervisord -c /etc/supervisord.conf

