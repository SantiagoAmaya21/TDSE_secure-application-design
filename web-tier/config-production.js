// Production Configuration for Secure Application Design
// ======================================================

// API Configuration
const API_CONFIG = {
    // Base URL for the Spring Boot backend in AWS
    // Update this with your actual Spring server domain
    BASE_URL: window.location.hostname === 'localhost' 
        ? 'http://localhost:8080'  // Local development
        : 'https://tdse-secure-app.duckdns.org:8443', // AWS production
    
    // API Endpoints (without /api prefix)
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
    
    // Request configuration
    TIMEOUT: 30000, // 30 seconds
    RETRIES: 3,
    
    // Headers
    HEADERS: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
};

// Application Configuration
const APP_CONFIG = {
    // Application metadata
    NAME: 'Secure Application Design',
    VERSION: '1.0.0',
    DESCRIPTION: 'Enterprise Architecture Workshop: Secure Application Design',
    
    // Security settings
    SECURITY: {
        // Token storage
        TOKEN_KEY: 'secure_app_token',
        TOKEN_EXPIRY_CHECK: true,
        
        // Password requirements
        MIN_PASSWORD_LENGTH: 6,
        PASSWORD_REGEX: /^(?=.*[a-zA-Z])(?=.*\d).{6,}$/,
        
        // Session settings
        SESSION_TIMEOUT: 8 * 60 * 60 * 1000, // 8 hours
        WARNING_TIMEOUT: 5 * 60 * 1000, // 5 minutes before expiry
        
        // HTTPS enforcement
        ENFORCE_HTTPS: window.location.protocol === 'https:',
        SECURE_COOKIES: true
    },
    
    // UI Configuration
    UI: {
        // Animation settings
        ANIMATION_DURATION: 300,
        LOADING_DELAY: 500,
        
        // Theme
        THEME: {
            PRIMARY_COLOR: '#007bff',
            SECONDARY_COLOR: '#6c757d',
            SUCCESS_COLOR: '#28a745',
            DANGER_COLOR: '#dc3545',
            WARNING_COLOR: '#ffc107',
            INFO_COLOR: '#17a2b8'
        },
        
        // Layout
        LAYOUT: {
            HEADER_HEIGHT: '60px',
            SIDEBAR_WIDTH: '250px',
            CONTAINER_MAX_WIDTH: '1200px'
        }
    },
    
    // Environment detection
    ENVIRONMENT: {
        isDevelopment: window.location.hostname === 'localhost',
        isProduction: window.location.hostname !== 'localhost',
        isSecure: window.location.protocol === 'https:',
        
        // Feature flags
        FEATURES: {
            DEBUG_MODE: window.location.hostname === 'localhost',
            ANALYTICS: window.location.hostname !== 'localhost',
            ERROR_REPORTING: window.location.hostname !== 'localhost'
        }
    },
    
    // Logging configuration
    LOGGING: {
        LEVEL: window.location.hostname === 'localhost' ? 'debug' : 'error',
        CONSOLE: window.location.hostname === 'localhost',
        REMOTE: window.location.hostname !== 'localhost'
    }
};

// Export configurations (for use in other modules)
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        API_CONFIG,
        APP_CONFIG
    };
}

// Global error handler
window.addEventListener('error', function(event) {
    if (APP_CONFIG.LOGGING.REMOTE && APP_CONFIG.ENVIRONMENT.isProduction) {
        // In production, you might want to send errors to a logging service
        console.error('Application error:', event.error);
    }
});

// Security: Enforce HTTPS in production
if (APP_CONFIG.SECURITY.ENFORCE_HTTPS && !APP_CONFIG.ENVIRONMENT.isSecure) {
    window.location.href = window.location.href.replace('http://', 'https://');
}

console.log(`%c${APP_CONFIG.NAME} v${APP_CONFIG.VERSION}`, 
            `color: ${APP_CONFIG.UI.THEME.PRIMARY_COLOR}; font-size: 16px; font-weight: bold;`);
console.log(`Environment: ${APP_CONFIG.ENVIRONMENT.isDevelopment ? 'Development' : 'Production'}`);
console.log(`API Base URL: ${API_CONFIG.BASE_URL}`);
