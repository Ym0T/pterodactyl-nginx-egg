# Composer Module

This module installs additional Composer packages at container startup based on the `COMPOSER_MODULES` environment variable.

## Features

- Conditional execution based on `COMPOSER_STATUS` (true/false)
- Reads a space-separated list of Composer packages from `COMPOSER_MODULES`
- Runs `composer require` in the web root (`/home/container/www`)
- Skips execution if module is disabled or `COMPOSER_MODULES` is empty
- Non-interactive, ANSI output

## Configuration

| Env Variable         | Default    | Description                                                                |
|----------------------|------------|----------------------------------------------------------------------------|
| `COMPOSER_STATUS`    | `1`        | Enable (`1`) or disable (`0`) the Composer module                  |
| `COMPOSER_MODULES`   | (empty)    | Space-separated list of packages, e.g. `vendor/pkg1:^2.0 vendor/pkg2:~1.5` |

## Script Details

- Uses strict flags (`set -euo pipefail`) and a `trap` for error reporting
- Defines color variables and a `header()` function for consistency
- Guard clauses skip execution when disabled or when no modules are specified
- Executes `composer require` with `--no-interaction` and `--ansi`

---