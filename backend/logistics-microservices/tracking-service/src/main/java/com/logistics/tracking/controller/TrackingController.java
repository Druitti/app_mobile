package com.logistics.tracking.controller;

import com.logistics.tracking.dto.LocationUpdateRequest;
import com.logistics.tracking.dto.TrackingResponse;
import com.logistics.tracking.model.DeliveryTracking;
import com.logistics.tracking.model.Location;
import com.logistics.tracking.service.TrackingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;

@RestController
@RequestMapping("/api/tracking")
@CrossOrigin(origins = "*")
public class TrackingController {
    
    @Autowired
    private TrackingService trackingService;
    
    @PostMapping("/location")
    public ResponseEntity<Location> updateLocation(@Valid @RequestBody LocationUpdateRequest request) {
        try {
            Location location = trackingService.updateLocation(request);
            return ResponseEntity.ok(location);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    @GetMapping("/order/{orderId}")
    public ResponseEntity<TrackingResponse> getOrderTracking(@PathVariable Long orderId) {
        return trackingService.getOrderTracking(orderId)
                .map(tracking -> ResponseEntity.ok(tracking))
                .orElse(ResponseEntity.notFound().build());
    }
    
    @GetMapping("/order/{orderId}/history")
    public ResponseEntity<List<Location>> getLocationHistory(@PathVariable Long orderId) {
        List<Location> history = trackingService.getLocationHistory(orderId);
        return ResponseEntity.ok(history);
    }
    
    @GetMapping("/driver/{driverId}/history")
    public ResponseEntity<List<Location>> getDriverLocationHistory(@PathVariable Long driverId) {
        List<Location> history = trackingService.getDriverLocationHistory(driverId);
        return ResponseEntity.ok(history);
    }
    
    @GetMapping("/order/{orderId}/current")
    public ResponseEntity<Location> getCurrentLocation(@PathVariable Long orderId) {
        return trackingService.getCurrentLocation(orderId)
                .map(location -> ResponseEntity.ok(location))
                .orElse(ResponseEntity.notFound().build());
    }
    
    @GetMapping("/driver/{driverId}/current")
    public ResponseEntity<Location> getCurrentDriverLocation(@PathVariable Long driverId) {
        return trackingService.getCurrentDriverLocation(driverId)
                .map(location -> ResponseEntity.ok(location))
                .orElse(ResponseEntity.notFound().build());
    }
    
    @GetMapping("/nearby")
    public ResponseEntity<List<Location>> getNearbyDeliveries(
            @RequestParam Double latitude,
            @RequestParam Double longitude,
            @RequestParam(defaultValue = "5.0") Double radiusKm) {
        
        List<Location> nearbyDeliveries = trackingService.getNearbyDeliveries(latitude, longitude, radiusKm);
        return ResponseEntity.ok(nearbyDeliveries);
    }
    
    @PostMapping("/create")
    public ResponseEntity<DeliveryTracking> createTracking(
            @RequestParam Long orderId,
            @RequestParam Long driverId,
            @RequestParam String originAddress,
            @RequestParam String destinationAddress) {
        
        try {
            DeliveryTracking tracking = trackingService.createTracking(orderId, driverId, originAddress, destinationAddress);
            return ResponseEntity.ok(tracking);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    @PutMapping("/order/{orderId}/delivered")
    public ResponseEntity<Void> markAsDelivered(@PathVariable Long orderId) {
        try {
            trackingService.markAsDelivered(orderId);
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
}