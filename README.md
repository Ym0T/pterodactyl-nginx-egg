
# Pterodactyl Nginx Egg

A versatile Pterodactyl Egg featuring Nginx, PHP 8.x, WordPress, Git, Composer, Cronjob, ionCube Loader, and Cloudflare Tunnel support.

<br>

## Table of Contents
- [Features](#features)
- [Installation](#installation)
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

- 🧹 LogCleaner: Cleans `/tmp` and old logs (dry-run supported)  
- 🌱 Git Module: Auto `git pull` on restart  
- 📦 Composer Module: Installs packages from `composer.json` or a fallback variable  
- 🔐 ionCube Loader: Auto-detected and enabled for encrypted PHP  
- 🌐 Cloudflare Tunnel: Secure tunnel with token validation  
- 🚀 PHP-NGINX Startup: Auto-detects PHP-FPM version, runs NGINX in foreground  
- 🖥️ Multi-arch support: AMD64 & ARM64  
- 🎯 **Selectable PHP Versions:**  
  - ✅ 8.4  
  - ✅ 8.3  
  - ☑️ 8.2 (security-only)  
  - ☑️ 8.1 (security-only)  

[PHP Supported Versions](https://www.php.net/supported-versions.php)

<br>

## Installation

1. Download the egg file (`egg-nginx.json`)  
2. In your Pterodactyl panel, navigate to **Nests** in the sidebar  
3. Import the egg under **Import Egg**  
4. Create a new server and select the **Nginx** egg  
5. Choose the Docker image matching your desired PHP version  
6. Fill in all required variables, including whether WordPress is desired and the PHP version field (must be set explicitly)  

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

- 🔹 **Step 10: Depending on the type, select http and URL always “localhost” + the web server port**

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

<br>

## License

[MIT License](https://choosealicense.com/licenses/mit/)

Forked and adapted from: https://gitlab.com/tenten8401/pterodactyl-nginx
