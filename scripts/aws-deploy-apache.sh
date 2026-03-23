#!/bin/bash
# AWS Deployment Script for Apache Web Server
# ==========================================
# Usage: ./aws-deploy-apache.sh

set -e  # Exit on any error

echo "🚀 Starting Apache Web Server deployment..."

# Update system
echo "📦 Updating system packages..."
sudo dnf update -y

# Install Apache
echo "🌐 Installing Apache HTTP Server..."
sudo dnf install httpd -y

# Start and enable Apache
echo "▶️ Starting Apache service..."
sudo systemctl start httpd
sudo systemctl enable httpd

# Configure firewall
echo "🔥 Configuring firewall..."
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

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

# Create Apache configuration for secure app
echo "⚙️ Configuring Apache virtual host..."
sudo tee /etc/httpd/conf.d/secure-app.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName _default_
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
    ServerName _default_
    DocumentRoot /var/www/html/secure-app
    
    # SSL Configuration (will be configured by Let's Encrypt)
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/your-domain.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/your-domain.com/privkey.pem
    
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

echo "✅ Apache deployment completed!"
echo "📝 Next steps:"
echo "   1. Configure your domain to point to this instance"
echo "   2. Run: sudo dnf install certbot python3-certbot-apache -y"
echo "   3. Run: sudo certbot --apache -d your-domain.com"
echo "   4. Update web-tier/config.js with your Spring server URL"
