package com.logistics.gateway.config;

import org.springdoc.core.models.GroupedOpenApi;
import org.springdoc.core.properties.SwaggerUiConfigParameters;
import org.springframework.cloud.gateway.route.RouteDefinition;
import org.springframework.cloud.gateway.route.RouteDefinitionLocator;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Lazy;

import java.util.ArrayList;
import java.util.List;

@Configuration
public class SwaggerConfig {

    @Bean
    @Lazy(false)
    public List<GroupedOpenApi> apis(
            SwaggerUiConfigParameters swaggerUiConfigParameters,
            RouteDefinitionLocator locator) {
        
        List<GroupedOpenApi> groups = new ArrayList<>();
        List<RouteDefinition> definitions = locator.getRouteDefinitions().collectList().block();
        
        // Definir manualmente os serviços (mais confiável que descoberta automática)
        groups.add(createServiceGroup("auth-service", "Auth Service", "/api/auth"));
        groups.add(createServiceGroup("orders-service", "Orders Service", "/api/orders"));
        groups.add(createServiceGroup("tracking-service", "Tracking Service", "/api/tracking"));
        
        return groups;
    }
    
    private GroupedOpenApi createServiceGroup(String serviceName, String displayName, String pathPattern) {
        return GroupedOpenApi.builder()
                .group(serviceName)
                .displayName(displayName)
                .pathsToMatch(pathPattern + "/")
                .build();
}
}