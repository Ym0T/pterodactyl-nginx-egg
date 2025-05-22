# Composer Module

This module installs Composer packages at container startup based on either a `composer.json` file or the `COMPOSER_MODULES` environment variable.

## Features

- Conditional execution based on `COMPOSER_STATUS` (`1`/`true`)
- Prefers installation via `composer.json` if present
- Falls back to `COMPOSER_MODULES` if no `composer.json` is found
- Runs commands in the web root (`/home/container/www`)
- Skips execution if disabled or no sources are found
- Uses non-interactive and ANSI output for better logging

## Configuration

| Env Variable         | Default                           | Description                                                                 |
|----------------------|-----------------------------------|-----------------------------------------------------------------------------|
| `COMPOSER_STATUS`    | `1`                               | Enable (`1`/`true`) or disable (`0`/`false`) the Composer module            |
| `COMPOSER_MODULES`   | *(empty)*                         | Space-separated list of packages (e.g. `monolog/monolog:^3.0 vlucas/phpdotenv`) |
| `COMPOSER_WWW_DIR`   | `/home/container/www`             | Working directory for Composer                                              |
| `COMPOSER_CACHE_DIR` | `/home/container/.cache/composer` | Location to store Composer cache files                                     |

## Behavior

1. If `COMPOSER_STATUS` is `0` or `false`, the script exits early.
2. If `composer.json` exists in the working directory, `composer install` is executed.
3. If no `composer.json` is found but `COMPOSER_MODULES` is set, `composer require` installs the specified packages.
4. If neither source is available, the script skips installation.

## Script Details

- Uses strict flags (`set -euo pipefail`) and `trap` for robust error handling
- Supports custom cache and working directories via environment variables
- Logs steps with colored output for easier debugging
- Automatically creates cache directory if missing

## Example

### Environment Variable Setup (in panel)

COMPOSER_STATUS=1 
COMPOSER_MODULES=monolog/monolog:^3.0 symfony/var-dumper:^6.3

### Example composer.json

```json
{
  "require": {
    "slim/slim": "^4.12",
    "monolog/monolog": "^3.0"
  },
  "autoload": {
    "psr-4": {
      "App\\": "src/"
    }
  }
}


