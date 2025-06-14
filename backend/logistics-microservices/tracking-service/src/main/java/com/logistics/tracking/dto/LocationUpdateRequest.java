package com.logistics.tracking.dto;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDateTime;

public class LocationUpdateRequest {
    @NotNull
    private Long orderId;
    
    @NotNull
    private Long driverId;
    
    @NotNull
    private Double latitude;
    
    @NotNull
    private Double longitude;
    
    private Double speed;
    private Double bearing;
    private LocalDateTime timestamp;
    
    // Constructors, Getters and Setters
    public LocationUpdateRequest() {}
    
    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }
    
    public Long getDriverId() { return driverId; }
    public void setDriverId(Long driverId) { this.driverId = driverId; }
    
    public Double getLatitude() { return latitude; }
    public void setLatitude(Double latitude) { this.latitude = latitude; }
    
    public Double getLongitude() { return longitude; }
    public void setLongitude(Double longitude) { this.longitude = longitude; }
    
    public Double getSpeed() { return speed; }
    public void setSpeed(Double speed) { this.speed = speed; }
    
    public Double getBearing() { return bearing; }
    public void setBearing(Double bearing) { this.bearing = bearing; }
    
    public LocalDateTime getTimestamp() { return timestamp; }
    public void setTimestamp(LocalDateTime timestamp) { this.timestamp = timestamp; }
}