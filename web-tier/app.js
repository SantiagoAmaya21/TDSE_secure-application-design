// Main Application Controller
// Handles UI interactions and application logic

class SecureApp {
    constructor() {
        this.currentUser = null;
        this.loginAttempts = 0;
        this.lockoutUntil = null;
        this.init();
    }

    // Initialize the application
    init() {
        this.bindEvents();
        this.checkAuthentication();
        LOG_CONFIG.log('Application initialized');
    }

    // Bind event listeners
    bindEvents() {
        // Login form
        document.getElementById('login-form').addEventListener('submit', (e) => {
            e.preventDefault();
            this.handleLogin();
        });

        // Register form
        document.getElementById('register-form').addEventListener('submit', (e) => {
            e.preventDefault();
            this.handleRegister();
        });

        // Logout button
        document.getElementById('logout-btn').addEventListener('click', () => {
            this.handleLogout();
        });

        // Data retrieval buttons
        document.getElementById('get-secure-data').addEventListener('click', () => {
            this.getSecureData();
        });

        document.getElementById('get-public-data').addEventListener('click', () => {
            this.getPublicData();
        });

        document.getElementById('get-users').addEventListener('click', () => {
            this.getAllUsers();
        });

        // Message form
        document.getElementById('message-form').addEventListener('submit', (e) => {
            e.preventDefault();
            this.sendMessage();
        });

        // Clear error messages on input
        document.querySelectorAll('input, textarea').forEach(input => {
            input.addEventListener('input', () => {
                this.clearErrorMessages();
            });
        });
    }

    // Check if user is authenticated
    checkAuthentication() {
        if (apiService.isAuthenticated()) {
            this.currentUser = apiService.getCurrentUser();
            this.showDashboard();
        } else {
            this.showLoginSection();
        }
    }

    // Handle login
    async handleLogin() {
        if (this.isLockedOut()) {
            this.showError('login-error', `Account locked. Try again in ${Math.ceil((this.lockoutUntil - Date.now()) / 60000)} minutes.`);
            return;
        }

        const username = document.getElementById('username').value;
        const password = document.getElementById('password').value;

        if (!this.validateLoginForm(username, password)) {
            return;
        }

        this.showLoading(true);

        try {
            const response = await apiService.login({ username, password });
            
            if (response.token) {
                apiService.setToken(response.token);
                this.currentUser = {
                    username: response.username,
                    email: response.email,
                    role: response.role,
                    id: response.id
                };
                
                // Store user data
                localStorage.setItem(APP_CONFIG.SESSION.USER_KEY, JSON.stringify(this.currentUser));
                
                this.showSuccess('Login successful!');
                this.showDashboard();
                this.resetLoginAttempts();
                
                // Clear form
                document.getElementById('login-form').reset();
            }
        } catch (error) {
            this.loginAttempts++;
            this.showError('login-error', error.message);
            
            if (this.loginAttempts >= APP_CONFIG.SECURITY.MAX_LOGIN_ATTEMPTS) {
                this.lockoutUntil = Date.now() + APP_CONFIG.SECURITY.LOCKOUT_DURATION;
                this.showError('login-error', `Too many failed attempts. Account locked for ${APP_CONFIG.SECURITY.LOCKOUT_DURATION / 60000} minutes.`);
            }
        } finally {
            this.showLoading(false);
        }
    }

    // Handle registration
    async handleRegister() {
        const username = document.getElementById('reg-username').value;
        const email = document.getElementById('reg-email').value;
        const password = document.getElementById('reg-password').value;

        console.log('Registration data:', { username, email, password }); // Debug logging

        if (!this.validateRegistrationForm(username, email, password)) {
            return;
        }

        this.showLoading(true);

        try {
            await apiService.register({ username, email, password });
            this.showSuccess('Registration successful! Please login.');
            
            // Clear form
            document.getElementById('register-form').reset();
            
            // Switch to login tab visually
            document.getElementById('username').focus();
        } catch (error) {
            this.showError('register-error', error.message);
        } finally {
            this.showLoading(false);
        }
    }

    // Handle logout
    handleLogout() {
        apiService.clearToken();
        this.currentUser = null;
        this.showLoginSection();
        this.showSuccess('Logged out successfully!');
    }

    // Get secure data
    async getSecureData() {
        this.showLoading(true);
        
        try {
            const data = await apiService.getSecureData();
            this.displayResult('secure-data-result', data, 'Secure Data Retrieved Successfully');
        } catch (error) {
            this.showError('secure-data-result', error.message);
        } finally {
            this.showLoading(false);
        }
    }

    // Get public data
    async getPublicData() {
        this.showLoading(true);
        
        try {
            const data = await apiService.getPublicData();
            this.displayResult('public-data-result', data, 'Public Data Retrieved Successfully');
        } catch (error) {
            this.showError('public-data-result', error.message);
        } finally {
            this.showLoading(false);
        }
    }

    // Get all users
    async getAllUsers() {
        this.showLoading(true);
        
        try {
            const users = await apiService.getAllUsers();
            this.displayResult('users-result', users, 'All Users Retrieved Successfully');
        } catch (error) {
            this.showError('users-result', error.message);
        } finally {
            this.showLoading(false);
        }
    }

    // Send message
    async sendMessage() {
        const messageContent = document.getElementById('message-content').value;
        
        if (!messageContent.trim()) {
            this.showError('message-result', 'Please enter a message.');
            return;
        }

        this.showLoading(true);

        try {
            const response = await apiService.sendMessage(messageContent);
            this.displayResult('message-result', response, 'Message Sent Successfully');
            
            // Clear form
            document.getElementById('message-form').reset();
        } catch (error) {
            this.showError('message-result', error.message);
        } finally {
            this.showLoading(false);
        }
    }

    // Show dashboard
    showDashboard() {
        document.getElementById('login-section').classList.add('hidden');
        document.getElementById('dashboard-section').classList.remove('hidden');
        
        // Update user info
        if (this.currentUser) {
            document.getElementById('user-name').textContent = this.currentUser.username;
            document.getElementById('user-role').textContent = this.currentUser.role;
            document.getElementById('user-email').textContent = this.currentUser.email;
        }
        
        // Add animation
        document.getElementById('dashboard-section').classList.add('fade-in');
    }

    // Show login section
    showLoginSection() {
        document.getElementById('login-section').classList.remove('hidden');
        document.getElementById('dashboard-section').classList.add('hidden');
        
        // Add animation
        document.getElementById('login-section').classList.add('fade-in');
    }

    // Validation methods
    validateLoginForm(username, password) {
        if (!username || !password) {
            this.showError('login-error', 'Please enter both username and password.');
            return false;
        }

        if (password.length < APP_CONFIG.SECURITY.MIN_PASSWORD_LENGTH) {
            this.showError('login-error', `Password must be at least ${APP_CONFIG.SECURITY.MIN_PASSWORD_LENGTH} characters long.`);
            return false;
        }

        return true;
    }

    validateRegistrationForm(username, email, password) {
        if (!username || !email || !password) {
            this.showError('register-error', 'Please enter all required fields.');
            return false;
        }

        if (username.length < 3) {
            this.showError('register-error', 'Username must be at least 3 characters long.');
            return false;
        }

        if (password.length < APP_CONFIG.SECURITY.MIN_PASSWORD_LENGTH) {
            this.showError('register-error', `Password must be at least ${APP_CONFIG.SECURITY.MIN_PASSWORD_LENGTH} characters long.`);
            return false;
        }

        if (!this.isValidEmail(email)) {
            this.showError('register-error', 'Please enter a valid email address.');
            return false;
        }

        return true;
    }

    isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    // UI helper methods
    showLoading(show) {
        const modal = document.getElementById('loading-modal');
        if (show) {
            modal.classList.remove('hidden');
        } else {
            setTimeout(() => {
                modal.classList.add('hidden');
            }, APP_CONFIG.UI.LOADING_DELAY);
        }
    }

    showError(elementId, message) {
        const errorElement = document.getElementById(elementId);
        if (errorElement) {
            errorElement.textContent = message;
            errorElement.classList.add('show');
            
            // Auto-hide after delay
            setTimeout(() => {
                errorElement.classList.remove('show');
            }, APP_CONFIG.UI.AUTO_HIDE_MESSAGES);
        }
    }

    showSuccess(message) {
        // Create a temporary success message
        const successDiv = document.createElement('div');
        successDiv.className = 'success-message show';
        successDiv.textContent = message;
        successDiv.style.position = 'fixed';
        successDiv.style.top = '20px';
        successDiv.style.right = '20px';
        successDiv.style.zIndex = '9999';
        successDiv.style.maxWidth = '300px';
        
        document.body.appendChild(successDiv);
        
        setTimeout(() => {
            successDiv.remove();
        }, APP_CONFIG.UI.AUTO_HIDE_MESSAGES);
    }

    displayResult(elementId, data, title) {
        const resultElement = document.getElementById(elementId);
        if (resultElement) {
            const formattedData = typeof data === 'object' 
                ? JSON.stringify(data, null, 2)
                : data;
            
            resultElement.innerHTML = `
                <h4>${title}</h4>
                <pre>${formattedData}</pre>
            `;
        }
    }

    clearErrorMessages() {
        document.querySelectorAll('.error-message').forEach(element => {
            element.classList.remove('show');
        });
    }

    // Security methods
    isLockedOut() {
        return this.lockoutUntil && Date.now() < this.lockoutUntil;
    }

    resetLoginAttempts() {
        this.loginAttempts = 0;
        this.lockoutUntil = null;
    }
}

// Initialize the application when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.app = new SecureApp();
});

// Export for testing
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SecureApp;
}
