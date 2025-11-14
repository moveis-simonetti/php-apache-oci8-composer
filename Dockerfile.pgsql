FROM lojassimonetti/php-apache-oci8-composer:php8dot3

USER root

RUN echo "---> PGSQL" && \
    apt-get update && apt-get install -y --no-install-recommends libpq-dev && \
    docker-php-ext-install pdo_pgsql

USER www-data:www-data
