FROM php:8.5-fpm-alpine

ENV COMPOSER_ALLOW_SUPERUSER=1

ARG XLSWRITER_VERSION=3.0.0

RUN apk add --no-cache git unzip libzip libpq \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS zlib-dev libzip-dev postgresql-dev \
    && docker-php-ext-install -j"$(nproc)" pdo_mysql pdo_pgsql zip bcmath \
    && pecl install "xlswriter-${XLSWRITER_VERSION}" \
    && docker-php-ext-enable xlswriter \
    && apk del .build-deps \
    && rm -rf /tmp/pear \
    && php -r 'foreach (["pdo_mysql","pdo_pgsql","zip","bcmath","xlswriter"] as $e) { if (!extension_loaded($e)) { fwrite(STDERR, "missing ext: $e\n"); exit(1); } } exit(method_exists("Vtiful\\Kernel\\Excel", "nextRow") ? 0 : 1);'

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY docker/php/php.ini /usr/local/etc/php/conf.d/30-custom.ini

WORKDIR /var/www/html

COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction

COPY . .
RUN composer dump-autoload --optimize --no-dev \
    && mkdir -p storage/app/private/imports \
    && chown -R www-data:www-data storage bootstrap/cache

USER www-data

EXPOSE 9000
CMD ["php-fpm"]
