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
COMPOSER_JSON="$WWW_DIR/composer.json"

# Function to check if Composer should be enabled
enabled() { [[ "$1" =~ ^(true|1)$ ]]; }

# Skip if Composer is disabled
if ! enabled "$COMPOSER_STATUS"; then
  exit 0
fi

# Ensure the Composer cache directory exists
mkdir -p "$CACHE_DIR"
export COMPOSER_CACHE_DIR="$CACHE_DIR"

# Start installation header
header "Installing Composer packages"

# Prefer composer.json if it exists
if [[ -f "$COMPOSER_JSON" ]]; then
  echo -e "${WHITE}[Composer] composer.json found. Running install...${NC}"
  composer install \
    --working-dir="$WWW_DIR" \
    --no-interaction --ansi
  header "Composer install complete"

# Fallback to COMPOSER_MODULES if composer.json is missing
elif [[ -n "$COMPOSER_MODULES" ]]; then
  echo -e "${WHITE}[Composer] composer.json not found. Installing from COMPOSER_MODULES: $COMPOSER_MODULES${NC}"
  composer require $COMPOSER_MODULES \
    --working-dir="$WWW_DIR" \
    --no-interaction --ansi
  header "Composer module installation complete"

# No installation source found
else
  echo -e "${YELLOW}[Composer] No composer.json and no modules specified. Skipping.${NC}"
fi