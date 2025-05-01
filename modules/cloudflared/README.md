# Cloudflared Tunnel Module

This module manages a Cloudflare Tunnel at container startup, with configurable settings and robust execution.

## Features

- Conditional execution based on `CLOUDFLARED_STATUS` (1/0)
- Reads token from `CLOUDFLARED_TOKEN_FILE`; skips if missing or empty
- Starts Cloudflared in background, saves PID to `CLOUDFLARED_PID_FILE`
- Monitors log (`CLOUDFLARED_LOG_FILE`) for success or failure patterns
- Status updates at configurable intervals (`CLOUDFLARED_STATUS_TIMES`)
- Failure handling with detailed log output
- Colorized, structured output
- Configurable via environment variables

## Configuration

Environment variables:

- `CLOUDFLARED_STATUS` (default: `0`) – enable or disable Cloudflared startup
- `CLOUDFLARED_TOKEN` (default: `""`) – Cloudflared auth token (no file required)
- `CLOUDFLARED_LOG_FILE` (default: `/home/container/logs/cloudflared.log`)
- `CLOUDFLARED_PID_FILE` (default: `/home/container/tmp/cloudflared.pid`)
- `CLOUDFLARED_MAX_ATTEMPTS` (default: `130`)
- `CLOUDFLARED_STATUS_TIMES` (default: `5 10 15 30 60 90 120`)

## Example Egg JSON Variables

```json
"variables": [
  { "name": "Enable Cloudflared Tunnel", "env_variable": "CLOUDFLARED_STATUS", "default_value": "0", "description": "Run Cloudflared Tunnel on startup", "required": false },
  { "name": "Cloudflared Token File", "env_variable": "CLOUDFLARED_TOKEN_FILE", "default_value": "/home/container/cloudflared_token.txt", "description": "Path to Cloudflare Tunnel token file", "required": false },
  { "name": "Cloudflared Log File", "env_variable": "CLOUDFLARED_LOG_FILE", "default_value": "/home/container/logs/cloudflared.log", "description": "Path to store Cloudflared logs", "required": false },
  { "name": "Cloudflared PID File", "env_variable": "CLOUDFLARED_PID_FILE", "default_value": "/home/container/tmp/cloudflared.pid", "description": "Path to save Cloudflared PID", "required": false }
]
```

## Script Logic

1. Exit immediately if `CLOUDFLARED_STATUS` is `0`.
2. Validate presence and readability of `CLOUDFLARED_TOKEN_FILE`.
3. Launch Cloudflared Tunnel in background; log to `CLOUDFLARED_LOG_FILE`.
4. Record PID in `CLOUDFLARED_PID_FILE`.
5. Loop up to `CLOUDFLARED_MAX_ATTEMPTS` seconds, printing status at intervals in `CLOUDFLARED_STATUS_TIMES`.
6. On failure to start or missing success message, print last logs and exit 1.
7. On success, print confirmation and exit 0.

