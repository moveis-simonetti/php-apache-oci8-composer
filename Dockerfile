FROM lojassimonetti/php-apache-oci8-composer:php8dot2

USER root

RUN echo "---> Mongo DB" && \
    pecl install mongodb && \
    docker-php-ext-enable mongodb

USER www-data:www-data
