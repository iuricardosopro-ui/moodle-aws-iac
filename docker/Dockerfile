# syntax=docker/dockerfile:1
#
# Multi-stage build: fetch and prepare the Moodle PHP application in a
# throwaway stage, then copy only the final application code into a slim
# runtime image. Keeps the final image free of build tools and archives.

ARG MOODLE_VERSION=4.4.2
ARG PHP_VERSION=8.2

# ---- Stage 1: fetch and unpack Moodle -------------------------------------
FROM alpine:3.20 AS fetch

ARG MOODLE_VERSION
WORKDIR /tmp

RUN apk add --no-cache curl tar \
    && curl -fsSL -o moodle.tgz \
       "https://download.moodle.org/download.php/direct/stable_candidate/moodle-latest-${MOODLE_VERSION}.tgz" \
    && tar -xzf moodle.tgz \
    && rm moodle.tgz

# ---- Stage 2: runtime image -------------------------------------------
FROM php:${PHP_VERSION}-apache AS runtime

# Moodle's required PHP extensions.
RUN apt-get update && apt-get install -y --no-install-recommends \
        libzip-dev libpng-dev libxml2-dev libxslt1-dev libfreetype6-dev \
        libjpeg62-turbo-dev libsodium-dev unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        zip gd xml xsl mysqli soap sodium intl opcache \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/*

# Apache listens on 8080 so the container can run as a non-root user,
# matching the ALB target group port defined in terraform/modules/alb.
RUN sed -i 's/80/8080/' /etc/apache2/ports.conf /etc/apache2/sites-available/000-default.conf
EXPOSE 8080

COPY --from=fetch /tmp/moodle /var/www/html
COPY config.php /var/www/html/config.php
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p /var/www/moodledata \
    && chown -R www-data:www-data /var/www/html /var/www/moodledata

ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]
