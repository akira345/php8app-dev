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

ENV PYTHON_VERSION 3.14.0a2
ENV PYTHON_SHA256 2ff9e10147342b3efd69f5cd9cc06ec46250f2a046587599d18e2cac69c05920

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

# Install Python3.14 and more...(based on debian:bookworm-slim)
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		netbase \
		tzdata \
	; \
	rm -rf /var/lib/apt/lists/*

RUN set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		dpkg-dev \
		gcc \
		gnupg \
		libbluetooth-dev \
		libbz2-dev \
		libc6-dev \
		libdb-dev \
		libffi-dev \
		libgdbm-dev \
		liblzma-dev \
		libncursesw5-dev \
		libreadline-dev \
		libsqlite3-dev \
		libssl-dev \
		make \
		tk-dev \
		uuid-dev \
		wget \
		xz-utils \
		zlib1g-dev \
	; \
	\
	wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz"; \
	echo "$PYTHON_SHA256 *python.tar.xz" | sha256sum -c -; \
	mkdir -p /usr/src/python; \
	tar --extract --directory /usr/src/python --strip-components=1 --file python.tar.xz; \
	rm python.tar.xz; \
	\
	cd /usr/src/python; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	./configure \
		--build="$gnuArch" \
		--enable-loadable-sqlite-extensions \
		--enable-optimizations \
		--enable-option-checking=fatal \
		--enable-shared \
		--with-lto \
		--with-ensurepip \
	; \
	nproc="$(nproc)"; \
	EXTRA_CFLAGS="$(dpkg-buildflags --get CFLAGS)"; \
	LDFLAGS="$(dpkg-buildflags --get LDFLAGS)"; \
	LDFLAGS="${LDFLAGS:--Wl},--strip-all"; \
	make -j "$nproc" \
		"EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" \
		"LDFLAGS=${LDFLAGS:-}" \
	; \
# https://github.com/docker-library/python/issues/784
# prevent accidental usage of a system installed libpython of the same version
	rm python; \
	make -j "$nproc" \
		"EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" \
		"LDFLAGS=${LDFLAGS:--Wl},-rpath='\$\$ORIGIN/../lib'" \
		python \
	; \
	make install; \
	\
	cd /; \
	rm -rf /usr/src/python; \
	\
	find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
			-o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name 'libpython*.a' \) \) \
		\) -exec rm -rf '{}' + \
	; \
	\
	ldconfig; \
	\
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' \
		| awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -r apt-mark manual \
	; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*; \
	\
	export PYTHONDONTWRITEBYTECODE=1; \
	python3 --version; \
	pip3 --version

# make some useful symlinks that are expected to exist ("/usr/local/bin/python" and friends)
RUN set -eux; \
	for src in idle3 pip3 pydoc3 python3 python3-config; do \
		dst="$(echo "$src" | tr -d 3)"; \
		[ -s "/usr/local/bin/$src" ]; \
		[ ! -e "/usr/local/bin/$dst" ]; \
		ln -svT "$src" "/usr/local/bin/$dst"; \
	done

RUN pip install boto3

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
