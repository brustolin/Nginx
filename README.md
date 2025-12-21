# Nginx Docker with Let's Encrypt

Easy-to-use scripts and configurations for managing nginx inside Docker with automatic SSL certificate management using Let's Encrypt and certbot.

## Features

- 🐳 **Docker-based**: nginx and certbot running in Docker containers
- 🔐 **Automatic SSL**: Easy Let's Encrypt certificate provisioning and auto-renewal
- 🚀 **Simple Scripts**: Add, remove, and manage domains with simple bash scripts
- ♻️ **Auto-renewal**: Certificates automatically renew every 12 hours
- 📝 **Production-ready**: Includes security best practices and modern SSL configuration

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Domain(s) pointed to your server's IP address
- Ports 80 and 443 open and accessible from the internet

### Installation

1. Clone this repository:
```bash
git clone https://github.com/brustolin/Nginx.git
cd Nginx
```

2. Initialize the environment:
```bash
./init-nginx.sh
```

3. Start the containers:
```bash
docker-compose up -d
```

4. Add your first domain with SSL:
```bash
./add-domain.sh example.com admin@example.com
```

That's it! Your domain should now be accessible via HTTPS with a valid SSL certificate.

## Scripts

### `init-nginx.sh`

Initializes the nginx and certbot environment. Creates necessary directories, default configurations, and docker-compose.yml.

**Usage:**
```bash
./init-nginx.sh
```

**What it does:**
- Creates directory structure (nginx/conf.d, nginx/html, certbot/conf, certbot/www)
- Creates default nginx configuration
- Creates docker-compose.yml
- Creates .gitignore for sensitive files
- Creates a default index.html

### `add-domain.sh`

Adds a new domain to nginx and requests an SSL certificate from Let's Encrypt.

**Usage:**
```bash
./add-domain.sh <domain> <email>
```

**Example:**
```bash
./add-domain.sh example.com admin@example.com
./add-domain.sh blog.example.com admin@example.com
```

**What it does:**
1. Validates domain and email format
2. Creates nginx configuration with HTTP for certificate verification
3. Requests SSL certificate from Let's Encrypt
4. Updates nginx configuration to use HTTPS
5. Reloads nginx to apply changes

**Note:** The domain must point to your server's IP address before running this script.

### `remove-domain.sh`

Removes a domain's nginx configuration (certificates are preserved).

**Usage:**
```bash
./remove-domain.sh <domain>
```

**Example:**
```bash
./remove-domain.sh example.com
```

### `list-domains.sh`

Lists all configured domains with their SSL certificate status.

**Usage:**
```bash
./list-domains.sh
```

### `renew-certificates.sh`

Manually renews all SSL certificates (automatic renewal happens every 12 hours).

**Usage:**
```bash
./renew-certificates.sh
```

## Directory Structure

```
.
├── add-domain.sh              # Script to add a new domain
├── init-nginx.sh              # Script to initialize the environment
├── remove-domain.sh           # Script to remove a domain
├── list-domains.sh            # Script to list domains
├── renew-certificates.sh      # Script to manually renew certificates
├── docker-compose.yml         # Docker Compose configuration
├── nginx/
│   ├── conf.d/               # nginx configuration files
│   │   ├── default.conf      # Default configuration
│   │   └── example.com.conf  # Domain-specific configs
│   └── html/                 # Web root directory
│       └── index.html        # Default index page
└── certbot/
    ├── conf/                 # Let's Encrypt certificates (git-ignored)
    └── www/                  # ACME challenge directory (git-ignored)
```

## Configuration

### Customizing Domain Configuration

After adding a domain, you can customize its nginx configuration by editing the file in `nginx/conf.d/<domain>.conf`.

**Example: Proxying to a backend service**

Edit `nginx/conf.d/example.com.conf`:

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    
    server_name example.com www.example.com;
    
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    # Proxy to backend
    location / {
        proxy_pass http://backend:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

After editing, reload nginx:
```bash
docker-compose exec nginx nginx -s reload
```

### SSL Configuration

The default SSL configuration includes:
- TLS 1.2 and 1.3 support
- Strong cipher suites
- Automatic HTTP to HTTPS redirect
- Certificate auto-renewal every 12 hours

## Docker Compose Commands

**Start containers:**
```bash
docker-compose up -d
```

**Stop containers:**
```bash
docker-compose down
```

**View logs:**
```bash
docker-compose logs -f nginx
docker-compose logs -f certbot
```

**Restart nginx:**
```bash
docker-compose restart nginx
```

**Execute commands in nginx container:**
```bash
docker-compose exec nginx nginx -t  # Test configuration
docker-compose exec nginx nginx -s reload  # Reload configuration
```

## Troubleshooting

### Certificate Request Fails

If certificate request fails, check:

1. **DNS Configuration**: Ensure your domain's A record points to your server's IP
   ```bash
   dig +short example.com
   ```

2. **Port Accessibility**: Ensure ports 80 and 443 are open
   ```bash
   sudo netstat -tlnp | grep :80
   sudo netstat -tlnp | grep :443
   ```

3. **Let's Encrypt Rate Limits**: Check if you've hit rate limits (5 certificates per week per domain)

4. **nginx Status**: Ensure nginx is running
   ```bash
   docker-compose ps
   ```

### nginx Configuration Test Failed

Test the configuration manually:
```bash
docker-compose exec nginx nginx -t
```

If there are errors, check the configuration files in `nginx/conf.d/`.

### View Detailed Logs

```bash
docker-compose logs -f nginx
docker-compose logs -f certbot
```

## Security Considerations

- Certificates and private keys are stored in `certbot/conf/` and are git-ignored
- SSL configuration uses modern TLS versions (1.2 and 1.3)
- Strong cipher suites are configured
- Automatic certificate renewal prevents expiration
- HTTP requests are automatically redirected to HTTPS

## Contributing

Feel free to submit issues and enhancement requests!

## License

MIT License - feel free to use this for your projects.

## Acknowledgments

- [nginx](https://nginx.org/) - High-performance HTTP server
- [Let's Encrypt](https://letsencrypt.org/) - Free SSL certificates
- [Certbot](https://certbot.eff.org/) - Easy Let's Encrypt integration
