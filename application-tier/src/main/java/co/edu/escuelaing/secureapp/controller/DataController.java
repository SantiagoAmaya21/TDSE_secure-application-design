package co.edu.escuelaing.secureapp.controller;

import co.edu.escuelaing.secureapp.model.User;
import co.edu.escuelaing.secureapp.service.DataService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/data")
@CrossOrigin(origins = "*")
public class DataController {

    @Autowired
    private DataService dataService;

    @GetMapping("/secure")
    public ResponseEntity<Map<String, String>> getSecureData(Authentication authentication) {
        Map<String, String> response = dataService.getSecureData(authentication.getName());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/public")
    public ResponseEntity<Map<String, String>> getPublicData() {
        Map<String, String> response = dataService.getPublicData();
        return ResponseEntity.ok(response);
    }

    @GetMapping("/users")
    public ResponseEntity<List<User>> getAllUsers(Authentication authentication) {
        List<User> users = dataService.getAllUsers();
        return ResponseEntity.ok(users);
    }

    @PostMapping("/message")
    public ResponseEntity<Map<String, String>> postMessage(@RequestBody Map<String, String> message, 
                                                          Authentication authentication) {
        Map<String, String> response = dataService.saveMessage(message.get("content"), authentication.getName());
        return ResponseEntity.ok(response);
    }
}
