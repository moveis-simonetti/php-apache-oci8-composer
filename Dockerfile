# Container Base
FROM php:8.3-apache

ENV \
    NR_ENABLED=false \
    NR_APP_NAME="" \
    NR_LICENSE_KEY="" \
    NR_VERSION="" \
    PHP_BUILD_DATE="20211130" \
    PHP_OPCACHE_ENABLED=false \
    SESSION_HANDLER=false \
    SESSION_HANDLER_NAME="" \
    SESSION_HANDLER_PATH="" \
    XDEBUG_AUTOSTART=false \
    XDEBUG_CONNECT_BACK=true \
    XDEBUG_ENABLED=false \
    XDEBUG_IDEKEY="docker" \
    XDEBUG_VERSION="-3.3.2" \
    XDEBUG_REMOTE_PORT=9000 \
    PHP_EXTENSION_WDDX=1 \
    PHP_OPENSSL=1

ENV CONTAINER_STARTED_LOCK=/var/lock/container.starting

RUN apt-get update && apt-get install -y --no-install-recommends wget vim supervisor libfreetype6-dev libjpeg-dev libjpeg62-turbo-dev \
    libmcrypt-dev libpng-dev libssl-dev libaio1 git libcurl4-openssl-dev libxslt-dev \
    libldap2-dev libicu-dev libc-client-dev libkrb5-dev libsqlite3-dev libedit-dev \
    sudo zlib1g zlib1g-dev libzip4 libzip-dev zip unzip librabbitmq-dev musl-dev && \
    rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite unique_id

RUN docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) bcmath gd pdo_mysql calendar exif gettext shmop soap sockets intl pcntl xsl ldap imap ftp

RUN echo "---> Adding Redis" && \
    pecl install redis && \
    docker-php-ext-enable redis

RUN echo "---> Adding xDebug" && \
    pecl install "xdebug${XDEBUG_VERSION}"

RUN echo "---> Adding Zip" && \
    pecl install zip && \
    docker-php-ext-enable zip

RUN echo "---> Adding AMQp" && \
    apt-get update && apt-get install -y -f librabbitmq-dev libssh-dev \
    && docker-php-source extract \
    && mkdir /usr/src/php/ext/amqp \
    && curl -L https://github.com/php-amqp/php-amqp/archive/master.tar.gz | tar -xzC /usr/src/php/ext/amqp --strip-components=1 \
    && docker-php-ext-install amqp \
    && docker-php-ext-enable amqp

RUN echo "---> Configure Opcache" && \
    docker-php-ext-install opcache && \
    echo "opcache.enable=0" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.enable_cli=0" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

RUN echo "---> Adding NewRelic" && \
    apt-get update && apt-get install -y -q --no-install-recommends --no-install-suggests gnupg2 \
    && echo 'deb http://apt.newrelic.com/debian/ newrelic non-free' | sudo tee /etc/apt/sources.list.d/newrelic.list \
    && wget -O- https://download.newrelic.com/548C16BF.gpg | sudo apt-key add - \
    && sudo apt-get update && apt-get install -y -q --no-install-recommends --no-install-suggests newrelic-php5 \
    && NR_INSTALL_USE_CP_NOT_LN=1 NR_INSTALL_SILENT=1 newrelic-install install \
    && chown www-data:www-data /usr/local/etc/php/conf.d/newrelic.ini && chmod a+rw /usr/local/etc/php/conf.d/newrelic.ini \
    && apt-get remove -y gnupg2 && rm -rf /var/lib/apt/lists/* \
    && echo "newrelic.distributed_tracing_enabled = false" | sudo tee -a /usr/local/etc/php/conf.d/newrelic.ini \
    && echo "newrelic.application_logging.enabled = false" | sudo tee -a /usr/local/etc/php/conf.d/newrelic.ini \
    && echo "newrelic.enabled = false" | sudo tee -a /usr/local/etc/php/conf.d/newrelic.ini

RUN echo "---> Adding Tini" && \
    wget -O /tini https://github.com/krallin/tini/releases/download/v0.18.0/tini-static && \
    chmod +x /tini

RUN echo "---> Config sudoers" && \
    echo "www-data  ALL = ( ALL ) NOPASSWD: ALL" >> /etc/sudoers

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN echo "---> Fix permissions" \
    && chown -R www-data:www-data /var/log/apache2 \
    && mkdir /var/www/.composer && chown -R www-data:www-data /var/www/.composer

COPY configs/ports.conf /etc/apache2/ports.conf
COPY configs/logs.conf /etc/apache2/conf-enabled/logs.conf
COPY configs/php-errors.ini /usr/local/etc/php/conf.d/php-errors.ini
COPY apache-run.sh /usr/bin/apache-run
COPY ./bin /usr/bin/

RUN chmod a+x \
    /usr/bin/apache-run \
    /usr/bin/xdebug-set-mode \
    /usr/bin/post-startup-hook

USER www-data

WORKDIR "/var/www/html"

EXPOSE 8080 9001

CMD ["/tini", "--", "/usr/bin/apache-run"]
