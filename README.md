
# Pterodactyl Nginx egg

Nginx web server egg with PHP and optional Wordpress installation.


## Features
You can select the desired PHP version.
- ✅ 8.2
- ✅ 8.1
- ✅ 8.0
- ✅ 7.3


## How to install
- **Step 1:** Download the egg (json file egg-nginx.json)
- **Step 2:** In your panel, go to the "Nests" category in the sidebar
- **Step 3:** Import the egg under "Import egg" and then press "save" at the bottom right
- **Step 4:** Create a new server and select the "Nginx" egg
- **Step 5:** Select the corresponding Docker image with the desired PHP version
- **Step 6:** Fill in the text fields. Whether Wordpress is desired or not. It is important to **enter the selected PHP version in the PHP version field**.


## FAQ

#### In which folder do I upload my files for my site?
Here the "www" folder is used as a public folder, which can be accessed by everyone. Added files can be accessed in this folder.


## How to use https://
Go to the file: /home/container/nginx/conf.d/default.conf

Change "listen" to: listen <YOUR_PORT> ssl;
Please also change the spacer distance. Otherwise the "listen" will be overwritten each time the egg is restarted.

Add the following lines:
    ssl_certificate /home/container/your_cert.crt;
    ssl_certificate_key /home/container/your_cert_key.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

Adjust the lines accordingly.
Furthermore, if not already done, adjust to your domain: "server_name www.example.com";


## License
[MIT](https://choosealicense.com/licenses/mit/)

Originally forked and edited from https://gitlab.com/tenten8401/pterodactyl-nginx
