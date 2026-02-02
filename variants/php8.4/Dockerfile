# ==========================================
# Build Stage 2: PHP拡張ビルド環境
# ==========================================
FROM php:8.5-apache-trixie AS php-builder

# Setting locale
RUN apt-get update \
    && apt-get install -y apt-utils locales fonts-ipafont libnss3 libx11-6 libnss3-dev libasound2-data  libasound2 xdg-utils chromium \
    && rm -rf /var/lib/apt/lists/* \
    && echo "ja_JP.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen ja_JP.UTF-8
ENV LC_ALL=ja_JP.UTF-8
ENV TZ="Asia/Tokyo"
ENV DEBIAN_FRONTEND=noninteractive

# PHP拡張ビルドに必要な開発パッケージのインストール
RUN apt-get update && apt-get install --no-install-recommends -y \
    git \
    curl \
    unzip \
    vim \
    wget \
    sudo \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libzip-dev \
    libxml2-dev \
    libpq-dev \
    libpq5 \
    mariadb-client \
    ssl-cert \
    libicu-dev \
    libmemcached-dev \
    libgmp3-dev \
    libonig-dev \
    && rm -rf /var/lib/apt/lists/*

# PHP拡張の構成とビルド
RUN docker-php-ext-configure \
    gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
    && docker-php-ext-install -j$(nproc) \
    mbstring zip gd xml pdo pdo_pgsql pdo_mysql soap pgsql mysqli gmp intl opcache

# PECL拡張のビルド
RUN pecl channel-update pecl.php.net \
    && pecl install memcached \
    && docker-php-ext-enable memcached

# ==========================================
# Runtime Stage: PHPのみ
# ==========================================
FROM php:8.5-apache-trixie

# 日本ロケール設定
RUN apt-get update \
    && apt-get install -y locales fonts-ipafont \
    && rm -rf /var/lib/apt/lists/* \
    && echo "ja_JP.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen ja_JP.UTF-8
ENV LC_ALL=ja_JP.UTF-8
ENV TZ="Asia/Tokyo"

# 初期設定
ENV DOCUMENT_ROOT=/var/www/web/html
ENV MEMCACHED_HOST=memcached_srv
COPY .bashrc /root/

ENV ADMINER_VERSION=5.4.1


# PHP機能拡張に必要なものをインストール
RUN apt-get update && apt-get install --no-install-recommends -y \
    git \
    curl \
    unzip \
    vim \
    wget \
    sudo \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libzip-dev \
    libxml2-dev \
    libpq-dev \
    libpq5 \
    mariadb-client \
    ssl-cert \
    libicu-dev \
    libmemcached-dev \
    libgmp3-dev \
    libonig-dev \
    && rm -rf /var/lib/apt/lists/*

# PHPビルドステージから構築済みPHPをコピー
COPY --from=php-builder /usr/local /usr/local



# PostgreSQL関連のパッケージをインストール
# install postgresql17 client
RUN apt-get update && apt-get install --no-install-recommends -y wget gnupg gnupg2 gnupg1\
    && curl -LfsS https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgres-archive-keyring.gpg \
    && sh -c 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/postgres-archive-keyring.gpg] http://apt.postgresql.org/pub/repos/apt/ trixie-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list' \
    && apt-get update \
    && apt-get install --no-install-recommends -y postgresql-client-17

# copy from custom php.ini file
COPY php.ini /usr/local/etc/php/

# Adminerのダウンロードとインストール
RUN mkdir -p /var/www/adminer \
    && cd /var/www/adminer \
    && wget https://www.adminer.org/static/download/$ADMINER_VERSION/adminer-$ADMINER_VERSION.php \
    && wget https://raw.githubusercontent.com/vrana/adminer/master/designs/nicu/adminer.css \
    && mv adminer-$ADMINER_VERSION.php index.php

# memcached monitorのダウンロードとインストール
RUN mkdir -p /var/www/memcached \
    && cd /var/www/memcached \
    && wget https://raw.githubusercontent.com/DBezemer/memcachephp/master/memcache.php \
    && mv ./memcache.php ./index.php 

# Apache設定
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

# 権限設定
RUN chown -R www-data: /var/www

# Composerのインストール
RUN curl -sS https://getcomposer.org/installer | php -- \
    --filename=composer \
    --install-dir=/usr/local/bin

USER www-data

# Laravel installerのインストール
RUN composer global require --optimize-autoloader \
    "laravel/installer"

USER root
ENV PATH=$PATH:/var/www/.config/composer/vendor/bin/
WORKDIR /var/www/web
VOLUME /var/www/web

# Node.js LTSのインストール
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# SSL証明書生成スクリプトをコピー
COPY --chown=root:root generate_certs.sh /tmp
RUN chmod +x /tmp/generate_certs.sh

# エンドポイントスクリプトをコピー
COPY --chown=root:root endpoint_script.sh /tmp
RUN chmod +x /tmp/endpoint_script.sh

# ポート設定
EXPOSE 80 443

# エンドポイント設定
ENTRYPOINT ["/tmp/endpoint_script.sh"]
CMD [ "apache2-foreground" ]
