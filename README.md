# Pterodactyl Nginx Egg

A versatile Pterodactyl Egg featuring Nginx, PHP 8.x, WordPress, Git, Composer, Cronjob, ionCube Loader, Auto-Update, and Cloudflare Tunnel support.

<br>

## Table of Contents
- [Features](#features)
- [Installation](#installation)
- [Auto-Update System](#auto-update-system)
- [SSL Certificate with Certbot](#ssl-certificate-setup-tutorial)
- [Composer Modules Usage](#composer-modules-usage)
- [ionCube Loader Support](#ioncube-loader-support)
- [Cloudflared Tunnel Tutorial 🚀](#-cloudflared-tunnel-tutorial)
- [Git Module](#git-module)
- [Cronjob](#cronjob)
- [Change PHP version](#change-php-version)
- [PHP extensions](#php-extensions)
- [Notes](#notes)
- [License](#license)

<br>

## Features

- 🔄 **Auto-Update**: Automatically checks for and applies updates via Tavuru API
- 🧹 LogCleaner: Cleans `/tmp` and old logs (dry-run supported)  
- 🌱 Git Module: Auto `git pull` on restart  
- 📦 Composer Module: Installs packages from `composer.json` or a fallback variable  
- 🔐 ionCube Loader: Auto-detected and enabled for encrypted PHP  
- 🌐 Cloudflare Tunnel: Secure tunnel with token validation  
- 🚀 PHP-NGINX Startup: Auto-detects PHP-FPM version, runs NGINX in foreground  
- 🖥️ Multi-arch support: AMD64 & ARM64  
- 🎯 **Selectable PHP Versions:**
  - ✅ 8.5
  - ✅ 8.4  
  - ☑️ 8.3 (security-only)  
  - ☑️ 8.2 (security-only)  
  - ❌ 8.1 (EOL)  

[PHP Supported Versions](https://www.php.net/supported-versions.php)

<br>

## Installation

1. Download the egg file (`egg-nginx-v3.json`)  
2. In your Pterodactyl panel, navigate to **Nests** in the sidebar  
3. Import the egg under **Import Egg**  
4. Create a new server and select the **Nginx** egg  
5. Choose the Docker image matching your desired PHP version  
6. Fill in all required variables, including whether WordPress is desired and the PHP version field (must be set explicitly)  

<br>

## Auto-Update System

The egg includes an intelligent auto-update system that keeps your installation current with the latest features and security updates.

### How it works:

- **Automatic Version Checking**: Uses the Tavuru API to check for new releases
- **Smart Differential Updates**: Downloads only changed files, not the entire codebase
- **Selective Updates**: Only updates core system files (modules, nginx, php configs)
- **User Data Protection**: Never touches your `www` directory or user data
- **Self-Update Capability**: Can safely update its own update mechanism

### Configuration:

| Variable | Default | Description |
|----------|---------|-------------|
| `AUTOUPDATE_STATUS` | `1` | Enable (`1`) or disable (`0`) auto-update checks |
| `AUTOUPDATE_FORCE` | `1` | Automatically apply updates (`1`) or just check (`0`) |

### Update Behavior:

#### **Conservative Mode (Default)**
- `AUTOUPDATE_STATUS=1`, `AUTOUPDATE_FORCE=0`
- Checks for updates and shows availability
- Shows version information and changelog
- Updates must be manually approved

#### **Automatic Mode**
- `AUTOUPDATE_STATUS=1`, `AUTOUPDATE_FORCE=1`
- Automatically downloads and applies updates
- Shows detailed progress during updates
- Creates backups before applying changes

#### **Disabled Mode**
- `AUTOUPDATE_STATUS=0`
- Skips all update operations
- Useful for production environments requiring manual updates

### Example Output:

```bash
[AutoUpdate] Current version: v2.1.0
[AutoUpdate] Latest version: v2.2.0
[AutoUpdate] ⚠ Update available: v2.1.0 → v2.2.0
[AutoUpdate] Update summary:
  • Total changes: 15
  • Files added: 3
  • Files modified: 8
  • Files removed: 2
[AutoUpdate] ✓ Update completed successfully
```

### What Gets Updated:

- ✅ **Module scripts** (modules/)
- ✅ **Nginx configurations** (nginx/)
- ✅ **PHP configurations** (php/)
- ✅ **Core scripts** (start-modules.sh)
- ✅ **Documentation** (README.md, LICENSE)
- ❌ **User content** (www/ directory)
- ❌ **User data** (logs, uploads, databases)

<br>

## SSL Certificate Setup Tutorial  

With **Certbot DNS-01 Challenge**, you can create SSL certificates for your domain **without** needing port 80 or 443 open!  
[Let's Encrypt | Getting Started](https://letsencrypt.org/getting-started/)

### 📌 Requirements  
- A [DNS provider](https://www.cloudflare.com/) account with access to create TXT records  
- Your domain name

---

- 🔹 **Step 1: Enable Certbot in Pterodactyl Startup settings**  
  Set `CERTBOT_STATUS=true`

- 🔹 **Step 2: Configure your email address**  
  Set `CERTBOT_EMAIL=your@email.com`

- 🔹 **Step 3: Set your domain name**  
  Set `CERTBOT_DOMAIN=yourdomain.com`

- 🔹 **Step 4: Restart your server and watch console output**  
  Certbot will display a DNS TXT record

- 🔹 **Step 5: Create the DNS TXT record at your DNS provider**  
  - Name: `_acme-challenge.yourdomain.com`
  - Type: `TXT`
  - Value: Copy from Certbot output
  - Wait 2-5 minutes for DNS propagation

- 🔹 **Step 6: Verify DNS with online tool**  
  Check: https://toolbox.googleapps.com/apps/dig/#TXT/_acme-challenge.yourdomain.com

- 🔹 **Step 7: Continue in Pterodactyl console**  
  Type SPACE + ENTER twice in the command line

- 🔹 **Step 8: Copy SSL configuration template**  
  Copy `/nginx/conf.d/default-ssl.conf.temp` content into `default.conf`

- 🔹 **Step 9: Replace placeholders in default.conf**  
  Replace `<port>` with your port (e.g., `25783`)  
  Replace `<domain>` with your domain (e.g., `yourdomain.com`)

- 🔹 **Step 10: Restart Nginx server**

- 🔹 **Step 11: Create DNS A records at your DNS provider**  
  - Name: `@` → Type: `A` → Value: Your server IP
  - Name: `www` → Type: `A` → Value: Your server IP

- 🔹 **Step 12: Access your site via HTTPS**  
  Visit `https://<domain>:<port>` in your browser! 🎉

---

### 📝 Important Notes
- Staging certificates are for testing only (not trusted by browsers)
- For production: Set `CERTBOT_STAGING=false` and `CERTBOT_FORCE_RENEWAL=true`
- Certificates expire after 90 days - manual renewal required
- Certificate files location: `/home/container/letsencrypt/config/live/yourdomain.com/`


<br>

## Composer Modules Usage

This egg supports easy installation of PHP libraries using Composer.

### How it works:

- If a `composer.json` file exists in your server's root directory, it will be used automatically to install dependencies.  
- If `composer.json` is missing, the egg looks for a variable (e.g. `COMPOSER_MODULES`) with a space-separated list of Composer packages to install.  
- If neither `composer.json` nor `COMPOSER_MODULES` is set, Composer installation is skipped.

### Specifying Composer Modules manually:

- Enter the packages in the `COMPOSER_MODULES` variable in this format:

```bash
vendor/package[:version_constraint]
```

Examples:  
- Latest stable version:  
  ``` 
  symfony/http-foundation 
  ```  
- Specific version or range:  
  ``` 
  monolog/monolog:^2.0 doctrine/orm:~2.10 nesbot/carbon:^2.50 
  ```  
- Multiple packages separated by spaces:  
  ``` 
  symfony/http-foundation:^6.0 monolog/monolog guzzlehttp/guzzle 
  ```

### Notes:

- Make sure package names and versions exist on [Packagist](https://packagist.org/).  
- Incorrect inputs can cause installation errors visible in the server console.  
- Installing many or complex packages can increase startup time.  
- Composer must be pre-installed in the container environment (this egg includes it).  

<br>

## ionCube Loader Support

- ionCube Loader is detected and enabled automatically if encrypted PHP files are present.  
- No manual configuration needed; simply upload your ionCube-protected scripts and run.  

<br>

## 🚀 Cloudflared Tunnel Tutorial  

With **Cloudflared**, you can create a secure tunnel to your server, making it accessible over the internet **without** complicated port forwarding!  
[Cloudflared | Create a remotely-managed tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-remote-tunnel/)

### 📌 Requirements  
- A [Cloudflare](https://dash.cloudflare.com/) account  

---

- 🔹 **Step 1: Log in to Zero Trust ↗ and go to Networks > Tunnel**  
- 🔹 **Step 2: Select Create a tunnel.**  
- 🔹 **Step 3: Choose Cloudflared for the connector type and select Next.**  
- 🔹 **Step 4: Enter a name for your tunnel.**  
- 🔹 **Step 5: Select Save tunnel.**  
- 🔹 **Step 6: Save the token. (The token is very long)**
  
![grafik](https://github.com/user-attachments/assets/0c0430a5-5cb6-45e4-8b26-1805cddde3cc)

---

- 🔹 **Step 7: Activate Cloudflared**
    
![grafik](https://github.com/user-attachments/assets/726c5dad-7cb6-4537-a215-6aaec59d827a)

---

- 🔹 **Step 8: Add your token.**
  
![grafik](https://github.com/user-attachments/assets/46b09f6a-30b0-48aa-9980-53697b1fbcf6)

---

- 🔹 **Step 9: Add public hostname**
  
![grafik](https://github.com/user-attachments/assets/2107c323-1ed1-406b-8fcf-12ceac963aea)

---

- 🔹 **Step 10: Depending on the type, select http and URL always "localhost" + the web server port**

![grafik](https://github.com/user-attachments/assets/7b1a4e91-50f3-4fcb-a0da-7eed611ae391)

---

- 🔹 **Step 11: Restart your webserver.**
  
![grafik](https://github.com/user-attachments/assets/3d4b63fd-db66-4a7d-85ea-0bec4a7ef948)

<br>

## Git Module

- Specify your Git repository URL in the `GIT_ADDRESS` variable  
- Enable Git by setting the `GIT_STATUS` variable to `1` or `true`  
- On server creation, your repo will be cloned into the `www` folder  
- On each restart, `git pull` runs to update the files  

<br>

## Cronjob

This egg includes a **container-native cron engine** for automated task scheduling without requiring system cron.

### How it works:

- Enable cron by setting the `CRON_STATUS` variable to `1` or `true`
- Create or edit `/home/container/crontab` with your scheduled tasks
- The cron engine runs automatically in the background and executes jobs at the specified times
- All execution logs are saved to `/home/container/logs/cron.log`

### Cron Job Examples:

```bash
# Run every minute
* * * * * echo "$(date): Task executed" >> /home/container/logs/task.log

# Daily backup at 2 AM
0 2 * * * tar -czf /home/container/backups/backup-$(date +%Y%m%d).tar.gz /home/container/www

# Clean old logs weekly (Sundays at midnight)
0 0 * * 0 find /home/container/logs -name "*.log" -mtime +7 -delete

# Laravel Scheduler (if using Laravel)
* * * * * cd /home/container/www && /usr/bin/php artisan schedule:run >> /home/container/logs/scheduler.log 2>&1
```

### Notes:

- Uses **custom cron engine** - no system cron dependency required
- Supports **command substitution** like `$(date)` and environment variables
- **Always use absolute paths** in cron commands
- The cron engine starts automatically with the container

<br>

## Change PHP version

Changing the PHP version is currently still somewhat cumbersome. A revised version will be available in the future.

- **Step 1:** In your Pterodactyl panel, go to the "Startup" tab on your web server. Change the variable "PHP VERSION" to the desired version.

![php_version](https://github.com/user-attachments/assets/b07d66d2-ab20-4604-8358-50842d172dda)

---

- **Step 2:** Finally, you need to customise the Docker image. Select the appropriate Docker image to match the version.

![docker_image](https://github.com/user-attachments/assets/050b6db9-9cc8-42f7-a300-11450e60cb7d)

<br>

## PHP extensions

PHP extensions of PHP version 8.3:

```bash
Core, date, libxml, openssl, pcre, zlib, filter, hash, json, random, Reflection, SPL, session, standard, sodium, cgi-fcgi, mysqlnd, PDO, psr, xml, bcmath, calendar, ctype, curl, dom, mbstring, FFI, fileinfo, ftp, gd, gettext, gmp, iconv, igbinary, imagick, imap, intl, ldap, exif, memcache, mongodb, msgpack, mysqli, odbc, pcov, pdo_mysql, PDO_ODBC, pdo_pgsql, pdo_sqlite, pgsql, Phar, posix, ps, pspell, readline, shmop, SimpleXML, soap, sockets, sqlite3, sysvmsg, sysvsem, sysvshm, tokenizer, xmlreader, xmlwriter, xsl, zip, mailparse, memcached, inotify, maxminddb, protobuf, Zend OPcache
```

<br>

## Notes

- Public web root directory: `www`  
- To enable HTTPS, modify `/home/container/nginx/conf.d/default.conf` accordingly  
- PHP extensions vary slightly per version; full list available in docs  
- Changing PHP versions requires matching Docker image selection and restart  
- Auto-updates are powered by the [Tavuru API](https://api.tavuru.de) for reliable version management

<br>

## License

[MIT License](https://choosealicense.com/licenses/mit/)



Forked and adapted from: https://gitlab.com/tenten8401/pterodactyl-nginx
