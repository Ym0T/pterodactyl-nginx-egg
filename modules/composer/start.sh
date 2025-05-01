#!/usr/bin/env bash
set -euo pipefail
trap 'echo -e "${RED}[composer] Error on line $LINENO${NC}"' ERR

# Color definitions
BLUE='\033[0;34m'; BOLD_BLUE='\033[1;34m'
WHITE='\033[0;37m'; GREEN='\033[0;32m'
YELLOW='\033[0;33m'; RED='\033[0;31m'
NC='\033[0m'

# Header function
header() {
  echo -e "${BLUE}───────────────────────────────────────────────${NC}"
  echo -e "${BOLD_BLUE}[Composer] $1${NC}"
}

# Configuration via environment variables
COMPOSER_STATUS="${COMPOSER_STATUS:-false}"
COMPOSER_MODULES="${COMPOSER_MODULES:-}"
CACHE_DIR="${COMPOSER_CACHE_DIR:-/home/container/.cache/composer}"
WWW_DIR="${COMPOSER_WWW_DIR:-/home/container/www}"

# Skip if disabled
enabled() { [[ "$1" =~ ^(true|1)$ ]]; }
if ! enabled "$COMPOSER_STATUS"; then
  exit 0
fi

# Ensure cache directory exists and is writable
mkdir -p "$CACHE_DIR"
# Optionally set ownership here if needed:
# chown -R container:container "$CACHE_DIR"
export COMPOSER_CACHE_DIR="$CACHE_DIR"

# Start installation header
header "Installing Composer packages"

# Install modules if specified
if [[ -n "$COMPOSER_MODULES" ]]; then
  echo -e "${WHITE}[Composer] Installing: $COMPOSER_MODULES${NC}"
  composer require $COMPOSER_MODULES \
    --working-dir="$WWW_DIR" \
    --no-interaction --ansi
  header "Composer installation complete"
else
  echo -e "${YELLOW}[Composer] No Composer modules specified; skipping.${NC}"
fi
