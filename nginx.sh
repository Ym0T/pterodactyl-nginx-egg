#!/bin/bash

# Header
echo -e " "
echo -e "\033[0;34m───────────────────────────────────────────────\033[0m"
echo -e "\033[1;34m[Docker] Loading setup\033[0m"
echo -e "\033[0;34m───────────────────────────────────────────────\033[0m"

# [Cleanup] Removing temporary files
echo -e "\033[0;35m[Cleanup] Removing temporary files\033[0m"
rm -rf /home/container/tmp/*

# [Cleanup] Checking & Deleting Old or Large Logs
LOG_FILES=(
    "/home/container/logs/naccess.log"
    "/home/container/logs/nerror.log"
    "/home/container/logs/error.log"
    "/home/container/logs/php_errors.log"
    "/home/container/logs/php-fpm.log"
)
MAX_SIZE_MB=10
MAX_AGE_DAYS=30

echo -e "\033[0;35m[Cleanup] Checking log files for deletion...\033[0m"

for FILE in "${LOG_FILES[@]}"; do
    if [ -f "$FILE" ]; then
        FILE_SIZE_MB=$(( $(stat -c%s "$FILE") / 1024 / 1024 ))
        FILE_AGE_DAYS=$(( ($(date +%s) - $(stat -c %Y "$FILE")) / 86400 ))

        if [[ $FILE_SIZE_MB -gt $MAX_SIZE_MB || $FILE_AGE_DAYS -gt $MAX_AGE_DAYS ]]; then
            echo -e "\033[0;33m[Cleanup] Deleting: $FILE (Size: ${FILE_SIZE_MB}MB, Age: ${FILE_AGE_DAYS} days)\033[0m"
            rm "$FILE"
        else
            echo -e "\033[0;32m[Cleanup] Keeping: $FILE (Size: ${FILE_SIZE_MB}MB, Age: ${FILE_AGE_DAYS} days)\033[0m"
        fi
    fi
done

echo -e "\033[0;35m[Cleanup] Log file cleanup complete.\033[0m"
echo -e " "

# [Setup] Loading PHP version
echo -e "\033[0;37m[Docker] Loading PHP version\033[0m"
PHP_VERSION=$(cat "/home/container/php_version.txt")

# [Docker] Starting PHP-FPM
echo -e "\033[0;37m[Docker] Starting PHP-FPM (PHP $PHP_VERSION)\033[0m"
php-fpm$PHP_VERSION -c /home/container/php/php.ini --fpm-config /home/container/php/php-fpm.conf --daemonize > /dev/null 2>&1

# [Docker] Starting NGINX
echo -e "\033[0;37m[Docker] Starting NGINX\033[0m"

# Success message
echo -e "\033[0;32m[Docker] Services successfully launched!\033[0m"

# Pause 1 sec
sleep 1

# Copyright
echo -e " "
echo -e "\033[0;34m───────────────────────────────────────────────\033[0m"
echo -e "\033[1;36m© 2023-2025 by Ym0T\033[0m"
echo -e "\033[1;36mScript: \033[4;34mhttps://github.com/Ym0T\033[0m"
echo -e "\033[1;36mLicensed under the MIT License.\033[0m"
echo -e "\033[1;36mSee the LICENSE file for details.\033[0m"
echo -e "\033[0;34m───────────────────────────────────────────────\033[0m"

# Start NGINX
nginx -c /home/container/nginx/nginx.conf -p /home/container
