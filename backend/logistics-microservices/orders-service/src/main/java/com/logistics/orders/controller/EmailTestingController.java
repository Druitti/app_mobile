package com.logistics.orders.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.logistics.orders.model.Order;
import com.logistics.orders.service.EmailService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;

@RestController
@Tag(name = "Email Management", description = "APIs para gerenciamento de pedidos do sistema de logística")
public class EmailTestingController {
    private final EmailService emailService;

    public EmailTestingController(EmailService emailService) {
        this.emailService = emailService;
    }

     @Operation(
        summary = "enviar email de teste",
        description = "envia email"
    )
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Email enviado com sucesso",
                    content = @Content(schema = @Schema(implementation = Order.class))),
    })
    @RequestMapping("/send-test-email")
    public String sendEmailTest(){
        emailService.sendEmail("pedroafranco1313@gmail.com", "testando api", "isso é um email de teste");
        return "Email test sent successfully";
    }

    
    
}
