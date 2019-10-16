#!/bin/bash

if [[ $XDEBUG_ENABLED == true ]]; then
    echo "zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20170718/xdebug.so" | sudo tee -a /usr/local/etc/php/conf.d/xdebug.ini
    echo "xdebug.var_display_max_depth=5" | sudo tee -a /usr/local/etc/php/conf.d/xdebug.ini
    echo "xdebug.idekey=${XDEBUG_IDEKEY}" | sudo tee -a /usr/local/etc/php/conf.d/xdebug.ini
    echo "xdebug.remote_enable=1" | sudo tee -a /usr/local/etc/php/conf.d/xdebug.ini
    echo "xdebug.remote_port=9000" | sudo tee -a /usr/local/etc/php/conf.d/xdebug.ini

    [[ ${XDEBUG_AUTOSTART} == true ]] && {
        echo "xdebug.remote_autostart=on" | sudo tee -a /usr/local/etc/php/conf.d/xdebug.ini
    } || echo "xdebug.remote_autostart=off" | sudo tee -a /usr/local/etc/php/conf.d/xdebug.ini

    [[ ${XDEBUG_CONNECT_BACK} == true ]] && {
        echo "xdebug.remote_connect_back=1" | sudo tee -a /usr/local/etc/php/conf.d/xdebug.ini
    } || echo "xdebug.remote_connect_back=0" | sudo tee -a /usr/local/etc/php/conf.d/xdebug.ini
fi

if [[ $NR_ENABLED == true ]]; then
    sudo sed -i -e "s/"REPLACE_WITH_REAL_KEY"/$NR_LICENSE_KEY/g" /scripts/newrelic.ini
    sudo sed -i -e "s/PHP Application/$NR_APP_NAME/g" /scripts/newrelic.ini
    sudo cp /scripts/newrelic.ini /usr/local/etc/php/conf.d/newrelic.ini
fi

if [[ $SESSION_HANDLER == true ]]; then
    echo "session.save_handler = $SESSION_HANDLER_NAME" | sudo tee -a /usr/local/etc/php/conf.d/session-handler.ini
    echo "session.save_path = $SESSION_HANDLER_PATH" | sudo tee -a /usr/local/etc/php/conf.d/session-handler.ini
fi

sudo rm -rf var/cache/* var/logs/* &&
    sudo mkdir -p /var/www/html/var/cache &&
    sudo mkdir -p /var/www/html/var/logs &&
    sudo mkdir -p /var/www/html/var/sessions &&
    sudo chown -R www-data:www-data /var/www/html/var/cache && chmod 777 /var/www/html/var/cache &&
    sudo chown -R www-data:www-data /var/www/html/var/logs && chmod 777 /var/www/html/var/logs &&
    sudo chown -R www-data:www-data /var/www/html/var/sessions && chmod 777 /var/www/html/var/sessions

exec apache2-foreground
