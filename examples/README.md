# Nginx Configuration Examples

This directory contains example nginx configurations for common use cases.

## Static Website

See `static-site.conf` - Basic configuration for serving static files.

## Reverse Proxy

See `reverse-proxy.conf` - Configuration for proxying to a backend application.

## Multiple Backends (Load Balancing)

See `load-balancer.conf` - Configuration for load balancing across multiple backend servers.

## WebSocket Support

See `websocket.conf` - Configuration for WebSocket connections.

## SPA (Single Page Application)

See `spa.conf` - Configuration for React, Vue, Angular, etc.

## Usage

1. Copy the example configuration you need
2. Replace `example.com` with your actual domain
3. Customize the backend URLs, ports, and paths as needed
4. Place the file in `nginx/conf.d/<yourdomain>.conf`
5. Reload nginx: `docker-compose exec nginx nginx -s reload`

## Note

These are examples only. The `add-domain.sh` script creates a basic configuration that you can then customize based on these examples.
