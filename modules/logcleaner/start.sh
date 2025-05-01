#!/usr/bin/env bash
set -euo pipefail
trap 'echo -e "${YELLOW}[logcleaner] Error on line $LINENO${NC}"' ERR

# Colors
BLUE='\033[0;34m'; BOLD_BLUE='\033[1;34m'
MAGENTA='\033[0;35m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'
NC='\033[0m'

# Header function
header() {
  echo -e "${BOLD_BLUE}$1${NC}"
  echo -e "${BLUE}───────────────────────────────────────────────${NC}"
}

# Configurable via environment variables
LOGCLEANER_STATUS="${LOGCLEANER_STATUS:-false}"
LOG_DIR="${LOG_DIR:-/home/container/logs}"
TMP_DIR="${TMP_DIR:-/home/container/tmp}"
MAX_SIZE_MB="${MAX_SIZE_MB:-10}"
MAX_AGE_DAYS="${MAX_AGE_DAYS:-30}"
DRY_RUN="${DRY_RUN:-false}"

# Skip if disabled
if ! [[ "$LOGCLEANER_STATUS" =~ ^(true|1)$ ]]; then
  exit 0
fi

# Delete helper
delete_file() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}[logcleaner][DRY-RUN] Would delete: $1${NC}"
  else
    rm -f "$1"
  fi
}

# Start
header "[logcleaner] Starting log cleanup"

# Remove temporary files
echo -e "${MAGENTA}[logcleaner] Removing temporary files${NC}"
if compgen -G "$TMP_DIR/*" > /dev/null; then
  for file in "$TMP_DIR"/*; do
    delete_file "$file"
  done
else
  echo -e "${MAGENTA}[logcleaner] No temporary files to remove.${NC}"
fi

# Clean large logs
header "[logcleaner] Cleaning logs larger than ${MAX_SIZE_MB}MB"
mapfile -t large_logs < <(find "$LOG_DIR" -type f -name '*.log' -size +${MAX_SIZE_MB}M)
if (( ${#large_logs[@]} )); then
  for file in "${large_logs[@]}"; do
    delete_file "$file"
  done
else
  echo -e "${MAGENTA}[logcleaner] No logs exceed ${MAX_SIZE_MB}MB.${NC}"
fi

# Clean old logs
header "[logcleaner] Cleaning logs older than ${MAX_AGE_DAYS} days"
mapfile -t old_logs < <(find "$LOG_DIR" -type f -name '*.log' -mtime +${MAX_AGE_DAYS})
if (( ${#old_logs[@]} )); then
  for file in "${old_logs[@]}"; do
    delete_file "$file"
  done
else
  echo -e "${MAGENTA}[logcleaner] No logs older than ${MAX_AGE_DAYS} days.${NC}"
fi

# Completion
echo -e "${GREEN}[logcleaner] Log cleanup complete.${NC}\n"
