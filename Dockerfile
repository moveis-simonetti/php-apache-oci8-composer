# Container Base
FROM php:7.0-apache

ENV http_proxy ${HTTP_PROXY}
ENV https_proxy ${HTTP_PROXY}
ENV XDEBUG_ENABLED=false
ENV NR_ENABLED=false
ENV NR_APP_NAME=""
ENV NR_LICENSE_KEY=""
ENV SESSION_HANDLER=false
ENV SESSION_HANDLER_NAME=""
ENV SESSION_HANDLER_PATH=""

RUN apt-get update && apt-get install -y wget vim supervisor zip libfreetype6-dev libjpeg62-turbo-dev \
       libmcrypt-dev libpng-dev libssl-dev libaio1 git libcurl4-openssl-dev libxslt-dev \
       libldap2-dev libicu-dev libc-client-dev libkrb5-dev libsqlite3-dev libedit-dev

RUN a2enmod rewrite

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure hash --with-mhash \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) iconv bcmath mcrypt \
        gd pdo_mysql calendar curl exif ftp gettext \
        hash xsl ldap intl imap pdo_sqlite mbstring \
        mcrypt pcntl readline shmop soap sockets wddx zip

RUN pecl install redis \
    && echo "extension=redis.so" >> /usr/local/etc/php/conf.d/redis.ini

RUN echo "---> Adding Support for NewRelic" && \
    mkdir /tmp/newrelic /scripts/ && \
    cd /tmp/newrelic && \
    wget -r -l1 -nd -A"linux.tar.gz" https://download.newrelic.com/php_agent/release/ && \
    gzip -dc newrelic*.tar.gz | tar xf - && \
    cd newrelic-php5* && \
    rm -f /usr/local/lib/php/extensions/no-debug-non-zts-20151012/newrelic.so && \
    cp ./agent/x64/newrelic-20151012.so /usr/local/lib/php/extensions/no-debug-non-zts-20151012/newrelic.so && \
    cp ./daemon/newrelic-daemon.x64 /usr/bin/newrelic-daemon && \
    cp ./scripts/newrelic.ini.template /scripts/newrelic.ini && \
    mkdir /var/log/newrelic

RUN echo "---> Adding Tini" && \
    wget -O /tini https://github.com/krallin/tini/releases/download/v0.18.0/tini-static && \
    chmod +x /tini

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

RUN pecl install xdebug

COPY configs/ports.conf /etc/apache2/ports.conf
COPY apache-run.sh /usr/bin/apache-run

RUN chmod a+x /usr/bin/apache-run

USER www-data

WORKDIR "/var/www/html"

EXPOSE 8080 9001

ENTRYPOINT ["/tini", "--"]

CMD ["/usr/bin/apache-run"]