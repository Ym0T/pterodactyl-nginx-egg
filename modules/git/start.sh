#!/usr/bin/env bash
set -euo pipefail

BLUE='\033[0;34m'
BOLD_BLUE='\033[1;34m'
WHITE='\033[0;37m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

trap 'echo -e "${RED}[Git] Error on line $LINENO${NC}"' ERR

header() {
  echo -e "${BLUE}───────────────────────────────────────────────${NC}"
  echo -e "${BOLD_BLUE}$1${NC}"
}

GIT_STATUS="${GIT_STATUS:-false}"
GIT_DIR="${GIT_DIR:-/home/container/www}"
GIT_BRANCH="${GIT_BRANCH:-master}"
GIT_SSH_STRICT_HOST_CHECKING="${GIT_SSH_STRICT_HOST_CHECKING:-yes}"

# Exit immediately if git updates are disabled
if ! [[ "$GIT_STATUS" =~ ^(true|1)$ ]]; then
  exit 0
fi

header "[Git] Checking & Updating Repository"

# Ensure git exists
if ! command -v git >/dev/null 2>&1; then
  echo -e "${RED}[Git] Git not installed; skipping.${NC}"
  exit 0
fi

# Ensure repo exists
if [[ ! -d "$GIT_DIR/.git" ]]; then
  echo -e "${YELLOW}[Git] No Git repo in '$GIT_DIR'; skipping.${NC}"
  exit 0
fi

cd "$GIT_DIR"

CURRENT_URL="$(git config --get remote.origin.url || true)"

if [[ -z "$CURRENT_URL" ]]; then
  echo -e "${YELLOW}[Git] No remote URL found; skipping.${NC}"
  exit 0
fi

# SSH remote support
if [[ "$CURRENT_URL" =~ ^git@|^ssh:// ]]; then
  echo -e "${WHITE}[Git] SSH remote detected.${NC}"

  mkdir -p /home/container/.ssh
  chmod 700 /home/container/.ssh

  if [[ -z "${GIT_SSH_PRIVATE_KEY:-}" ]]; then
    echo -e "${RED}[Git] SSH remote is configured but GIT_SSH_PRIVATE_KEY is empty.${NC}"
    exit 1
  fi


  echo "${GIT_SSH_PRIVATE_KEY}" | tr -d '\r' > /home/container/.ssh/id_ed25519
  chmod 600 /home/container/.ssh/id_ed25519

  if [[ -n "${GIT_SSH_KNOWN_HOSTS:-}" ]]; then
    echo "${GIT_SSH_KNOWN_HOSTS}" > /home/container/.ssh/known_hosts
  else
    if command -v ssh-keyscan >/dev/null 2>&1; then
      ssh-keyscan -H github.com > /home/container/.ssh/known_hosts 2>/dev/null
    else
      echo -e "${RED}[Git] ssh-keyscan is not available and GIT_SSH_KNOWN_HOSTS is empty.${NC}"
      exit 1
    fi
  fi
  chmod 600 /home/container/.ssh/known_hosts

  export GIT_SSH_COMMAND="ssh -i /home/container/.ssh/id_ed25519 -o StrictHostKeyChecking=${GIT_SSH_STRICT_HOST_CHECKING} -o UserKnownHostsFile=/home/container/.ssh/known_hosts"

# HTTPS token auth fallback
else
  if [[ -n "${USERNAME:-}" ]] && [[ -n "${ACCESS_TOKEN:-}" ]]; then
    echo -e "${WHITE}[Git] HTTPS remote detected; applying token auth…${NC}"

    CLEAN_URL="$(echo "$CURRENT_URL" | sed -E 's|https://[^@]*@|https://|')"
    GIT_DOMAIN="$(echo "$CLEAN_URL" | sed -E 's|https://([^/]+)/.*|\1|')"
    GIT_REPO="$(echo "$CLEAN_URL" | sed -E 's|https://[^/]+/(.*)|\1|')"
    NEW_URL="https://${USERNAME}:${ACCESS_TOKEN}@${GIT_DOMAIN}/${GIT_REPO}"

    git remote set-url origin "$NEW_URL"
    echo -e "${GREEN}[Git] Remote URL updated with credentials.${NC}"
  else
    echo -e "${WHITE}[Git] No HTTPS credentials provided; using existing configuration.${NC}"
  fi
fi

echo -e "${WHITE}[Git] Fetching latest changes…${NC}"
git fetch origin

echo -e "${WHITE}[Git] Resetting working tree to origin/${GIT_BRANCH}…${NC}"
git reset --hard "origin/${GIT_BRANCH}"

echo -e "${GREEN}[Git] Repository updated successfully.${NC}"