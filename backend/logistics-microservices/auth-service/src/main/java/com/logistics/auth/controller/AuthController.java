package com.logistics.auth.controller;

import com.logistics.auth.dto.AuthResponse;
import com.logistics.auth.dto.LoginRequest;
import com.logistics.auth.dto.RegisterRequest;
import com.logistics.auth.service.AuthService;
import com.logistics.auth.service.JwtService;
import io.jsonwebtoken.Claims;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {
    
    @Autowired
    private AuthService authService;
    
    @Autowired
    private JwtService jwtService;
    
    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        try {
            AuthResponse response = authService.register(request);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        try {
            AuthResponse response = authService.login(request);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    @PostMapping("/validate")
    public ResponseEntity<Map<String, Object>> validateToken(@RequestParam String token) {
        Map<String, Object> response = new HashMap<>();
        
        try {
            boolean isValid = authService.validateToken(token);
            response.put("valid", isValid);
            
            if (isValid) {
                Claims claims = jwtService.getClaimsFromToken(token);
                response.put("userId", claims.get("userId"));
                response.put("email", claims.get("email"));
                response.put("userType", claims.get("userType"));
            }
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("valid", false);
            return ResponseEntity.ok(response);
        }
    }
}