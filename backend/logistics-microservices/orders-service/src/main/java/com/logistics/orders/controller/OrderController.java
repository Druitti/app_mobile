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

@RestController
@RequestMapping("/api/orders")
@Tag(name = "Order Management", description = "APIs para gerenciamento de pedidos do sistema de logística")
public class OrderController {
    
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
        try {
            Order order = orderService.createOrder(request);
            return ResponseEntity.ok(order);
        } catch (Exception e) {
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
        List<Order> orders = orderService.getAllOrders();
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
        return orderService.getOrderById(id)
                .map(order -> ResponseEntity.ok(order))
                .orElse(ResponseEntity.notFound().build());
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
        List<Order> orders = orderService.getOrdersByCustomer(customerId);
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
        List<Order> orders = orderService.getOrdersByDriver(driverId);
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
        List<Order> orders = orderService.getOrdersByStatus(status);
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
        try {
            Order order = orderService.updateOrderStatus(id, status);
            return ResponseEntity.ok(order);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
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
        try {
            Order order = orderService.assignDriver(id, driverId);
            return ResponseEntity.ok(order);
        } catch (RuntimeException e) {
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
        try {
            orderService.cancelOrder(id);
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
}