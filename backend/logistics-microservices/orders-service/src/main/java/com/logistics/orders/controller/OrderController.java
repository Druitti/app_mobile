package com.logistics.orders.controller;

import com.logistics.orders.dto.CreateOrderRequest;
import com.logistics.orders.model.Order;
import com.logistics.orders.service.OrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@RestController
@RequestMapping("/api/orders")
@Tag(name = "Order Management", description = "APIs para gerenciamento de pedidos do sistema de logística")
public class OrderController {
    
    private static final Logger logger = LoggerFactory.getLogger(OrderController.class);
    
    @Autowired
    private OrderService orderService;
    
    @PostMapping
    @Operation(
        summary = "Criar novo pedido",
        description = "Cria um novo pedido no sistema de logística com as informações fornecidas"
    )
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Pedido criado com sucesso",
                    content = @Content(schema = @Schema(implementation = Order.class))),
        @ApiResponse(responseCode = "400", description = "Dados inválidos fornecidos",
                    content = @Content)
    })
    public ResponseEntity<Order> createOrder(
            @Parameter(description = "Dados do pedido a ser criado", required = true)
            @Valid @RequestBody CreateOrderRequest request) {
        logger.info("Iniciando criação de pedido: {}", request);
        try {
            Order order = orderService.createOrder(request);
            logger.info("Pedido criado com sucesso - ID: {}", order.getId());
            return ResponseEntity.ok(order);
        } catch (Exception e) {
            logger.error("Erro ao criar pedido: {}", e.getMessage(), e);
            return ResponseEntity.badRequest().build();
        }
    }
    
    @GetMapping
    @Operation(
        summary = "Listar todos os pedidos",
        description = "Retorna uma lista com todos os pedidos cadastrados no sistema"
    )
    @ApiResponse(responseCode = "200", description = "Lista de pedidos retornada com sucesso",
                content = @Content(schema = @Schema(implementation = Order.class)))
    public ResponseEntity<List<Order>> getAllOrders() {
        logger.info("Buscando todos os pedidos");
        List<Order> orders = orderService.getAllOrders();
        logger.info("Encontrados {} pedidos", orders.size());
        return ResponseEntity.ok(orders);
    }
    
    @GetMapping("/{id}")
    @Operation(
        summary = "Buscar pedido por ID",
        description = "Retorna um pedido específico baseado no ID fornecido"
    )
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Pedido encontrado",
                    content = @Content(schema = @Schema(implementation = Order.class))),
        @ApiResponse(responseCode = "404", description = "Pedido não encontrado",
                    content = @Content)
    })
    public ResponseEntity<Order> getOrderById(
            @Parameter(description = "ID do pedido", required = true, example = "1")
            @PathVariable Long id) {
        logger.info("Buscando pedido por ID: {}", id);
        return orderService.getOrderById(id)
                .map(order -> {
                    logger.info("Pedido encontrado - ID: {} Status: {}", order.getId(), order.getStatus());
                    return ResponseEntity.ok(order);
                })
                .orElseGet(() -> {
                    logger.warn("Pedido não encontrado - ID: {}", id);
                    return ResponseEntity.notFound().build();
                });
    }
    
    @GetMapping("/customer/{customerId}")
    @Operation(
        summary = "Buscar pedidos por cliente",
        description = "Retorna todos os pedidos associados a um cliente específico"
    )
    @ApiResponse(responseCode = "200", description = "Lista de pedidos do cliente retornada com sucesso",
                content = @Content(schema = @Schema(implementation = Order.class)))
    public ResponseEntity<List<Order>> getOrdersByCustomer(
            @Parameter(description = "ID do cliente", required = true, example = "123")
            @PathVariable Long customerId) {
        logger.info("Buscando pedidos por cliente ID: {}", customerId);
        List<Order> orders = orderService.getOrdersByCustomer(customerId);
        logger.info("Encontrados {} pedidos para cliente ID: {}", orders.size(), customerId);
        return ResponseEntity.ok(orders);
    }
    
    @GetMapping("/driver/{driverId}")
    @Operation(
        summary = "Buscar pedidos por motorista",
        description = "Retorna todos os pedidos atribuídos a um motorista específico"
    )
    @ApiResponse(responseCode = "200", description = "Lista de pedidos do motorista retornada com sucesso",
                content = @Content(schema = @Schema(implementation = Order.class)))
    public ResponseEntity<List<Order>> getOrdersByDriver(
            @Parameter(description = "ID do motorista", required = true, example = "456")
            @PathVariable Long driverId) {
        logger.info("Buscando pedidos por motorista ID: {}", driverId);
        List<Order> orders = orderService.getOrdersByDriver(driverId);
        logger.info("Encontrados {} pedidos para motorista ID: {}", orders.size(), driverId);
        return ResponseEntity.ok(orders);
    }
    
    @GetMapping("/status/{status}")
    @Operation(
        summary = "Buscar pedidos por status",
        description = "Retorna todos os pedidos que possuem um status específico"
    )
    @ApiResponse(responseCode = "200", description = "Lista de pedidos com o status especificado",
                content = @Content(schema = @Schema(implementation = Order.class)))
    public ResponseEntity<List<Order>> getOrdersByStatus(
            @Parameter(description = "Status do pedido", required = true, 
                      schema = @Schema(implementation = Order.OrderStatus.class))
            @PathVariable Order.OrderStatus status) {
        logger.info("Buscando pedidos por status: {}", status);
        List<Order> orders = orderService.getOrdersByStatus(status);
        logger.info("Encontrados {} pedidos com status: {}", orders.size(), status);
        return ResponseEntity.ok(orders);
    }
    
    @PutMapping("/{id}/status")
    @Operation(
        summary = "Atualizar status do pedido",
        description = "Atualiza o status de um pedido específico"
    )
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Status atualizado com sucesso",
                    content = @Content(schema = @Schema(implementation = Order.class))),
        @ApiResponse(responseCode = "404", description = "Pedido não encontrado",
                    content = @Content)
    })
    public ResponseEntity<Order> updateOrderStatus(
            @Parameter(description = "ID do pedido", required = true, example = "1")
            @PathVariable Long id,
            @Parameter(description = "Novo status do pedido", required = true,
                      schema = @Schema(implementation = Order.OrderStatus.class))
            @RequestParam Order.OrderStatus status) {
        
        logger.info("=== INICIANDO ATUALIZAÇÃO DE STATUS ===");
        logger.info("Pedido ID recebido: {}", id);
        logger.info("Novo status recebido: {}", status);
        logger.info("Tipo do ID: {}", id != null ? id.getClass().getSimpleName() : "null");
        logger.info("Tipo do status: {}", status != null ? status.getClass().getSimpleName() : "null");
        
        try {
            logger.info("Chamando orderService.updateOrderStatus({}, {})", id, status);
            Order order = orderService.updateOrderStatus(id, status);
            
            logger.info("Status atualizado com sucesso!");
            logger.info("Pedido ID: {}", order.getId());
            logger.info("Status anterior -> atual: {}", order.getStatus());
            logger.info("=== FIM DA ATUALIZAÇÃO - SUCESSO ===");
            
            return ResponseEntity.ok(order);
            
        } catch (RuntimeException e) {
            logger.error("=== ERRO DURANTE ATUALIZAÇÃO ===");
            logger.error("Tipo da exceção: {}", e.getClass().getSimpleName());
            logger.error("Mensagem do erro: {}", e.getMessage());
            logger.error("Stack trace completo:", e);
            logger.error("=== FIM DO ERRO ===");
            
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("=== ERRO INESPERADO ===");
            logger.error("Tipo da exceção: {}", e.getClass().getSimpleName());
            logger.error("Mensagem do erro: {}", e.getMessage());
            logger.error("Stack trace completo:", e);
            logger.error("=== FIM DO ERRO INESPERADO ===");
            
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @PutMapping("/{id}/assign-driver")
    @Operation(
        summary = "Atribuir motorista ao pedido",
        description = "Atribui um motorista específico a um pedido"
    )
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Motorista atribuído com sucesso",
                    content = @Content(schema = @Schema(implementation = Order.class))),
        @ApiResponse(responseCode = "404", description = "Pedido ou motorista não encontrado",
                    content = @Content)
    })
    public ResponseEntity<Order> assignDriver(
            @Parameter(description = "ID do pedido", required = true, example = "1")
            @PathVariable Long id,
            @Parameter(description = "ID do motorista", required = true, example = "456")
            @RequestParam Long driverId) {
        
        logger.info("Atribuindo motorista - Pedido ID: {}, Motorista ID: {}", id, driverId);
        
        try {
            Order order = orderService.assignDriver(id, driverId);
            logger.info("Motorista atribuído com sucesso - Pedido ID: {}, Motorista ID: {}", 
                       order.getId(), order.getDriverId());
            return ResponseEntity.ok(order);
        } catch (RuntimeException e) {
            logger.error("Erro ao atribuir motorista - Pedido ID: {}, Motorista ID: {}, Erro: {}", 
                        id, driverId, e.getMessage(), e);
            return ResponseEntity.notFound().build();
        }
    }
    
    @DeleteMapping("/{id}")
    @Operation(
        summary = "Cancelar pedido",
        description = "Cancela um pedido específico, removendo-o do sistema"
    )
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Pedido cancelado com sucesso"),
        @ApiResponse(responseCode = "404", description = "Pedido não encontrado",
                    content = @Content)
    })
    public ResponseEntity<Void> cancelOrder(
            @Parameter(description = "ID do pedido a ser cancelado", required = true, example = "1")
            @PathVariable Long id) {
        
        logger.info("Cancelando pedido ID: {}", id);
        
        try {
            orderService.cancelOrder(id);
            logger.info("Pedido cancelado com sucesso - ID: {}", id);
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            logger.error("Erro ao cancelar pedido ID: {}, Erro: {}", id, e.getMessage(), e);
            return ResponseEntity.notFound().build();
        }
    }
}