#!/bin/bash

# Script to initialize nginx and certbot docker environment
# Usage: ./init-nginx.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Initializing nginx and certbot environment...${NC}"

# Create directory structure
echo -e "${GREEN}Creating directory structure...${NC}"
mkdir -p nginx/conf.d
mkdir -p nginx/html
mkdir -p certbot/conf
mkdir -p certbot/www

# Create a default index.html
if [ ! -f "nginx/html/index.html" ]; then
    echo -e "${GREEN}Creating default index.html...${NC}"
    cat > nginx/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to nginx!</title>
    <style>
        body {
            width: 35em;
            margin: 0 auto;
            font-family: Tahoma, Verdana, Arial, sans-serif;
        }
    </style>
</head>
<body>
    <h1>Welcome to nginx!</h1>
    <p>If you see this page, the nginx web server is successfully installed and
    working. Further configuration is required.</p>
    <p>Use the <code>add-domain.sh</code> script to add a new domain with SSL certificate.</p>
</body>
</html>
EOF
fi

# Create default nginx configuration
if [ ! -f "nginx/conf.d/default.conf" ]; then
    echo -e "${GREEN}Creating default nginx configuration...${NC}"
    cat > nginx/conf.d/default.conf << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name _;
    
    root /usr/share/nginx/html;
    index index.html index.htm;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
}
EOF
fi

# Create docker-compose.yml
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${GREEN}Creating docker-compose.yml...${NC}"
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  nginx:
    image: nginx:latest
    container_name: nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./nginx/html:/usr/share/nginx/html
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    networks:
      - nginx-network
    command: "/bin/sh -c 'while :; do sleep 6h & wait $${!}; nginx -s reload; done & nginx -g \"daemon off;\"'"

  certbot:
    image: certbot/certbot
    container_name: certbot
    restart: unless-stopped
    volumes:
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    networks:
      - nginx-network
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done;'"

networks:
  nginx-network:
    driver: bridge
EOF
else
    echo -e "${YELLOW}docker-compose.yml already exists, skipping...${NC}"
fi

# Create .gitignore
if [ ! -f ".gitignore" ]; then
    echo -e "${GREEN}Creating .gitignore...${NC}"
    cat > .gitignore << 'EOF'
# Certbot certificates and private keys
certbot/conf/*
certbot/www/*

# Backup files
*.backup.*

# OS files
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
EOF
fi

# Create README sections
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Start the nginx and certbot containers:"
echo "     ${GREEN}docker-compose up -d${NC}"
echo ""
echo "  2. Add a domain with SSL certificate:"
echo "     ${GREEN}./add-domain.sh example.com admin@example.com${NC}"
echo ""
echo "  3. Check container status:"
echo "     ${GREEN}docker-compose ps${NC}"
echo ""
echo "  4. View nginx logs:"
echo "     ${GREEN}docker-compose logs -f nginx${NC}"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "  - Make sure your domain's DNS A record points to this server's IP"
echo "  - Ensure ports 80 and 443 are open and accessible from the internet"
echo "  - Certificates will automatically renew every 12 hours"
