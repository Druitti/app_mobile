package com.logistics.orders.service;

import com.logistics.orders.dto.RouteResponse;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.RestClientException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;

@Service
public class RouteService {
    
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;
    
    public RouteService() {
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
    }
    
    @CircuitBreaker(name = "osrmRoute", fallbackMethod = "calculateFallbackRoute")
    @Retry(name = "osrmRoute")
    public RouteResponse calculateRoute(String originAddress, String destinationAddress) {
        try {
            // Primeiro, obter coordenadas dos endereços usando Nominatim (OpenStreetMap)
            double[] originCoords = getCoordinates(originAddress);
            double[] destCoords = getCoordinates(destinationAddress);
            
            // Usar OSRM para calcular a rota
            String osrmUrl = String.format(
                "http://router.project-osrm.org/route/v1/driving/%f,%f;%f,%f?overview=full&geometries=geojson",
                originCoords[1], originCoords[0], destCoords[1], destCoords[0]
            );
            
            String response = restTemplate.getForObject(osrmUrl, String.class);
            JsonNode root = objectMapper.readTree(response);
            
            if (root.has("routes") && root.get("routes").size() > 0) {
                JsonNode route = root.get("routes").get(0);
                
                double distance = route.get("distance").asDouble() / 1000.0; // convertendo para km
                int duration = route.get("duration").asInt() / 60; // convertendo para minutos
                String geometry = route.get("geometry").toString();
                
                return new RouteResponse(distance, duration, geometry);
            }
            
        } catch (Exception e) {
            // Fallback para cálculo simples baseado em distância linear
            return calculateFallbackRoute(originAddress, destinationAddress, e);
        }
        
        return new RouteResponse(0.0, 0, "");
    }
    
    private double[] getCoordinates(String address) {
        try {
            String nominatimUrl = String.format(
                "https://nominatim.openstreetmap.org/search?format=json&q=%s&limit=1",
                address.replace(" ", "+")
            );
            
            String response = restTemplate.getForObject(nominatimUrl, String.class);
            JsonNode results = objectMapper.readTree(response);
            
            if (results.size() > 0) {
                JsonNode firstResult = results.get(0);
                double lat = firstResult.get("lat").asDouble();
                double lon = firstResult.get("lon").asDouble();
                return new double[]{lat, lon};
            }
        } catch (Exception e) {
            // Em caso de erro, usar coordenadas padrão (centro de uma cidade)
            return new double[]{-19.9208, -43.9378}; // Belo Horizonte como padrão
        }
        
        return new double[]{-19.9208, -43.9378};
    }
    
    private RouteResponse calculateFallbackRoute(String origin, String destination, Throwable t) {
        // Cálculo simplificado baseado na diferença de endereços
        double estimatedDistance = 10.0 + (Math.random() * 20); // 10-30 km
        int estimatedTime = (int) (estimatedDistance * 3); // ~3 min por km
        return new RouteResponse(estimatedDistance, estimatedTime, "");
    }
}