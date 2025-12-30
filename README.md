# php8app-dev

Container for PHP 8 Web application development

This container develops PHP 8 web application in the Japanese locale and time.

## Tags

* [php8.1](https://github.com/akira345/php8app-dev/tree/master/variants/php8.1/Dockerfile) (PostgreSQL14 Client Installed.)
* [php8.2](https://github.com/akira345/php8app-dev/tree/master/variants/php8.2/Dockerfile) (PostgreSQL15 Client Installed.)
* [php8.3](https://github.com/akira345/php8app-dev/tree/master/variants/php8.3/Dockerfile) (PostgreSQL16 Client Installed.)
* [php8.4](https://github.com/akira345/php8app-dev/tree/master/variants/php8.4/Dockerfile) (PostgreSQL17 Client Installed.)
* [php8.5](https://github.com/akira345/php8app-dev/tree/master/variants/php8.5/Dockerfile) (PostgreSQL18 Client Installed.)
* [latest](https://github.com/akira345/php8app-dev/tree/master/variants/latest/Dockerfile) (PostgreSQL18 Client Installed.)
* [php8.1-python3.10](https://github.com/akira345/php8app-dev/tree/master/variants/php8.1-python3.10/Dockerfile) (PostgreSQL14 Client Installed.)
* [php8.2-python3.11](https://github.com/akira345/php8app-dev/tree/master/variants/php8.2-python3.11/Dockerfile) (PostgreSQL15 Client Installed.)
* [php8.2-python3.12](https://github.com/akira345/php8app-dev/tree/master/variants/php8.2-python3.12/Dockerfile) (PostgreSQL15 Client Installed.)
* [php8.3-python3.13](https://github.com/akira345/php8app-dev/tree/master/variants/php8.3-python3.13/Dockerfile) (PostgreSQL16 Client Installed.)
* [php8.4-python3.14](https://github.com/akira345/php8app-dev/tree/master/variants/php8.4-python3.14/Dockerfile) (PostgreSQL17 Client Installed.)
* [php8.5-python3.15](https://github.com/akira345/php8app-dev/tree/master/variants/php8.5-python3.15/Dockerfile) (PostgreSQL18 Client Installed.)


## Environments

  - DOCUMENT_ROOT

    Sets the path of the document root in the container.(ex: /var/www/web/public_html)

    Defailt path is /var/www/web/html

  - MEMCACHED_HOST

    Set Memcached server name.

    Defaiult name is memcached_srv.

## MountPoints

  - /var/www/web is Application Directroy into container.

## Preinstalled applications.

  - Adminer 5.4.1 into /adminer.
  - memcachephp into /memcached

    (ID:memcache PW:password)

  - Includes Larabel installer and composer. If you use, `docker exec -it ...`
  - Installed MySQL/MariaDB and PosgreSQL Clients.
  - Installed nodeJS LTS.
  - Enable PHP opcache.
  - With self certificate by port 443. (TLSv1.3 Only!!)

## Commandline example.

  ```
  docker run --rm -v `pwd`/app:/var/www/web -p 8080:80 -e DOCUMENT_ROOT=/var/www/web/public_html --name example akira345/php8app-dev:latest
  ```
