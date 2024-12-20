FROM php:8.4-apache-bookworm

# Setting locale
RUN apt-get update \
  && apt-get install -y apt-utils locales fonts-ipafont libnss3 libx11-6 libnss3-dev libasound2-data  libasound2 xdg-utils chromium \
  && rm -rf /var/lib/apt/lists/* \
  && echo "ja_JP.UTF-8 UTF-8" > /etc/locale.gen \
  && locale-gen ja_JP.UTF-8
ENV LC_ALL ja_JP.UTF-8
ENV TZ "Asia/Tokyo"
ENV DEBIAN_FRONTEND noninteractive

# Setting Envionment
ENV DOCUMENT_ROOT /var/www/web/html
ENV MEMCACHED_HOST memcached_srv

# Build Environment
ENV ADMINER_VERSION 4.8.1



# copy from custom bashrc
COPY .bashrc /root/

# install postgresql17 client
RUN apt-get update && apt-get install --no-install-recommends -y wget gnupg gnupg2 gnupg1\
  && curl -LfsS https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgres-archive-keyring.gpg \
  && sh -c 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/postgres-archive-keyring.gpg] http://apt.postgresql.org/pub/repos/apt/ bookworm-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list' \
  && apt-get update \
  && apt-get install --no-install-recommends -y postgresql-client-17

# install php middleware
RUN apt-get update && apt-get install --no-install-recommends -y \
  git curl unzip vim wget sudo libfreetype6-dev libjpeg62-turbo-dev libmcrypt-dev libmcrypt-dev libzip-dev \
  libxml2-dev libpq-dev libpq5 mariadb-client ssl-cert libicu-dev libmemcached-dev libgmp3-dev libonig-dev\
  && docker-php-ext-configure \
  gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
  && docker-php-ext-install -j$(nproc) \
  mbstring zip gd xml pdo pdo_pgsql pdo_mysql soap intl opcache pgsql mysqli gmp\
  && rm -r /var/lib/apt/lists/*

# install php pecl extentions
RUN pecl channel-update pecl.php.net \
  && pecl install memcached \
  && docker-php-ext-enable memcached

# copy from custom php.ini file
COPY php.ini /usr/local/etc/php/



# install adminer
RUN mkdir -p /var/www/adminer \
  && cd /var/www/adminer \
  && wget https://www.adminer.org/static/download/$ADMINER_VERSION/adminer-$ADMINER_VERSION.php \
  && wget https://raw.githubusercontent.com/vrana/adminer/master/designs/nicu/adminer.css \
  && mv adminer-$ADMINER_VERSION.php index.php

# install memached monitor
RUN mkdir -p /var/www/memcached \
  && cd /var/www/memcached \
  && wget https://raw.githubusercontent.com/DBezemer/memcachephp/master/memcache.php \
  && mv ./memcache.php ./index.php 

# setting apache virtualhost
COPY virtual.conf /etc/apache2/sites-available/
RUN mkdir -p /var/log/httpd/php8.localdomain \
  && mkdir -p /var/www/web \
  && ln -s /dev/stdout /var/log/httpd/php8.localdomain/access_log \
  && ln -s /dev/stderr /var/log/httpd/php8.localdomain/error_log \
  && a2enmod rewrite \
  && a2enmod headers \
  && a2dissite 000-default \
  #  && a2ensite virtual \
  && service apache2 restart
RUN chown -R www-data: /var/www

# install composer and settings
RUN curl -sS https://getcomposer.org/installer | php -- \
  --filename=composer \
  --install-dir=/usr/local/bin

USER www-data

# install laravel installer
RUN composer global require --optimize-autoloader \
  "laravel/installer"

USER root
ENV PATH $PATH:/var/www/.config/composer/vendor/bin/
WORKDIR /var/www/web
VOLUME /var/www/web

# install nodeJS lTS
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
RUN apt-get install -y nodejs

# Setting Document Root and start apache
COPY --chown=root:root endpoint_script.sh /tmp
COPY --chown=root:root generate_certs.sh /tmp
RUN chmod +x /tmp/endpoint_script.sh
RUN chmod +x /tmp/generate_certs.sh
ENTRYPOINT ["/tmp/endpoint_script.sh"]
CMD [ "apache2-foreground" ]
