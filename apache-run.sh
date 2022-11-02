#!/bin/bash

if [[ ${XDEBUG_ENABLED} == true ]]; then
    sudo xdebug-set-mode ${XDEBUG_MODE:-debug}
fi

if [[ ${NR_ENABLED} == true ]]; then
    sudo sed -i -e "s/"REPLACE_WITH_REAL_KEY"/${NR_LICENSE_KEY}/g" /usr/local/etc/php/conf.d/newrelic.ini
    sudo sed -i -e "s/PHP Application/${NR_APP_NAME}/g" /usr/local/etc/php/conf.d/newrelic.ini
else
    echo "newrelic.enabled = false" | sudo tee -a /usr/local/etc/php/conf.d/newrelic.ini
fi

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

exec apache2-foreground
