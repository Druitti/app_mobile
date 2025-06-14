package com.logistics.orders.service;

import com.logistics.orders.dto.CreateOrderRequest;
import com.logistics.orders.dto.RouteResponse;
import com.logistics.orders.model.Order;
import com.logistics.orders.repository.OrderRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.amqp.rabbit.core.RabbitTemplate;

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
        order.setStatus(status);
        
        Order updatedOrder = orderRepository.save(order);
        
        // Publicar evento de status atualizado
        rabbitTemplate.convertAndSend("order.exchange", "order.status.updated", updatedOrder);
        
        return updatedOrder;
    }
    
    public Order assignDriver(Long orderId, Long driverId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Pedido não encontrado"));
        
        order.setDriverId(driverId);
        order.setStatus(Order.OrderStatus.ACCEPTED);
        
        Order updatedOrder = orderRepository.save(order);
        
        // Publicar evento de motorista atribuído
        rabbitTemplate.convertAndSend("order.exchange", "order.driver.assigned", updatedOrder);
        
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