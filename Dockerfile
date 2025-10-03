FROM lojassimonetti/php-apache-oci8-composer:php8dot3

USER root

RUN echo "---> Mongo DB" && \
    pecl install mongodb-1.21.0 && \
    docker-php-ext-enable mongodb

USER www-data:www-data
