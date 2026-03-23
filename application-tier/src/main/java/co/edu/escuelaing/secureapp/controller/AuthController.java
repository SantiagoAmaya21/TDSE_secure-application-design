package co.edu.escuelaing.secureapp.controller;

import co.edu.escuelaing.secureapp.dto.LoginRequest;
import co.edu.escuelaing.secureapp.dto.LoginResponse;
import co.edu.escuelaing.secureapp.dto.RegisterRequest;
import co.edu.escuelaing.secureapp.service.AuthService;
import co.edu.escuelaing.secureapp.service.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    @Autowired
    private AuthService authService;

    @Autowired
    private UserService userService;

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest loginRequest) {
        try {
            LoginResponse response = authService.authenticateUser(loginRequest);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest registrationRequest) {
        try {
            // Debug logging
            System.out.println("Received registration request: " + registrationRequest.getUsername() + ", " + registrationRequest.getEmail() + ", " + registrationRequest.getPassword());
            
            userService.registerUser(registrationRequest);
            return ResponseEntity.ok().body("{\"message\": \"User registered successfully\"}");
        } catch (RuntimeException e) {
            System.out.println("Registration error (RuntimeException): " + e.getMessage());
            return ResponseEntity.badRequest().body("{\"error\": \"Registration failed: " + e.getMessage() + "\"}");
        } catch (Exception e) {
            System.out.println("Registration error (Exception): " + e.getMessage());
            return ResponseEntity.internalServerError().body("{\"error\": \"Registration failed: " + e.getMessage() + "\"}");
        }
    }

    @GetMapping("/validate")
    public ResponseEntity<?> validateToken(@RequestParam String token) {
        try {
            boolean isValid = authService.validateToken(token);
            return ResponseEntity.ok(isValid);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
}
