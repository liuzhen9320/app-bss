FROM liuzhen932/app-openresty:latest
# Setup document root
WORKDIR /var/www/html

# Install packages and remove default server definition
RUN apk add --no-cache \
  curl \
  linux-headers \
  libpng-dev \
  libzip-dev \
  libwebp-dev \
  freetype-dev \
  libjpeg-turbo-dev \
  imagemagick \
  php84 \
  php84-ctype \
  php84-curl \
  php84-dom \
  php84-fileinfo \
  php84-fpm \
  php84-gd \
  php84-pecl-imagick \
  php84-intl \
  php84-mbstring \
  php84-pdo \
  php84-pdo_mysql \
  php84-pdo_pgsql \
  php84-pdo_sqlite \
  php84-mysqli \
  php84-sqlite3 \
  php84-opcache \
  php84-openssl \
  php84-phar \
  php84-session \
  php84-tokenizer \
  php84-xml \
  php84-xmlreader \
  php84-xmlwriter \
  php84-zip \
  supervisor \
  && ln -s /usr/bin/php84 /usr/bin/php || true

# Configure nginx - http
COPY config/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
# Configure nginx - default server
COPY config/conf.d /etc/nginx/conf.d/

# Configure PHP-FPM
ENV PHP_INI_DIR=/etc/php84
COPY config/fpm-pool.conf ${PHP_INI_DIR}/php-fpm.d/www.conf
COPY config/php.ini ${PHP_INI_DIR}/conf.d/custom.ini

RUN { \
        echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
		echo 'display_errors = Off'; \
		echo 'display_startup_errors = Off'; \
		echo 'log_errors = On'; \
		echo 'error_log = /dev/stderr'; \
		echo 'log_errors_max_len = 1024'; \
		echo 'ignore_repeated_errors = On'; \
		echo 'ignore_repeated_source = Off'; \
		echo 'html_errors = Off'; \
	} > ${PHP_INI_DIR}/conf.d/error-logging.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN mkdir -p /var/log/nginx && chown -R nobody:nobody /var/www/html /run /var/log/nginx /usr/local/openresty/

# Switch to use a non-root user from here on
USER nobody

# Add application
COPY --chown=nobody src/ /var/www/html/

# Expose the port openresty is reachable on
EXPOSE 8080

# Let supervisord start openresty & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping || exit 1
