#!/bin/bash

# Script to add a new domain to nginx and request Let's Encrypt SSL certificate
# Usage: ./add-domain.sh <domain> <email>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if required arguments are provided
if [ $# -lt 2 ]; then
    echo -e "${RED}Error: Missing required arguments${NC}"
    echo "Usage: $0 <domain> <email>"
    echo "Example: $0 example.com admin@example.com"
    exit 1
fi

DOMAIN=$1
EMAIL=$2
NGINX_CONF_DIR="./nginx/conf.d"
CERTBOT_DIR="./certbot"
DOCKER_COMPOSE_FILE="./docker-compose.yml"

# Validate domain format (basic check)
if ! [[ $DOMAIN =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
    echo -e "${RED}Error: Invalid domain format${NC}"
    exit 1
fi

# Validate email format (basic check)
if ! [[ $EMAIL =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo -e "${RED}Error: Invalid email format${NC}"
    exit 1
fi

echo -e "${GREEN}Setting up domain: ${DOMAIN}${NC}"
echo -e "${GREEN}Contact email: ${EMAIL}${NC}"

# Create necessary directories if they don't exist
mkdir -p "$NGINX_CONF_DIR"
mkdir -p "$CERTBOT_DIR/conf"
mkdir -p "$CERTBOT_DIR/www"

# Check if docker compose.yml exists
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    echo -e "${RED}Error: docker compose.yml not found. Please run init-nginx.sh first.${NC}"
    exit 1
fi

# Create nginx configuration for the domain (initial HTTP-only for certificate verification)
CONF_FILE="$NGINX_CONF_DIR/${DOMAIN}.conf"

if [ -f "$CONF_FILE" ]; then
    echo -e "${YELLOW}Warning: Configuration for ${DOMAIN} already exists. Backing up...${NC}"
    cp "$CONF_FILE" "${CONF_FILE}.backup.$(date +%s)"
fi

echo -e "${GREEN}Creating nginx configuration for ${DOMAIN}...${NC}"
cat > "$CONF_FILE" << EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name ${DOMAIN} www.${DOMAIN};
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://\$host\$request_uri;
    }
}
EOF

# Reload nginx to apply the configuration
echo -e "${GREEN}Reloading nginx...${NC}"
docker compose exec -T nginx nginx -t && docker compose exec -T nginx nginx -s reload || {
    echo -e "${YELLOW}Note: nginx not running or reload failed. Will apply on next start.${NC}"
}

# Request SSL certificate from Let's Encrypt
echo -e "${GREEN}Requesting SSL certificate from Let's Encrypt...${NC}"
certbot certonly --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    -d "$DOMAIN" \
    -d "www.${DOMAIN}" || {
    echo -e "${RED}Certificate request failed. This could be because:${NC}"
    echo "  - The domain does not point to this server"
    echo "  - Port 80 is not accessible from the internet"
    echo "  - Let's Encrypt rate limits have been reached"
    echo ""
    echo -e "${YELLOW}The HTTP configuration has been created. Fix the issues and try again.${NC}"
    exit 1
}

# Update nginx configuration to use SSL
echo -e "${GREEN}Updating nginx configuration to use SSL...${NC}"
cat > "$CONF_FILE" << EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name ${DOMAIN} www.${DOMAIN};
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    
    server_name ${DOMAIN} www.${DOMAIN};
    
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Root directory (customize as needed)
    root /usr/share/nginx/html;
    index index.html index.htm;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # Example: Proxy to a backend service
    # Uncomment and modify as needed
    # location /api {
    #     proxy_pass http://backend:8080;
    #     proxy_set_header Host \$host;
    #     proxy_set_header X-Real-IP \$remote_addr;
    #     proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    #     proxy_set_header X-Forwarded-Proto \$scheme;
    # }
}
EOF

# Reload nginx to apply the SSL configuration
echo -e "${GREEN}Reloading nginx with SSL configuration...${NC}"
docker compose exec -T nginx nginx -t && docker compose exec -T nginx nginx -s reload

echo -e "${GREEN}✓ Domain ${DOMAIN} has been configured successfully!${NC}"
echo ""
echo "Next steps:"
echo "  1. Verify the site is accessible at https://${DOMAIN}"
echo "  2. Edit ${CONF_FILE} to customize the configuration"
echo "  3. Reload nginx after changes: docker compose exec nginx nginx -s reload"
echo ""
echo "Note: Certificates will auto-renew via the certbot container."
