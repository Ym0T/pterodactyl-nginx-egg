#!/usr/bin/env bash
set -euo pipefail
trap 'echo -e "${RED}[Certbot] Error on line $LINENO${NC}"' ERR

# Color definitions
BLUE='\033[0;34m'; BOLD_BLUE='\033[1;34m'
WHITE='\033[0;37m'; GREEN='\033[0;32m'
YELLOW='\033[0;33m'; RED='\033[0;31m'
NC='\033[0m'

# header function
header() {
  echo -e "${BLUE}───────────────────────────────────────────────${NC}"
  echo -e "${BOLD_BLUE}[Certbot] $1${NC}"
}

# Configuration via environment variables
CERTBOT_STATUS="${CERTBOT_STATUS:-false}"
CERTBOT_EMAIL="${CERTBOT_EMAIL:-}"
CERTBOT_DOMAIN="${CERTBOT_DOMAIN:-}"
CERTBOT_STAGING="${CERTBOT_STAGING:-false}"
CERTBOT_FORCE_RENEWAL="${CERTBOT_FORCE_RENEWAL:-false}"
CERTBOT_LOG_FILE="${CERTBOT_LOG_FILE:-/home/container/logs/certbot.log}"
CERTBOT_CERT_PATH="${CERTBOT_CERT_PATH:-/home/container/letsencrypt/config/live}"
CERTBOT_CONFIG_DIR="/home/container/letsencrypt/config"
CERTBOT_WORK_DIR="/home/container/letsencrypt/work"
CERTBOT_LOGS_DIR="/home/container/logs"

# Helper to test enabled status: true or 1
enabled() { [[ "$1" =~ ^(true|1)$ ]]; }

# Skip if disabled
if ! enabled "$CERTBOT_STATUS"; then
  exit 0
fi

# Header
header "Starting SSL Certificate Manager (DNS-01 Challenge)"

# Verify email
if [[ -z "$CERTBOT_EMAIL" ]]; then
  echo -e "${RED}[Certbot] CERTBOT_EMAIL is not set; skipping certificate setup.${NC}"
  exit 0
fi

# Verify domain
if [[ -z "$CERTBOT_DOMAIN" ]]; then
  echo -e "${RED}[Certbot] CERTBOT_DOMAIN is not set; skipping certificate setup.${NC}"
  exit 0
fi

# Create log directory if it doesn't exist
mkdir -p "$CERTBOT_LOGS_DIR"
mkdir -p "$CERTBOT_CONFIG_DIR"
mkdir -p "$CERTBOT_WORK_DIR"

# Check if certificate already exists and is valid
if [[ -d "$CERTBOT_CERT_PATH/$CERTBOT_DOMAIN" ]] && ! enabled "$CERTBOT_FORCE_RENEWAL"; then
  echo -e "${YELLOW}[Certbot] Certificate for $CERTBOT_DOMAIN already exists. Checking validity...${NC}"
  
  # Check expiration date
  if openssl x509 -checkend 2592000 -noout -in "$CERTBOT_CERT_PATH/$CERTBOT_DOMAIN/cert.pem" 2>/dev/null; then
    echo -e "${GREEN}[Certbot] Certificate is valid for more than 30 days. Skipping renewal.${NC}"
    
    # Display current expiration
    EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$CERTBOT_CERT_PATH/$CERTBOT_DOMAIN/cert.pem" | cut -d= -f2)
    echo -e "${WHITE}[Certbot] Current certificate expires: $EXPIRY_DATE${NC}"
    echo -e "${YELLOW}[Certbot] To force renewal, set CERTBOT_FORCE_RENEWAL=true${NC}"
    exit 0
  else
    echo -e "${YELLOW}[Certbot] Certificate expires soon. Will renew...${NC}"
  fi
fi

# Build certbot command for DNS-01 challenge
CERTBOT_CMD="certbot certonly --manual --preferred-challenges dns --manual-public-ip-logging-ok \
--agree-tos --email $CERTBOT_EMAIL -d $CERTBOT_DOMAIN \
--config-dir $CERTBOT_CONFIG_DIR --work-dir $CERTBOT_WORK_DIR --logs-dir $CERTBOT_LOGS_DIR"

# Add staging flag if enabled
if enabled "$CERTBOT_STAGING"; then
  CERTBOT_CMD="$CERTBOT_CMD --staging"
  echo -e "${YELLOW}[Certbot] Using staging server (test mode)${NC}"
fi

# Add force renewal flag if enabled
if enabled "$CERTBOT_FORCE_RENEWAL"; then
  CERTBOT_CMD="$CERTBOT_CMD --force-renewal"
  echo -e "${YELLOW}[Certbot] Force renewal enabled${NC}"
fi

# Execute certbot
header "Obtaining SSL Certificate for $CERTBOT_DOMAIN (DNS-01)"
echo -e "${YELLOW}[Certbot] Using DNS-01 challenge mode${NC}"
echo ""
echo -e "${BOLD_BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}INSTRUCTIONS FOR DNS VALIDATION:${NC}"
echo -e "${YELLOW}1. Certbot will display a DNS TXT record below${NC}"
echo -e "${YELLOW}2. Create the TXT record at your DNS provider:${NC}"
echo -e "${YELLOW}   - Record name: _acme-challenge.yourdomain.com${NC}"
echo -e "${YELLOW}   - Record type: TXT${NC}"
echo -e "${YELLOW}   - Record value: (shown by Certbot below)${NC}"
echo -e "${YELLOW}3. Wait 2-5 minutes for DNS propagation${NC}"
echo -e "${YELLOW}4. To continue in Pterodactyl console:${NC}"
echo -e "${YELLOW}   - Type a SPACE in the command line${NC}"
echo -e "${YELLOW}   - Then press ENTER${NC}"
echo -e "${YELLOW}   - You need to do this TWICE (space + enter, twice)${NC}"
echo -e "${BOLD_BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Execute certbot with live output
if eval "$CERTBOT_CMD" 2>&1 | tee -a "$CERTBOT_LOG_FILE"; then
  echo ""
  echo -e "${GREEN}[Certbot] Certificate obtained successfully!${NC}"
  echo -e "${WHITE}[Certbot] Certificate location: $CERTBOT_CERT_PATH/$CERTBOT_DOMAIN/${NC}"
  
  # Display certificate info
  if [[ -f "$CERTBOT_CERT_PATH/$CERTBOT_DOMAIN/cert.pem" ]]; then
    EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$CERTBOT_CERT_PATH/$CERTBOT_DOMAIN/cert.pem" | cut -d= -f2)
    echo -e "${WHITE}[Certbot] Certificate expires: $EXPIRY_DATE${NC}"
    echo ""
    echo -e "${YELLOW}[Certbot] IMPORTANT: This certificate will NOT auto-renew!${NC}"
    echo -e "${YELLOW}[Certbot] To renew, run this script again with CERTBOT_FORCE_RENEWAL=true${NC}"
    echo -e "${YELLOW}[Certbot] before the expiration date shown above.${NC}"
  fi
  
  exit 0
else
  echo ""
  header "Certificate Acquisition Failed"
  echo -e "${RED}[Certbot] Failed to obtain certificate. Check logs: $CERTBOT_LOG_FILE${NC}"
  echo -e "${WHITE}[Certbot] Last 15 lines of log:${NC}"
  tail -n 15 "$CERTBOT_LOG_FILE" | sed "s/^/  /"
  exit 1
fi
