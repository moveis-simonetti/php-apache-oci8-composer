# Container Base
FROM php:7.4.0-apache

ENV http_proxy ${HTTP_PROXY}
ENV https_proxy ${HTTP_PROXY}
ENV NR_ENABLED=false
ENV NR_APP_NAME=""
ENV NR_LICENSE_KEY=""
ENV NR_VERSION=""
ENV PHP_BUILD_DATE="20190902"
ENV PHP_OPCACHE_ENABLED=false
ENV SESSION_HANDLER=false
ENV SESSION_HANDLER_NAME=""
ENV SESSION_HANDLER_PATH=""
ENV XDEBUG_AUTOSTART=false
ENV XDEBUG_CONNECT_BACK=true
ENV XDEBUG_ENABLED=false
ENV XDEBUG_IDEKEY="docker"
ENV XDEBUG_VERSION="-2.8.1"
ENV PHP_EXTENSION_WDDX=1
ENV PHP_OPENSSL=1

RUN apt-get update && apt-get install -y --no-install-recommends wget vim supervisor libfreetype6-dev libjpeg62-turbo-dev \
    libmcrypt-dev libpng-dev libssl-dev libaio1 git libcurl4-openssl-dev libxslt-dev \
    libldap2-dev libicu-dev libc-client-dev libkrb5-dev libsqlite3-dev libedit-dev \
    sudo zlib1g zlib1g-dev libzip4 libzip-dev zip unzip librabbitmq-dev && \
    rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite

RUN docker-php-ext-configure gd \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) bcmath gd pdo_mysql calendar exif gettext shmop soap sockets intl pcntl xsl ldap imap

RUN echo "---> Adding Redis" && \
    pecl install redis && \
    docker-php-ext-enable redis

RUN echo "---> Adding xDebug" && \
    pecl install xdebug${XDEBUG_VERSION}

RUN echo "---> Adding Zip" && \
    pecl install zip && \
    docker-php-ext-enable zip

RUN echo "---> Adding AMQP" && \
    pecl install amqp && \
    docker-php-ext-enable amqp

RUN echo "---> Configure Opcache" && \
    docker-php-ext-install opcache && \
    echo "opcache.enable=0" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.enable_cli=0" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

RUN apt-get update && apt-get install -y -q --no-install-recommends --no-install-suggests gnupg2 \
    && echo 'deb http://apt.newrelic.com/debian/ newrelic non-free' | sudo tee /etc/apt/sources.list.d/newrelic.list \
    && wget -O- https://download.newrelic.com/548C16BF.gpg | sudo apt-key add - \
    && sudo apt-get update && apt-get install -y -q --no-install-recommends --no-install-suggests newrelic-php5 \
    && NR_INSTALL_USE_CP_NOT_LN=1 NR_INSTALL_SILENT=1 newrelic-install install \
    && chown www-data:www-data /usr/local/etc/php/conf.d/newrelic.ini && chmod a+rw /usr/local/etc/php/conf.d/newrelic.ini \
    && apt-get remove -y gnupg2 && rm -rf /var/lib/apt/lists/*

RUN echo "---> Adding Tini" && \
    wget -O /tini https://github.com/krallin/tini/releases/download/v0.18.0/tini-static && \
    chmod +x /tini

RUN echo "---> Config sudoers" && \
    echo "www-data  ALL = ( ALL ) NOPASSWD: ALL" >> /etc/sudoers

RUN echo "---> Fix Logs permissions" && \
    chown -R www-data:www-data /var/log/apache2

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer && \
    mkdir /var/www/.composer && chown -R www-data:www-data /var/www/.composer

COPY configs/ports.conf /etc/apache2/ports.conf
COPY apache-run.sh /usr/bin/apache-run

RUN chmod a+x /usr/bin/apache-run

USER www-data

WORKDIR "/var/www/html"

EXPOSE 8080 9001

CMD ["/tini", "--", "/usr/bin/apache-run"]
