package com.logistics.gateway.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.client.ServiceInstance;
import org.springframework.cloud.client.discovery.DiscoveryClient;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.util.List;

@RestController
public class SwaggerController {

    @Autowired
    private DiscoveryClient discoveryClient;
    
    @Autowired
    private WebClient.Builder webClientBuilder;

    @GetMapping("/v3/api-docs/{service}")
    public Mono<ResponseEntity<String>> getServiceApiDocs(@PathVariable String service) {
        return getServiceUrl(service)
                .flatMap(url -> webClientBuilder.build()
                        .get()
                        .uri(url + "/v3/api-docs")
                        .retrieve()
                        .bodyToMono(String.class)
                        .map(ResponseEntity::ok))
                .onErrorReturn(ResponseEntity.notFound().build());
    }

    private Mono<String> getServiceUrl(String serviceName) {
        List<ServiceInstance> instances = discoveryClient.getInstances(serviceName.toUpperCase());
        if (!instances.isEmpty()) {
            ServiceInstance instance = instances.get(0);
            String url = instance.getUri().toString();
            return Mono.just(url);
        }
        return Mono.error(new RuntimeException("Service not found: " + serviceName));
}
}