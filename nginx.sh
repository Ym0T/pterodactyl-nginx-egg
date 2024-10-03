#!/bin/bash

# [Cleanup] Remove all files in the temporary directory
rm -rf /home/container/tmp/*

# [Setup] Load the PHP version from the file
PHP_VERSION=$(cat "/home/container/php_version.txt")

# [Docker] Starting PHP-FPM with the specified PHP version
echo "[Docker] Starting PHP-FPM"
php-fpm$PHP_VERSION -c /home/container/php/php.ini --fpm-config /home/container/php/php-fpm.conf --daemonize > /dev/null 2>&1

# [Docker] Starting NGINX
echo "[Docker] Starting NGINX"
echo "[Docker] Services successfully launched"

nginx -c /home/container/nginx/nginx.conf -p /home/container
