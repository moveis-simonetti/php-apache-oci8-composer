# Container Base
FROM php:7.3-apache

ENV http_proxy ${HTTP_PROXY}
ENV https_proxy ${HTTP_PROXY}
ENV XDEBUG_ENABLED=false
ENV XDEBUG_VERSION="-2.7.0beta1"
ENV NR_ENABLED=false
ENV NR_APP_NAME=""
ENV NR_LICENSE_KEY=""
ENV NR_VERSION=""
ENV PHP_BUILD_DATE="20180731"
ENV PHP_OPCACHE_ENABLED=false
ENV SESSION_HANDLER=false
ENV SESSION_HANDLER_NAME=""
ENV SESSION_HANDLER_PATH=""

RUN apt-get update && apt-get install -y wget vim supervisor libfreetype6-dev libjpeg62-turbo-dev \
    libmcrypt-dev libpng-dev libssl-dev libaio1 git libcurl4-openssl-dev libxslt-dev \
    libldap2-dev libicu-dev libc-client-dev libkrb5-dev libsqlite3-dev libedit-dev \
    sudo zlib1g zlib1g-dev libzip4 libzip-dev zip

RUN a2enmod rewrite

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure hash --with-mhash \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) bcmath \
    gd pdo_mysql calendar exif gettext \
    hash xsl ldap intl imap \
    pcntl shmop soap sockets wddx

RUN pecl install redis \
    && docker-php-ext-enable redis

RUN echo "---> Adding xDebug" && \
    pecl install xdebug${XDEBUG_VERSION}

RUN echo "---> Adding Zip" && \
    pecl install zip && \
    docker-php-ext-enable zip

RUN echo "---> Configure Opcache" && \
    docker-php-ext-install opcache && \
    echo "opcache.enable=0" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.enable_cli=0" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

RUN echo "---> Adding Support for NewRelic" && \
    mkdir /tmp/newrelic /scripts/ && \
    cd /tmp/newrelic && \
    wget -r -l1 -nd -A"linux.tar.gz" https://download.newrelic.com/php_agent/release/ && \
    gzip -dc newrelic*.tar.gz | tar xf - && \
    cd newrelic-php5* && \
    rm -f /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_BUILD_DATE}/newrelic.so && \
    cp ./agent/x64/newrelic-${PHP_BUILD_DATE}.so /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_BUILD_DATE}/newrelic.so && \
    cp ./daemon/newrelic-daemon.x64 /usr/bin/newrelic-daemon && \
    cp ./scripts/newrelic.ini.template /scripts/newrelic.ini && \
    mkdir /var/log/newrelic &&  \
    chown -R www-data:www-data /var/log/newrelic && \
    rm -rf /tmp/*

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
