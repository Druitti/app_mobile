package com.logistics.gateway.filter;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.factory.AbstractGatewayFilterFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Map;

@Component
public class AuthenticationGatewayFilterFactory 
        extends AbstractGatewayFilterFactory<AuthenticationGatewayFilterFactory.Config> {
    
    @Autowired
    private WebClient.Builder webClientBuilder;
    
    public AuthenticationGatewayFilterFactory() {
        super(Config.class);
    }
    
    @Override
    public GatewayFilter apply(Config config) {
        return (exchange, chain) -> {
            ServerHttpRequest request = exchange.getRequest();
            
            // Verificar se existe o header de autorização
            if (!request.getHeaders().containsKey(HttpHeaders.AUTHORIZATION)) {
                return onError(exchange, "Token de autorização não fornecido", HttpStatus.UNAUTHORIZED);
            }
            
            String authHeader = request.getHeaders().get(HttpHeaders.AUTHORIZATION).get(0);
            
            if (!authHeader.startsWith("Bearer ")) {
                return onError(exchange, "Formato de token inválido", HttpStatus.UNAUTHORIZED);
            }
            
            String token = authHeader.substring(7);
            
            // Validar token com o serviço de autenticação
            return validateToken(token)
                    .flatMap(tokenData -> {
                        if (!(Boolean) tokenData.get("valid")) {
                            return onError(exchange, "Token inválido", HttpStatus.UNAUTHORIZED);
                        }
                        
                        String userType = (String) tokenData.get("userType");
                        
                        // Verificar se o usuário tem a role necessária
                        if (!hasRequiredRole(userType, config.getRequiredRole())) {
                            return onError(exchange, "Acesso negado", HttpStatus.FORBIDDEN);
                        }
                        
                        // Adicionar headers com informações do usuário
                        ServerHttpRequest mutatedRequest = request.mutate()
                                .header("X-User-Id", tokenData.get("userId").toString())
                                .header("X-User-Email", (String) tokenData.get("email"))
                                .header("X-User-Type", userType)
                                .build();
                        
                        return chain.filter(exchange.mutate().request(mutatedRequest).build());
                    })
                    .onErrorResume(throwable -> 
                            onError(exchange, "Erro na validação do token", HttpStatus.INTERNAL_SERVER_ERROR));
        };
    }
    
    private Mono<Map> validateToken(String token) {
        return webClientBuilder.build()
                .post()
                .uri("lb://auth-service/api/auth/validate")
                .bodyValue(Map.of("token", token))
                .retrieve()
                .bodyToMono(Map.class);
    }
    
    private boolean hasRequiredRole(String userType, String requiredRole) {
        if ("USER".equals(requiredRole)) {
            return List.of("CUSTOMER", "DRIVER", "ADMIN").contains(userType);
        }
        
        if ("DRIVER".equals(requiredRole)) {
            return List.of("DRIVER", "ADMIN").contains(userType);
        }
        
        if ("ADMIN".equals(requiredRole)) {
            return "ADMIN".equals(userType);
        }
        
        return false;
    }
    
    private Mono<Void> onError(ServerWebExchange exchange, String err, HttpStatus httpStatus) {
        ServerHttpResponse response = exchange.getResponse();
        response.setStatusCode(httpStatus);
        response.getHeaders().add("Content-Type", "application/json");
        
        String errorMessage = String.format("{\"error\": \"%s\", \"status\": %d}", err, httpStatus.value());
        
        return response.writeWith(Mono.just(response.bufferFactory().wrap(errorMessage.getBytes())));
    }
    
    public static class Config {
        private String requiredRole = "USER";
        
        public String getRequiredRole() {
            return requiredRole;
        }
        
        public void setRequiredRole(String requiredRole) {
            this.requiredRole = requiredRole;
        }
    }
}