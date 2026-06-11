FROM composer:2 AS composer-bin

FROM node:22-bookworm-slim AS frontend-builder

WORKDIR /workspace

COPY . .

RUN npm install \
    && npm run build \
    && cd packages/Webkul/Admin && npm install && npm run build \
    && cd /workspace/packages/Webkul/Installer && npm install && npm run build \
    && cd /workspace/packages/Webkul/WebForm && npm install && npm run build

FROM php:8.3-apache-bookworm

ARG DEBIAN_FRONTEND=noninteractive
ARG APACHE_DOCUMENT_ROOT=/var/www/html/public

ENV COMPOSER_ALLOW_SUPERUSER=1
ENV APACHE_DOCUMENT_ROOT=${APACHE_DOCUMENT_ROOT}

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    zip \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libkrb5-dev \
    libc-client-dev \
    libonig-dev \
    libpng-dev \
    libxml2-dev \
    libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install -j"$(nproc)" \
        bcmath \
        calendar \
        exif \
        gd \
        imap \
        intl \
        mbstring \
        mysqli \
        pdo_mysql \
        zip \
    && a2enmod rewrite headers expires remoteip \
    && sed -ri "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/sites-available/*.conf \
    && sed -ri "s!/var/www/!${APACHE_DOCUMENT_ROOT%/public}/!g" /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer-bin /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .
COPY --from=frontend-builder /workspace/public/build ./public/build
COPY --from=frontend-builder /workspace/public/admin/build ./public/admin/build
COPY --from=frontend-builder /workspace/public/installer/build ./public/installer/build
COPY --from=frontend-builder /workspace/public/webform/build ./public/webform/build

RUN cp .env.example .env \
    && composer install --no-dev --prefer-dist --optimize-autoloader \
    && rm -f .env \
    && mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

EXPOSE 80

CMD ["apache2-foreground"]
