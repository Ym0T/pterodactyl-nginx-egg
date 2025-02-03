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
echo -e "[Docker]\033[0;32m Services successfully launched \033[0m"

# Copyright and License Information
echo -e " "
echo -e "\033[0;34mCopyright (c) 2023-2025 by Ym0T\033[0m"
echo -e "\033[0;34mScript created by: https://github.com/Ym0T\033[0m"
echo -e "\033[0;34mLicensed under the MIT License.\033[0m"
echo -e "\033[0;34mSee the LICENSE file for details.\033[0m"
echo -e " "

nginx -c /home/container/nginx/nginx.conf -p /home/container
