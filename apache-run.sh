#!/bin/bash

if [[ ${XDEBUG_ENABLED} == true ]]; then
    sudo rm -f /usr/local/etc/php/conf.d/xdebug.ini || true
    echo "zend_extension=xdebug.so" | sudo tee -a /usr/local/etc/php/conf.d/xdebug.ini
    echo "xdebug.var_display_max_depth=5" | sudo tee -a /usr/local/etc/php/conf.d/xdebug.ini
    echo "xdebug.idekey=${XDEBUG_IDEKEY}" | sudo tee -a /usr/local/etc/php/conf.d/xdebug.ini
    echo "xdebug.mode=debug" | sudo tee -a /usr/local/etc/php/conf.d/xdebug.ini
    echo "xdebug.client_port=${XDEBUG_REMOTE_PORT:-$XDEBUG_CLIENT_PORT}" | sudo tee -a /usr/local/etc/php/conf.d/xdebug.ini

    export XDEBUG_AUTOSTART=${XDEBUG_AUTOSTART:-$XDEBUG_START_WITH_REQUEST}
    [[ ${XDEBUG_AUTOSTART} == true ]] && {
        echo "xdebug.start_with_request=yes" | sudo tee -a /usr/local/etc/php/conf.d/xdebug.ini
    } || echo "xdebug.start_with_request=no" | sudo tee -a /usr/local/etc/php/conf.d/xdebug.ini

    export XDEBUG_CONNECT_BACK=${XDEBUG_CONNECT_BACK:-$XDEBUG_DISCOVER_CLIENT_HOST}
    [[ ${XDEBUG_CONNECT_BACK} == true ]] && {
        echo "xdebug.discover_client_host=1" | sudo tee -a /usr/local/etc/php/conf.d/xdebug.ini
    } || echo "xdebug.discover_client_host=0" | sudo tee -a /usr/local/etc/php/conf.d/xdebug.ini
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
