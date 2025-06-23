#!/usr/bin/env bash
set -euo pipefail
trap 'echo -e "${YELLOW}[Startup] Error on line $LINENO${NC}"' ERR

# Color definitions
RED='\033[0;31m'
BLUE='\033[0;34m'; BOLD_BLUE='\033[1;34m'
WHITE='\033[0;37m'; GREEN='\033[0;32m'
YELLOW='\033[0;33m'; CYAN='\033[1;36m'
UNDERLINE='\033[4m'; NC='\033[0m'

# Header function
header() {
  echo -e "${BLUE}───────────────────────────────────────────────${NC}"
  echo -e "${BOLD_BLUE}$1${NC}"
}

# Configurable paths/files via env vars with defaults
PHP_VERSION="${PHP_VERSION:-8.4}"
PHP_INI="${PHP_INI:-/home/container/php/php.ini}"
PHP_FPM_CONF="${PHP_FPM_CONF:-/home/container/php/php-fpm.conf}"
NGINX_CONF="${NGINX_CONF:-/home/container/nginx/nginx.conf}"
NGINX_PREFIX="${NGINX_PREFIX:-/home/container}"

# Locate php-fpm binary for the desired version
if command -v "php-fpm${PHP_VERSION}" >/dev/null 2>&1; then
  PHP_FPM_BIN="php-fpm${PHP_VERSION}"
elif command -v php-fpm >/dev/null 2>&1; then
  PHP_FPM_BIN=php-fpm
else
  echo -e "${RED}[Startup] ERROR: php-fpm${PHP_VERSION} not found; this may indicate a version mismatch between your Docker image and the PHP_VERSION variable (${PHP_VERSION}).${NC}"
  exit 1
fi

# Start PHP-FPM
header "[Startup] Starting PHP-FPM"
echo -e "${WHITE}[Startup] Launching ${PHP_FPM_BIN} (PHP ${PHP_VERSION})${NC}"
"$PHP_FPM_BIN" \
  -c "$PHP_INI" \
  --fpm-config "$PHP_FPM_CONF" \
  --daemonize > /dev/null 2>&1 || {
    echo -e "${RED}[Startup] ERROR: Failed to launch ${PHP_FPM_BIN}. Please check that your PHP_VERSION matches the installed php-fpm binary.${NC}"
    exit 1
  }

# Success message
echo -e "${GREEN}[Startup] Services successfully launched!${NC}"

# Brief pause
sleep 1

# Copyright footer
echo -e " "
echo -e "\033[0;34m───────────────────────────────────────────────\033[0m"
echo -e "\033[1;36m© 2023-2025 by Ym0T - Thanks to all contributors\033[0m"
echo -e "\033[1;36mScript: \033[4;34mhttps://github.com/Ym0T\033[0m"
echo -e "\033[1;36mLicensed under the MIT License.\033[0m"
echo -e "\033[1;36mSee the LICENSE file for details.\033[0m"
echo -e "\033[0;34m───────────────────────────────────────────────\033[0m"

# Start NGINX
nginx -c "$NGINX_CONF" -p "$NGINX_PREFIX"
