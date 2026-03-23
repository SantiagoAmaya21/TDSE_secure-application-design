#!/bin/bash
# SSL Setup Script for Spring Boot on AWS
# =========================================
# Usage: ./setup-ssl-spring.sh your-domain.com

set -e  # Exit on any error

# Check if domain is provided
if [ -z "$1" ]; then
    echo "❌ Error: Please provide your domain name"
    echo "Usage: ./setup-ssl-spring.sh your-domain.com"
    exit 1
fi

DOMAIN="$1"
echo "🔒 Setting up SSL for Spring Boot with domain: $DOMAIN"

# Install certbot if not installed
if ! command -v certbot &> /dev/null; then
    echo "📦 Installing certbot..."
    sudo dnf install certbot -y
fi

# Generate SSL certificate for Spring Boot
echo "🔐 Generating SSL certificate for Spring Boot..."
sudo certbot certonly --standalone -d "$DOMAIN" --email your-email@example.com --agree-tos --no-eff-email

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

# Update production configuration with actual domain
echo "⚙️ Updating production configuration..."
sudo sed -i "s/your-apache-domain.com/$DOMAIN/g" /opt/secure-app/application-production.properties

# Create SSL renewal script
echo "🔄 Creating SSL renewal script..."
sudo tee /home/ec2-user/ssl-renewal.sh > /dev/null <<EOF
#!/bin/bash
# SSL Certificate Renewal Script

DOMAIN="$DOMAIN"
KEystore_PASSWORD="CHANGEME"

# Renew certificate
sudo certbot renew --standalone

# Recreate keystore
sudo openssl pkcs12 -export \\
    -in "/etc/letsencrypt/live/\$DOMAIN/fullchain.pem" \\
    -inkey "/etc/letsencrypt/live/\$DOMAIN/privkey.pem" \\
    -out "/home/ec2-user/keystore.p12" \\
    -name "springboot" \\
    -password pass:\$KEystore_PASSWORD \\
    -CAfile "/etc/letsencrypt/live/\$DOMAIN/chain.pem" \\
    -caname root

# Set permissions
sudo chown ec2-user:ec2-user /home/ec2-user/keystore.p12
chmod 600 /home/ec2-user/keystore.p12

# Restart Spring Boot service
sudo systemctl restart secure-app

echo "SSL certificate renewed and Spring Boot restarted"
EOF

sudo chmod +x /home/ec2-user/ssl-renewal.sh

# Setup automatic renewal (cron job)
echo "⏰ Setting up automatic SSL renewal..."
(crontab -l 2>/dev/null; echo "0 2 * * * /home/ec2-user/ssl-renewal.sh >> /var/log/ssl-renewal.log 2>&1") | crontab -

# Restart Spring Boot to apply SSL configuration
echo "🔄 Restarting Spring Boot service..."
sudo systemctl restart secure-app

# Wait for service to start
sleep 5

# Test SSL configuration
echo "🧪 Testing SSL configuration..."
if curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8443/auth/register | grep -q "404\|400"; then
    echo "✅ SSL configuration successful!"
    echo "🌐 Spring Boot is responding on https://localhost:8443"
else
    echo "❌ SSL configuration test failed"
    echo "🔍 Checking service status..."
    sudo systemctl status secure-app --no-pager
    echo "📋 Checking logs..."
    sudo journalctl -u secure-app --no-pager -n 20
fi

echo "✅ SSL setup completed!"
echo "📝 Important information:"
echo "   - Keystore password: CHANGEME (change this in production!)"
echo "   - Keystore location: /home/ec2-user/keystore.p12"
echo "   - Certificate location: /etc/letsencrypt/live/$DOMAIN/"
echo "   - Auto-renewal: Daily at 2:00 AM"
echo "   - Test with: curl -k https://localhost:8443/auth/register"
