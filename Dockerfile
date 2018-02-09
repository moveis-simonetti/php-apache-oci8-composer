# Container Base
FROM php:7.2-apache

ENV http_proxy ${HTTP_PROXY}
ENV https_proxy ${HTTP_PROXY}

COPY configs/ports.conf /etc/apache2/ports.conf
COPY apache-run.sh /usr/bin/apache-run

RUN chmod a+x /usr/bin/apache-run

# Install libs
RUN apt-get update && apt-get install -y wget supervisor libfreetype6-dev \
        libjpeg62-turbo-dev libpng-dev git libxslt-dev \
       libldap2-dev libicu-dev libc-client-dev libkrb5-dev

RUN a2enmod rewrite

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure hash --with-mhash \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) bcmath \
        gd pdo_mysql calendar exif gettext \
        xsl ldap intl imap \
        pcntl shmop soap sockets wddx

# Install ssh2
RUN wget https://www.libssh2.org/download/libssh2-1.8.0.tar.gz && wget https://pecl.php.net/get/ssh2-1.1.2.tgz \
    && tar vxzf libssh2-1.8.0.tar.gz && tar vxzf ssh2-1.1.2.tgz \
    && cd libssh2-1.8.0 && ./configure \
    && make && make install \
    && cd ../ssh2-1.1.2 && phpize && ./configure --with-ssh2 \
    && make && make install \
    && echo "extension=ssh2.so" >> /usr/local/etc/php/conf.d/ssh2.ini

# Install oci8
RUN apt-get update && apt-get -y install wget bsdtar libaio1 && \
    wget -qO- https://raw.githubusercontent.com/caffeinalab/php-fpm-oci8/master/oracle/instantclient-basic-linux.x64-12.2.0.1.0.zip | bsdtar -xvf- -C /usr/local && \
    wget -qO- https://raw.githubusercontent.com/caffeinalab/php-fpm-oci8/master/oracle/instantclient-sdk-linux.x64-12.2.0.1.0.zip | bsdtar -xvf-  -C /usr/local && \
    wget -qO- https://raw.githubusercontent.com/caffeinalab/php-fpm-oci8/master/oracle/instantclient-sqlplus-linux.x64-12.2.0.1.0.zip | bsdtar -xvf- -C /usr/local && \
    ln -s /usr/local/instantclient_12_2 /usr/local/instantclient && \
    ln -s /usr/local/instantclient/libclntsh.so.* /usr/local/instantclient/libclntsh.so && \
    ln -s /usr/local/instantclient/lib* /usr/lib && \
    ln -s /usr/local/instantclient/sqlplus /usr/bin/sqlplus && \
    docker-php-ext-configure oci8 --with-oci8=instantclient,/usr/local/instantclient && \
    docker-php-ext-install oci8 && \
    rm -rf /var/lib/apt/lists/* && \
    php -v

# Install redis
RUN pecl install redis \
    && echo "extension=redis.so" >> /usr/local/etc/php/conf.d/redis.ini

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# Install XDebug
RUN pecl install xdebug

# Run composer install
CMD /usr/bin/apache-run

EXPOSE 8080
