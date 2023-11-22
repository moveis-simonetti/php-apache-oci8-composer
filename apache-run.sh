#!/bin/bash

set -e

rm -f $CONTAINER_STARTED_LOCK

if [[ ${XDEBUG_ENABLED} == true ]]; then
    sudo -E xdebug-set-mode ${XDEBUG_MODE:-debug}
fi

sudo -E newrelic-setup
sudo -E opcache-setup

if [[ ${SESSION_HANDLER} == true ]]; then
    echo "session.save_handler = ${SESSION_HANDLER_NAME}" | sudo tee -a /usr/local/etc/php/conf.d/session-handler.ini
    echo "session.save_path = ${SESSION_HANDLER_PATH}" | sudo tee -a /usr/local/etc/php/conf.d/session-handler.ini
fi

sudo rm -rf var/cache/* var/logs/* &&
    sudo mkdir -p /var/www/html/var/cache &&
    sudo mkdir -p /var/www/html/var/logs &&
    sudo mkdir -p /var/www/html/var/sessions &&
    sudo chown -R www-data:www-data /var/www/html/var/cache && chmod 777 /var/www/html/var/cache &&
    sudo chown -R www-data:www-data /var/www/html/var/logs && chmod 777 /var/www/html/var/logs &&
    sudo chown -R www-data:www-data /var/www/html/var/sessions && chmod 777 /var/www/html/var/sessions

post-startup-hook

touch $CONTAINER_STARTED_LOCK

exec apache2-foreground
