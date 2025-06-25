package com.logistics.tracking.service;

import com.logistics.tracking.dto.LocationUpdateRequest;
import com.logistics.tracking.dto.TrackingResponse;
import com.logistics.tracking.model.DeliveryTracking;
import com.logistics.tracking.model.Location;
import com.logistics.tracking.repository.DeliveryTrackingRepository;
import com.logistics.tracking.repository.LocationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.amqp.rabbit.core.RabbitTemplate;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class TrackingService {
    
    @Autowired
    private LocationRepository locationRepository;
    
    @Autowired
    private DeliveryTrackingRepository deliveryTrackingRepository;
    
    @Autowired
    private GeoService geoService;
    
    @Autowired
    private RabbitTemplate rabbitTemplate;
    
    public Location updateLocation(LocationUpdateRequest request) {
        // Salvar a localização
        Location location = new Location();
        location.setOrderId(request.getOrderId());
        location.setDriverId(request.getDriverId());
        location.setLatitude(request.getLatitude());
        location.setLongitude(request.getLongitude());
        location.setSpeed(request.getSpeed());
        location.setBearing(request.getBearing());
        
        if (request.getTimestamp() != null) {
            location.setTimestamp(request.getTimestamp());
        }
        
        // Fazer reverse geocoding para obter endereço
        String address = geoService.reverseGeocode(request.getLatitude(), request.getLongitude());
        location.setAddress(address);
        
        Location savedLocation = locationRepository.save(location);
        
        // Atualizar tracking da entrega
        updateDeliveryTracking(request);
        
        // Publicar evento de localização atualizada
        rabbitTemplate.convertAndSend("tracking.exchange", "location.updated", savedLocation);
        
        return savedLocation;
    }
    
    private void updateDeliveryTracking(LocationUpdateRequest request) {
        Optional<DeliveryTracking> trackingOpt = deliveryTrackingRepository.findByOrderId(request.getOrderId());
        
        if (trackingOpt.isPresent()) {
            DeliveryTracking tracking = trackingOpt.get();
            
            // Atualizar posição atual
            tracking.setCurrentLatitude(request.getLatitude());
            tracking.setCurrentLongitude(request.getLongitude());
            tracking.setCurrentAddress(geoService.reverseGeocode(request.getLatitude(), request.getLongitude()));
            
            // Calcular distância restante
            if (tracking.getDestinationLatitude() != null && tracking.getDestinationLongitude() != null) {
                double remainingDistance = geoService.calculateDistance(
                    request.getLatitude(), request.getLongitude(),
                    tracking.getDestinationLatitude(), tracking.getDestinationLongitude()
                );
                
                tracking.setRemainingDistance(remainingDistance);
                
                // Verificar se está próximo do destino
                if (geoService.isNearDestination(
                    request.getLatitude(), request.getLongitude(),
                    tracking.getDestinationLatitude(), tracking.getDestinationLongitude(),
                    0.5 // 500 metros
                )) {
                    tracking.setStatus(DeliveryTracking.TrackingStatus.NEAR_DESTINATION);
                } else if (tracking.getStatus() == DeliveryTracking.TrackingStatus.WAITING_PICKUP) {
                    tracking.setStatus(DeliveryTracking.TrackingStatus.IN_TRANSIT);
                    tracking.setStartTime(LocalDateTime.now());
                }
                
                // Estimar tempo de chegada baseado na velocidade
                if (request.getSpeed() != null && request.getSpeed() > 0) {
                    int estimatedMinutes = (int) ((remainingDistance / request.getSpeed()) * 60);
                    tracking.setEstimatedTimeMinutes(estimatedMinutes);
                    tracking.setEstimatedArrival(LocalDateTime.now().plusMinutes(estimatedMinutes));
                }
            }
            
            deliveryTrackingRepository.save(tracking);
        }
    }
    
    public Optional<TrackingResponse> getOrderTracking(Long orderId) {
        return deliveryTrackingRepository.findByOrderId(orderId)
                .map(TrackingResponse::new);
    }
    
    public List<Location> getLocationHistory(Long orderId) {
        return locationRepository.findByOrderIdOrderByTimestampDesc(orderId);
    }
    
    public List<Location> getDriverLocationHistory(Long driverId) {
        return locationRepository.findByDriverIdOrderByTimestampDesc(driverId);
    }
    
    public Optional<Location> getCurrentLocation(Long orderId) {
        return locationRepository.findLatestLocationByOrderId(orderId);
    }
    
    public Optional<Location> getCurrentDriverLocation(Long driverId) {
        return locationRepository.findLatestLocationByDriverId(driverId);
    }
    
    public List<Location> getNearbyDeliveries(double latitude, double longitude, double radiusKm) {
        LocalDateTime since = LocalDateTime.now().minusHours(24); // Últimas 24 horas
        return locationRepository.findNearbyLocations(latitude, longitude, radiusKm, since);
    }
    
    public DeliveryTracking createTracking(Long orderId, Long driverId, 
                                         String originAddress, String destinationAddress) {
        DeliveryTracking tracking = new DeliveryTracking();
        tracking.setOrderId(orderId);
        tracking.setDriverId(driverId);
        tracking.setOriginAddress(originAddress);
        tracking.setDestinationAddress(destinationAddress);
        
        return deliveryTrackingRepository.save(tracking);
    }
    
    public void markAsDelivered(Long orderId) {
        DeliveryTracking tracking = deliveryTrackingRepository.findByOrderId(orderId)
                .orElseThrow(() -> new RuntimeException("Tracking não encontrado"));
        
        tracking.setStatus(DeliveryTracking.TrackingStatus.DELIVERED);
        tracking.setActualArrival(LocalDateTime.now());
        
        deliveryTrackingRepository.save(tracking);
        
        // Publicar evento de entrega concluída
        rabbitTemplate.convertAndSend("tracking.exchange", "delivery.completed", tracking);
    }
}