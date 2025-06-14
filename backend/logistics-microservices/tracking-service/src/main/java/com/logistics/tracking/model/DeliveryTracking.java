package com.logistics.tracking.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "delivery_tracking")
public class DeliveryTracking {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(unique = true)
    private Long orderId;
    
    private Long driverId;
    
    @Enumerated(EnumType.STRING)
    private TrackingStatus status;
    
    private Double currentLatitude;
    private Double currentLongitude;
    private String currentAddress;
    
    private Double originLatitude;
    private Double originLongitude;
    private String originAddress;
    
    private Double destinationLatitude;
    private Double destinationLongitude;
    private String destinationAddress;
    
    private LocalDateTime startTime;
    private LocalDateTime estimatedArrival;
    private LocalDateTime actualArrival;
    
    private Double totalDistance;
    private Double remainingDistance;
    private Integer estimatedTimeMinutes;
    
    private LocalDateTime lastUpdate;
    private LocalDateTime createdAt;
    
    public enum TrackingStatus {
        WAITING_PICKUP, IN_TRANSIT, NEAR_DESTINATION, DELIVERED, DELAYED
    }
    
    // Constructors
    public DeliveryTracking() {
        this.status = TrackingStatus.WAITING_PICKUP;
        this.createdAt = LocalDateTime.now();
        this.lastUpdate = LocalDateTime.now();
    }
    
    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }
    
    public Long getDriverId() { return driverId; }
    public void setDriverId(Long driverId) { this.driverId = driverId; }
    
    public TrackingStatus getStatus() { return status; }
    public void setStatus(TrackingStatus status) { 
        this.status = status;
        this.lastUpdate = LocalDateTime.now();
    }
    
    public Double getCurrentLatitude() { return currentLatitude; }
    public void setCurrentLatitude(Double currentLatitude) { this.currentLatitude = currentLatitude; }
    
    public Double getCurrentLongitude() { return currentLongitude; }
    public void setCurrentLongitude(Double currentLongitude) { this.currentLongitude = currentLongitude; }
    
    public String getCurrentAddress() { return currentAddress; }
    public void setCurrentAddress(String currentAddress) { this.currentAddress = currentAddress; }
    
    public Double getOriginLatitude() { return originLatitude; }
    public void setOriginLatitude(Double originLatitude) { this.originLatitude = originLatitude; }
    
    public Double getOriginLongitude() { return originLongitude; }
    public void setOriginLongitude(Double originLongitude) { this.originLongitude = originLongitude; }
    
    public String getOriginAddress() { return originAddress; }
    public void setOriginAddress(String originAddress) { this.originAddress = originAddress; }
    
    public Double getDestinationLatitude() { return destinationLatitude; }
    public void setDestinationLatitude(Double destinationLatitude) { this.destinationLatitude = destinationLatitude; }
    
    public Double getDestinationLongitude() { return destinationLongitude; }
    public void setDestinationLongitude(Double destinationLongitude) { this.destinationLongitude = destinationLongitude; }
    
    public String getDestinationAddress() { return destinationAddress; }
    public void setDestinationAddress(String destinationAddress) { this.destinationAddress = destinationAddress; }
    
    public LocalDateTime getStartTime() { return startTime; }
    public void setStartTime(LocalDateTime startTime) { this.startTime = startTime; }
    
    public LocalDateTime getEstimatedArrival() { return estimatedArrival; }
    public void setEstimatedArrival(LocalDateTime estimatedArrival) { this.estimatedArrival = estimatedArrival; }
    
    public LocalDateTime getActualArrival() { return actualArrival; }
    public void setActualArrival(LocalDateTime actualArrival) { this.actualArrival = actualArrival; }
    
    public Double getTotalDistance() { return totalDistance; }
    public void setTotalDistance(Double totalDistance) { this.totalDistance = totalDistance; }
    
    public Double getRemainingDistance() { return remainingDistance; }
    public void setRemainingDistance(Double remainingDistance) { this.remainingDistance = remainingDistance; }
    
    public Integer getEstimatedTimeMinutes() { return estimatedTimeMinutes; }
    public void setEstimatedTimeMinutes(Integer estimatedTimeMinutes) { this.estimatedTimeMinutes = estimatedTimeMinutes; }
    
    public LocalDateTime getLastUpdate() { return lastUpdate; }
    public void setLastUpdate(LocalDateTime lastUpdate) { this.lastUpdate = lastUpdate; }
    
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}