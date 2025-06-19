#!/usr/bin/env bash
set -euo pipefail
trap 'echo -e "${RED}[Cron] Error on line $LINENO${NC}"' ERR

# Color definitions
BLUE='\033[0;34m'; BOLD_BLUE='\033[1;34m'
WHITE='\033[0;37m'; GREEN='\033[0;32m'
YELLOW='\033[0;33m'; RED='\033[0;31m'
MAGENTA='\033[0;35m'; NC='\033[0m'

# Header function
header() {
  echo -e "${BLUE}───────────────────────────────────────────────${NC}"
  echo -e "${BOLD_BLUE}$1${NC}"
}

# Configuration via environment variables
CRON_STATUS="${CRON_STATUS:-false}"
CRON_CONFIG_FILE="${CRON_CONFIG_FILE:-/home/container/cron/crontab}"
CRON_LOG_FILE="${CRON_LOG_FILE:-/home/container/logs/cron.log}"
CRON_PID_FILE="${CRON_PID_FILE:-/home/container/tmp/cron.pid}"
CRON_ENGINE="/home/container/modules/cron/cron-engine.sh"

# Function to check if cron should be enabled
enabled() { [[ "$1" =~ ^(true|1)$ ]]; }

# Skip if cron is disabled
if ! enabled "$CRON_STATUS"; then
  exit 0
fi

# Start header
header "[Cron] Starting Cron Service"

# Create default crontab if missing
if [[ ! -f "$CRON_CONFIG_FILE" ]]; then
  echo -e "${WHITE}[Cron] No crontab found. Creating default configuration...${NC}"
  cat > "$CRON_CONFIG_FILE" << 'EOF'
# Edit this file to introduce tasks to be run by cron.
# 
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
# 
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').
# 
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
# 
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
# 
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
# 
# For more information see the manual pages of crontab(5) and cron(8)
# 
# m h  dom mon dow   command
EOF
  echo -e "${GREEN}[Cron] Default crontab created successfully${NC}"
fi

# Basic syntax validation
echo -e "${WHITE}[Cron] Validating crontab syntax...${NC}"
while IFS= read -r line; do
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${line// }" ]] && continue
  
  field_count=$(echo "$line" | awk '{print NF}')
  if [[ $field_count -lt 6 ]]; then
    echo -e "${RED}[Cron] Invalid crontab line (requires 6+ fields): $line${NC}"
    exit 1
  fi
done < "$CRON_CONFIG_FILE"
echo -e "${WHITE}[Cron] Crontab syntax validation passed${NC}"

# Start cron service
echo -e "${WHITE}[Cron] Starting cron service...${NC}"
"$CRON_ENGINE" & CRON_PID=$!
echo "$CRON_PID" > "$CRON_PID_FILE"

# Verify startup
sleep 2
if kill -0 "$CRON_PID" 2>/dev/null; then
  echo -e "${GREEN}[Cron] Cron service started successfully (PID: $CRON_PID)${NC}"
  
  # Display active cron jobs
  echo -e "${WHITE}[Cron] Active cron jobs:${NC}"
  active_jobs=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    echo -e "${MAGENTA}  ✓ $line${NC}"
    active_jobs=$((active_jobs + 1))
  done < "$CRON_CONFIG_FILE"
  
  if [[ $active_jobs -eq 0 ]]; then
    echo -e "${YELLOW}[Cron] No active cron jobs found${NC}"
  else
    echo -e "${BOLD_BLUE}[Cron] $active_jobs cron job(s) loaded${NC}"
  fi
  
  echo -e "${GREEN}[Cron] Cron service is running successfully${NC}"
else
  echo -e "${RED}[Cron] Failed to start cron service${NC}"
  exit 1
fi