package com.logistics.orders.repository;

import com.logistics.orders.model.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    List<Order> findByCustomerId(Long customerId);
    List<Order> findByDriverId(Long driverId);
    List<Order> findByStatus(Order.OrderStatus status);
    List<Order> findByCustomerIdAndStatus(Long customerId, Order.OrderStatus status);
}