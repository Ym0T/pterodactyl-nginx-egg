# Pterodactyl Nginx egg

Pterodactyl Nginx web server egg with PHP8.x, Wordpress, Git & Cloudflare Tunnel support 
<br><br>
## Features

#### 🔹 Supports AMD64 & ARM64
#### 🔹 Cloudflare Tunnel support
#### 🔹 Git support for your webserver
#### 🔹 You can select the desired PHP version:
- ✅ 8.4
- ✅ 8.3
- ✅ 8.2 [Only critical security updates]
- ✅ 8.1 [Only critical security updates]
- ☑️ 8.0 [EOL]

[PHP supported versions](https://www.php.net/supported-versions.php)
<br><br>
## How to install

- **Step 1:** Download the egg (json file `egg-nginx.json`)
- **Step 2:** In your panel, go to the "Nests" category in the sidebar
- **Step 3:** Import the egg under "Import egg"
- **Step 4:** Create a new server and select the "Nginx" egg
- **Step 5:** Select the corresponding Docker image with the desired PHP version
- **Step 6:** Fill in the text fields. Whether Wordpress is desired or not. It is important to **enter the selected PHP version in the PHP version field**.
<br><br>
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


✅ You have successfully set up Cloudflared and connected it to your server!<br><br>
🔹 Info: Your web server ip and port does not have to be accessible from outside and can have a local IP such as 127.0.0.1.
<br><br>
## How to Use Composer Modules

This Pterodactyl Egg allows you to easily install additional PHP libraries (Composer modules) for your server. Here's how:

1.  **Locate the `Composer modules` Variable:** When creating or editing your server in the Pterodactyl panel, you will find a variable named `Composer modules`.

2.  **Specify the Modules:** In the value field of the `Composer modules` variable, enter a space-separated list of the Composer packages you wish to install. You can also specify the desired version constraints.

    * **Basic Package:** To install the latest stable version of a package, simply enter its name:
        ```
        vendor/package
        ```
        Example: `symfony/http-foundation`

    * **Specific Version:** To install a specific version or version range, use the following format:
        ```
        vendor/package:version_constraint
        ```
        Examples:
        * `monolog/monolog:^2.0` (installs the latest version within the 2.x branch)
        * `doctrine/orm:~2.10` (installs a version compatible with 2.10)
        * `nesbot/carbon:^2.50`

    * **Multiple Modules:** To install multiple modules, separate them with spaces:
        ```
        vendor/package1:version vendor/package2 vendor/package3:^1.0
        ```
        Example: `symfony/http-foundation ^6.0 monolog/monolog guzzlehttp/guzzle`

3.  **Save and Start/Restart Your Server:** After entering the desired Composer modules in the `COMPOSER_MODULES` variable, save your server configuration. If your server is already running, you will need to restart it for the changes to take effect.

4.  **Module Installation:** During the server startup process, the Egg will automatically detect the modules listed in the `COMPOSER_MODULES` variable and attempt to install them using Composer. You can monitor the server console for the installation output.

**Important Notes:**

* Ensure that the package names and version constraints you enter are correct and exist on Packagist ([https://packagist.org/](https://packagist.org/)).
* Incorrectly specified modules or version constraints may lead to installation errors. Check your server console for any error messages.
* Installing a large number of modules or very complex dependencies can increase the server startup time.
* This Egg assumes that Composer is already installed within the server environment.

By following these steps, you can easily extend the functionality of your server by adding various PHP libraries through Composer modules.

<br><br>
## FAQ


#### In which folder do I upload my files for my site?
The "www" folder is used as a public folder. There you can add your PHP, HTML, CSS, JS and so on files that are required for the public or for the operation of the site.
<br><br>
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
<br><br>
## Change PHP version

Changing the PHP version is currently still somewhat cumbersome. A revised version will be available in the future.

- **Step 1:** In your Pterodactyl panel, go to the "Startup" tab on your web server. Change the variable "PHP VERSION" to the desired version.

![php_version](https://github.com/user-attachments/assets/b07d66d2-ab20-4604-8358-50842d172dda)

---

- **Step 2:** Finally, you need to customise the Docker image. Select the appropriate Docker image to match the version.

![docker_image](https://github.com/user-attachments/assets/050b6db9-9cc8-42f7-a300-11450e60cb7d)

---

- **Step 3:** Restart your container.
<br><br>
## PHP extensions

PHP extensions of PHP version 8.3:

```bash
Core, date, libxml, openssl, pcre, zlib, filter, hash, json, random, Reflection, SPL, session, standard, sodium, cgi-fcgi, mysqlnd, PDO, psr, xml, bcmath, calendar, ctype, curl, dom, mbstring, FFI, fileinfo, ftp, gd, gettext, gmp, iconv, igbinary, imagick, imap, intl, ldap, exif, memcache, mongodb, msgpack, mysqli, odbc, pcov, pdo_mysql, PDO_ODBC, pdo_pgsql, pdo_sqlite, pgsql, Phar, posix, ps, pspell, readline, shmop, SimpleXML, soap, sockets, sqlite3, sysvmsg, sysvsem, sysvshm, tokenizer, xmlreader, xmlwriter, xsl, zip, mailparse, memcached, inotify, maxminddb, protobuf, Zend OPcache
```

Small differences in the extensions between the PHP versions.
<br><br>
## License

[MIT License](https://choosealicense.com/licenses/mit/)

Originally forked and edited from https://gitlab.com/tenten8401/pterodactyl-nginx
