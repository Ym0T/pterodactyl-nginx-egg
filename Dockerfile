FROM debian:bookworm-slim

LABEL author="Ym0t" maintainer="YmoT@tuta.com"

ARG PHP_VERSION="8.3"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y apt-transport-https lsb-release ca-certificates wget nginx \
    && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
    && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        php${PHP_VERSION} \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-mysqlnd \
        php${PHP_VERSION}-PDO \
        php${PHP_VERSION}-psr \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-calendar \
        php${PHP_VERSION}-ctype \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-dom \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-fileinfo \
        php${PHP_VERSION}-ftp \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-gettext \
        php${PHP_VERSION}-gmp \
        php${PHP_VERSION}-iconv \
        php${PHP_VERSION}-igbinary \
        php${PHP_VERSION}-imagick \
        php${PHP_VERSION}-imap \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-ldap \
        php${PHP_VERSION}-exif \
        php${PHP_VERSION}-memcache \
        php${PHP_VERSION}-mongodb \
        php${PHP_VERSION}-msgpack \
        php${PHP_VERSION}-mysqli \
        php${PHP_VERSION}-odbc \
        php${PHP_VERSION}-pcov \
        php${PHP_VERSION}-pgsql \
        php${PHP_VERSION}-Phar \
        php${PHP_VERSION}-posix \
        php${PHP_VERSION}-ps \
        php${PHP_VERSION}-pspell \
        php${PHP_VERSION}-readline \
        php${PHP_VERSION}-shmop \
        php${PHP_VERSION}-SimpleXML \
        php${PHP_VERSION}-soap \
        php${PHP_VERSION}-sockets \
        php${PHP_VERSION}-sqlite3 \
        php${PHP_VERSION}-sysvmsg \
        php${PHP_VERSION}-sysvsem \
        php${PHP_VERSION}-sysvshm \
        php${PHP_VERSION}-tokenizer \
        php${PHP_VERSION}-xmlreader \
        php${PHP_VERSION}-xmlwriter \
        php${PHP_VERSION}-xsl \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-mailparse \
        php${PHP_VERSION}-memcached \
        php${PHP_VERSION}-inotify \
        php${PHP_VERSION}-maxminddb \
        php${PHP_VERSION}-protobuf \
        php${PHP_VERSION}-OPcache \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -d /home/container/ -s /bin/bash container
ENV USER=container HOME=/home/container

WORKDIR /home/container

STOPSIGNAL SIGINT

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD /entrypoint.sh
