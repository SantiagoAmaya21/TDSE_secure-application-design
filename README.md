# Secure Application Design Workshop

A comprehensive secure web application built with Spring Boot backend and Apache frontend, demonstrating enterprise-level security practices including JWT authentication, TLS encryption, and secure deployment patterns.

## Architecture Overview

This application implements a secure, scalable architecture with two main components:

### Backend (Spring Boot)
- **Framework**: Spring Boot 3.2.0 with Java 17
- **Security**: JWT-based authentication with Spring Security
- **Database**: H2 in-memory database (for development)
- **API**: RESTful endpoints with proper validation
- **Password Security**: BCrypt hashing for password storage

### Frontend (Apache + HTML/JavaScript)
- **Server**: Apache HTTP Server
- **Client**: Asynchronous HTML5 + JavaScript (ES6+)
- **UI**: Modern responsive design with CSS Grid/Flexbox
- **Security**: HTTPS-only communication, secure token storage
- **UX**: Real-time validation, loading states, error handling

## Security Features

### Authentication & Authorization
- **JWT Tokens**: Secure stateless authentication
- **Password Hashing**: BCrypt with salt
- **Role-based Access**: USER/ADMIN roles
- **Session Management**: Secure token storage and validation
- **Login Protection**: Rate limiting and account lockout

### Transport Security
- **TLS/SSL**: End-to-end encryption with Let's Encrypt certificates
- **HTTPS Enforcement**: Automatic redirect to secure connections
- **CORS Configuration**: Proper cross-origin resource sharing
- **Security Headers**: X-Frame-Options, X-Content-Type-Options, etc.

### Data Protection
- **Input Validation**: Comprehensive server-side validation
- **SQL Injection Prevention**: JPA/Hibernate parameterized queries
- **XSS Protection**: Input sanitization and output encoding
- **CSRF Protection**: Spring Security CSRF tokens

## Project Structure

```
TDSE_secure-application-design/
├── application-tier/                 # Spring Boot Backend
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/co/edu/escuelaing/secureapp/
│   │   │   │   ├── config/           # Security, CORS configuration
│   │   │   │   ├── controller/       # REST API controllers
│   │   │   │   ├── dto/              # Data transfer objects
│   │   │   │   ├── model/            # JPA entities
│   │   │   │   ├── repository/       # Data repositories
│   │   │   │   ├── security/         # JWT authentication
│   │   │   │   ├── service/          # Business logic
│   │   │   │   └── SecureappApplication.java
│   │   │   └── resources/
│   │   │       ├── application.properties           # Development config
│   │   │       └── application-production.properties # Production config
│   └── pom.xml
├── web-tier/                        # Apache Frontend
│   ├── index.html                   # Main HTML page
│   ├── styles.css                   # CSS styling
│   ├── config.js                    # Development configuration
│   ├── config-production.js         # Production configuration
│   ├── api.js                       # API client
│   └── app.js                       # Application logic
├── scripts/                         # AWS Deployment Scripts
│   ├── aws-deploy-apache.sh         # Apache deployment
│   ├── aws-deploy-spring.sh         # Spring Boot deployment
│   ├── setup-ssl-spring.sh          # SSL configuration
│   ├── deploy-complete.sh           # Complete deployment
│   └── aws-academy-guide.md         # Detailed AWS guide
├── img/                            # Screenshots and documentation
├── README.md                       # This file
├── .gitignore                      # Git ignore file
└── .gitattributes                  # Git attributes
```

## Getting Started

### Prerequisites
- Java 17 or higher
- Maven 3.6+
- Apache HTTP Server
- Let's Encrypt (for production certificates)

### Local Development Setup

#### Backend Setup
1. Navigate to the `application-tier` directory
2. Build the application:
   ```bash
   mvn clean install
   ```
3. Run the Spring Boot application:
   ```bash
   mvn spring-boot:run
   ```
4. The backend will be available at `http://localhost:8080`

#### Frontend Setup
1. Navigate to the `web-tier` directory
2. Configure Apache to serve the files:
   ```apache
   <VirtualHost *:80>
       DocumentRoot /path/to/web-tier
       ServerName localhost
   </VirtualHost>
   ```
3. Restart Apache:
   ```bash
   sudo systemctl restart apache2
   ```
4. Access the application at `http://localhost`

### Testing the Application
1. Open your browser and navigate to the frontend URL
2. Register a new user account
3. Login with your credentials
4. Test all features: secure data access, user management, messaging

## Configuration

### Backend Configuration (`application.properties`)
- Database settings
- JWT secret and expiration
- CORS configuration
- Logging levels

### Frontend Configuration (`config.js`)
- API endpoints
- Security settings
- Environment detection
- TLS enforcement

## AWS Deployment

### Quick Start (AWS Academy)

#### Prerequisites
- AWS Academy account with EC2 access
- Domain name (required for Let's Encrypt)
- SSH key pair for EC2 access

#### Step 1: Create EC2 Instances
```bash
# Instance 1: Apache Web Server
# - Amazon Linux 2023
# - Security Group: HTTP(80), HTTPS(443), SSH(22)

# Instance 2: Spring Boot Application  
# - Amazon Linux 2023
# - Security Group: Custom TCP(8443), SSH(22)
```

#### Step 2: Deploy Apache Server
```bash
# Connect to Apache instance
ssh -i your-key.pem ec2-user@<APACHE_PUBLIC_IP>

# Clone and deploy
git clone https://github.com/SantiagoAmaya21/TDSE_secure-application-design.git
cd TDSE_secure-application-design
chmod +x scripts/aws-deploy-apache-duckdns.sh
./scripts/aws-deploy-apache-duckdns.sh tdse-secure-app TU_DUCKDNS_TOKEN

# Configure SSL (DuckDNS domain already configured in script)
sudo certbot --apache -d tdse-secure-app.duckdns.org
```

#### Step 3: Deploy Spring Boot
```bash
# Connect to Spring instance
ssh -i your-key.pem ec2-user@<SPRING_PUBLIC_IP>

# Clone and deploy
git clone https://github.com/SantiagoAmaya21/TDSE_secure-application-design.git
cd TDSE_secure-application-design
chmod +x scripts/aws-deploy-spring.sh
chmod +x scripts/setup-ssl-spring-duckdns.sh
./scripts/aws-deploy-spring.sh
./scripts/setup-ssl-spring-duckdns.sh tdse-secure-app.duckdns.org TU_DUCKDNS_TOKEN
```

#### Step 4: Update Configuration
```bash
# On Apache instance - frontend already configured for tdse-secure-app.duckdns.org
# No changes needed to config.js

# On Spring instance - CORS already configured for tdse-secure-app.duckdns.org
# No changes needed to application-production.properties
```

### Detailed Instructions
For complete step-by-step instructions, see: **[scripts/aws-academy-guide.md](scripts/aws-academy-guide.md)**

### Manual Configuration

#### Apache Configuration
```bash
# Install Apache
sudo dnf install httpd -y
sudo systemctl start httpd
sudo systemctl enable httpd

# Deploy frontend
sudo cp -r web-tier/* /var/www/html/

# SSL with Let's Encrypt
sudo dnf install certbot python3-certbot-apache -y
sudo certbot --apache -d your-domain.com
```

#### Spring Boot Configuration
```bash
# Install Java and Maven
sudo dnf install java-17-amazon-corretto maven -y

# Build application
cd application-tier
mvn clean package -DskipTests

# Run with production profile
java -jar -Dspring.profiles.active=production target/secureapp-0.0.1-SNAPSHOT.jar
```

### SSL/TLS Configuration

#### Let's Encrypt for Apache
```bash
# Generate certificate
sudo certbot --apache -d your-domain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

#### Let's Encrypt for Spring Boot
```bash
# Generate certificate
sudo certbot certonly --standalone -d your-spring-domain.com

# Create PKCS12 keystore
sudo openssl pkcs12 -export \
  -in /etc/letsencrypt/live/your-domain/fullchain.pem \
  -inkey /etc/letsencrypt/live/your-domain/privkey.pem \
  -out keystore.p12 \
  -name springboot \
  -password pass:CHANGEME
```

## API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `GET /api/auth/validate` - Token validation

### Data Access
- `GET /api/data/secure` - Authenticated user data
- `GET /api/data/public` - Public data
- `GET /api/data/users` - All users (authenticated)
- `POST /api/data/message` - Send message

## Testing

### Running Tests
```bash
# Backend tests
cd application-tier
mvn test

# Frontend testing
# Open browser developer tools and test manually
```

### Security Testing
- Test authentication flows
- Verify HTTPS enforcement
- Check CORS policies
- Validate input sanitization
- Test rate limiting

## Monitoring & Logging

### Application Logs
- Spring Boot: Console and file logging
- Apache: Access and error logs
- Security: Authentication attempts, failed logins

### Monitoring Metrics
- Response times
- Error rates
- Authentication success/failure
- Resource utilization

## Security Best Practices Implemented

1. **Password Security**
   - Minimum 6-character passwords
   - BCrypt hashing with salt
   - Password complexity validation

2. **Session Security**
   - JWT tokens with expiration
   - Secure token storage
   - Automatic token refresh

3. **Transport Security**
   - TLS 1.2+ encryption
   - HSTS headers
   - Secure cookie flags

4. **Input Validation**
   - Server-side validation
   - SQL injection prevention
   - XSS protection

5. **Access Control**
   - Role-based authorization
   - API endpoint protection
   - CORS configuration

## Deployment on AWS

For detailed deployment instructions, please refer to the [AWS Academy Deployment Guide](scripts/aws-academy-guide.md).

## License

This project is part of the Enterprise Architecture Workshop: Secure Application Design.

## Support

For questions or issues related to this workshop:
- Check the documentation
- Review the AWS deployment guide
- Consult the security best practices

---

**Note**: This is an educational project designed to demonstrate secure application development practices. Always conduct thorough security testing before deploying to production environments.
