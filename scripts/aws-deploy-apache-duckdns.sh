#!/bin/bash
# AWS Deployment Script for Apache with DuckDNS
# =============================================

set -e  # Exit on any error

# DuckDNS Configuration
DUCKDNS_SUBDOMAIN="${1:-tdse-secure-app}"
DUCKDNS_TOKEN="${2:-YOUR_DUCKDNS_TOKEN}"
DOMAIN="${DUCKDNS_SUBDOMAIN}.duckdns.org"

echo "🚀 Starting Apache deployment with DuckDNS..."
echo "🌐 Domain: $DOMAIN"

# Update system
echo "📦 Updating system packages..."
sudo dnf update -y

# Install Apache and required tools
echo "🌐 Installing Apache HTTP Server..."
sudo dnf install httpd curl -y

# Install Certbot
echo "🔒 Installing Certbot..."
sudo dnf install certbot python3-certbot-apache -y

# Start and enable Apache
echo "▶️ Starting Apache service..."
sudo systemctl start httpd
sudo systemctl enable httpd

# Configure firewall
echo "🔥 Configuring firewall..."
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# Update DuckDNS IP (automatically get public IP)
echo "🦆 Updating DuckDNS IP..."
PUBLIC_IP=$(curl -s ifconfig.me)
echo "📍 Public IP: $PUBLIC_IP"

# Update DuckDNS with current IP
curl "https://www.duckdns.org/update?domains=${DUCKDNS_SUBDOMAIN}&token=${DUCKDNS_TOKEN}&ip=${PUBLIC_IP}"

# Wait for DNS propagation
echo "⏳ Waiting for DNS propagation..."
sleep 30

# Test DNS resolution
echo "🧪 Testing DNS resolution..."
if nslookup $DOMAIN > /dev/null 2>&1; then
    echo "✅ DNS resolution successful!"
else
    echo "❌ DNS resolution failed, continuing anyway..."
fi

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /var/www/html/secure-app
sudo chown -R ec2-user:ec2-user /var/www/html/secure-app

# Deploy frontend files (assuming repo is already cloned)
if [ -d "/home/ec2-user/TDSE_secure-application-design/web-tier" ]; then
    echo "📄 Copying frontend files..."
    sudo cp -r /home/ec2-user/TDSE_secure-application-design/web-tier/* /var/www/html/secure-app/
    sudo chown -R apache:apache /var/www/html/secure-app/
else
    echo "❌ Error: web-tier directory not found!"
    echo "Please ensure the repository is cloned: git clone <your-repo-url>"
    exit 1
fi

# Create Apache configuration for DuckDNS
echo "⚙️ Configuring Apache virtual host for DuckDNS..."
sudo tee /etc/httpd/conf.d/secure-app.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    DocumentRoot /var/www/html/secure-app
    
    # Redirect HTTP to HTTPS
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
    
    # Security headers
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    
    # Enable compression
    LoadModule deflate_module modules/mod_deflate.so
    <Location />
        SetOutputFilter DEFLATE
        SetEnvIfNoCase Request_URI \
            \.(?:gif|jpe?g|png)$ no-gzip dont-vary
        SetEnvIfNoCase Request_URI \
            \.(?:exe|t?gz|zip|bz2|sit|rar)$ no-gzip dont-vary
    </Location>
</VirtualHost>

<VirtualHost *:443>
    ServerName $DOMAIN
    DocumentRoot /var/www/html/secure-app
    
    # SSL Configuration (will be configured by Let's Encrypt)
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/$DOMAIN/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$DOMAIN/privkey.pem
    
    # Security headers
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    
    # Enable compression
    LoadModule deflate_module modules/mod_deflate.so
    <Location />
        SetOutputFilter DEFLATE
        SetEnvIfNoCase Request_URI \
            \.(?:gif|jpe?g|png)$ no-gzip dont-vary
        SetEnvIfNoCase Request_URI \
            \.(?:exe|t?gz|zip|bz2|sit|rar)$ no-gzip dont-vary
    </Location>
</VirtualHost>
EOF

# Test Apache configuration
echo "🧪 Testing Apache configuration..."
sudo apachectl configtest

# Restart Apache to apply changes
echo "🔄 Restarting Apache..."
sudo systemctl restart httpd

# Generate SSL certificate with Let's Encrypt
echo "🔒 Generating SSL certificate with Let's Encrypt..."
echo "⚠️  Note: Make sure port 80 is accessible from the internet"

# Try to get certificate (may need to wait for DNS propagation)
for i in {1..3}; do
    if sudo certbot --apache -d $DOMAIN --non-interactive --agree-tos --email your-email@example.com; then
        echo "✅ SSL certificate generated successfully!"
        break
    else
        echo "❌ SSL certificate generation failed, attempt $i/3"
        if [ $i -eq 3 ]; then
            echo "🔄 You may need to run this manually:"
            echo "   sudo certbot --apache -d $DOMAIN"
        else
            echo "⏳ Waiting 60 seconds before retry..."
            sleep 60
        fi
    fi
done

# Create DuckDNS IP update cron job
echo "⏰ Setting up DuckDNS IP update cron job..."
sudo tee /home/ec2-user/update-duckdns.sh > /dev/null <<EOF
#!/bin/bash
# DuckDNS IP Update Script

DUCKDNS_SUBDOMAIN="$DUCKDNS_SUBDOMAIN"
DUCKDNS_TOKEN="$DUCKDNS_TOKEN"

# Get current public IP
CURRENT_IP=\$(curl -s ifconfig.me)

# Update DuckDNS
curl "https://www.duckdns.org/update?domains=\${DUCKDNS_SUBDOMAIN}&token=\${DUCKDNS_TOKEN}&ip=\${CURRENT_IP}"

echo "DuckDNS updated: \$(date) - IP: \${CURRENT_IP}"
EOF

sudo chmod +x /home/ec2-user/update-duckdns.sh

# Add to cron (every 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/ec2-user/update-duckns.sh >> /var/log/duckdns-update.log 2>&1") | crontab -

# Restart Apache one more time
sudo systemctl restart httpd

echo "✅ Apache deployment with DuckDNS completed!"
echo "📝 Important information:"
echo "   - Domain: https://$DOMAIN"
echo "   - Document Root: /var/www/html/secure-app"
echo "   - SSL Certificate: Let's Encrypt"
echo "   - DuckDNS IP update: Every 5 minutes"
echo ""
echo "📝 Next steps:"
echo "   1. Update web-tier/config.js with your Spring server URL"
echo "   2. Deploy Spring Boot server"
echo "   3. Test the application at: https://$DOMAIN"
echo ""
echo "🔧 Manual commands if needed:"
echo "   - Update DuckDNS: curl \"https://www.duckdns.org/update?domains=${DUCKDNS_SUBDOMAIN}&token=${DUCKDNS_TOKEN}&ip=\$(curl -s ifconfig.me)\""
echo "   - Renew SSL: sudo certbot renew"
echo "   - Check Apache: sudo systemctl status httpd"
