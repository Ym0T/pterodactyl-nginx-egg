#!/bin/bash
# Production Cron-Engine for containers
CRON_CONFIG_FILE="${CRON_CONFIG_FILE:-/home/container/crontab}"
CRON_LOG_FILE="${CRON_LOG_FILE:-/home/container/logs/cron.log}"

log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$CRON_LOG_FILE"
}

execute_if_match() {
  local minute="$1" hour="$2" day="$3" month="$4" weekday="$5" command="$6"
  
  # Get current time (portable version)
  local curr_min curr_hour curr_day curr_month curr_weekday
  curr_min=$(date '+%M' | sed 's/^0*//')
  curr_hour=$(date '+%H' | sed 's/^0*//')
  curr_day=$(date '+%d' | sed 's/^0*//')
  curr_month=$(date '+%m' | sed 's/^0*//')
  curr_weekday=$(date '+%w')
  
  # Fix empty values (when sed removes all chars)
  [[ -z "$curr_min" ]] && curr_min=0
  [[ -z "$curr_hour" ]] && curr_hour=0
  [[ -z "$curr_day" ]] && curr_day=0
  [[ -z "$curr_month" ]] && curr_month=0
  
  # Check if current time matches cron pattern
  [[ "$minute" != "*" && "$minute" != "$curr_min" ]] && return
  [[ "$hour" != "*" && "$hour" != "$curr_hour" ]] && return
  [[ "$day" != "*" && "$day" != "$curr_day" ]] && return
  [[ "$month" != "*" && "$month" != "$curr_month" ]] && return
  [[ "$weekday" != "*" && "$weekday" != "$curr_weekday" ]] && return
  
  # Execute command
  log_message "Executing: $command"
  eval "$command" >> "$CRON_LOG_FILE" 2>&1
}

# Main cron loop
log_message "Cron engine started (PID: $$)"

while true; do
  if [[ -f "$CRON_CONFIG_FILE" ]]; then
    # Read file safely without command expansion
    while IFS= read -r line || [[ -n "$line" ]]; do
      # Skip comments and empty lines
      [[ "$line" =~ ^[[:space:]]*# ]] && continue
      [[ -z "${line// }" ]] && continue
      
      # Validate line has enough fields
      field_count=$(echo "$line" | awk '{print NF}')
      [[ $field_count -lt 6 ]] && {
        log_message "ERROR: Invalid cron line: $line"
        continue
      }
      
      # Parse cron line safely without wildcard expansion
      minute=$(echo "$line" | awk '{print $1}')
      hour=$(echo "$line" | awk '{print $2}')
      day=$(echo "$line" | awk '{print $3}')
      month=$(echo "$line" | awk '{print $4}')
      weekday=$(echo "$line" | awk '{print $5}')
      command=$(echo "$line" | cut -d' ' -f6-)
      
      execute_if_match "$minute" "$hour" "$day" "$month" "$weekday" "$command"
    done < "$CRON_CONFIG_FILE"
  fi
  
  # Sleep until next minute
  sleep $((60 - $(date '+%S')))
done