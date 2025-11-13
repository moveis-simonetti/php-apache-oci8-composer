FROM lojassimonetti/php-apache-oci8-composer:php8dot4

USER root

RUN echo "---> GRPC" && \
    pecl install grpc && \
    docker-php-ext-enable grpc

USER www-data:www-data
