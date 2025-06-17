package com.logistics.gateway.exception;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.web.reactive.error.ErrorWebExceptionHandler;
import org.springframework.cloud.gateway.support.NotFoundException;
import org.springframework.core.annotation.Order;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Component
@Order(-2) // Prioridade mais alta que o filtro
public class GlobalExceptionHandler implements ErrorWebExceptionHandler {
    
    private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    @Override
    public Mono<Void> handle(ServerWebExchange exchange, Throwable ex) {
        ServerHttpResponse response = exchange.getResponse();
        
        // Se a resposta já foi commitada, não processa
        if (response.isCommitted()) {
            return Mono.error(ex);
        }
        
        // Apenas trata erros específicos do Gateway, deixa outros passarem
        if (!shouldHandle(ex)) {
            return Mono.error(ex);
        }
        
        HttpStatus status = determineHttpStatus(ex);
        String message = determineErrorMessage(ex, status);
        
        // Log do erro
        logException(ex, exchange, status);
        
        // Monta resposta de erro
        Map<String, Object> errorResponse = buildErrorResponse(
            status, 
            message, 
            ex.getMessage(), 
            exchange.getRequest().getPath().toString()
        );
        
        // Configura headers da resposta
        response.setStatusCode(status);
        response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
        
        try {
            String errorJson = objectMapper.writeValueAsString(errorResponse);
            DataBuffer buffer = response.bufferFactory().wrap(errorJson.getBytes(StandardCharsets.UTF_8));
            return response.writeWith(Mono.just(buffer));
        } catch (JsonProcessingException e) {
            logger.error("Erro ao serializar resposta de erro", e);
            return response.setComplete();
        }
    }
    
    private boolean shouldHandle(Throwable ex) {
        // Apenas trata erros específicos do Gateway
        return ex instanceof NotFoundException || 
               ex instanceof java.net.ConnectException ||
               ex instanceof java.util.concurrent.TimeoutException ||
               ex instanceof org.springframework.cloud.gateway.support.TimeoutException ||
               (ex instanceof ResponseStatusException && 
                ((ResponseStatusException) ex).getStatusCode().is5xxServerError());
    }
    
    private HttpStatus determineHttpStatus(Throwable ex) {
        if (ex instanceof NotFoundException) {
            return HttpStatus.SERVICE_UNAVAILABLE;
        } else if (ex instanceof ResponseStatusException) {
            ResponseStatusException rse = (ResponseStatusException) ex;
            // Converte HttpStatusCode para HttpStatus
            return HttpStatus.valueOf(rse.getStatusCode().value());
        } else if (ex instanceof java.net.ConnectException) {
            return HttpStatus.SERVICE_UNAVAILABLE;
        } else if (ex instanceof java.util.concurrent.TimeoutException) {
            return HttpStatus.GATEWAY_TIMEOUT;
        } else {
            return HttpStatus.INTERNAL_SERVER_ERROR;
        }
    }
    
    private String determineErrorMessage(Throwable ex, HttpStatus status) {
        if (ex instanceof NotFoundException) {
            return "Serviço não encontrado ou indisponível";
        } else if (ex instanceof java.net.ConnectException) {
            return "Erro de conexão com o serviço";
        } else if (ex instanceof java.util.concurrent.TimeoutException) {
            return "Timeout na comunicação com o serviço";
        } else {
            switch (status) {
                case SERVICE_UNAVAILABLE:
                    return "Serviço temporariamente indisponível";
                case GATEWAY_TIMEOUT:
                    return "Timeout do gateway";
                case NOT_FOUND:
                    return "Recurso não encontrado";
                default:
                    return "Erro interno do gateway";
            }
        }
    }
    
    private Map<String, Object> buildErrorResponse(HttpStatus status, String message, String details, String path) {
        Map<String, Object> response = new HashMap<>();
        response.put("timestamp", LocalDateTime.now().toString());
        response.put("status", status.value());
        response.put("error", status.getReasonPhrase());
        response.put("message", message);
        response.put("details", details);
        response.put("path", path);
        response.put("service", "api-gateway");
        return response;
    }
    
    private void logException(Throwable ex, ServerWebExchange exchange, HttpStatus status) {
        String logMessage = String.format(
            "Gateway Exception: %s | Status: %d | Path: %s | Method: %s | Message: %s",
            ex.getClass().getSimpleName(),
            status.value(),
            exchange.getRequest().getPath(),
            exchange.getRequest().getMethod(),
            ex.getMessage()
        );
        
        if (status.is5xxServerError()) {
            logger.error(logMessage, ex);
        } else {
            logger.warn(logMessage);
        }
    }
}