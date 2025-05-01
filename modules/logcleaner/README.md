# Cloudflared Tunnel Module

This module manages a Cloudflare Tunnel at container startup, with configurable settings and robust execution.

## Features

- Conditional execution based on `CF_STATUS` (true/false)
- Reads token from `CF_TOKEN_FILE`; skips if missing or empty
- Starts Cloudflared in background, saves PID to `CF_PID_FILE`
- Monitors log (`CF_LOG_FILE`) for success or failure patterns
- Status updates at configurable intervals (`CF_STATUS_TIMES`)
- Failure handling with detailed log output
- Colorized, structured output
- Configurable via environment variables

## Configuration

Environment variables:

- `LOGCLEANER_STATUS` (default: `true`) – enable (`true`) or disable (`false`) the logcleaner module
- `LOG_DIR` (default: `/home/container/logs`)
- `TMP_DIR` (default: `/home/container/tmp`)
- `MAX_SIZE_MB` (default: `10`)
- `MAX_AGE_DAYS` (default: `30`)
- `DRY_RUN` (default: `false`)

## Example Egg JSON Variables

```json
"variables": [
  { "name": "Enable Cloudflared Tunnel", "env_variable": "CF_STATUS", "default_value": "true", "description": "Run Cloudflared Tunnel on startup", "required": false },
  { "name": "Cloudflared Token File", "env_variable": "CF_TOKEN_FILE", "default_value": "/home/container/cloudflared_token.txt", "description": "Path to Cloudflare Tunnel token file", "required": false },
  { "name": "Cloudflared Log File", "env_variable": "CF_LOG_FILE", "default_value": "/home/container/logs/cloudflared.log", "description": "Path to store Cloudflared logs", "required": false },
  { "name": "Cloudflared PID File", "env_variable": "CF_PID_FILE", "default_value": "/home/container/tmp/cloudflared.pid", "description": "Path to save Cloudflared PID", "required": false }
]
```

## Script Logic

1. Exit immediately if `CF_STATUS` is not `true`.
2. Validate presence and readability of `CF_TOKEN_FILE`.
3. Launch Cloudflared Tunnel in background; log to `CF_LOG_FILE`.
4. Record PID in `CF_PID_FILE`.
5. Loop up to `CF_MAX_ATTEMPTS` seconds, printing status at intervals in `CF_STATUS_TIMES`.
6. On failure to start or missing success message, print last logs and exit 1.
7. On success, print confirmation and exit 0.

