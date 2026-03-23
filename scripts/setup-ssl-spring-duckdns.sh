#!/bin/bash
# SSL Setup Script for Spring Boot with DuckDNS
# ==============================================

set -e  # Exit on any error

# Check if domain is provided
if [ -z "$1" ]; then
    echo "❌ Error: Please provide your DuckDNS subdomain"
    echo "Usage: ./setup-ssl-spring-duckdns.sh tdse-secure-app.duckdns.org"
    exit 1
fi

DOMAIN="$1"
DUCKDNS_SUBDOMAIN=$(echo "$DOMAIN" | cut -d'.' -f1)
DUCKDNS_TOKEN="${2:-YOUR_DUCKDNS_TOKEN}"

echo "🔒 Setting up SSL for Spring Boot with DuckDNS domain: $DOMAIN"

# Update DuckDNS with Spring server IP
echo "🦆 Updating DuckDNS for Spring server..."
SPRING_IP=$(curl -s ifconfig.me)
echo "📍 Spring Server IP: $SPRING_IP"

# Update DuckDNS (if using same subdomain, this will override - careful!)
if [ "$DUCKDNS_TOKEN" != "YOUR_DUCKDNS_TOKEN" ]; then
    curl "https://www.duckdns.org/update?domains=${DUCKDNS_SUBDOMAIN}&token=${DUCKDNS_TOKEN}&ip=${SPRING_IP}"
    echo "⏳ Waiting for DNS propagation..."
    sleep 30
fi

# Install certbot if not installed
if ! command -v certbot &> /dev/null; then
    echo "📦 Installing certbot..."
    sudo dnf install certbot -y
fi

# Stop Spring Boot service temporarily
echo "⏹️ Stopping Spring Boot service..."
sudo systemctl stop secure-app || echo "Service not running, continuing..."

# Generate SSL certificate for Spring Boot
echo "🔐 Generating SSL certificate for Spring Boot..."
for i in {1..3}; do
    if sudo certbot certonly --standalone -d "$DOMAIN" --email your-email@example.com --agree-tos --no-eff-email; then
        echo "✅ SSL certificate generated successfully!"
        break
    else
        echo "❌ SSL certificate generation failed, attempt $i/3"
        if [ $i -eq 3 ]; then
            echo "🔄 You may need to run this manually:"
            echo "   sudo certbot certonly --standalone -d $DOMAIN"
            exit 1
        else
            echo "⏳ Waiting 60 seconds before retry..."
            sleep 60
        fi
    fi
done

# Create PKCS12 keystore from Let's Encrypt certificates
echo "🗝️ Creating PKCS12 keystore..."
sudo openssl pkcs12 -export \
    -in "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" \
    -inkey "/etc/letsencrypt/live/$DOMAIN/privkey.pem" \
    -out "/home/ec2-user/keystore.p12" \
    -name "springboot" \
    -password pass:CHANGEME \
    -CAfile "/etc/letsencrypt/live/$DOMAIN/chain.pem" \
    -caname root

# Set proper permissions
echo "🔐 Setting keystore permissions..."
sudo chown ec2-user:ec2-user /home/ec2-user/keystore.p12
chmod 600 /home/ec2-user/keystore.p12

# Update production configuration with DuckDNS domain
echo "⚙️ Updating production configuration..."
if [ -f "/opt/secure-app/application-production.properties" ]; then
    sudo sed -i "s/your-apache-domain.com/$DOMAIN/g" /opt/secure-app/application-production.properties
    echo "✅ Production configuration updated!"
else
    echo "⚠️ Production configuration not found, creating new one..."
    sudo tee /opt/secure-app/application-production.properties > /dev/null <<EOF
# Production Configuration for DuckDNS
server.port=8443
server.ssl.enabled=true
server.ssl.key-store=file:/home/ec2-user/keystore.p12
server.ssl.key-store-password=CHANGEME
server.ssl.key-store-type=PKCS12
server.ssl.key-alias=springboot

# CORS - Update with your Apache DuckDNS domain
cors.allowed-origins=https://$DOMAIN

# Production logging
logging.level.co.edu.escuelaing.secureapp=INFO
logging.level.org.springframework.security=WARN
logging.level.org.springframework.web=WARN
EOF
fi

# Create SSL renewal script
echo "🔄 Creating SSL renewal script..."
sudo tee /home/ec2-user/ssl-renewal-duckdns.sh > /dev/null <<EOF
#!/bin/bash
# SSL Certificate Renewal Script for DuckDNS

DOMAIN="$DOMAIN"
DUCKDNS_SUBDOMAIN="$DUCKDNS_SUBDOMAIN"
DUCKDNS_TOKEN="$DUCKDNS_TOKEN"
KEystore_Password="CHANGEME"

# Update DuckDNS IP
SPRING_IP=\$(curl -s ifconfig.me)
curl "https://www.duckdns.org/update?domains=\${DUCKDNS_SUBDOMAIN}&token=\${DUCKDNS_TOKEN}&ip=\${SPRING_IP}"

# Renew certificate
sudo certbot renew --standalone

# Recreate keystore
sudo openssl pkcs12 -export \\
    -in "/etc/letsencrypt/live/\$DOMAIN/fullchain.pem" \\
    -inkey "/etc/letsencrypt/live/\$DOMAIN/privkey.pem" \\
    -out "/home/ec2-user/keystore.p12" \\
    -name "springboot" \\
    -password pass:\$KEystore_Password \\
    -CAfile "/etc/letsencrypt/live/\$DOMAIN/chain.pem" \\
    -caname root

# Set permissions
sudo chown ec2-user:ec2-user /home/ec2-user/keystore.p12
chmod 600 /home/ec2-user/keystore.p12

# Restart Spring Boot service
sudo systemctl restart secure-app

echo "SSL certificate renewed and Spring Boot restarted"
EOF

sudo chmod +x /home/ec2-user/ssl-renewal-duckdns.sh

# Setup automatic renewal (cron job)
echo "⏰ Setting up automatic SSL renewal..."
(crontab -l 2>/dev/null; echo "0 2 * * * /home/ec2-user/ssl-renewal-duckdns.sh >> /var/log/ssl-renewal.log 2>&1") | crontab -

# Restart Spring Boot to apply SSL configuration
echo "🔄 Restarting Spring Boot service..."
sudo systemctl start secure-app

# Wait for service to start
sleep 10

# Test SSL configuration
echo "🧪 Testing SSL configuration..."
if curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8443/auth/register | grep -q "404\|400"; then
    echo "✅ SSL configuration successful!"
    echo "🌐 Spring Boot is responding on https://localhost:8443"
    echo "🌍 Public URL: https://$DOMAIN:8443"
else
    echo "❌ SSL configuration test failed"
    echo "🔍 Checking service status..."
    sudo systemctl status secure-app --no-pager
    echo "📋 Checking logs..."
    sudo journalctl -u secure-app --no-pager -n 20
fi

echo "✅ DuckDNS SSL setup completed!"
echo "📝 Important information:"
echo "   - Domain: https://$DOMAIN:8443"
echo "   - Keystore password: CHANGEME (change this in production!)"
echo "   - Keystore location: /home/ec2-user/keystore.p12"
echo "   - Certificate location: /etc/letsencrypt/live/$DOMAIN/"
echo "   - Auto-renewal: Daily at 2:00 AM"
echo "   - DuckDNS update: Included in renewal process"
echo ""
echo "📝 Testing commands:"
echo "   - Local test: curl -k https://localhost:8443/auth/register"
echo "   - Public test: curl -k https://$DOMAIN:8443/auth/register"
echo "   - Check service: sudo systemctl status secure-app"
echo "   - Check logs: sudo journalctl -u secure-app -f"
echo ""
echo "🔧 Manual DuckDNS update:"
echo "   curl \"https://www.duckdns.org/update?domains=${DUCKDNS_SUBDOMAIN}&token=${DUCKDNS_TOKEN}&ip=\$(curl -s ifconfig.me)\""
