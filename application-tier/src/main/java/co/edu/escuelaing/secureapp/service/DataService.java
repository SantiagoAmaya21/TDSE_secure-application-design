package co.edu.escuelaing.secureapp.service;

import co.edu.escuelaing.secureapp.model.User;
import co.edu.escuelaing.secureapp.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class DataService {

    @Autowired
    private UserRepository userRepository;

    public Map<String, String> getSecureData(String username) {
        Map<String, String> response = new HashMap<>();
        response.put("message", "This is secure data accessible only to authenticated users");
        response.put("user", username);
        response.put("timestamp", String.valueOf(System.currentTimeMillis()));
        response.put("security_level", "HIGH");
        return response;
    }

    public Map<String, String> getPublicData() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "This is public data accessible to everyone");
        response.put("timestamp", String.valueOf(System.currentTimeMillis()));
        response.put("security_level", "PUBLIC");
        return response;
    }

    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    public Map<String, String> saveMessage(String content, String username) {
        Map<String, String> response = new HashMap<>();
        response.put("status", "success");
        response.put("message", "Message saved successfully");
        response.put("content", content);
        response.put("user", username);
        response.put("timestamp", String.valueOf(System.currentTimeMillis()));
        return response;
    }
}
