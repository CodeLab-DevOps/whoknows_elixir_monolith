#!/bin/bash
# Script to enable SSL for the application
# Run this after initial deployment to set up HTTPS

set -e

DOMAIN="${1:-codelab-devops.dk}"
EMAIL="${2:-admin@${DOMAIN}}"

echo "🔐 Enabling SSL for ${DOMAIN}..."
echo ""

# Step 1: Generate SSL certificates
echo "Step 1: Generating SSL certificates with certbot..."
docker compose exec certbot certbot certonly --webroot \
  -w /var/www/certbot \
  -d ${DOMAIN} \
  -d www.${DOMAIN} \
  --email ${EMAIL} \
  --agree-tos \
  --non-interactive

if [ $? -ne 0 ]; then
  echo "❌ Failed to generate SSL certificates"
  exit 1
fi

echo "✅ SSL certificates generated successfully"
echo ""

# Step 2: Update nginx configuration to enable HTTPS
echo "Step 2: Updating nginx configuration to enable HTTPS..."

cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream phoenix_app {
        server app:4000;
    }

    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name codelab-devops.dk www.codelab-devops.dk;

        # Let's Encrypt challenge location
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 301 https://$host$request_uri;
        }
    }

    # HTTPS server
    server {
        listen 443 ssl;
        http2 on;
        server_name codelab-devops.dk www.codelab-devops.dk;

        ssl_certificate /etc/letsencrypt/live/codelab-devops.dk/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/codelab-devops.dk/privkey.pem;

        # SSL configuration
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        # Security headers
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;

        location / {
            proxy_pass http://phoenix_app;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }

        # WebSocket support for Phoenix LiveView
        location /live {
            proxy_pass http://phoenix_app;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF

echo "✅ nginx.conf updated with HTTPS configuration"
echo ""

# Step 3: Copy updated config to nginx container and reload
echo "Step 3: Reloading nginx with new configuration..."
docker compose exec nginx nginx -t
docker compose restart nginx

if [ $? -ne 0 ]; then
  echo "❌ Failed to reload nginx"
  exit 1
fi

echo "✅ nginx reloaded successfully"
echo ""
echo "🎉 SSL is now enabled!"
echo ""
echo "Your application is now accessible at:"
echo "  https://${DOMAIN}"
echo "  https://www.${DOMAIN}"
echo ""
echo "HTTP traffic will automatically redirect to HTTPS."
