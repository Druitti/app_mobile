package com.logistics.gateway.exception;

import org.springframework.boot.web.reactive.error.ErrorWebExceptionHandler;
import org.springframework.core.annotation.Order;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;

@Component
@Order(-1)
public class GlobalExceptionHandler implements ErrorWebExceptionHandler {
    
    @Override
    public Mono<Void> handle(ServerWebExchange exchange, Throwable ex) {
        ServerHttpResponse response = exchange.getResponse();
        
        if (response.isCommitted()) {
            return Mono.error(ex);
        }
        
        response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
        
        HttpStatus status = HttpStatus.INTERNAL_SERVER_ERROR;
        String message = "Erro interno do servidor";
        
        if (ex instanceof org.springframework.web.server.ResponseStatusException) {
            org.springframework.web.server.ResponseStatusException rsEx = 
                (org.springframework.web.server.ResponseStatusException) ex;
            status = HttpStatus.valueOf(rsEx.getStatusCode().value());
            message = rsEx.getReason();
        }
        
        response.setStatusCode(status);
        
        String errorJson = String.format(
            "{\"error\": \"%s\", \"status\": %d, \"timestamp\": \"%s\", \"path\": \"%s\"}",
            message, status.value(), LocalDateTime.now(), exchange.getRequest().getPath()
        );
        
        DataBuffer buffer = response.bufferFactory().wrap(errorJson.getBytes());
        return response.writeWith(Mono.just(buffer));
    }
}