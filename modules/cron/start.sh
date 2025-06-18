#!/usr/bin/env bash
set -euo pipefail
trap 'echo -e "${RED}[Cron] Error on line $LINENO${NC}"' ERR

# Color definitions
BLUE='\033[0;34m'; BOLD_BLUE='\033[1;34m'
WHITE='\033[0;37m'; GREEN='\033[0;32m'
YELLOW='\033[0;33m'; RED='\033[0;31m'
NC='\033[0m'

# Header function
header() {
  echo -e "${BLUE}───────────────────────────────────────────────${NC}"
  echo -e "${BOLD_BLUE}[Cron] $1${NC}"
}

# Configuration via environment variables
CRON_STATUS="${CRON_STATUS:-false}"
CRON_CONFIG_FILE="${CRON_CONFIG_FILE:-/home/container/cron/crontab}"
CRON_LOG_FILE="${CRON_LOG_FILE:-/home/container/logs/cron.log}"
CRON_PID_FILE="${CRON_PID_FILE:-/home/container/tmp/cron.pid}"

# Helper to test enabled status: true or 1
enabled() { [[ "$1" =~ ^(true|1)$ ]]; }

# Skip if disabled
if ! enabled "$CRON_STATUS"; then
  exit 0
fi

# Header
header "Starting Cron Service"

# Ensure required directories exist
mkdir -p "$(dirname "$CRON_CONFIG_FILE")" "$(dirname "$CRON_LOG_FILE")" "$(dirname "$CRON_PID_FILE")"

# Check if cron config file exists
if [[ ! -f "$CRON_CONFIG_FILE" ]]; then
  echo -e "${YELLOW}[Cron] No crontab file found at $CRON_CONFIG_FILE${NC}"
  echo -e "${YELLOW}[Cron] Creating default crontab with example entries${NC}"
  
  # Create default crontab with examples
  cat > "$CRON_CONFIG_FILE" << 'EOF'
# Example crontab for Laravel/PHP applications
# Format: minute hour day month weekday command
#
# Examples:
# Run Laravel scheduler every minute
# * * * * * cd /home/container/www && /usr/bin/php artisan schedule:run >> /home/container/logs/scheduler.log 2>&1
#
# Clear cache every hour
# 0 * * * * cd /home/container/www && /usr/bin/php artisan cache:clear >> /home/container/logs/cache-clear.log 2>&1
#
# Weekly database backup (Sundays at 2 AM)
# 0 2 * * 0 cd /home/container/www && /usr/bin/php artisan backup:run >> /home/container/logs/backup.log 2>&1
#
# Clean old log files daily at midnight
# 0 0 * * * find /home/container/logs -name "*.log" -mtime +7 -delete
#
# Note: Add your custom cron jobs below this line
EOF
  
  echo -e "${GREEN}[Cron] Default crontab created. Edit $CRON_CONFIG_FILE to add your jobs.${NC}"
  exit 0
fi

# Validate crontab syntax
if ! crontab -T "$CRON_CONFIG_FILE" 2>/dev/null; then
  echo -e "${RED}[Cron] Invalid crontab syntax in $CRON_CONFIG_FILE${NC}"
  echo -e "${RED}[Cron] Please check your cron job definitions${NC}"
  exit 1
fi

# Install the crontab
echo -e "${WHITE}[Cron] Installing crontab from $CRON_CONFIG_FILE${NC}"
crontab "$CRON_CONFIG_FILE"

# Start cron daemon in background
echo -e "${WHITE}[Cron] Starting cron daemon...${NC}"
cron -f > "$CRON_LOG_FILE" 2>&1 &
CRON_PID=$!

# Save PID for later management
echo "$CRON_PID" > "$CRON_PID_FILE"

# Wait a moment and check if cron started successfully
sleep 2
if kill -0 "$CRON_PID" 2>/dev/null; then
  echo -e "${GREEN}[Cron] Cron daemon started successfully (PID: $CRON_PID)${NC}"
  
  # Show active cron jobs
  echo -e "${WHITE}[Cron] Active cron jobs:${NC}"
  crontab -l | grep -v '^#' | grep -v '^$' || echo -e "${YELLOW}[Cron] No active cron jobs found${NC}"
  
  echo -e "${GREEN}[Cron] Cron service is running${NC}"
else
  echo -e "${RED}[Cron] Failed to start cron daemon${NC}"
  exit 1
fi