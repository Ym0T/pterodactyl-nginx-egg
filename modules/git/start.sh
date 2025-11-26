#!/usr/bin/env bash
set -euo pipefail
trap 'echo -e "${RED}[Git] Error on line $LINENO${NC}"' ERR

# Color definitions
BLUE='\033[0;34m'; BOLD_BLUE='\033[1;34m'
WHITE='\033[0;37m'; GREEN='\033[0;32m'
YELLOW='\033[0;33m'; RED='\033[0;31m'
NC='\033[0m'

# Header function
header() {
  echo -e "${BLUE}───────────────────────────────────────────────${NC}"
  echo -e "${BOLD_BLUE}$1${NC}"
}

# Configuration
GIT_STATUS="${GIT_STATUS:-false}"
GIT_DIR="${GIT_DIR:-/home/container/www}"

# If disabled, skip immediately
if ! [[ "$GIT_STATUS" =~ ^(true|1)$ ]]; then
  exit 0
fi

# Start header
header "[Git] Checking & Updating Repository"

# Ensure git is available
command -v git > /dev/null 2>&1 \
  || { echo -e "${RED}[Git] Git not installed; skipping.${NC}"; exit 0; }

# Ensure target dir exists and is a repo
if [[ ! -d "$GIT_DIR/.git" ]]; then
  echo -e "${YELLOW}[Git] No Git repo in '$GIT_DIR'; skipping.${NC}"
  exit 0
fi

# Change to git directory
cd "$GIT_DIR"

# Update remote URL with credentials if USERNAME and ACCESS_TOKEN are provided
if [[ -n "${USERNAME:-}" ]] && [[ -n "${ACCESS_TOKEN:-}" ]]; then
  echo -e "${WHITE}[Git] Updating remote URL with provided credentials…${NC}"

  # Get current remote URL
  CURRENT_URL=$(git config --get remote.origin.url)

  if [[ -n "$CURRENT_URL" ]]; then
    # Extract domain and repo path from current URL
    # Remove any existing credentials from URL
    CLEAN_URL=$(echo "$CURRENT_URL" | sed -E 's|https://[^@]*@|https://|')

    # Extract domain (github.com, gitlab.com, etc.)
    GIT_DOMAIN=$(echo "$CLEAN_URL" | sed -E 's|https://([^/]+)/.*|\1|')

    # Extract repo path (user/repo.git)
    GIT_REPO=$(echo "$CLEAN_URL" | sed -E 's|https://[^/]+/(.*)|\1|')

    # Construct new URL with credentials
    NEW_URL="https://${USERNAME}:${ACCESS_TOKEN}@${GIT_DOMAIN}/${GIT_REPO}"

    # Update remote URL
    git remote set-url origin "$NEW_URL"
    echo -e "${GREEN}[Git] Remote URL updated with credentials.${NC}"
  else
    echo -e "${YELLOW}[Git] No remote URL found; skipping credential update.${NC}"
  fi
else
  echo -e "${WHITE}[Git] No credentials provided; using existing configuration.${NC}"
fi

# Perform pull
echo -e "${WHITE}[Git] Pulling latest changes…${NC}"
if git pull; then
  echo -e "${GREEN}[Git] Repository updated successfully.${NC}"
else
  echo -e "${RED}[Git] Failed to pull latest changes.${NC}"
fi
