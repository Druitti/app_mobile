package com.logistics.gateway.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/gateway")
public class GatewayController {
    
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("timestamp", LocalDateTime.now());
        response.put("service", "API Gateway");
        response.put("version", "1.0.0");
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/info")
    public ResponseEntity<Map<String, Object>> info() {
        Map<String, Object> response = new HashMap<>();
        response.put("name", "Logistics API Gateway");
        response.put("description", "Gateway para roteamento e autenticação dos microsserviços");
        response.put("version", "1.0.0");
        
        Map<String, String> endpoints = new HashMap<>();
        endpoints.put("auth", "/api/auth/**");
        endpoints.put("orders", "/api/orders/**");
        endpoints.put("tracking", "/api/tracking/**");
        endpoints.put("admin-orders", "/api/admin/orders/**");
        endpoints.put("admin-tracking", "/api/admin/tracking/**");
        endpoints.put("driver-orders", "/api/driver/orders/**");
        endpoints.put("driver-tracking", "/api/driver/tracking/**");
        
        response.put("routes", endpoints);
        
        return ResponseEntity.ok(response);
    }
}