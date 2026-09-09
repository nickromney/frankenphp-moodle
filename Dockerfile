ARG FRANKENPHP_IMAGE=dunglas/frankenphp:php8.4-bookworm
FROM composer:2 AS composer-bin

FROM ${FRANKENPHP_IMAGE}

ARG MOODLE_SERIES=stable502
ARG MOODLE_VERSION=5.2.2
ARG MOODLE_PACKAGE_URL=
ARG MOODLE_PHP_EXTENSIONS="gd intl mysqli pdo_mysql soap zip ldap"

ENV DEBIAN_FRONTEND=noninteractive

RUN install-php-extensions \
    ${MOODLE_PHP_EXTENSIONS}

COPY --from=composer-bin /usr/bin/composer /usr/local/bin/composer

RUN mkdir -p /app/public /app/moodledata /app/config

WORKDIR /app/public

RUN set -eux; \
    package_url="${MOODLE_PACKAGE_URL:-https://download.moodle.org/download.php/direct/${MOODLE_SERIES}/moodle-${MOODLE_VERSION}.tgz}"; \
    curl -fsSL -o /tmp/moodle.tgz "${package_url}"; \
    tar -xzf /tmp/moodle.tgz --strip-components=1 -C /app/public; \
    rm -f /tmp/moodle.tgz; \
    composer install --no-dev --optimize-autoloader --no-interaction; \
    rm -f /usr/local/bin/composer

# The bundled "lovely" theme (a Boost child theme, see theme/lovely/). Moodle 5.0+
# serves the web root from a public/ subdirectory of the dirroot, while Moodle 4.4
# serves the dirroot itself. Install the theme in the matching location so either
# package layout can be built from this Dockerfile.
COPY theme/lovely /tmp/moodle-theme-lovely

RUN set -eux; \
    if [ -d /app/public/public ]; then \
        mkdir -p /app/public/public/theme; \
        cp -a /tmp/moodle-theme-lovely /app/public/public/theme/lovely; \
    else \
        mkdir -p /app/public/theme; \
        cp -a /tmp/moodle-theme-lovely /app/public/theme/lovely; \
    fi; \
    rm -rf /tmp/moodle-theme-lovely

RUN printf 'max_input_vars=5000\nmemory_limit=256M\n' > /usr/local/etc/php/conf.d/zz-moodle.ini

COPY docker/Caddyfile /etc/frankenphp/Caddyfile
COPY docker/tls-preflight.sh /usr/local/bin/tls-preflight.sh
COPY docker/entrypoint.sh /usr/local/bin/frankenphp-moodle-entrypoint

RUN chmod 0755 /usr/local/bin/frankenphp-moodle-entrypoint /usr/local/bin/tls-preflight.sh

ENTRYPOINT ["frankenphp-moodle-entrypoint"]

CMD ["--config", "/etc/frankenphp/Caddyfile", "--adapter", "caddyfile"]
