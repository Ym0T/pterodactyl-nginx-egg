# Git Update Module

This module conditionally updates a Git repository at container startup.

## Features

- Conditional execution based on `GIT_STATUS` (1/0)
- Verifies that Git is installed; skips update if not
- Checks if the target directory is a Git repository; skips if not
- Pulls the latest changes and reports success or failure
- Colorized, structured output for readability
- Robust execution with strict shell flags and error trapping

## Configuration

| Env Variable | Default                | Description                                    |
|--------------|------------------------|------------------------------------------------|
| `GIT_STATUS` | `0`                    | Whether to run the Git update script           |
| `GIT_DIR`    | `/home/container/www`  | Path to the Git repository directory           |

## Example Egg JSON Variables

```json
"variables": [
  {
    "name": "Enable Git Update",
    "env_variable": "GIT_STATUS",
    "default_value": "0",
    "description": "Run Git update script on startup",
    "required": false
  },
  {
    "name": "Git Repository Directory",
    "env_variable": "GIT_DIR",
    "default_value": "/home/container/www",
    "description": "Path to the Git repository",
    "required": false
  }
]
```

## Script Details

- Uses `set -euo pipefail` for safety and a `trap` to report errors.
- Defines color variables and a reusable `header()` function.
- Honors `GIT_STATUS` to skip the entire Git workflow if disabled.

---

