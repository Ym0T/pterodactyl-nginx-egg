# Certbot SSL Certificate Module

This module manages SSL certificate acquisition using Certbot's DNS-01 challenge at container startup, with manual DNS validation and configurable settings.

## Features

- Conditional execution based on `CERTBOT_STATUS` (true/1 or false/0)
- Manual DNS-01 challenge for domains without requiring port 80/443
- Interactive TXT record creation with clear instructions
- Certificate validity checking (skips renewal if >30 days valid)
- Force renewal option for testing or updating certificates
- Staging mode for testing without hitting rate limits
- Colorized, structured output with step-by-step guidance
- Configurable certificate paths and log locations
- Compatible with Pterodactyl console input

## Configuration

Environment variables:

- `CERTBOT_STATUS` (default: `false`) – enable or disable Certbot execution
- `CERTBOT_EMAIL` (default: `""`) – email address for Let's Encrypt notifications (required)
- `CERTBOT_DOMAIN` (default: `""`) – domain name for certificate (required)
- `CERTBOT_STAGING` (default: `false`) – use Let's Encrypt staging server for testing
- `CERTBOT_FORCE_RENEWAL` (default: `false`) – force certificate renewal even if valid
- `CERTBOT_LOG_FILE` (default: `/home/container/logs/certbot.log`) – path to store Certbot logs
- `CERTBOT_CERT_PATH` (default: `/home/container/letsencrypt/config/live`) – certificate storage location
- `CERTBOT_CONFIG_DIR` (default: `/home/container/letsencrypt/config`) – Certbot configuration directory
- `CERTBOT_WORK_DIR` (default: `/home/container/letsencrypt/work`) – Certbot working directory
- `CERTBOT_LOGS_DIR` (default: `/home/container/logs`) – Certbot logs directory

## Example Egg JSON Variables

"variables": [
{
"name": "Enable Certbot SSL",
"env_variable": "CERTBOT_STATUS",
"default_value": "false",
"description": "Enable automatic SSL certificate acquisition on startup",
"required": false
},
{
"name": "Certbot Email",
"env_variable": "CERTBOT_EMAIL",
"default_value": "",
"description": "Email address for Let's Encrypt certificate notifications",
"required": false
},
{
"name": "Certbot Domain",
"env_variable": "CERTBOT_DOMAIN",
"default_value": "",
"description": "Domain name for SSL certificate (e.g., example.com)",
"required": false
},
{
"name": "Certbot Staging Mode",
"env_variable": "CERTBOT_STAGING",
"default_value": "false",
"description": "Use staging server for testing (certificates won't be trusted by browsers)",
"required": false
},
{
"name": "Certbot Force Renewal",
"env_variable": "CERTBOT_FORCE_RENEWAL",
"default_value": "false",
"description": "Force certificate renewal even if current certificate is valid",
"required": false
},
{
"name": "Certbot Log File",
"env_variable": "CERTBOT_LOG_FILE",
"default_value": "/home/container/logs/certbot.log",
"description": "Path to store Certbot logs",
"required": false
}
]

## Script Logic

1. Exit immediately if `CERTBOT_STATUS` is not `true` or `1`
2. Validate `CERTBOT_EMAIL` and `CERTBOT_DOMAIN` are set
3. Create necessary directories for logs and certificates
4. Check if certificate already exists and is valid (>30 days remaining)
   - If valid and `CERTBOT_FORCE_RENEWAL` is false, skip renewal
   - If expiring soon or force renewal enabled, proceed
5. Build Certbot command with DNS-01 challenge and staging flag if enabled
6. Display clear instructions for DNS TXT record creation
7. Execute Certbot, which will:
   - Display the required TXT record name and value
   - Wait for user to press Enter in Pterodactyl console (type space to continue)
   - Validate the DNS TXT record
   - Issue the certificate if validation succeeds
8. On success, display certificate location and expiration date
9. On failure, show last 15 lines of log for troubleshooting
10. Remind user that manual renewal is required before expiration

## Usage Instructions

### Initial Setup (Testing)

1. Set environment variables:

CERTBOT_STATUS=true
CERTBOT_EMAIL=your@email.com
CERTBOT_DOMAIN=yourdomain.com
CERTBOT_STAGING=true

2. Start the container and watch the console output

3. When Certbot displays the TXT record:
- Go to your DNS provider
- Create a TXT record: `_acme-challenge.yourdomain.com`
- Set the value shown by Certbot
- Wait 2-5 minutes for DNS propagation

4. Verify DNS propagation:
- Use: https://toolbox.googleapps.com/apps/dig/#TXT/_acme-challenge.yourdomain.com
- Or run: `nslookup -type=TXT _acme-challenge.yourdomain.com`

5. Enter a space in the Pterodactyl console command line to continue

6. Certbot will validate and issue a staging certificate

### Production Certificate

Once testing succeeds, get a real certificate:

CERTBOT_STATUS=true
CERTBOT_EMAIL=your@email.com
CERTBOT_DOMAIN=yourdomain.com
CERTBOT_STAGING=false
CERTBOT_FORCE_RENEWAL=true

Follow the same DNS TXT record process. The production certificate will be trusted by all browsers.

### Certificate Renewal

Certificates expire after 90 days. To renew:

1. Set `CERTBOT_FORCE_RENEWAL=true`
2. Restart the container or run the script
3. Create the new TXT record shown by Certbot
4. Continue the process as before
5. Set `CERTBOT_FORCE_RENEWAL=false`

**Note:** Automatic renewal is not supported with manual DNS-01 challenge. You must manually renew before expiration.

## Certificate Files

After successful acquisition, certificates are stored at:

/home/container/letsencrypt/config/live/yourdomain.com/
├── fullchain.pem (certificate + chain)
├── privkey.pem (private key)
├── cert.pem (certificate only)
└── chain.pem (chain only)

Use `fullchain.pem` and `privkey.pem` for most web servers.

## Troubleshooting

**Certificate not trusted by browsers:**
- Check if `CERTBOT_STAGING=true` – staging certificates are for testing only
- Set `CERTBOT_STAGING=false` and `CERTBOT_FORCE_RENEWAL=true` to get production certificate

**DNS validation fails:**
- Verify TXT record is created correctly at `_acme-challenge.yourdomain.com`
- Wait longer for DNS propagation (can take 5-10 minutes)
- Check DNS with online tools or `nslookup`

**"Certificate already exists" message:**
- This is normal if certificate is still valid
- Set `CERTBOT_FORCE_RENEWAL=true` to override

**Cannot enter input in Pterodactyl:**
- Type a space character in the command line input field
- This simulates pressing Enter for Certbot

## Important Notes

- **Port 80/443 not required:** DNS-01 challenge works without open ports
- **Manual process:** Each certificate request requires creating a DNS TXT record
- **No auto-renewal:** You must manually renew before the 90-day expiration
- **Rate limits:** Production server has limits (5 failures/hour, 50 certs/week per domain)
- **Staging for testing:** Always test with `CERTBOT_STAGING=true` first