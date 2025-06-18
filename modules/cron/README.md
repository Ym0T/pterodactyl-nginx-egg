# Cron Module

This module manages cron jobs at container startup, ideal for Laravel applications and scheduled tasks.

## Features

- Conditional execution based on `CRON_STATUS` (1/0)
- Configurable crontab file location
- Automatic creation of default crontab with Laravel examples
- Syntax validation of cron jobs before installation
- Background cron daemon with PID management
- Comprehensive logging and error handling
- GDPR-compliant logging (no sensitive data in logs)

## Configuration

| Environment Variable | Default                            | Description                                    |
|----------------------|------------------------------------|--------------------------------------------- |
| `CRON_STATUS`        | `false`                            | Enable (`true`/`1`) or disable (`false`/`0`) |
| `CRON_CONFIG_FILE`   | `/home/container/cron/crontab`     | Path to the crontab configuration file       |
| `CRON_LOG_FILE`      | `/home/container/logs/cron.log`    | Path to cron daemon log file                 |
| `CRON_PID_FILE`      | `/home/container/tmp/cron.pid`     | Path to store cron daemon PID                |

## Usage

### 1. Enable Cron Module
Set `CRON_STATUS=1` in your Pterodactyl panel variables.

### 2. Configure Cron Jobs
Create or edit `/home/container/cron/crontab` with your cron jobs:

```bash
# Laravel scheduler (recommended for Laravel apps)
* * * * * cd /home/container/www && /usr/bin/php artisan schedule:run >> /home/container/logs/scheduler.log 2>&1

# Cache cleanup every hour
0 * * * * cd /home/container/www && /usr/bin/php artisan cache:clear >> /home/container/logs/cache-clear.log 2>&1

# Weekly backup (Sundays at 2 AM)
0 2 * * 0 cd /home/container/www && /usr/bin/php artisan backup:run >> /home/container/logs/backup.log 2>&1

# Clean old logs daily
0 0 * * * find /home/container/logs -name "*.log" -mtime +7 -delete
```

### 3. Common Laravel Use Cases

#### Laravel Scheduler
```bash
# Run Laravel's built-in scheduler every minute
* * * * * cd /home/container/www && /usr/bin/php artisan schedule:run >> /home/container/logs/scheduler.log 2>&1
```

#### Database Maintenance
```bash
# Optimize database tables weekly
0 3 * * 0 cd /home/container/www && /usr/bin/php artisan db:optimize >> /home/container/logs/db-optimize.log 2>&1
```

#### Queue Processing (if not using supervisor)
```bash
# Restart queue workers every hour
0 * * * * cd /home/container/www && /usr/bin/php artisan queue:restart >> /home/container/logs/queue.log 2>&1
```

## Security & GDPR Compliance

- All logs contain only execution status, no user data
- No environment variables with sensitive data are logged
- File permissions are properly managed
- Cron jobs run with container user privileges

## Egg JSON Configuration

Add these variables to your `egg-nginx-v2.json`:

```json
{
  "name": "Enable Cron Module",
  "description": "Enable cron job scheduling for automated tasks",
  "env_variable": "CRON_STATUS",
  "default_value": "0",
  "user_viewable": true,
  "user_editable": true,
  "rules": "required|boolean",
  "field_type": "text"
},
{
  "name": "Cron Config File",
  "description": "Path to crontab configuration file",
  "env_variable": "CRON_CONFIG_FILE",
  "default_value": "/home/container/cron/crontab",
  "user_viewable": true,
  "user_editable": true,
  "rules": "required|string",
  "field_type": "text"
}
```

## Docker Requirements

Ensure your Dockerfile includes cron:

```dockerfile
RUN apt-get update && apt-get install -y \
    cron \
    && rm -rf /var/lib/apt/lists/*
```

## Troubleshooting

### Check Cron Status
```bash
# View cron log
tail -f /home/container/logs/cron.log

# Check if cron is running
ps aux | grep cron

# Verify crontab installation
crontab -l
```

### Common Issues

1. **Cron jobs not running**: Check syntax with `crontab -T /home/container/cron/crontab`
2. **Permission denied**: Ensure files have correct permissions
3. **Environment variables missing**: Use full paths in cron commands
4. **Laravel artisan fails**: Check PHP path and working directory

### Debug Mode
Add this to your crontab for debugging:
```bash
# Debug cron environment
* * * * * env > /home/container/logs/cron-env.log 2>&1
```

## Best Practices

1. **Always use absolute paths** in cron commands
2. **Redirect output** to log files for debugging
3. **Use Laravel's scheduler** instead of multiple cron entries when possible
4. **Set proper timezone** in your application
5. **Monitor log files** for errors
6. **Test cron jobs manually** before scheduling

## Example Laravel Scheduler Setup

In your Laravel application's `app/Console/Kernel.php`:

```php
<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    protected function schedule(Schedule $schedule)
    {
        // Run every minute
        $schedule->command('cache:prune-stale-tags')->everyMinute();
        
        // Run hourly
        $schedule->command('queue:prune-batches --hours=48')->hourly();
        
        // Run daily
        $schedule->command('backup:clean')->dailyAt('01:00');
        $schedule->command('backup:run')->dailyAt('02:00');
        
        // Custom command
        $schedule->command('app:cleanup-temp-files')->daily();
    }
}
```

Then just use one cron entry:
```bash
* * * * * cd /home/container/www && /usr/bin/php artisan schedule:run >> /home/container/logs/scheduler.log 2>&1
```