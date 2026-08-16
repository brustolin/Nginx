#!/bin/bash

# Script to import an nginx configuration file into the local nginx setup
# and request SSL certificates for the domains defined in it.
# Usage: ./import-nginx-conf.sh <path-to-nginx-conf> [email]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if required arguments are provided
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo -e "${RED}Error: Missing or invalid arguments${NC}"
    echo "Usage: $0 <path-to-nginx-conf> [email]"
    echo "Example: $0 ./examples/reverse-proxy.conf admin@example.com"
    exit 1
fi

SOURCE_FILE=$1
EMAIL=${2:-}
NGINX_CONF_DIR="./nginx/conf.d"
CERTBOT_DIR="./certbot"
DOCKER_COMPOSE_FILE="./docker-compose.yml"
TARGET_FILE="$NGINX_CONF_DIR/$(basename "$SOURCE_FILE")"
TEMP_CONFIG="$NGINX_CONF_DIR/zz-certbot-temp.conf"

# Validate source file
if [ ! -f "$SOURCE_FILE" ]; then
    echo -e "${RED}Error: Source file not found: ${SOURCE_FILE}${NC}"
    exit 1
fi

# Validate email format (basic check)
if [ -z "$EMAIL" ]; then
    read -p "Enter your email for Let's Encrypt: " EMAIL
fi

if ! [[ $EMAIL =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo -e "${RED}Error: Invalid email format${NC}"
    exit 1
fi

mkdir -p "$NGINX_CONF_DIR"
mkdir -p "$CERTBOT_DIR/conf"
mkdir -p "$CERTBOT_DIR/www"

# Check if docker compose.yml exists
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    echo -e "${RED}Error: docker compose.yml not found. Please run init-nginx.sh first.${NC}"
    exit 1
fi

echo -e "${GREEN}Importing nginx configuration from ${SOURCE_FILE}${NC}"
echo -e "${GREEN}Installing it as ${TARGET_FILE}${NC}"

# Back up an existing file before replacing it
if [ -f "$TARGET_FILE" ]; then
    cp "$TARGET_FILE" "${TARGET_FILE}.backup.$(date +%s)"
fi

# Copy the supplied configuration into the nginx conf.d directory
cp "$SOURCE_FILE" "$TARGET_FILE"

# Extract domains from server_name directives
mapfile -t DOMAINS < <(
    awk '
        /server_name/ {
            line = $0
            sub(/.*server_name/, "", line)
            gsub(/;/, " ", line)
            n = split(line, parts, /[[:space:]]+/)
            for (i = 1; i <= n; i++) {
                name = parts[i]
                if (name == "" || name == "_" || name ~ /^default_server$/) {
                    continue
                }
                if (name ~ /^[A-Za-z0-9.-]+$/) {
                    print name
                }
            }
        }
    ' "$SOURCE_FILE" | sed '/^$/d' | sort -u
)

if [ ${#DOMAINS[@]} -eq 0 ]; then
    echo -e "${YELLOW}No valid server_name entries were found in ${SOURCE_FILE}. Unable to request certificates.${NC}"
    exit 1
fi

# Expand to include www. subdomains for base domains when appropriate.
declare -a CERT_DOMAINS=()
for domain in "${DOMAINS[@]}"; do
    if [[ "$domain" == *"*"* ]]; then
        continue
    fi
    CERT_DOMAINS+=("$domain")
    if [[ "$domain" != www.* ]] && [[ "$domain" == *.* ]]; then
        CERT_DOMAINS+=("www.$domain")
    fi
done

mapfile -t CERT_DOMAINS < <(printf '%s\n' "${CERT_DOMAINS[@]}" | sed '/^$/d' | sort -u)

if [ ${#CERT_DOMAINS[@]} -eq 0 ]; then
    echo -e "${YELLOW}No valid domains were extracted from ${SOURCE_FILE}. Unable to request certificates.${NC}"
    exit 1
fi

# Create a temporary nginx config that serves the ACME challenge on port 80
cat > "$TEMP_CONFIG" <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name $(printf '%s ' "${CERT_DOMAINS[@]}");

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}
EOF

echo -e "${GREEN}Configuring temporary HTTP challenge handler...${NC}"
# Reload nginx to apply the temporary config
if docker compose exec -T nginx nginx -t && docker compose exec -T nginx nginx -s reload; then
    :
else
    echo -e "${YELLOW}Note: nginx is not running or reload failed. The temporary challenge handler will be applied on next start.${NC}"
fi

# Request SSL certificate from Let's Encrypt
CERTBOT_ARGS=()
for domain in "${CERT_DOMAINS[@]}"; do
    CERTBOT_ARGS+=("-d" "$domain")
done

echo -e "${GREEN}Requesting SSL certificates for:${NC}"
printf '  - %s\n' "${CERT_DOMAINS[@]}"

docker compose run --rm \
  --entrypoint certbot \
  certbot certonly --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    "${CERTBOT_ARGS[@]}" || {
    echo -e "${RED}Certificate request failed. Please verify that the domains point to this server and that port 80 is reachable.${NC}"
    exit 1
}

# Remove temporary challenge config and reload nginx
rm -f "$TEMP_CONFIG"
docker compose exec -T nginx nginx -t && docker compose exec -T nginx nginx -s reload || {
    echo -e "${YELLOW}Imported configuration was installed, but nginx reload after cleanup failed.${NC}"
}

echo -e "${GREEN}✓ Certificates and nginx configuration are ready.${NC}"
echo ""
echo "Configured domains:"
printf '  - %s\n' "${CERT_DOMAINS[@]}"
echo ""
echo "The nginx config was installed at ${TARGET_FILE}"
echo "You can edit it and reload nginx with: docker compose exec nginx nginx -s reload"
