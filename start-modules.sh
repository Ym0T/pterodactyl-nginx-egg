#!/usr/bin/env bash
# Ensure Unix line endings
sed -i 's/\r$//' "$0"
find modules -type f -name "*.sh" -exec sed -i 's/\r$//' {} + 2>/dev/null || true

set -euo pipefail
trap 'echo -e "${RED}[Orchestrator] Error on line $LINENO${NC}"' ERR

# Enable nullglob so non-matching globs expand to empty
shopt -s nullglob

# Color definitions
BLUE='\033[0;34m'; BOLD_BLUE='\033[1;34m'
WHITE='\033[0;37m'; GREEN='\033[0;32m'
YELLOW='\033[0;33m'; RED='\033[0;31m'
NC='\033[0m'

# header function for consistent separators
header() {
  echo -e " "
  echo -e "\n${BLUE}───────────────────────────────────────────────${NC}"
  echo -e "${BOLD_BLUE}[Orchestrator] $1${NC}"
}

# Start orchestration
echo -e "\n${BOLD_BLUE}[Orchestrator] Module orchestration starting...${NC}"

# Helper to test enabled status: true or 1
is_enabled() { [[ "$1" =~ ^(true|1)$ ]]; }

# 0) PHP extension selection
# Rebuilt on every start so it follows image updates. Runs before the modules
# because they (and php-fpm, started by nginx) inherit PHP_INI_SCAN_DIR.
PHP_VERSION="${PHP_VERSION:-8.4}"
PHP_DISABLED_EXTENSIONS="${PHP_DISABLED_EXTENSIONS:-}"
PHP_CONF_SOURCE="${PHP_CONF_SOURCE:-/etc/php/${PHP_VERSION}}"
PHP_CONF_USER="${PWD}/php/conf.d"
PHP_CONF_ACTIVE="${PWD}/php/conf.d-active"

disabled_list="${PHP_DISABLED_EXTENSIONS//,/ }"
disabled_list="${disabled_list,,}"
user_inis=("$PHP_CONF_USER"/*.ini)

if [[ -n "${disabled_list// /}" || ${#user_inis[@]} -gt 0 ]]; then
  header "Configuring PHP extensions"
  rm -rf "$PHP_CONF_ACTIVE"
  mkdir -p "$PHP_CONF_ACTIVE"

  linked=0
  skipped=" "
  # A single scan dir serves both SAPIs, so merge FPM with the CLI-only files
  for ini in "$PHP_CONF_SOURCE"/fpm/conf.d/*.ini "$PHP_CONF_SOURCE"/cli/conf.d/*.ini; do
    name=$(basename "$ini")
    [[ -e "$PHP_CONF_ACTIVE/$name" ]] && continue
    ext="${name#*-}"; ext="${ext%.ini}"; ext="${ext,,}"
    if [[ " ${disabled_list} " == *" ${ext} "* ]]; then
      skipped+="${ext} "
      continue
    fi
    ln -s "$ini" "$PHP_CONF_ACTIVE/$name"
    linked=$((linked + 1))
  done

  if (( linked == 0 )); then
    # An empty scan dir would leave PHP without any shared extension
    echo -e "${YELLOW}[PHP] No extension .ini files found in ${PHP_CONF_SOURCE}; check PHP_VERSION. Keeping the image defaults.${NC}"
    rm -rf "$PHP_CONF_ACTIVE"
  else
    for ext in $disabled_list; do
      if [[ "$skipped" == *" ${ext} "* ]]; then
        echo -e "${WHITE}[PHP] Disabled extension: ${ext}${NC}"
      else
        echo -e "${YELLOW}[PHP] '${ext}' is not loaded by this image; nothing to disable.${NC}"
      fi
    done

    # The target may be a symlink into the read-only image; replace, don't write through
    for ini in "${user_inis[@]}"; do
      rm -f "$PHP_CONF_ACTIVE/$(basename "$ini")"
      cp "$ini" "$PHP_CONF_ACTIVE/"
      echo -e "${WHITE}[PHP] Custom ini: $(basename "$ini")${NC}"
    done

    export PHP_INI_SCAN_DIR="$PHP_CONF_ACTIVE"
    echo -e "${GREEN}[PHP] Extension configuration ready (${PHP_INI_SCAN_DIR})${NC}"
  fi
else
  rm -rf "$PHP_CONF_ACTIVE"
fi

# 1) Run logcleaner second if enabled
LOGCLEANER_STATUS="${LOGCLEANER_STATUS:-false}"
if is_enabled "$LOGCLEANER_STATUS"; then
  header "Running module: logcleaner"
  modules/logcleaner/start.sh
fi

# 2) Run auto-update first if enabled (only if module exists)
AUTOUPDATE_STATUS="${AUTOUPDATE_STATUS:-true}"
if is_enabled "$AUTOUPDATE_STATUS" && [[ -f "modules/autoupdate/start.sh" ]]; then
  header "Running module: autoupdate"
  modules/autoupdate/start.sh
fi

# 3) Execute other modules (except autoupdate, logcleaner and nginx)
for module_dir in modules/*/; do
  module_name=$(basename "$module_dir")
  [[ "$module_name" == "autoupdate" || "$module_name" == "logcleaner" || "$module_name" == "nginx" ]] && continue
  start_script="${module_dir}start.sh"
  status_var="${module_name^^}_STATUS"
  status="${!status_var:-false}"

  # Skip silently if disabled
  if ! is_enabled "$status"; then
    continue
  fi

  # Run module if script is executable
  if [[ -x "$start_script" ]]; then
    header "Running module: ${module_name}"
    "$start_script"
  fi
done

# 4) Run nginx module last (blocking)
NGINX_STATUS="${NGINX_STATUS:-true}"
if is_enabled "$NGINX_STATUS"; then
  header "Running module: nginx"
  modules/nginx/start.sh
  # nginx runs in foreground/blocking; exit after start
  exit 0
fi

# Completion message if nginx skipped
echo -e "\n${GREEN}[Orchestrator] Module orchestration complete.${NC}\n"