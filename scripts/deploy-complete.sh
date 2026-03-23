#!/bin/bash
# Complete AWS Deployment Script
# =============================
# Usage: ./deploy-complete.sh [apache|spring|all]

set -e  # Exit on any error

# Check deployment type
DEPLOYMENT_TYPE="${1:-all}"
DOMAIN="${2:-your-domain.com}"

echo "🚀 Starting complete AWS deployment..."
echo "📋 Deployment type: $DEPLOYMENT_TYPE"
echo "🌐 Domain: $DOMAIN"

# Function to deploy Apache
deploy_apache() {
    echo "🌐 Deploying Apache Web Server..."
    
    # Check if script exists
    if [ ! -f "aws-deploy-apache.sh" ]; then
        echo "❌ Error: aws-deploy-apache.sh not found!"
        exit 1
    fi
    
    # Make script executable and run
    chmod +x aws-deploy-apache.sh
    ./aws-deploy-apache.sh
    
    echo "✅ Apache deployment completed!"
}

# Function to deploy Spring Boot
deploy_spring() {
    echo "☕ Deploying Spring Boot Application..."
    
    # Check if script exists
    if [ ! -f "aws-deploy-spring.sh" ]; then
        echo "❌ Error: aws-deploy-spring.sh not found!"
        exit 1
    fi
    
    # Make script executable and run
    chmod +x aws-deploy-spring.sh
    ./aws-deploy-spring.sh
    
    echo "✅ Spring Boot deployment completed!"
}

# Function to setup SSL
setup_ssl() {
    echo "🔒 Setting up SSL certificates..."
    
    # Check if script exists
    if [ ! -f "setup-ssl-spring.sh" ]; then
        echo "❌ Error: setup-ssl-spring.sh not found!"
        exit 1
    fi
    
    # Make script executable and run
    chmod +x setup-ssl-spring.sh
    ./setup-ssl-spring.sh "$DOMAIN"
    
    echo "✅ SSL setup completed!"
}

# Function to update frontend configuration
update_frontend_config() {
    echo "⚙️ Updating frontend configuration..."
    
    # Get the public IP of the Spring Boot instance
    if [ -f "/home/ec2-user/spring-instance-ip.txt" ]; then
        SPRING_IP=$(cat /home/ec2-user/spring-instance-ip.txt)
    else
        echo "❌ Error: Spring instance IP not found!"
        echo "Please create /home/ec2-user/spring-instance-ip.txt with the Spring server IP"
        exit 1
    fi
    
    # Update config.js with Spring server URL
    if [ -f "/var/www/html/secure-app/config.js" ]; then
        sudo sed -i "s|http://localhost:8080|https://$SPRING_IP:8443|g" /var/www/html/secure-app/config.js
        echo "✅ Frontend configuration updated!"
    else
        echo "❌ Error: config.js not found!"
        exit 1
    fi
}

# Function to test deployment
test_deployment() {
    echo "🧪 Testing deployment..."
    
    # Test Apache
    echo "🌐 Testing Apache..."
    if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200"; then
        echo "✅ Apache is responding on port 80"
    else
        echo "❌ Apache test failed"
    fi
    
    # Test Spring Boot
    echo "☕ Testing Spring Boot..."
    if curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8443/auth/register | grep -q "404\|400"; then
        echo "✅ Spring Boot is responding on port 8443"
    else
        echo "❌ Spring Boot test failed"
    fi
    
    echo "🔍 Testing communication between servers..."
    # This would be tested from the frontend side
}

# Main deployment logic
case $DEPLOYMENT_TYPE in
    "apache")
        deploy_apache
        ;;
    "spring")
        deploy_spring
        ;;
    "ssl")
        setup_ssl
        ;;
    "all")
        deploy_apache
        deploy_spring
        setup_ssl
        update_frontend_config
        test_deployment
        ;;
    *)
        echo "❌ Error: Invalid deployment type!"
        echo "Usage: $0 [apache|spring|ssl|all] [domain]"
        exit 1
        ;;
esac

echo "🎉 Deployment completed successfully!"
echo "📝 Next steps:"
echo "   1. Configure your domain DNS to point to the Apache instance"
echo "   2. Run Let's Encrypt for Apache: sudo certbot --apache -d $DOMAIN"
echo "   3. Test the complete application in your browser"
echo "   4. Create screenshots and video for documentation"

# Create deployment summary
cat > deployment-summary.txt <<EOF
AWS Deployment Summary
=====================

Deployment Date: $(date)
Domain: $DOMAIN
Deployment Type: $DEPLOYMENT_TYPE

Apache Server:
- Public IP: $(curl -s ifconfig.me)
- HTTP Port: 80 (redirects to HTTPS)
- HTTPS Port: 443
- Document Root: /var/www/html/secure-app

Spring Boot Server:
- Private IP: $(hostname -I | awk '{print $1}')
- HTTPS Port: 8443
- JAR Location: /opt/secure-app/secureapp-0.0.1-SNAPSHOT.jar
- Service: secure-app

SSL Certificates:
- Location: /etc/letsencrypt/live/$DOMAIN/
- Keystore: /home/ec2-user/keystore.p12
- Auto-renewal: Daily at 2:00 AM

Services Status:
- Apache: $(systemctl is-active httpd)
- Spring Boot: $(systemctl is-active secure-app)

Testing Commands:
- Apache: curl http://localhost
- Spring Boot: curl -k https://localhost:8443/auth/register

Log Commands:
- Apache: sudo journalctl -u httpd -f
- Spring Boot: sudo journalctl -u secure-app -f
EOF

echo "📄 Deployment summary saved to deployment-summary.txt"
