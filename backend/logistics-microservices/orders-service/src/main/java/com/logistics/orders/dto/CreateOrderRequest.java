package com.logistics.orders.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public class CreateOrderRequest {
    @NotNull(message = "O ID do cliente é obrigatório")
    private Long customerId;
    
    @NotBlank(message = "O endereço de origem é obrigatório")
    private String originAddress;
    
    @NotBlank(message = "O endereço de destino é obrigatório")
    private String destinationAddress;
    
    private String cargoType;
    private String description;
    private BigDecimal price;
    
    // Constructors, Getters and Setters
    public CreateOrderRequest() {}
    
    public Long getCustomerId() { return customerId; }
    public void setCustomerId(Long customerId) { this.customerId = customerId; }
    
    public String getOriginAddress() { return originAddress; }
    public void setOriginAddress(String originAddress) { this.originAddress = originAddress; }
    
    public String getDestinationAddress() { return destinationAddress; }
    public void setDestinationAddress(String destinationAddress) { this.destinationAddress = destinationAddress; }
    
    public String getCargoType() { return cargoType; }
    public void setCargoType(String cargoType) { this.cargoType = cargoType; }
    
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    
    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }
}