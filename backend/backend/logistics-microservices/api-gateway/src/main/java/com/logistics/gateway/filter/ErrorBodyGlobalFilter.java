package com.logistics.gateway.filter;

import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

@Component
public class ErrorBodyGlobalFilter implements GlobalFilter, Ordered {
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, org.springframework.cloud.gateway.filter.GatewayFilterChain chain) {
        return chain.filter(exchange).then(Mono.defer(() -> {
            ServerHttpResponse response = exchange.getResponse();
            if (response.getStatusCode() != null && response.getStatusCode().isError()) {
                // Não altera o body, apenas garante que o erro do downstream seja repassado
                // O body já estará presente se o serviço downstream retornou
                return Mono.empty();
            }
            return Mono.empty();
        }));
    }

    @Override
    public int getOrder() {
        return -2; // Executa antes do handler padrão
    }
}
