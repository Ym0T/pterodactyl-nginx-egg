# PHP & NGINX Startup Script

This script initializes PHP-FPM and NGINX for the container in a robust and configurable way.

## Features

- Reads PHP version from the `PHP_VERSION` environment variable
- Starts PHP-FPM with configurable `php.ini` and `php-fpm.conf`
- Optional static / SPA mode (`PHP_STATUS=0`): skips PHP-FPM and serves static files with a fallback to `/index.html`
- Starts NGINX with configurable config (`NGINX_CONF`) and prefix (`NGINX_PREFIX`)
- Colorized, structured output for readability
- Robust execution with `set -euo pipefail` and error trapping
- Fully configurable via environment variables

## Configuration

| Env Variable      | Default                              | Description                                  |
|-------------------|--------------------------------------|----------------------------------------------|
| `PHP_STATUS`      | `true`                               | `1`/`true` starts PHP-FPM, `0`/`false` enables static / SPA mode |
| `PHP_VERSION`     | `8.4`                                | PHP version to run (used in `php-fpm{VERSION}`) |
| `PHP_INI`         | `/home/container/php/php.ini`        | Path to the `php.ini` file                  |
| `PHP_FPM_CONF`    | `/home/container/php/php-fpm.conf`   | Path to the PHP-FPM configuration file       |
| `NGINX_CONF`      | `/home/container/nginx/nginx.conf`   | Path to the NGINX config file                |
| `NGINX_PREFIX`    | `/home/container`                    | Directory prefix for NGINX (`-p` flag)      |

## Script Details

- The script expects `PHP_VERSION` to be provided. It defaults to `8.4` if unset.
- On every start it copies `nginx/snippets/php-enabled.conf` or `nginx/snippets/php-disabled.conf` (depending on `PHP_STATUS`) to `/home/container/tmp/php-mode.conf`, which the server blocks in `nginx/conf.d/` include.
- If PHP is disabled and no server block includes `php-mode.conf` (e.g. an old `default.conf`), a warning is printed.
- Uses strict shell flags and a trap for error reporting.
- Color codes and header functions improve readability and maintainability.

## Example Egg JSON Variables

```json
"variables": [
  {
    "name": "PHP Version",
    "env_variable": "PHP_VERSION",
    "default_value": "8.4",
    "description": "PHP version to use",
    "required": false
  },
  {
    "name": "PHP INI Path",
    "env_variable": "PHP_INI",
    "default_value": "/home/container/php/php.ini",
    "description": "Path to php.ini",
    "required": false
  },
  {
    "name": "PHP-FPM Config Path",
    "env_variable": "PHP_FPM_CONF",
    "default_value": "/home/container/php/php-fpm.conf",
    "description": "Path to PHP-FPM config",
    "required": false
  },
  {
    "name": "NGINX Config Path",
    "env_variable": "NGINX_CONF",
    "default_value": "/home/container/nginx/nginx.conf",
    "description": "Path to NGINX config",
    "required": false
  }
]
```

