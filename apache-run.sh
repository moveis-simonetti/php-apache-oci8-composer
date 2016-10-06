#!/usr/bin/env bash

usermod -u 1000 www-data \
    && cd /var/www/html && composer install && rm -rf var/cache/* var/logs/* \
    && chown -R www-data:www-data /var/www/html/var/cache && chmod 777 /var/www/html/var/cache \
    && chown -R www-data:www-data /var/www/html/var/logs && chmod 777 /var/www/html/var/logs \
    && apache2-foreground