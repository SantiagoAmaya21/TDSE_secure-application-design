#!/bin/bash
# AWS Deployment Script for Spring Boot Application
# ================================================
# Usage: ./aws-deploy-spring.sh

set -e  # Exit on any error

echo "🚀 Starting Spring Boot application deployment..."

# Update system
echo "📦 Updating system packages..."
sudo dnf update -y

# Install Java 17
echo "☕ Installing Java 17..."
sudo dnf install java-17-amazon-corretto -y

# Install Maven
echo "🔨 Installing Maven..."
sudo dnf install maven -y

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /opt/secure-app
sudo chown -R ec2-user:ec2-user /opt/secure-app

# Clone repository (if not already cloned)
if [ ! -d "/home/ec2-user/TDSE_secure-application-design" ]; then
    echo "📥 Cloning repository..."
    cd /home/ec2-user
    git clone https://github.com/SantiagoAmaya21/TDSE_secure-application-design.git
else
    echo "📥 Repository already exists, pulling latest changes..."
    cd /home/ec2-user/TDSE_secure-application-design
    git pull origin main
fi

# Build application
echo "🔨 Building Spring Boot application..."
cd /home/ec2-user/TDSE_secure-application-design/application-tier
mvn clean package -DskipTests

# Copy JAR to application directory
echo "📄 Copying application JAR..."
cp target/secureapp-0.0.1-SNAPSHOT.jar /opt/secure-app/

# Create systemd service
echo "⚙️ Creating systemd service..."
sudo tee /etc/systemd/system/secure-app.service > /dev/null <<EOF
[Unit]
Description=Secure Application Spring Boot
After=network.target

[Service]
Type=simple
User=ec2-user
Group=ec2-user
WorkingDirectory=/opt/secure-app
ExecStart=/usr/bin/java -jar -Dspring.profiles.active=production secureapp-0.0.1-SNAPSHOT.jar
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=secure-app

# Environment variables
Environment=JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto
Environment=SPRING_PROFILES_ACTIVE=production

[Install]
WantedBy=multi-user.target
EOF

# Create application.properties override for production
echo "⚙️ Creating production configuration override..."
sudo tee /opt/secure-app/application-production.properties > /dev/null <<EOF
# Override for AWS deployment
server.port=8443
server.ssl.enabled=true
server.ssl.key-store=file:/home/ec2-user/keystore.p12
server.ssl.key-store-password=CHANGEME
server.ssl.key-store-type=PKCS12
server.ssl.key-alias=springboot

# CORS - Update with your Apache domain
cors.allowed-origins=https://your-apache-domain.com

# Production logging
logging.level.co.edu.escuelaing.secureapp=INFO
logging.level.org.springframework.security=WARN
logging.level.org.springframework.web=WARN
EOF

# Configure firewall for HTTPS
echo "🔥 Configuring firewall for HTTPS..."
sudo firewall-cmd --permanent --add-port=8443/tcp
sudo firewall-cmd --reload

# Enable and start service
echo "▶️ Enabling and starting Spring Boot service..."
sudo systemctl daemon-reload
sudo systemctl enable secure-app
sudo systemctl start secure-app

# Wait a moment for service to start
echo "⏳ Waiting for service to start..."
sleep 10

# Check service status
echo "🔍 Checking service status..."
sudo systemctl status secure-app --no-pager

echo "✅ Spring Boot deployment completed!"
echo "📝 Next steps:"
echo "   1. Configure SSL certificates (run setup-ssl-spring.sh)"
echo "   2. Update CORS_ALLOWED_ORIGINS with your Apache domain"
echo "   3. Test the application: curl -k https://localhost:8443/auth/register"
echo "   4. Check logs: sudo journalctl -u secure-app -f"
