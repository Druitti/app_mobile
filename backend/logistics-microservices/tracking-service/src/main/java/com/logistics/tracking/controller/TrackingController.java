package com.logistics.tracking.controller;

import com.logistics.tracking.dto.LocationUpdateRequest;
import com.logistics.tracking.dto.TrackingResponse;
import com.logistics.tracking.model.DeliveryTracking;
import com.logistics.tracking.model.Location;
import com.logistics.tracking.service.TrackingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tracking")
@CrossOrigin(origins = "*")
@Tag(name = "Tracking", description = "Endpoints de rastreamento de entregas")
public class TrackingController {

    @Autowired
    private TrackingService trackingService;

    @Operation(summary = "Atualiza a localização de uma entrega")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Localização atualizada com sucesso",
            content = @Content(schema = @Schema(implementation = Location.class))),
        @ApiResponse(responseCode = "400", description = "Requisição inválida")
    })
    @PostMapping("/location")
    public ResponseEntity<Location> updateLocation(@Valid @RequestBody LocationUpdateRequest request) {
        try {
            Location location = trackingService.updateLocation(request);
            return ResponseEntity.ok(location);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @Operation(summary = "Obtém informações de rastreamento de um pedido")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Informações de rastreamento retornadas com sucesso"),
        @ApiResponse(responseCode = "404", description = "Pedido não encontrado")
    })
    @GetMapping("/order/{orderId}")
    public ResponseEntity<TrackingResponse> getOrderTracking(
            @Parameter(description = "ID do pedido") @PathVariable Long orderId) {
        return trackingService.getOrderTracking(orderId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @Operation(summary = "Obtém o histórico de localizações de um pedido")
    @GetMapping("/order/{orderId}/history")
    public ResponseEntity<List<Location>> getLocationHistory(
            @Parameter(description = "ID do pedido") @PathVariable Long orderId) {
        List<Location> history = trackingService.getLocationHistory(orderId);
        return ResponseEntity.ok(history);
    }

    @Operation(summary = "Obtém o histórico de localizações de um motorista")
    @GetMapping("/driver/{driverId}/history")
    public ResponseEntity<List<Location>> getDriverLocationHistory(
            @Parameter(description = "ID do motorista") @PathVariable Long driverId) {
        List<Location> history = trackingService.getDriverLocationHistory(driverId);
        return ResponseEntity.ok(history);
    }

    @Operation(summary = "Obtém a localização atual de um pedido")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Localização atual retornada"),
        @ApiResponse(responseCode = "404", description = "Pedido não encontrado")
    })
    @GetMapping("/order/{orderId}/current")
    public ResponseEntity<Location> getCurrentLocation(
            @Parameter(description = "ID do pedido") @PathVariable Long orderId) {
        return trackingService.getCurrentLocation(orderId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @Operation(summary = "Obtém a localização atual de um motorista")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Localização atual retornada"),
        @ApiResponse(responseCode = "404", description = "Motorista não encontrado")
    })
    @GetMapping("/driver/{driverId}/current")
    public ResponseEntity<Location> getCurrentDriverLocation(
            @Parameter(description = "ID do motorista") @PathVariable Long driverId) {
        return trackingService.getCurrentDriverLocation(driverId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @Operation(summary = "Obtém entregas próximas a uma coordenada")
    @GetMapping("/nearby")
    public ResponseEntity<List<Location>> getNearbyDeliveries(
            @Parameter(description = "Latitude de referência") @RequestParam Double latitude,
            @Parameter(description = "Longitude de referência") @RequestParam Double longitude,
            @Parameter(description = "Raio em quilômetros", example = "5.0") @RequestParam(defaultValue = "5.0") Double radiusKm) {
        
        List<Location> nearbyDeliveries = trackingService.getNearbyDeliveries(latitude, longitude, radiusKm);
        return ResponseEntity.ok(nearbyDeliveries);
    }

    @Operation(summary = "Cria o rastreamento de uma nova entrega")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Rastreamento criado com sucesso"),
        @ApiResponse(responseCode = "400", description = "Erro ao criar rastreamento")
    })
    @PostMapping("/create")
    public ResponseEntity<DeliveryTracking> createTracking(
            @Parameter(description = "ID do pedido") @RequestParam Long orderId,
            @Parameter(description = "ID do motorista") @RequestParam Long driverId,
            @Parameter(description = "Endereço de origem") @RequestParam String originAddress,
            @Parameter(description = "Endereço de destino") @RequestParam String destinationAddress) {
        
        try {
            DeliveryTracking tracking = trackingService.createTracking(orderId, driverId, originAddress, destinationAddress);
            return ResponseEntity.ok(tracking);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @Operation(summary = "Marca um pedido como entregue")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Pedido marcado como entregue"),
        @ApiResponse(responseCode = "404", description = "Pedido não encontrado")
    })
    @PutMapping("/order/{orderId}/delivered")
    public ResponseEntity<Void> markAsDelivered(
            @Parameter(description = "ID do pedido") @PathVariable Long orderId) {
        try {
            trackingService.markAsDelivered(orderId);
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
}
