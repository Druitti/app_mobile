package com.logistics.tracking.dto;

import com.logistics.tracking.model.DeliveryTracking;
import java.time.LocalDateTime;

public class TrackingResponse {
    private Long orderId;
    private DeliveryTracking.TrackingStatus status;
    private Double currentLatitude;
    private Double currentLongitude;
    private String currentAddress;
    private Double remainingDistance;
    private Integer estimatedTimeMinutes;
    private LocalDateTime estimatedArrival;
    private LocalDateTime lastUpdate;
    
    public TrackingResponse() {}
    
    public TrackingResponse(DeliveryTracking tracking) {
        this.orderId = tracking.getOrderId();
        this.status = tracking.getStatus();
        this.currentLatitude = tracking.getCurrentLatitude();
        this.currentLongitude = tracking.getCurrentLongitude();
        this.currentAddress = tracking.getCurrentAddress();
        this.remainingDistance = tracking.getRemainingDistance();
        this.estimatedTimeMinutes = tracking.getEstimatedTimeMinutes();
        this.estimatedArrival = tracking.getEstimatedArrival();
        this.lastUpdate = tracking.getLastUpdate();
    }
    
    // Getters and Setters
    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }
    
    public DeliveryTracking.TrackingStatus getStatus() { return status; }
    public void setStatus(DeliveryTracking.TrackingStatus status) { this.status = status; }
    
    public Double getCurrentLatitude() { return currentLatitude; }
    public void setCurrentLatitude(Double currentLatitude) { this.currentLatitude = currentLatitude; }
    
    public Double getCurrentLongitude() { return currentLongitude; }
    public void setCurrentLongitude(Double currentLongitude) { this.currentLongitude = currentLongitude; }
    
    public String getCurrentAddress() { return currentAddress; }
    public void setCurrentAddress(String currentAddress) { this.currentAddress = currentAddress; }
    
    public Double getRemainingDistance() { return remainingDistance; }
    public void setRemainingDistance(Double remainingDistance) { this.remainingDistance = remainingDistance; }
    
    public Integer getEstimatedTimeMinutes() { return estimatedTimeMinutes; }
    public void setEstimatedTimeMinutes(Integer estimatedTimeMinutes) { this.estimatedTimeMinutes = estimatedTimeMinutes; }
    
    public LocalDateTime getEstimatedArrival() { return estimatedArrival; }
    public void setEstimatedArrival(LocalDateTime estimatedArrival) { this.estimatedArrival = estimatedArrival; }
    
    public LocalDateTime getLastUpdate() { return lastUpdate; }
    public void setLastUpdate(LocalDateTime lastUpdate) { this.lastUpdate = lastUpdate; }
}