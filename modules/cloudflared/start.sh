#!/usr/bin/env bash
set -euo pipefail
trap 'echo -e "${RED}[Tunnel] Error on line $LINENO${NC}"' ERR

# Color definitions
BLUE='\033[0;34m'; BOLD_BLUE='\033[1;34m'
WHITE='\033[0;37m'; GREEN='\033[0;32m'
YELLOW='\033[0;33m'; RED='\033[0;31m'
NC='\033[0m'

# header function
header() {
  echo -e "${BLUE}───────────────────────────────────────────────${NC}"
  echo -e "${BOLD_BLUE}[Tunnel] $1${NC}"
}

# Configuration via environment variables
CLOUDFLARED_STATUS="${CLOUDFLARED_STATUS:-false}"
CLOUDFLARED_TOKEN="${CLOUDFLARED_TOKEN:-}"
CLOUDFLARED_LOG_FILE="${CLOUDFLARED_LOG_FILE:-/home/container/logs/cloudflared.log}"
CLOUDFLARED_PID_FILE="${CLOUDFLARED_PID_FILE:-/home/container/tmp/cloudflared.pid}"
CLOUDFLARED_MAX_ATTEMPTS="${CLOUDFLARED_MAX_ATTEMPTS:-130}"
CLOUDFLARED_STATUS_TIMES="${CLOUDFLARED_STATUS_TIMES:-5 10 15 30 60 90 120}"

# Helper to test enabled status: true or 1
enabled() { [[ "$1" =~ ^(true|1)$ ]]; }

# Skip if disabled
if ! enabled "$CLOUDFLARED_STATUS"; then
  exit 0
fi

# Header
header "Starting Cloudflared Tunnel"

# Verify token
if [[ -z "$CLOUDFLARED_TOKEN" ]]; then
  echo -e "${RED}[Tunnel] CLOUDFLARED_TOKEN is not set; skipping Cloudflared startup.${NC}"
  exit 0
fi

# Note: flags must appear before 'run'
cloudflared tunnel --no-autoupdate run --token "$CLOUDFLARED_TOKEN" \
  > "$CLOUDFLARED_LOG_FILE" 2>&1 &

pid=$!
echo "$pid" > "$CLOUDFLARED_PID_FILE"

# Prepare status intervals
read -ra TIMES <<< "$CLOUDFLARED_STATUS_TIMES"

echo -e "${YELLOW}[Tunnel] Waiting for Cloudflared to establish connection...${NC}"

# Monitor startup
for ((i=1; i<=CLOUDFLARED_MAX_ATTEMPTS; i++)); do
  sleep 1
  for t in "${TIMES[@]}"; do
    if [[ $i -eq $t ]]; then
      echo -e "${YELLOW}[Tunnel] Still waiting... (${i}s)${NC}"
    fi
  done

  if ! kill -0 "$pid" 2>/dev/null; then
    echo -e "${RED}[Tunnel] Cloudflared process died; check logs: $CLOUDFLARED_LOG_FILE${NC}"
    tail -n 10 "$CLOUDFLARED_LOG_FILE" | sed "s/^//;s/\$//"
    exit 1
  fi

  if grep -qE 'Registered tunnel connection|Updated to new configuration' "$CLOUDFLARED_LOG_FILE"; then
    echo -e "${GREEN}[Tunnel] Connected after ${i}s${NC}"
    echo -e "${GREEN}[Tunnel] Cloudflared is running successfully.${NC}"
    exit 0
  fi
done

# Timeout
header "Connection timeout"
echo -e "${RED}[Tunnel] No successful connection within ${CLOUDFLARED_MAX_ATTEMPTS}s; check logs: $CLOUDFLARED_LOG_FILE${NC}"
tail -n 10 "$CLOUDFLARED_LOG_FILE" | sed "s/^//;s/\$//"
exit 1
