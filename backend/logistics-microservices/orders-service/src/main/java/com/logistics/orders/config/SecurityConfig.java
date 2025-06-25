package com.logistics.orders.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .anyRequest().permitAll() // Permite acesso a todas as rotas
            )
            .csrf(csrf -> csrf.disable())
            .httpBasic(basic -> basic.disable()) // Desabilita HTTP Basic Auth
            .formLogin(form -> form.disable()); // Desabilita form login

        return http.build();
    }
}