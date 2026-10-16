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

# Helper to test enabled status: true or 1
is_enabled() { [[ "$1" =~ ^(true|1)$ ]]; }

# Configurable paths/files via env vars with defaults
PHP_STATUS="${PHP_STATUS:-true}"
PHP_VERSION="${PHP_VERSION:-8.4}"
PHP_INI="${PHP_INI:-/home/container/php/php.ini}"
PHP_FPM_CONF="${PHP_FPM_CONF:-/home/container/php/php-fpm.conf}"
NGINX_CONF="${NGINX_CONF:-/home/container/nginx/nginx.conf}"
NGINX_PREFIX="${NGINX_PREFIX:-/home/container}"

# Location snippet included by the server blocks in nginx/conf.d/ (regenerated on every start)
PHP_MODE_CONF="${NGINX_PREFIX}/tmp/php-mode.conf"
mkdir -p "${NGINX_PREFIX}/tmp"

select_php_mode() {
  cp "${NGINX_PREFIX}/nginx/snippets/$1" "$PHP_MODE_CONF" 2>/dev/null \
    || echo -e "${YELLOW}[Startup] WARNING: nginx/snippets/$1 not found, ${PHP_MODE_CONF} was not updated.${NC}"
}

if is_enabled "$PHP_STATUS"; then
  select_php_mode php-enabled.conf

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
else
  select_php_mode php-disabled.conf

  header "[Startup] PHP disabled"
  echo -e "${WHITE}[Startup] PHP-FPM disabled (PHP_STATUS=${PHP_STATUS}) - serving static files, SPA fallback to /index.html${NC}"

  # Existing installs keep their old default.conf (protected from auto-updates)
  if ! grep -qs "php-mode.conf" "${NGINX_PREFIX}/nginx/conf.d/"*.conf; then
    echo -e "${YELLOW}[Startup] WARNING: No server block in nginx/conf.d/ includes ${PHP_MODE_CONF}.${NC}"
    echo -e "${YELLOW}[Startup] The SPA fallback is not active and .php requests will fail.${NC}"
    echo -e "${YELLOW}[Startup] Replace the 'location /' and 'location ~ \\.php\$' blocks in nginx/conf.d/default.conf with:${NC}"
    echo -e "${YELLOW}[Startup]     include ${PHP_MODE_CONF};${NC}"
    echo -e "${YELLOW}[Startup] or copy nginx/conf.d/default.conf.example over default.conf.${NC}"
  fi
fi

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
nginx -c "$NGINX_CONF" -p "$NGINX_PREFIX" -e /dev/stderr
