#!/bin/bash

# Script to list all configured domains
# Usage: ./list-domains.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

NGINX_CONF_DIR="./nginx/conf.d"

echo -e "${GREEN}Configured domains:${NC}"
echo "===================="
echo ""

if [ ! -d "$NGINX_CONF_DIR" ]; then
    echo -e "${RED}Error: nginx configuration directory not found${NC}"
    exit 1
fi

# Count configuration files (excluding default.conf)
CONF_COUNT=$(find "$NGINX_CONF_DIR" -name "*.conf" ! -name "default.conf" | wc -l)

if [ "$CONF_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}No domains configured yet${NC}"
    echo ""
    echo "Use ./add-domain.sh to add a new domain"
    exit 0
fi

# List all configuration files
for conf_file in "$NGINX_CONF_DIR"/*.conf; do
    if [ "$(basename "$conf_file")" != "default.conf" ]; then
        domain=$(basename "$conf_file" .conf)
        echo -e "${GREEN}Domain:${NC} $domain"
        echo -e "  Config: $conf_file"
        
        # Check if SSL certificate exists
        if docker-compose exec -T nginx test -d "/etc/letsencrypt/live/$domain" 2>/dev/null; then
            echo -e "  SSL: ${GREEN}✓ Configured${NC}"
            
            # Try to get certificate expiry date
            expiry=$(docker-compose exec -T nginx openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$domain/fullchain.pem" 2>/dev/null | cut -d= -f2 || echo "")
            if [ -n "$expiry" ]; then
                echo -e "  Expires: $expiry"
            fi
        else
            echo -e "  SSL: ${YELLOW}✗ Not configured${NC}"
        fi
        echo ""
    fi
done

echo "===================="
echo -e "Total domains: ${GREEN}$CONF_COUNT${NC}"
