package com.logistics.gateway.config;

import com.logistics.gateway.filter.AuthenticationGatewayFilterFactory;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.reactive.CorsWebFilter;
import org.springframework.web.cors.reactive.UrlBasedCorsConfigurationSource;

@Configuration
public class GatewayConfig {
    
    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder, 
                                          AuthenticationGatewayFilterFactory authFilter) {
        return builder.routes()
                // Auth Service Routes (não requerem autenticação)
                .route("auth-service", r -> r.path("/api/auth/**")
                        .uri("lb://auth-service"))
                
                // Orders Service Routes (requerem autenticação)
                .route("orders-service", r -> r.path("/api/orders/**")
                        .filters(f -> f.filter(authFilter.apply(c -> c.setRequiredRole("USER"))))
                        .uri("lb://orders-service"))
                
                // Tracking Service Routes (requerem autenticação)
                .route("tracking-service", r -> r.path("/api/tracking/**")
                        .filters(f -> f.filter(authFilter.apply(c -> c.setRequiredRole("USER"))))
                        .uri("lb://tracking-service"))
                
                // Admin routes (requerem role ADMIN)
                .route("admin-orders", r -> r.path("/api/admin/orders/**")
                        .filters(f -> f.filter(authFilter.apply(c -> c.setRequiredRole("ADMIN")))
                                      .rewritePath("/api/admin/orders/(?<segment>.*)", "/api/orders/${segment}"))
                        .uri("lb://orders-service"))
                
                .route("admin-tracking", r -> r.path("/api/admin/tracking/**")
                        .filters(f -> f.filter(authFilter.apply(c -> c.setRequiredRole("ADMIN")))
                                      .rewritePath("/api/admin/tracking/(?<segment>.*)", "/api/tracking/${segment}"))
                        .uri("lb://tracking-service"))
                
                // Driver routes (requerem role DRIVER)
                .route("driver-orders", r -> r.path("/api/driver/orders/**")
                        .filters(f -> f.filter(authFilter.apply(c -> c.setRequiredRole("DRIVER")))
                                      .rewritePath("/api/driver/orders/(?<segment>.*)", "/api/orders/${segment}"))
                        .uri("lb://orders-service"))
                
                .route("driver-tracking", r -> r.path("/api/driver/tracking/**")
                        .filters(f -> f.filter(authFilter.apply(c -> c.setRequiredRole("DRIVER")))
                                      .rewritePath("/api/driver/tracking/(?<segment>.*)", "/api/tracking/${segment}"))
                        .uri("lb://tracking-service"))
                
                .build();
    }
    
    @Bean
    public CorsWebFilter corsWebFilter() {
        CorsConfiguration corsConfig = new CorsConfiguration();
        corsConfig.setAllowCredentials(true);
        corsConfig.addAllowedOriginPattern("*");
        corsConfig.addAllowedHeader("*");
        corsConfig.addAllowedMethod("*");
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", corsConfig);
        
        return new CorsWebFilter(source);
    }
}