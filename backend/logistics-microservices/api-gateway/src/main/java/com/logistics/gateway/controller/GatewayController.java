package com.logistics.gateway.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/gateway")
@Tag(name = "Gateway", description = "API Gateway endpoints para monitoramento e informações")
public class GatewayController {
    
    @GetMapping("/health")
    @Operation(summary = "Health Check", description = "Verifica o status de saúde do API Gateway")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Gateway está funcionando corretamente")
    })
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("timestamp", LocalDateTime.now());
        response.put("service", "API Gateway");
        response.put("version", "1.0.0");
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/info")
    @Operation(summary = "Gateway Info", description = "Informações sobre o Gateway e suas rotas disponíveis")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Informações do Gateway retornadas com sucesso")
    })
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