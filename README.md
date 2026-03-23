# Secure Application Design Workshop

A comprehensive secure web application built with Spring Boot backend and Apache frontend, demonstrating enterprise-level security practices including JWT authentication, TLS encryption, and secure deployment patterns.

## 🏗️ Architecture Overview

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

## 🔐 Security Features

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

## 📁 Project Structure

```
TDSE_secure-application-design/
├── application-tier/                 # Spring Boot Backend
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/co/edu/escuelaing/secureapp/
│   │   │   │   ├── controller/       # REST Controllers
│   │   │   │   ├── model/           # JPA Entities
│   │   │   │   ├── dto/             # Data Transfer Objects
│   │   │   │   ├── repository/      # JPA Repositories
│   │   │   │   ├── service/         # Business Logic
│   │   │   │   ├── security/        # Security Configuration
│   │   │   │   └── config/          # Application Configuration
│   │   │   └── resources/
│   │   │       └── application.properties
│   │   └── test/                    # Unit Tests
│   ├── pom.xml                      # Maven Configuration
│   └── img/                         # Documentation Images
├── web-tier/                        # Apache Frontend
│   ├── index.html                   # Main Application Page
│   ├── styles.css                   # Modern CSS Styling
│   ├── config.js                    # Application Configuration
│   ├── api.js                       # API Service Layer
│   ├── app.js                       # Main Application Logic
│   ├── .gitattributes
│   └── .gitignore
├── .gitignore                       # Git Ignore Rules
├── .gitattributes                   # Git Attributes
└── README.md                        # This File
```

## 🚀 Getting Started

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

## 🔧 Configuration

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

## 🌐 AWS Deployment Guide

### Prerequisites
- AWS Academy account
- EC2 Instances (2x t2.micro or larger)
- Security Groups configuration
- Let's Encrypt certificates

### Manual Deployment Steps in AWS Academy

#### 1. EC2 Instance Setup
```bash
# Update system
sudo yum update -y

# Install Java 17
sudo yum install java-17-amazon-corretto -y

# Install Maven
sudo yum install maven -y

# Install Apache
sudo yum install httpd -y

# Start services
sudo systemctl start httpd
sudo systemctl enable httpd
```

#### 2. Security Group Configuration
- **Apache Server**: Port 80 (HTTP), Port 443 (HTTPS)
- **Spring Server**: Port 8080 (HTTP), Port 8443 (HTTPS)
- **SSH**: Port 22 (for management)

#### 3. Let's Encrypt Certificate Setup
```bash
# Install Certbot
sudo yum install certbot python3-certbot-apache -y

# Generate certificates (necesitas un dominio)
sudo certbot --apache -d your-domain.com

# Set up auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

#### 4. Backend Deployment
```bash
# Clone repository
git clone <tu-repository-url>
cd TDSE_secure-application-design/application-tier

# Build application
mvn clean package -DskipTests

# Run as service
sudo java -jar target/demo-0.0.1-SNAPSHOT.jar
```

#### 5. Frontend Deployment
```bash
# Copy files to Apache directory
sudo cp -r web-tier/* /var/www/html/

# Configure Apache for HTTPS
sudo nano /etc/httpd/conf.d/ssl.conf
```

## 🔍 API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `GET /api/auth/validate` - Token validation

### Data Access
- `GET /api/data/secure` - Authenticated user data
- `GET /api/data/public` - Public data
- `GET /api/data/users` - All users (authenticated)
- `POST /api/data/message` - Send message

## 🧪 Testing

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

## 📊 Monitoring & Logging

### Application Logs
- Spring Boot: Console and file logging
- Apache: Access and error logs
- Security: Authentication attempts, failed logins

### Monitoring Metrics
- Response times
- Error rates
- Authentication success/failure
- Resource utilization

## 🔒 Security Best Practices Implemented

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

## 🚨 Limitations & External Dependencies

### What Cannot Be Automated (Requires Manual Setup):

1. **AWS Infrastructure**
   - EC2 instance creation and configuration
   - VPC and security group setup
   - Elastic IP allocation
   - IAM roles and policies

2. **Domain and DNS**
   - Domain name registration
   - DNS record configuration
   - Route 53 setup

3. **SSL Certificates**
   - Let's Encrypt certificate generation
   - Certificate renewal setup
   - Apache SSL configuration

4. **Production Database**
   - RDS instance setup
   - Database migration scripts
   - Backup configuration

5. **Load Balancing**
   - Application Load Balancer setup
   - Health checks configuration
   - Auto-scaling policies

6. **Monitoring & Alerting**
   - CloudWatch configuration
   - SNS notification setup
   - Log aggregation

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📝 License

This project is part of the Enterprise Architecture Workshop: Secure Application Design.

## 📞 Support

For questions or issues related to this workshop:
- Check the documentation
- Review the AWS deployment guide
- Consult the security best practices

---

**Note**: This is an educational project designed to demonstrate secure application development practices. Always conduct thorough security testing before deploying to production environments.
