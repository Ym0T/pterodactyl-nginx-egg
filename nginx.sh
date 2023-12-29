#!/bin/bash
rm -rf /home/container/tmp/*
PHP_VERSION=$(cat "/home/container/php_version.txt")

echo "[Docker] Starting PHP-FPM"
php-fpm$PHP_VERSION -c /home/container/php/php.ini --fpm-config /home/container/php/php-fpm.conf --daemonize > /dev/null 2>&1

echo "[Docker] Starting NGINX"
echo "[Docker] Services successfully launched"
nginx -c /home/container/nginx/nginx.conf -p /home/container