package com.logistics.orders.controller;

import com.logistics.orders.model.User;
import com.logistics.orders.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class UserController {
    @Autowired
    private UserRepository userRepository;

    @PutMapping("/{id}/fcm-token")
    public ResponseEntity<?> updateFcmToken(@PathVariable Long id, @RequestBody FcmTokenRequest request) {
        return userRepository.findById(id)
                .map(user -> {
                    user.setFcmToken(request.getFcmToken());
                    userRepository.save(user);
                    return ResponseEntity.ok().build();
                })
                .orElse(ResponseEntity.notFound().build());
    }

    public static class FcmTokenRequest {
        private String fcmToken;
        public String getFcmToken() { return fcmToken; }
        public void setFcmToken(String fcmToken) { this.fcmToken = fcmToken; }
    }
}
