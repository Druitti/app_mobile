package com.logistics.auth.exception;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.InsufficientAuthenticationException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.NoHandlerFoundException;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;

import jakarta.servlet.http.HttpServletRequest;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

import org.hibernate.exception.ConstraintViolationException;

@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE)
public class GlobalExceptionHandler {
    
    private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    // 400 - Bad Request
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidationException(
            MethodArgumentNotValidException ex, HttpServletRequest request) {
        
        logException(ex, request, HttpStatus.BAD_REQUEST);
        
        Map<String, String> fieldErrors = new HashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(error ->
            fieldErrors.put(error.getField(), error.getDefaultMessage())
        );
        
        Map<String, Object> response = buildErrorResponse(
            HttpStatus.BAD_REQUEST, 
            "Erro de validação", 
            fieldErrors.toString(), 
            request.getRequestURI()
        );
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<Map<String, Object>> handleTypeMismatchException(
            MethodArgumentTypeMismatchException ex, HttpServletRequest request) {
        
        logException(ex, request, HttpStatus.BAD_REQUEST);
        
        String message = "Parâmetro inválido: " + ex.getName() + ". Valor recebido: " + ex.getValue();
        Map<String, Object> response = buildErrorResponse(
            HttpStatus.BAD_REQUEST, 
            message, 
            ex.getMessage(), 
            request.getRequestURI()
        );
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    // 401 - Unauthorized
    @ExceptionHandler({BadCredentialsException.class, InsufficientAuthenticationException.class})
    public ResponseEntity<Map<String, Object>> handleUnauthorizedException(
            Exception ex, HttpServletRequest request) {
        
        logException(ex, request, HttpStatus.UNAUTHORIZED);
        
        Map<String, Object> response = buildErrorResponse(
            HttpStatus.UNAUTHORIZED, 
            "Credenciais inválidas ou ausentes", 
            ex.getMessage(), 
            request.getRequestURI()
        );
        
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
    }

    // 402 - Payment Required (exemplo customizado)
    @ExceptionHandler(PaymentRequiredException.class)
    public ResponseEntity<Map<String, Object>> handlePaymentRequiredException(
            PaymentRequiredException ex, HttpServletRequest request) {
        
        logException(ex, request, HttpStatus.PAYMENT_REQUIRED);
        
        Map<String, Object> response = buildErrorResponse(
            HttpStatus.PAYMENT_REQUIRED, 
            "Pagamento necessário para acessar este recurso", 
            ex.getMessage(), 
            request.getRequestURI()
        );
        
        return ResponseEntity.status(HttpStatus.PAYMENT_REQUIRED).body(response);
    }

    // 403 - Forbidden
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<Map<String, Object>> handleAccessDeniedException(
            AccessDeniedException ex, HttpServletRequest request) {
        
        logException(ex, request, HttpStatus.FORBIDDEN);
        
        Map<String, Object> response = buildErrorResponse(
            HttpStatus.FORBIDDEN, 
            "Acesso negado - Permissões insuficientes", 
            ex.getMessage(), 
            request.getRequestURI()
        );
        
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(response);
    }

    // 404 - Not Found
    @ExceptionHandler(NoHandlerFoundException.class)
    public ResponseEntity<Map<String, Object>> handleNotFoundException(
            NoHandlerFoundException ex, HttpServletRequest request) {
        
        logException(ex, request, HttpStatus.NOT_FOUND);
        
        Map<String, Object> response = buildErrorResponse(
            HttpStatus.NOT_FOUND, 
            "Recurso não encontrado", 
            "Endpoint não existe: " + ex.getRequestURL(), 
            request.getRequestURI()
        );
        
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
    }

    // 500 - Internal Server Error (RuntimeException específicas)
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Map<String, Object>> handleRuntimeException(
            RuntimeException ex, HttpServletRequest request) {
        
        logException(ex, request, HttpStatus.INTERNAL_SERVER_ERROR);
        
        Map<String, Object> response = buildErrorResponse(
            HttpStatus.INTERNAL_SERVER_ERROR, 
            "Erro interno do servidor", 
            ex.getMessage(), 
            request.getRequestURI()
        );
        
        // Adiciona stack trace completo
        response.put("stackTrace", getStackTraceAsString(ex));
        
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }

    // Handler genérico para todas as outras exceções
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleGenericException(
            Exception ex, HttpServletRequest request) {
        
        logException(ex, request, HttpStatus.INTERNAL_SERVER_ERROR);
        
        // Busca a causa raiz do erro
        Throwable rootCause = getRootCause(ex);
        
        Map<String, Object> response = buildErrorResponse(
            HttpStatus.INTERNAL_SERVER_ERROR, 
            "Erro interno do servidor", 
            rootCause.getMessage(), 
            request.getRequestURI()
        );
        
        // Adiciona informações detalhadas da exceção
        response.put("exceptionType", rootCause.getClass().getSimpleName());
        response.put("stackTrace", getStackTraceAsString(rootCause));
        
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }

    // Métodos auxiliares
    private Map<String, Object> buildErrorResponse(HttpStatus status, String message, 
                                                  String details, String path) {
        Map<String, Object> response = new HashMap<>();
        response.put("timestamp", LocalDateTime.now().toString());
        response.put("status", status.value());
        response.put("error", status.getReasonPhrase());
        response.put("message", message);
        response.put("details", details);
        response.put("path", path);
        return response;
    }

    private Throwable getRootCause(Throwable throwable) {
        Throwable root = throwable;
        while (root.getCause() != null && root.getCause() != root) {
            root = root.getCause();
        }
        return root;
    }

    private String getStackTraceAsString(Throwable throwable) {
        StringBuilder stackTrace = new StringBuilder();
        stackTrace.append(throwable.getClass().getName())
                  .append(": ")
                  .append(throwable.getMessage())
                  .append("\n");
        
        for (StackTraceElement element : throwable.getStackTrace()) {
            stackTrace.append("\tat ").append(element.toString()).append("\n");
        }
        
        // Inclui causas encadeadas
        Throwable cause = throwable.getCause();
        while (cause != null) {
            stackTrace.append("Caused by: ")
                      .append(cause.getClass().getName())
                      .append(": ")
                      .append(cause.getMessage())
                      .append("\n");
            
            for (StackTraceElement element : cause.getStackTrace()) {
                stackTrace.append("\tat ").append(element.toString()).append("\n");
            }
            cause = cause.getCause();
        }
        
        return stackTrace.toString();
    }

    private void logException(Exception ex, HttpServletRequest request, HttpStatus status) {
        String logMessage = String.format(
            "Exception handled: %s | Status: %d | Path: %s | Method: %s | Message: %s",
            ex.getClass().getSimpleName(),
            status.value(),
            request.getRequestURI(),
            request.getMethod(),
            ex.getMessage()
        );
        
        if (status.is5xxServerError()) {
            logger.error(logMessage, ex);
        } else {
            logger.warn(logMessage);
        }
    }
}

// Classe de exceção customizada para erro 402 (exemplo)
class PaymentRequiredException extends RuntimeException {
    public PaymentRequiredException(String message) {
        super(message);
    }
    
    public PaymentRequiredException(String message, Throwable cause) {
        super(message, cause);
    }
}