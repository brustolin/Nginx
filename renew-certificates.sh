#!/bin/bash

# Script to renew all SSL certificates manually
# Usage: ./renew-certificates.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Renewing SSL certificates...${NC}"

# Check if docker-compose.yml exists
if [ ! -f "./docker-compose.yml" ]; then
    echo -e "${RED}Error: docker-compose.yml not found${NC}"
    exit 1
fi

# Renew certificates
docker-compose run --rm certbot renew || {
    echo -e "${RED}Certificate renewal failed${NC}"
    exit 1
}

# Reload nginx to apply new certificates
echo -e "${GREEN}Reloading nginx...${NC}"
docker-compose exec -T nginx nginx -s reload || {
    echo -e "${YELLOW}Warning: nginx reload failed${NC}"
}

echo -e "${GREEN}✓ Certificate renewal complete!${NC}"
echo ""
echo "Note: Certificates are automatically renewed by the certbot container every 12 hours."
echo "This script is useful for manual renewal if needed."
