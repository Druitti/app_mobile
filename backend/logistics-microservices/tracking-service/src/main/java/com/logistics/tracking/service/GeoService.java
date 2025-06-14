package com.logistics.tracking.service;

import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
public class GeoService {
    
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;
    
    public GeoService() {
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
    }
    
    public double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        // Fórmula de Haversine para calcular distância entre dois pontos geográficos
        final int R = 6371; // Raio da Terra em km
        
        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        
        return R * c; // Distância em km
    }
    
    public String reverseGeocode(double latitude, double longitude) {
        try {
            String nominatimUrl = String.format(
                "https://nominatim.openstreetmap.org/reverse?format=json&lat=%f&lon=%f&zoom=18&addressdetails=1",
                latitude, longitude
            );
            
            String response = restTemplate.getForObject(nominatimUrl, String.class);
            JsonNode root = objectMapper.readTree(response);
            
            if (root.has("display_name")) {
                return root.get("display_name").asText();
            }
        } catch (Exception e) {
            // Em caso de erro, retornar coordenadas
            return String.format("Lat: %.6f, Lon: %.6f", latitude, longitude);
        }
        
        return "Endereço não encontrado";
    }
    
    public boolean isNearDestination(double currentLat, double currentLon, 
                                   double destLat, double destLon, double thresholdKm) {
        double distance = calculateDistance(currentLat, currentLon, destLat, destLon);
        return distance <= thresholdKm;
    }
}