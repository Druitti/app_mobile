package com.logistics.auth.controller;

import com.logistics.auth.dto.AuthResponse;
import com.logistics.auth.dto.LoginRequest;
import com.logistics.auth.dto.RegisterRequest;
import com.logistics.auth.model.User;
import com.logistics.auth.service.AuthService;
import com.logistics.auth.service.JwtService;
import io.jsonwebtoken.Claims;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@Tag(name = "Autenticação", description = "APIs para autenticação e gerenciamento de usuários")
public class AuthController {
    
    @Autowired
    private AuthService authService;
    
    @Autowired
    private JwtService jwtService;
    
    @Operation(
        summary = "Registrar novo perfil",
        description = "Registra um novo usuário no sistema e retorna o token de autenticação"
    )
    @ApiResponses(value = {
        @ApiResponse(
            responseCode = "200",
            description = "Usuário registrado com sucesso",
            content = @Content(
                mediaType = MediaType.APPLICATION_JSON_VALUE,
                schema = @Schema(implementation = AuthResponse.class),
                examples = @ExampleObject(
                    name = "Registro bem-sucedido",
                    value = """
                        {
                            "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                            "email": "usuario@exemplo.com",
                            "userType": "USER",
                            "message": "Usuário registrado com sucesso"
                        }
                        """
                )
            )
        ),
        @ApiResponse(
            responseCode = "400",
            description = "Dados inválidos ou usuário já existe",
            content = @Content(
                mediaType = MediaType.APPLICATION_JSON_VALUE,
                examples = @ExampleObject(
                    name = "Erro de validação",
                    value = """
                        {
                            "error": "Email já está em uso",
                            "timestamp": "2025-06-16T10:30:00"
                        }
                        """
                )
            )
        )
    })
    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(
        @io.swagger.v3.oas.annotations.parameters.RequestBody(
            description = "Dados para registro do usuário",
            required = true,
            content = @Content(
                mediaType = MediaType.APPLICATION_JSON_VALUE,
                schema = @Schema(implementation = RegisterRequest.class),
                examples = @ExampleObject(
                    name = "Exemplo de registro",
                    value = """
                       {
  "firstName": "João",
  "lastName":"Silva",
  "phone":"31122323344",
  "email": "joao@exemplo.com",
  "password": "senha123",
  "userType":"CUSTOMER"
}
                        """
                )
            )
        )
        @Valid @RequestBody RegisterRequest request
    ) {
        AuthResponse response = authService.register(request);
        return ResponseEntity.ok(response);
    }
    
    @Operation(
        summary = "Fazer login",
        description = "Autentica um usuário e retorna o token de acesso"
    )
    @ApiResponses(value = {
        @ApiResponse(
            responseCode = "200",
            description = "Login realizado com sucesso",
            content = @Content(
                mediaType = MediaType.APPLICATION_JSON_VALUE,
                schema = @Schema(implementation = AuthResponse.class),
                examples = @ExampleObject(
                    name = "Login bem-sucedido",
                    value = """
                        {
                            "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                            "email": "usuario@exemplo.com",
                            "userType": "USER",
                            "message": "Login realizado com sucesso"
                        }
                        """
                )
            )
        ),
        @ApiResponse(
            responseCode = "400",
            description = "Credenciais inválidas",
            content = @Content(
                mediaType = MediaType.APPLICATION_JSON_VALUE,
                examples = @ExampleObject(
                    name = "Erro de autenticação",
                    value = """
                        {
                            "error": "Email ou senha incorretos",
                            "timestamp": "2025-06-16T10:30:00"
                        }
                        """
                )
            )
        )
    })
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(
        @io.swagger.v3.oas.annotations.parameters.RequestBody(
            description = "Credenciais para login",
            required = true,
            content = @Content(
                mediaType = MediaType.APPLICATION_JSON_VALUE,
                schema = @Schema(implementation = LoginRequest.class),
                examples = @ExampleObject(
                    name = "Exemplo de login",
                    value = """
                        {
                            "email": "joao@exemplo.com",
                            "password": "senha123"
                        }
                        """
                )
            )
        )
        @Valid @RequestBody LoginRequest request
    ) {
        AuthResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }
    
    @Operation(
        summary = "Validar token JWT",
        description = "Valida um token JWT e retorna as informações do usuário se válido"
    )
    @ApiResponses(value = {
        @ApiResponse(
            responseCode = "200",
            description = "Token validado (pode ser válido ou inválido)",
            content = @Content(
                mediaType = MediaType.APPLICATION_JSON_VALUE,
                examples = {
                    @ExampleObject(
                        name = "Token válido",
                        value = """
                            {
                                "valid": true,
                                "userId": "123",
                                "email": "usuario@exemplo.com",
                                "userType": "USER"
                            }
                            """
                    ),
                    @ExampleObject(
                        name = "Token inválido",
                        value = """
                            {
                                "valid": false
                            }
                            """
                    )
                }
            )
        )
    })
    @PostMapping("/validate")
    public ResponseEntity<Map<String, Object>> validateToken(
        @Parameter(
            description = "Token JWT para validação",
            required = true,
            example = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
        )
        @RequestParam String token
    ) {
        Map<String, Object> response = new HashMap<>();
        boolean isValid = authService.validateToken(token);
        response.put("valid", isValid);
        if (isValid) {
            Claims claims = jwtService.getClaimsFromToken(token);
            response.put("userId", claims.get("userId"));
            response.put("email", claims.get("email"));
            response.put("userType", claims.get("userType"));
        }
        return ResponseEntity.ok(response);
    }
    
    @Operation(
        summary = "Buscar usuário por ID",
        description = "Retorna os dados de um usuário específico pelo seu ID"
    )
    @ApiResponses(value = {
        @ApiResponse(
            responseCode = "200",
            description = "Usuário encontrado com sucesso",
            content = @Content(
                mediaType = MediaType.APPLICATION_JSON_VALUE,
                schema = @Schema(implementation = User.class),
                examples = @ExampleObject(
                    name = "Usuário encontrado",
                    value = """
                        {
                            "id": 123,
                            "email": "joao@exemplo.com",
                            "firstName": "João",
                            "lastName": "Silva",
                            "phone": "(11) 99999-9999",
                            "userType": "USER",
                            "createdAt": "2025-06-16T10:30:00",
                            "updatedAt": "2025-06-16T10:30:00"
                        }
                        """
                )
            )
        ),
        @ApiResponse(
            responseCode = "404",
            description = "Usuário não encontrado",
            content = @Content(
                mediaType = MediaType.APPLICATION_JSON_VALUE,
                examples = @ExampleObject(
                    name = "Usuário não encontrado",
                    value = """
                        {
                            "error": "Usuário não encontrado",
                            "timestamp": "2025-06-16T10:30:00"
                        }
                        """
                )
            )
        )
    })
    @GetMapping("/user/{id}")
    public ResponseEntity<User> getUserById(
        @Parameter(
            description = "ID do usuário",
            required = true,
            example = "123"
        )
        @PathVariable Long id
    ) {
        User user = authService.getUserById(id);
        return ResponseEntity.ok(user);
    }
}