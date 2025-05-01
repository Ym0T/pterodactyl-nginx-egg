# LogCleaner Module

This module runs at container startup to clean up temporary and log files based on configurable thresholds.

## Features

- Conditional execution based on `LOGCLEANER_STATUS` (1 to enable)
- Removes all files in the temporary directory (`/home/container/tmp`)
- Deletes log files in `/home/container/logs` that are:
  - larger than `MAX_SIZE_MB` (default: 10 MB)
  - older than `MAX_AGE_DAYS` (default: 30 days)
- Supports dry-run via `DRY_RUN` (lists files without deleting)
- Colorized, structured output for easy reading
- Robust error handling with `set -euo pipefail` and trap on error

## Configuration

| Environment Variable   | Default                  | Description                                         |
|------------------------|--------------------------|-----------------------------------------------------|
| `LOGCLEANER_STATUS`    | `1`                      | Enable (`true`/`1`) or disable (`false`/`0`) module |
| `LOG_DIR`              | `/home/container/logs`   | Directory where log files are stored                |
| `TMP_DIR`              | `/home/container/tmp`    | Directory for temporary files                       |
| `MAX_SIZE_MB`          | `10`                     | Remove log files larger than this (in MB)           |
| `MAX_AGE_DAYS`         | `30`                     | Remove log files older than this (in days)          |
| `DRY_RUN`              | `false`                  | When `true`, only shows what would be deleted       |

## Usage

1. **Place and make executable** the script:
   ```bash
   chmod +x modules/logcleaner/start.sh
   ```
2. **Define environment variables** in your Egg JSON under `variables`:
   ```json
   [
     {
       "name": "Enable LogCleaner",
       "env_variable": "LOGCLEANER_STATUS",
       "default_value": "1",
       "description": "Enable or disable the LogCleaner module",
       "user_viewable": true,
       "user_editable": true,
       "rules": "required|boolean",
       "field_type": "boolean"
     },
     {
       "name": "Log Directory",
       "env_variable": "LOG_DIR",
       "default_value": "/home/container/logs",
       "description": "Path where log files are stored",
       "user_viewable": true,
       "user_editable": true,
       "rules": "required|string",
       "field_type": "text"
     },
     {
       "name": "Temp Directory",
       "env_variable": "TMP_DIR",
       "default_value": "/home/container/tmp",
       "description": "Path for temporary files",
       "user_viewable": true,
       "user_editable": true,
       "rules": "required|string",
       "field_type": "text"
     },
     {
       "name": "Max Log File Size (MB)",
       "env_variable": "MAX_SIZE_MB",
       "default_value": "10",
       "description": "Maximum log file size before deletion",
       "user_viewable": true,
       "user_editable": true,
       "rules": "required|integer",
       "field_type": "text"
     },
     {
       "name": "Max Log Age (days)",
       "env_variable": "MAX_AGE_DAYS",
       "default_value": "30",
       "description": "Maximum log file age before deletion",
       "user_viewable": true,
       "user_editable": true,
       "rules": "required|integer",
       "field_type": "text"
     },
     {
       "name": "Dry Run",
       "env_variable": "DRY_RUN",
       "default_value": "false",
       "description": "Show what would be deleted without removing files",
       "user_viewable": true,
       "user_editable": true,
       "rules": "required|boolean",
       "field_type": "boolean"
     }
   ]
   ```

## Script Details

- Uses `shopt -s nullglob` to handle empty directories gracefully.
- Gathers files via `find` and `mapfile`, then loops through arrays to delete.
- `delete_file` helper respects `DRY_RUN` mode.
- Each major section prints a header for clarity.
- Errors trap with line number for quick debugging.

---
