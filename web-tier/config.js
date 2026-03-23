// Configuration file for the Secure Application Design
// This file contains all the configuration settings for the application

// API Configuration
const API_CONFIG = {
    // Base URL for the Spring Boot backend
    // Change this to your Spring server URL when deploying
    BASE_URL: window.location.hostname === 'localhost' 
        ? 'http://localhost:8080' 
        : 'https://your-spring-server-domain.com',
    
    // API Endpoints
    ENDPOINTS: {
        AUTH: {
            LOGIN: '/auth/login',
            REGISTER: '/auth/register',
            VALIDATE: '/auth/validate'
        },
        DATA: {
            SECURE: '/data/secure',
            PUBLIC: '/data/public',
            USERS: '/data/users',
            MESSAGE: '/data/message'
        }
    },
    
    // Request timeout in milliseconds
    TIMEOUT: 10000,
    
    // Retry configuration
    RETRY: {
        MAX_RETRIES: 3,
        RETRY_DELAY: 1000
    }
};

// Application Configuration
const APP_CONFIG = {
    // Application name and version
    NAME: 'Secure Application Design',
    VERSION: '1.0.0',
    
    // Session configuration
    SESSION: {
        TOKEN_KEY: 'jwt_token',
        USER_KEY: 'user_data',
        TOKEN_EXPIRY_CHECK_INTERVAL: 60000 // Check every minute
    },
    
    // UI Configuration
    UI: {
        LOADING_DELAY: 300, // Minimum loading time in ms
        ANIMATION_DURATION: 500,
        AUTO_HIDE_MESSAGES: 5000 // Auto-hide success/error messages after 5 seconds
    },
    
    // Security configuration
    SECURITY: {
        // Minimum password length
        MIN_PASSWORD_LENGTH: 6,
        
        // Maximum login attempts
        MAX_LOGIN_ATTEMPTS: 3,
        
        // Lockout duration in milliseconds
        LOCKOUT_DURATION: 300000 // 5 minutes
    }
};

// Development/Production Environment Detection
const ENVIRONMENT = {
    isDevelopment: () => {
        return window.location.hostname === 'localhost' || 
               window.location.hostname === '127.0.0.1' ||
               window.location.hostname === '';
    },
    
    isProduction: () => {
        return !ENVIRONMENT.isDevelopment();
    },
    
    getApiBaseUrl: () => {
        if (ENVIRONMENT.isDevelopment()) {
            return API_CONFIG.BASE_URL;
        } else {
            // In production, use the actual deployed URL
            return 'https://your-production-spring-server.com/api';
        }
    }
};

// TLS/HTTPS Configuration
const TLS_CONFIG = {
    // Force HTTPS in production
    enforceHttps: () => {
        if (ENVIRONMENT.isProduction() && window.location.protocol !== 'https:') {
            window.location.href = `https://${window.location.host}${window.location.pathname}`;
        }
    },
    
    // Check if the connection is secure
    isSecure: () => {
        return window.location.protocol === 'https:' || ENVIRONMENT.isDevelopment();
    }
};

// Logging Configuration
const LOG_CONFIG = {
    LEVEL: ENVIRONMENT.isDevelopment() ? 'DEBUG' : 'ERROR',
    
    // Logging functions
    log: (message, data = null) => {
        if (LOG_CONFIG.LEVEL === 'DEBUG') {
            console.log(`[${new Date().toISOString()}] ${message}`, data);
        }
    },
    
    error: (message, error = null) => {
        console.error(`[${new Date().toISOString()}] ERROR: ${message}`, error);
    },
    
    warn: (message, data = null) => {
        console.warn(`[${new Date().toISOString()}] WARN: ${message}`, data);
    }
};

// Export configurations for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        API_CONFIG,
        APP_CONFIG,
        ENVIRONMENT,
        TLS_CONFIG,
        LOG_CONFIG
    };
}

// Initialize TLS enforcement
document.addEventListener('DOMContentLoaded', () => {
    TLS_CONFIG.enforceHttps();
    LOG_CONFIG.log('Application initialized', {
        environment: ENVIRONMENT.isDevelopment() ? 'Development' : 'Production',
        secure: TLS_CONFIG.isSecure(),
        apiBaseUrl: ENVIRONMENT.getApiBaseUrl()
    });
});
