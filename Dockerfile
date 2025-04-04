FROM php:8.2-fpm

# COPY ./docker/app/debian.sources /etc/apt/sources.list.d/debian.sources

RUN apt-get update && \
    apt-get install -y curl libpq-dev libzip-dev zip unzip git libaio1 && \
    apt-get clean && \
    rm -rf /var/cache/apt/archives/* /tmp/* /var/tmp/* \

RUN docker-php-ext-install pdo_pgsql opcache zip && \
    pecl install xdebug redis

# Переносим
ADD oracle/instantclient_21_17.tar.gz /usr/local/
RUN ln -s /usr/local/instantclient_21_17 /usr/local/instantclient

# Настройка окружения
ENV LD_LIBRARY_PATH="/use/local/instantclient:${LD_LIBRARY_PATH}"
ENV ORACLE_HOME="/usr/local/instantclient"
ENV C_INCLUDE_PATH="/usr/local/instantclient/sdk/include:${C_INCLUDE_PATH}"


RUN ln -s /usr/local/instantclient_21_17 /usr/local/instantclient
RUN rm /usr/local/instantclient/libclntsh.so
RUN ln -s /usr/local/instantclient/libclntsh.so.21.1 /usr/local/instantclient/libclntsh.so
RUN ln -s /usr/local/instantclient/lib* /usr/lib

# Установка OCI8
RUN echo "instantclient,/usr/local/instantclient" | pecl install oci8 \
    && docker-php-ext-enable oci8 redis

# Для PDO_OCI (если требуется)
RUN docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/usr/local/instantclient,21.17 \
    && docker-php-ext-install pdo_oci

WORKDIR /var/www/

#php-fpm сокет для nginx:
EXPOSE 9000