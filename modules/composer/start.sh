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
  echo -e "${BOLD_BLUE}$1${NC}"
  echo -e "${BLUE}───────────────────────────────────────────────${NC}"
}

# Configuration via environment variables
COMPOSER_STATUS="${COMPOSER_STATUS:-false}"
COMPOSER_MODULES="${COMPOSER_MODULES:-}"

# Skip if disabled
if ! [[ "$COMPOSER_STATUS" =~ ^(true|1)$ ]]; then
  exit 0
fi

# Start header
header "[composer] Installing Composer packages"

# Install modules if specified
if [[ -n "$COMPOSER_MODULES" ]]; then
  echo -e "${WHITE}[composer] Installing: $COMPOSER_MODULES${NC}"
  composer require $COMPOSER_MODULES \
    --working-dir=/home/container/www \
    --no-interaction --ansi
  echo -e "${GREEN}[composer] Packages installed successfully.${NC}"
else
  echo -e "${YELLOW}[composer] No Composer modules specified; skipping.${NC}"
fi
