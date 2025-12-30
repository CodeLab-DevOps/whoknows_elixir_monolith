#!/bin/bash

# SSL Certificate Setup Script for codelab-devops.dk
# Run this script AFTER deploying to your server with DNS A records configured

echo "=========================================="
echo "SSL Certificate Setup for codelab-devops.dk"
echo "=========================================="
echo ""

# Check if docker-compose is running
if ! docker ps | grep -q whoknows_nginx; then
    echo "Error: Nginx container is not running. Please start docker-compose first:"
    echo "  docker-compose up -d"
    exit 1
fi

echo "Step 1: Obtaining SSL certificate from Let's Encrypt..."
echo "This will request a certificate for:"
echo "  - codelab-devops.dk"
echo "  - www.codelab-devops.dk"
echo ""

# Request certificate using certbot
docker-compose run --rm certbot certonly --webroot \
    --webroot-path=/var/www/certbot \
    --email your-email@example.com \
    --agree-tos \
    --no-eff-email \
    -d codelab-devops.dk \
    -d www.codelab-devops.dk

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "Success! SSL certificate obtained."
    echo "=========================================="
    echo ""
    echo "Step 2: Reloading Nginx to apply SSL certificate..."
    docker-compose exec nginx nginx -s reload

    echo ""
    echo "=========================================="
    echo "Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Your site is now accessible at:"
    echo "  https://codelab-devops.dk"
    echo "  https://www.codelab-devops.dk"
    echo ""
    echo "HTTP requests will automatically redirect to HTTPS."
    echo ""
    echo "The certificate will auto-renew every 12 hours via the certbot container."
else
    echo ""
    echo "=========================================="
    echo "Error obtaining certificate"
    echo "=========================================="
    echo ""
    echo "Please ensure:"
    echo "  1. Your DNS A records are properly configured"
    echo "  2. Ports 80 and 443 are open on your server"
    echo "  3. The domain resolves to your server's IP"
    echo ""
    echo "You can test DNS resolution with:"
    echo "  nslookup codelab-devops.dk"
    exit 1
fi
