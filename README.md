# Pterodactyl Nginx egg

Nginx web server egg with PHP, optional Wordpress installation and git support.

## Features

#### Supports AMD64 & ARM64
#### Git support for your webserver
#### You can select the desired PHP version:
- ✅ 8.4
- ✅ 8.3
- ✅ 8.2
- ✅ 8.1 [Only critical security updates]
- ☑️ 8.0 [EOL]

[PHP supported versions](https://www.php.net/supported-versions.php)

## How to install

- **Step 1:** Download the egg (json file `egg-nginx.json`)
- **Step 2:** In your panel, go to the "Nests" category in the sidebar
- **Step 3:** Import the egg under "Import egg"
- **Step 4:** Create a new server and select the "Nginx" egg
- **Step 5:** Select the corresponding Docker image with the desired PHP version
- **Step 6:** Fill in the text fields. Whether Wordpress is desired or not. It is important to **enter the selected PHP version in the PHP version field**.

## FAQ

#### In which folder do I upload my files for my site?
The "www" folder is used as a public folder. There you can add your PHP, HTML, CSS, JS and so on files that are required for the public or for the operation of the site.

## How do I use Git support?

#### Instructions for Git support
Git support allows you to automatically clone a Git repository into the www folder of your web server and apply the latest changes every time you restart (git pull). This is how it works:

#### Prerequisites:
- Git Status must be enabled to use Git.
- GIT_ADDRESS must contain a valid Git repository that you want to clon

#### Steps to set up (Specify GIT_ADDRESS):
- When creating the web server, you can specify a Git repository URL in the GIT_ADDRESS field.
- Example: https://github.com/username/repository.git

#### Activate Git status:
- Make sure that the Git status is set to ‘active’ (1 or true) so that the repository is managed automatically.

#### Automatic installation:
- When the server is first created, the specified repository is automatically cloned into the www folder of your server.

#### Automatic updates:
- After each restart of the web server, the repository in the www folder is automatically updated to the latest version (git pull).

## How to use https://

Go to the file:

```bash
/home/container/nginx/conf.d/default.conf
```

Change "listen" to:

```bash
listen <YOUR_PORT> ssl;
```

Please also change the spacer distance. Otherwise the "listen" will be overwritten each time the egg is restarted.

Add the following lines:

```bash
ssl_certificate /home/container/your_cert.crt;
ssl_certificate_key /home/container/your_cert_key.key;
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers HIGH:!aNULL:!MD5;
```

Adjust the lines accordingly.

Furthermore, if not already done, adjust to your domain:

```bash
server_name www.example.com;
```

## Change PHP version

Changing the PHP version is currently still somewhat cumbersome. A revised version will be available in the future.

- **Step 1:** In your Pterodactyl panel, go to the "Startup" tab on your web server. Change the variable "PHP VERSION" to the desired version.

![php_version](https://github.com/Ym0T/pterodactyl-nginx-egg/assets/104158130/cf76cf05-a3df-464a-8f86-77a69101bfc4)

---

- **Step 2:** Finally, you need to customise the Docker image. Select the appropriate Docker image to match the version.

![docker_image](https://github.com/Ym0T/pterodactyl-nginx-egg/assets/104158130/cf76cf05-a3df-464a-8f86-77a69101bfc4)

---

- **Step 3:** Restart your container.

## PHP extensions

PHP extensions of PHP version 8.3:

```bash
Core, date, libxml, openssl, pcre, zlib, filter, hash, json, random, Reflection, SPL, session, standard, sodium, cgi-fcgi, mysqlnd, PDO, psr, xml, bcmath, calendar, ctype, curl, dom, mbstring, FFI, fileinfo, ftp, gd, gettext, gmp, iconv, igbinary, imagick, imap, intl, ldap, exif, memcache, mongodb, msgpack, mysqli, odbc, pcov, pdo_mysql, PDO_ODBC, pdo_pgsql, pdo_sqlite, pgsql, Phar, posix, ps, pspell, readline, shmop, SimpleXML, soap, sockets, sqlite3, sysvmsg, sysvsem, sysvshm, tokenizer, xmlreader, xmlwriter, xsl, zip, mailparse, memcached, inotify, maxminddb, protobuf, Zend OPcache
```

Small differences in the extensions between the PHP versions.

## License

[MIT License](https://choosealicense.com/licenses/mit/)

Originally forked and edited from https://gitlab.com/tenten8401/pterodactyl-nginx
