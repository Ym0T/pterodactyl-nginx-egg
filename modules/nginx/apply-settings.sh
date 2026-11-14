#!/usr/bin/env bash
# Applies the panel startup variables to PHP and nginx on every start.

ROOT="${NGINX_PREFIX:-/home/container}"
PHP_INI="${PHP_INI:-$ROOT/php/php.ini}"
POOL="$ROOT/php/pool.d/www.conf"
NGINX_SITE="$ROOT/nginx/conf.d/default.conf"
PANEL_DIR="$ROOT/php/conf.d"
PANEL_INI="$PANEL_DIR/zz-panel.ini"
PANEL_NGINX="$ROOT/nginx/conf.d/panel-extra.conf"
PHP_MODE_CONF="${PHP_MODE_CONF:-$ROOT/tmp/php-mode.conf}"

size_or() {
  local value="$1" fallback="$2"
  if [[ "$value" =~ ^[0-9]+[KkMmGg]?$ ]]; then
    printf '%s' "$value"
  else
    printf '%s' "$fallback"
  fi
}

number_or() {
  local value="$1" fallback="$2"
  if [[ "$value" =~ ^[0-9]+$ ]]; then
    printf '%s' "$value"
  else
    printf '%s' "$fallback"
  fi
}

apply_panel_settings() {
  local memory execution input_time post_size upload_size body children opcache
  memory="$(size_or "${PHP_MEMORY_LIMIT:-512M}" "512M")"
  execution="$(number_or "${PHP_MAX_EXECUTION_TIME:-300}" "300")"
  input_time="$(number_or "${PHP_MAX_INPUT_TIME:-300}" "300")"
  post_size="$(size_or "${PHP_POST_MAX_SIZE:-128M}" "128M")"
  upload_size="$(size_or "${PHP_UPLOAD_MAX_FILESIZE:-128M}" "128M")"
  body="$(size_or "${NGINX_CLIENT_MAX_BODY_SIZE:-128M}" "128M")"
  children="$(number_or "${PHP_FPM_MAX_CHILDREN:-10}" "10")"
  if [[ "${PHP_OPCACHE:-1}" =~ ^(0|false|off)$ ]]; then
    opcache=0
  else
    opcache=1
  fi

  mkdir -p "$PANEL_DIR" "$ROOT/nginx/conf.d" "$ROOT/tmp"
  rm -f "$ROOT/php/conf.d-active/zz-panel.ini"
  cat > "$PANEL_INI" <<EOF
memory_limit = ${memory}
max_execution_time = ${execution}
max_input_time = ${input_time}
post_max_size = ${post_size}
upload_max_filesize = ${upload_size}
opcache.enable = ${opcache}
EOF
  if [[ -n "${PHP_EXTRA_DIRECTIVES:-}" ]]; then
    printf '%s\n' "${PHP_EXTRA_DIRECTIVES//$'\r'/}" >> "$PANEL_INI"
  fi

  if [[ -n "${PHP_INI_SCAN_DIR:-}" ]]; then
    case ":${PHP_INI_SCAN_DIR}:" in
      *":${PANEL_DIR}:"*) ;;
      *) export PHP_INI_SCAN_DIR="${PHP_INI_SCAN_DIR}:${PANEL_DIR}" ;;
    esac
  else
    export PHP_INI_SCAN_DIR=":${PANEL_DIR}"
  fi

  if [[ -f "$POOL" ]]; then
    sed -i -E "s/^pm\\.max_children[[:space:]]*=.*/pm.max_children = ${children}/" "$POOL"
  fi

  if [[ -f "$NGINX_SITE" ]]; then
    sed -i -E "s/client_max_body_size[[:space:]]+[^;]+;/client_max_body_size ${body};/" "$NGINX_SITE"
    if ! grep -q "panel-extra.conf" "$NGINX_SITE"; then
      sed -i '$s/^}/include \/home\/container\/nginx\/conf.d\/panel-extra.conf;\n}/' "$NGINX_SITE"
    fi
  fi

  if [[ -n "${NGINX_EXTRA_DIRECTIVES:-}" ]]; then
    printf '%s\n' "${NGINX_EXTRA_DIRECTIVES//$'\r'/}" > "$PANEL_NGINX"
  else
    printf '%s\n' '# none' > "$PANEL_NGINX"
  fi

  echo "[Settings] PHP memory=${memory} upload=${upload_size} post=${post_size} execution=${execution}s children=${children} body=${body}"
}

apply_php_mode_limits() {
  local post_size upload_size
  post_size="$(size_or "${PHP_POST_MAX_SIZE:-128M}" "128M")"
  upload_size="$(size_or "${PHP_UPLOAD_MAX_FILESIZE:-128M}" "128M")"
  if [[ -f "$PHP_MODE_CONF" ]]; then
    sed -i -E "s|fastcgi_param PHP_VALUE .*|fastcgi_param PHP_VALUE \"upload_max_filesize = ${upload_size} \\n post_max_size=${post_size}\";|" "$PHP_MODE_CONF"
  fi
}

case "${1:-base}" in
  phpmode) apply_php_mode_limits ;;
  *) apply_panel_settings ;;
esac
