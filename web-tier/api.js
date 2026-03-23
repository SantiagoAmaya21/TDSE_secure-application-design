// API Service Module
// Handles all HTTP requests to the Spring Boot backend

class ApiService {
    constructor() {
        this.baseUrl = ENVIRONMENT.getApiBaseUrl();
        this.token = localStorage.getItem(APP_CONFIG.SESSION.TOKEN_KEY);
    }

    // Set authentication token
    setToken(token) {
        this.token = token;
        localStorage.setItem(APP_CONFIG.SESSION.TOKEN_KEY, token);
    }

    // Get authentication token
    getToken() {
        return this.token || localStorage.getItem(APP_CONFIG.SESSION.TOKEN_KEY);
    }

    // Clear authentication token
    clearToken() {
        this.token = null;
        localStorage.removeItem(APP_CONFIG.SESSION.TOKEN_KEY);
        localStorage.removeItem(APP_CONFIG.SESSION.USER_KEY);
    }

    // Generic HTTP request method
    async request(endpoint, options = {}) {
        const url = `${this.baseUrl}${endpoint}`;
        const config = {
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            },
            ...options
        };

        // Add authorization header if token exists
        if (this.getToken()) {
            config.headers.Authorization = `Bearer ${this.getToken()}`;
        }

        // Add timeout
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), API_CONFIG.TIMEOUT);
        config.signal = controller.signal;

        try {
            LOG_CONFIG.log(`Making ${config.method || 'GET'} request to:`, url);
            
            const response = await fetch(url, config);
            clearTimeout(timeoutId);

            // Handle different response statuses
            if (response.status === 401) {
                this.clearToken();
                throw new Error('Authentication failed. Please login again.');
            }

            if (response.status === 403) {
                throw new Error('Access denied. You do not have permission to access this resource.');
            }

            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}));
                throw new Error(errorData.message || `HTTP error! status: ${response.status}`);
            }

            const data = await response.json();
            LOG_CONFIG.log('Request successful:', data);
            return data;

        } catch (error) {
            clearTimeout(timeoutId);
            
            if (error.name === 'AbortError') {
                throw new Error('Request timeout. Please try again.');
            }
            
            LOG_CONFIG.error('Request failed:', error);
            throw error;
        }
    }

    // Authentication methods
    async login(credentials) {
        return this.request(API_CONFIG.ENDPOINTS.AUTH.LOGIN, {
            method: 'POST',
            body: JSON.stringify(credentials)
        });
    }

    async register(userData) {
        return this.request(API_CONFIG.ENDPOINTS.AUTH.REGISTER, {
            method: 'POST',
            body: JSON.stringify(userData)
        });
    }

    async validateToken(token) {
        return this.request(`${API_CONFIG.ENDPOINTS.AUTH.VALIDATE}?token=${token}`);
    }

    // Data methods
    async getSecureData() {
        return this.request(API_CONFIG.ENDPOINTS.DATA.SECURE);
    }

    async getPublicData() {
        return this.request(API_CONFIG.ENDPOINTS.DATA.PUBLIC);
    }

    async getAllUsers() {
        return this.request(API_CONFIG.ENDPOINTS.DATA.USERS);
    }

    async sendMessage(message) {
        return this.request(API_CONFIG.ENDPOINTS.DATA.MESSAGE, {
            method: 'POST',
            body: JSON.stringify({ content: message })
        });
    }

    // Retry mechanism for failed requests
    async requestWithRetry(endpoint, options = {}, retries = API_CONFIG.RETRY.MAX_RETRIES) {
        try {
            return await this.request(endpoint, options);
        } catch (error) {
            if (retries > 0 && this.shouldRetry(error)) {
                LOG_CONFIG.warn(`Request failed, retrying... (${retries} attempts left)`);
                await this.delay(API_CONFIG.RETRY.RETRY_DELAY);
                return this.requestWithRetry(endpoint, options, retries - 1);
            }
            throw error;
        }
    }

    // Helper method to determine if request should be retried
    shouldRetry(error) {
        return error.message.includes('timeout') || 
               error.message.includes('NetworkError') ||
               error.message.includes('fetch');
    }

    // Helper method for delays
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    // Check if user is authenticated
    isAuthenticated() {
        const token = this.getToken();
        if (!token) return false;

        try {
            // Simple token validation (you might want to add more sophisticated validation)
            const payload = JSON.parse(atob(token.split('.')[1]));
            const now = Date.now() / 1000;
            return payload.exp > now;
        } catch (error) {
            return false;
        }
    }

    // Get current user info from token
    getCurrentUser() {
        const token = this.getToken();
        if (!token) return null;

        try {
            const payload = JSON.parse(atob(token.split('.')[1]));
            return {
                username: payload.sub,
                userId: payload.userId,
                role: payload.role
            };
        } catch (error) {
            return null;
        }
    }
}

// Create a singleton instance
const apiService = new ApiService();

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = apiService;
}

// Global access for debugging
window.apiService = apiService;
