#!/bin/bash

# Script to initialize nginx and certbot docker environment
# Usage: ./init-nginx.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Initializing the environment...${NC}"

# Create default nginx configuration
if [ ! -f "nginx/conf.d/default.conf" ]; then
    echo -e "${GREEN}Creating default nginx configuration...${NC}"
    cp nginx/conf.d/conf.template nginx/conf.d/default.conf
fi

docker-compose up -d

# Create README sections
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Add a domain with SSL certificate:"
echo -e "     ${GREEN}./add-domain.sh example.com admin@example.com${NC}"
echo ""
echo "  2. Check container status:"
echo -e "     ${GREEN}docker-compose ps${NC}"
echo ""
echo "  3. View nginx logs:"
echo -e "     ${GREEN}docker-compose logs -f nginx${NC}"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "  - Make sure your domain's DNS A record points to this server's IP"
echo "  - Ensure ports 80 and 443 are open and accessible from the internet"
echo "  - Certificates will automatically renew every 12 hours"