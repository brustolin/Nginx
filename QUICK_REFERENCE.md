# Quick Reference Guide

## Initial Setup (One-time)

```bash
# 1. Initialize the environment
./init-nginx.sh

# 2. Start Docker containers
docker-compose up -d

# 3. Check container status
docker-compose ps
```

## Adding a Domain

```bash
# Add a domain with SSL certificate
./add-domain.sh yourdomain.com admin@yourdomain.com

# Example
./add-domain.sh example.com admin@example.com
```

**Prerequisites:**
- Domain DNS A record must point to this server's IP
- Ports 80 and 443 must be open and accessible

## Managing Domains

```bash
# List all configured domains
./list-domains.sh

# Remove a domain
./remove-domain.sh yourdomain.com

# Manually renew all certificates
./renew-certificates.sh
```

## Docker Commands

```bash
# View logs
docker-compose logs -f nginx
docker-compose logs -f certbot

# Restart services
docker-compose restart nginx
docker-compose restart certbot

# Stop all services
docker-compose down

# Test nginx configuration
docker-compose exec nginx nginx -t

# Reload nginx (after config changes)
docker-compose exec nginx nginx -s reload
```

## Customizing Configuration

1. Edit the configuration file for your domain:
   ```bash
   nano nginx/conf.d/yourdomain.com.conf
   ```

2. Test the configuration:
   ```bash
   docker-compose exec nginx nginx -t
   ```

3. Reload nginx:
   ```bash
   docker-compose exec nginx nginx -s reload
   ```

## Common Configurations

See the `examples/` directory for:
- **static-site.conf** - Serving static HTML/CSS/JS files
- **reverse-proxy.conf** - Proxying to backend applications
- **load-balancer.conf** - Load balancing across multiple servers
- **websocket.conf** - WebSocket support
- **spa.conf** - Single Page Applications (React, Vue, Angular)

## Troubleshooting

### Certificate request fails
- Check DNS: `dig +short yourdomain.com`
- Check ports: `sudo netstat -tlnp | grep :80`
- Check nginx logs: `docker-compose logs nginx`

### Configuration errors
- Test config: `docker-compose exec nginx nginx -t`
- View error log: `docker-compose logs nginx | tail -50`

### Service not starting
- Check status: `docker-compose ps`
- View logs: `docker-compose logs`
- Restart: `docker-compose restart`

## File Locations

- **Scripts**: `*.sh` in root directory
- **Nginx configs**: `nginx/conf.d/`
- **Web files**: `nginx/html/`
- **SSL certificates**: `certbot/conf/` (git-ignored)
- **Examples**: `examples/`

## Automatic Certificate Renewal

Certificates are automatically renewed by the certbot container every 12 hours. No manual intervention required.

## Security Notes

- Certificates and private keys are stored in `certbot/conf/` and excluded from git
- Modern TLS 1.2 and 1.3 protocols are used
- Strong cipher suites are configured
- HTTP requests are automatically redirected to HTTPS
