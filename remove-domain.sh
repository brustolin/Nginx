#!/bin/bash

# Script to remove a domain from nginx
# Usage: ./remove-domain.sh <domain>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if required arguments are provided
if [ $# -lt 1 ]; then
    echo -e "${RED}Error: Missing required argument${NC}"
    echo "Usage: $0 <domain>"
    echo "Example: $0 example.com"
    exit 1
fi

DOMAIN=$1
NGINX_CONF_DIR="./nginx/conf.d"
CONF_FILE="$NGINX_CONF_DIR/${DOMAIN}.conf"

# Check if configuration exists
if [ ! -f "$CONF_FILE" ]; then
    echo -e "${RED}Error: Configuration for ${DOMAIN} does not exist${NC}"
    exit 1
fi

echo -e "${YELLOW}This will remove the nginx configuration for ${DOMAIN}${NC}"
echo -e "${YELLOW}SSL certificates will remain in certbot/conf for future use${NC}"
read -p "Are you sure you want to continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Backup the configuration
echo -e "${GREEN}Backing up configuration...${NC}"
cp "$CONF_FILE" "${CONF_FILE}.backup.$(date +%s)"

# Remove the configuration
echo -e "${GREEN}Removing nginx configuration...${NC}"
rm "$CONF_FILE"

# Reload nginx
echo -e "${GREEN}Reloading nginx...${NC}"
docker-compose exec -T nginx nginx -t && docker-compose exec -T nginx nginx -s reload || {
    echo -e "${RED}nginx reload failed${NC}"
    exit 1
}

echo -e "${GREEN}✓ Domain ${DOMAIN} has been removed successfully!${NC}"
echo ""
echo "Note: SSL certificates are still available in certbot/conf/live/${DOMAIN}/"
echo "To completely remove certificates, manually delete the directory."
