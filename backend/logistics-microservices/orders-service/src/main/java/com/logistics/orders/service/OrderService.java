package com.logistics.orders.service;

import com.logistics.orders.client.UserServiceClient;
import com.logistics.orders.dto.CreateOrderRequest;
import com.logistics.orders.dto.RouteResponse;
import com.logistics.orders.model.Order;
import com.logistics.orders.model.User;
import com.logistics.orders.repository.OrderRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import com.logistics.orders.service.*;
import java.util.List;
import java.util.Optional;

@Service
public class OrderService {
    
    @Autowired
    private OrderRepository orderRepository;
    
    @Autowired
    private RouteService routeService;
    
    @Autowired
    private RabbitTemplate rabbitTemplate;

    @Autowired
    private EmailService emailService;

    @Autowired
    private  UserServiceClient userServiceClient;

    @Autowired
    private FirebaseNotificationService firebaseNotificationService;
    
    public Order createOrder(CreateOrderRequest request) {
        Order order = new Order();
        order.setCustomerId(request.getCustomerId());
        order.setOriginAddress(request.getOriginAddress());
        order.setDestinationAddress(request.getDestinationAddress());
        order.setCargoType(request.getCargoType());
        order.setDescription(request.getDescription());
        order.setPrice(request.getPrice());
        
        // Calcular rota
        RouteResponse route = routeService.calculateRoute(
            request.getOriginAddress(), 
            request.getDestinationAddress()
        );
        
        order.setDistance(route.getDistance());
        order.setEstimatedTime(route.getDuration());
        
        Order savedOrder = orderRepository.save(order);
        
        // Publicar evento de novo pedido
        rabbitTemplate.convertAndSend("order.exchange", "order.created", savedOrder);
        
        // Notificação push para o cliente
        User customer = userServiceClient.getUserById(order.getCustomerId());
        if (customer != null && customer.getFcmToken() != null) {
            firebaseNotificationService.sendNotification(
                "Pedido criado!",
                "Seu pedido #" + savedOrder.getId() + " foi criado com sucesso!",
                customer.getFcmToken()
            );
        }
        return savedOrder;
    }
    
    public List<Order> getAllOrders() {
        return orderRepository.findAll();
    }
    
    public Optional<Order> getOrderById(Long id) {
        return orderRepository.findById(id);
    }
    
    public List<Order> getOrdersByCustomer(Long customerId) {
        return orderRepository.findByCustomerId(customerId);
    }
    
    public List<Order> getOrdersByDriver(Long driverId) {
        return orderRepository.findByDriverId(driverId);
    }
    
    public List<Order> getOrdersByStatus(Order.OrderStatus status) {
        return orderRepository.findByStatus(status);
    }
    
   public Order updateOrderStatus(Long orderId, Order.OrderStatus status) {
    Order order = orderRepository.findById(orderId)
            .orElseThrow(() -> new RuntimeException("Pedido não encontrado"));
    
    Order.OrderStatus oldStatus = order.getStatus();
    User customer = userServiceClient.getUserById(order.getCustomerId());
    User driver = userServiceClient.getUserById(order.getDriverId());

    order.setStatus(status);
    
    if(status.equals(Order.OrderStatus.DELIVERED)) {
        // Enviar email para o cliente
        String customerSubject = "Pedido Entregue - #" + order.getId();
        String customerBody = buildCustomerEmailBody(order, customer, driver);
        emailService.sendEmail(customer.getEmail(), customerSubject, customerBody);
        
        // Enviar email para o motorista
        String driverSubject = "Entrega Concluída - Pedido #" + order.getId();
        String driverBody = buildDriverEmailBody(order, customer, driver);
        emailService.sendEmail(driver.getEmail(), driverSubject, driverBody);
    }

    System.out.println("cutomer: " + customer);
    System.out.println("driver: " + customer.getFcmToken());
    
    // Notificação push para o cliente
    if (customer != null && customer.getFcmToken() != null) {
        firebaseNotificationService.sendNotification(
            "Status do pedido atualizado!",
            "O status do seu pedido #" + order.getId() + " foi alterado para " + status + ".",
            customer.getFcmToken()
        );
    }
    
    Order updatedOrder = orderRepository.save(order);
    
    // Publicar evento de status atualizado
    rabbitTemplate.convertAndSend("order.exchange", "order.status.updated", updatedOrder);
    
    return updatedOrder;
}

private String buildCustomerEmailBody(Order order, User customer, User driver) {
    return String.format(
        "Olá %s,\n\n" +
        "Seu pedido foi entregue com sucesso!\n\n" +
        "DETALHES DO PEDIDO:\n" +
        "Número do Pedido: #%d\n" +
        "Origem: %s\n" +
        "Destino: %s\n" +
        "Tipo de Carga: %s\n" +
        "Descrição: %s\n" +
        "Valor: R$ %.2f\n" +
        "Distância: %.2f km\n" +
        "Data de Criação: %s\n" +
        "Data de Entrega: %s\n\n" +
        "MOTORISTA RESPONSÁVEL:\n" +
        "Nome: %s\n" +
        "Email: %s\n\n" +
        "Obrigado por escolher nossos serviços!\n\n" +
        "Atenciosamente,\n" +
        "Equipe de Logística",
        
        customer.getFirstName(),
        order.getId(),
        order.getOriginAddress(),
        order.getDestinationAddress(),
        order.getCargoType(),
        order.getDescription(),
        order.getPrice(),
        order.getDistance(),
        order.getCreatedAt().toString(),
        order.getUpdatedAt().toString(),
        driver.getLastName(),
        driver.getEmail()
    );
}

private String buildDriverEmailBody(Order order, User customer, User driver) {
    return String.format(
        "Olá %s,\n\n" +
        "Entrega concluída com sucesso!\n\n" +
        "DETALHES DO PEDIDO:\n" +
        "Número do Pedido: #%d\n" +
        "Origem: %s\n" +
        "Destino: %s\n" +
        "Tipo de Carga: %s\n" +
        "Descrição: %s\n" +
        "Valor: R$ %.2f\n" +
        "Distância: %.2f km\n" +
        "Data de Criação: %s\n" +
        "Data de Entrega: %s\n\n" +
        "CLIENTE:\n" +
        "Nome: %s %s\n" +
        "Email: %s\n\n" +
        "Parabéns pela entrega realizada!\n\n" +
        "Atenciosamente,\n" +
        "Equipe de Logística",
        
        driver.getFirstName(),
        order.getId(),
        order.getOriginAddress(),
        order.getDestinationAddress(),
        order.getCargoType(),
        order.getDescription(),
        order.getPrice(),
        order.getDistance(),
        order.getCreatedAt().toString(),
        order.getUpdatedAt().toString(),
        customer.getFirstName(),
        customer.getLastName(),
        customer.getEmail()
    );
}
    
    public Order assignDriver(Long orderId, Long driverId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Pedido não encontrado"));
        
        order.setDriverId(driverId);
        order.setStatus(Order.OrderStatus.ACCEPTED);
        
        Order updatedOrder = orderRepository.save(order);
        
        // Publicar evento de motorista atribuído
        rabbitTemplate.convertAndSend("order.exchange", "order.driver.assigned", updatedOrder);
        
        // Notificação push para o motorista
        User driver = userServiceClient.getUserById(driverId);
        if (driver != null && driver.getFcmToken() != null) {
            firebaseNotificationService.sendNotification(
                "Pedido aceito!",
                "Você aceitou o pedido #" + order.getId() + ".",
                driver.getFcmToken()
            );
        }
        return updatedOrder;
    }
    
    public void cancelOrder(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Pedido não encontrado"));
        
        order.setStatus(Order.OrderStatus.CANCELLED);
        orderRepository.save(order);
        
        // Publicar evento de cancelamento
        rabbitTemplate.convertAndSend("order.exchange", "order.cancelled", order);
    }
}