package com.logistics.orders.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.logistics.orders.dto.CreateOrderRequest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
public class OrderControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    public void testCreateOrderBadRequest() throws Exception {
        CreateOrderRequest request = new CreateOrderRequest();
        // Não preenche campos obrigatórios para forçar erro de validação
        mockMvc.perform(post("/api/orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void testGetAllOrders() throws Exception {
        mockMvc.perform(get("/api/orders"))
                .andExpect(status().isOk());
    }

    @Test
    public void testGetOrderByIdNotFound() throws Exception {
        mockMvc.perform(get("/api/orders/999999"))
                .andExpect(status().isNotFound());
    }

    @Test
    public void testGetOrdersByCustomer() throws Exception {
        mockMvc.perform(get("/api/orders/customer/1"))
                .andExpect(status().isOk());
    }

    @Test
    public void testGetOrdersByDriver() throws Exception {
        mockMvc.perform(get("/api/orders/driver/1"))
                .andExpect(status().isOk());
    }

    @Test
    public void testGetOrdersByStatus() throws Exception {
        mockMvc.perform(get("/api/orders/status/PENDING"))
                .andExpect(status().isOk());
    }

    @Test
    public void testUpdateOrderStatusNotFound() throws Exception {
        mockMvc.perform(put("/api/orders/999999/status")
                .param("status", "DELIVERED"))
                .andExpect(status().isNotFound());
    }

    @Test
    public void testAssignDriverNotFound() throws Exception {
        mockMvc.perform(put("/api/orders/999999/assign-driver")
                .param("driverId", "1"))
                .andExpect(status().isNotFound());
    }

    @Test
    public void testCancelOrderNotFound() throws Exception {
        mockMvc.perform(delete("/api/orders/999999"))
                .andExpect(status().isNotFound());
    }
}
