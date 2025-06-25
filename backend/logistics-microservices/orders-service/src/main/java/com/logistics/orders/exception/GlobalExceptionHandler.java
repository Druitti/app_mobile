package com.logistics.orders.exception;

import org.hibernate.exception.ConstraintViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

@ControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Object> handleValidationException(MethodArgumentNotValidException ex) {
        var errors = new java.util.HashMap<String, String>();
        ex.getBindingResult().getFieldErrors().forEach(error ->
            errors.put(error.getField(), error.getDefaultMessage())
        );
        var body = new java.util.HashMap<String, Object>();
        body.put("status", HttpStatus.BAD_REQUEST.value());
        body.put("error", "Erro de validação");
        body.put("details", errors);
        body.put("timestamp", java.time.LocalDateTime.now());
        return new ResponseEntity<>(body, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<Object> handleConstraintViolation(ConstraintViolationException ex) {
        var body = new java.util.HashMap<String, Object>();
        body.put("status", HttpStatus.BAD_REQUEST.value());
        body.put("error", "Violação de restrição: " + ex.getConstraintName());
        body.put("details", ex.getMessage());
        body.put("timestamp", java.time.LocalDateTime.now());
        return new ResponseEntity<>(body, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Object> handleAllExceptions(Exception ex) {
        Throwable root = ex;
        while (root.getCause() != null && root.getCause() != root) {
            root = root.getCause();
        }
        var body = new java.util.HashMap<String, Object>();
        body.put("status", HttpStatus.INTERNAL_SERVER_ERROR.value());
        body.put("error", root.getMessage());
        body.put("exceptionType", root.getClass().getSimpleName());
        body.put("stackTrace", root.getStackTrace());
        body.put("timestamp", java.time.LocalDateTime.now());
        return new ResponseEntity<>(body, HttpStatus.INTERNAL_SERVER_ERROR);
    }
}
