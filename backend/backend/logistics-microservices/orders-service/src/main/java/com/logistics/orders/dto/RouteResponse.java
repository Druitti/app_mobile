package com.logistics.orders.dto;

public class RouteResponse {
    private Double distance;
    private Integer duration; // em minutos
    private String geometry;
    
    public RouteResponse() {}
    
    public RouteResponse(Double distance, Integer duration, String geometry) {
        this.distance = distance;
        this.duration = duration;
        this.geometry = geometry;
    }
    
    // Getters and Setters
    public Double getDistance() { return distance; }
    public void setDistance(Double distance) { this.distance = distance; }
    
    public Integer getDuration() { return duration; }
    public void setDuration(Integer duration) { this.duration = duration; }
    
    public String getGeometry() { return geometry; }
    public void setGeometry(String geometry) { this.geometry = geometry; }
}