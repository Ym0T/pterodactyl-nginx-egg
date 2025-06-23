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