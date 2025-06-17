package com.logistics.gateway.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.web.server.SecurityWebFilterChain;

@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain springSecurityFilterChain(ServerHttpSecurity http) {
        return http
            .authorizeExchange(exchanges -> exchanges
                .pathMatchers(
                    "/swagger-ui/**", 
                    "/swagger-ui.html",
                    "/v3/api-docs/**", 
                    "/swagger-resources/**",
                    "/webjars/**",
                    "/api/gateway/health",
                    "/api/gateway/info",
                    "/api/gateway/v3/api-docs",
                    "/api/auth/**" // Liberar todas as rotas de autenticação
                ).permitAll()
                .anyExchange().authenticated()
            )
            .csrf(csrf -> csrf.disable())
            .build();
    }
}