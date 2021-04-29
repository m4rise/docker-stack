FROM php:7.4.9-apache-buster

# Surpresses debconf complaints of trying to install apt packages interactively
# https://github.com/moby/moby/issues/4032#issuecomment-192327844

ARG DEBIAN_FRONTEND=noninteractive
ARG USER_HOSTMACHINE_UID
ARG USER_HOSTMACHINE_GID
ARG USER_NAME

RUN groupadd -g ${USER_HOSTMACHINE_GID} ${USER_NAME} && \
    useradd --uid ${USER_HOSTMACHINE_UID} -g ${USER_NAME} ${USER_NAME}

# Update
RUN apt-get -y update --fix-missing && \
    apt-get upgrade -y && \
    apt-get --no-install-recommends install -y apt-utils && \
    rm -rf /var/lib/apt/lists/*

# Install useful tools and install important libaries
RUN apt-get -y update \
    && \
        apt-get -y --no-install-recommends install \
        nano wget dialog libsqlite3-dev libsqlite3-0 \
        default-mysql-client zlib1g-dev libzip-dev libicu-dev \
    && \
        apt-get -y --no-install-recommends install --fix-missing \
        apt-utils build-essential git curl libonig-dev libcurl4 libcurl4-openssl-dev zip openssl \
    && \
        rm -rf /var/lib/apt/lists/* \
    && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install xdebug
RUN pecl install xdebug-3.0.4 && \
    docker-php-ext-enable xdebug

# Install redis
RUN pecl install redis-5.3.4 && \
    docker-php-ext-enable redis

# Install imagick
RUN apt-get update && \
    apt-get -y --no-install-recommends install --fix-missing libmagickwand-dev && \
    rm -rf /var/lib/apt/lists/* && \
    pecl install imagick && \
    docker-php-ext-enable imagick

# Other PHP7 Extensions
RUN docker-php-ext-install pdo_mysql && \
    docker-php-ext-install pdo_sqlite && \
    docker-php-ext-install mysqli && \
    docker-php-ext-install curl && \
    docker-php-ext-install tokenizer && \
    docker-php-ext-install json && \
    docker-php-ext-install zip && \
    docker-php-ext-install -j$(nproc) intl && \
    docker-php-ext-install mbstring && \
    docker-php-ext-install gettext && \
    docker-php-ext-install exif

# Install Freetype and gd
RUN apt-get -y update \
    && \
        apt-get --no-install-recommends install -y \
        libfreetype6-dev libjpeg62-turbo-dev libpng-dev \
    && \
        rm -rf /var/lib/apt/lists/* \
    && \
        docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg \
    && \
        docker-php-ext-install gd

# Install Symfony binary
RUN wget https://get.symfony.com/cli/installer -O - | bash && \
    mv /root/.symfony/bin/symfony /usr/local/bin/symfony

# Install php-cs-fixer
RUN wget https://cs.symfony.com/download/php-cs-fixer-v2.phar -O php-cs-fixer  && \
    chmod a+x php-cs-fixer && \
    mv php-cs-fixer /usr/local/bin/php-cs-fixer

# Enable apache modules
RUN a2enmod rewrite headers ssl
RUN service apache2 restart

WORKDIR /var/www

# Cleanup
RUN rm -rf /usr/src/*

USER ${USER_NAME}
