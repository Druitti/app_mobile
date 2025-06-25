package com.logistics.tracking.repository;

import com.logistics.tracking.model.Location;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface LocationRepository extends JpaRepository<Location, Long> {
    List<Location> findByOrderIdOrderByTimestampDesc(Long orderId);
    List<Location> findByDriverIdOrderByTimestampDesc(Long driverId);
    
    @Query("SELECT l FROM Location l WHERE l.orderId = :orderId ORDER BY l.timestamp DESC LIMIT 1")
    Optional<Location> findLatestLocationByOrderId(@Param("orderId") Long orderId);
    
    @Query("SELECT l FROM Location l WHERE l.driverId = :driverId ORDER BY l.timestamp DESC LIMIT 1")
    Optional<Location> findLatestLocationByDriverId(@Param("driverId") Long driverId);
    
    @Query("SELECT l FROM Location l WHERE l.orderId = :orderId AND l.timestamp BETWEEN :startTime AND :endTime ORDER BY l.timestamp")
    List<Location> findLocationHistoryByOrderAndTimeRange(
            @Param("orderId") Long orderId,
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime
    );
    
    // Função para encontrar entregas próximas (usando fórmula de Haversine simplificada)
    @Query(value = """
        SELECT l.* FROM locations l 
        WHERE (6371 * acos(cos(radians(:latitude)) * cos(radians(l.latitude)) * 
               cos(radians(l.longitude) - radians(:longitude)) + 
               sin(radians(:latitude)) * sin(radians(l.latitude)))) <= :radiusKm
        AND l.timestamp_location >= :since
        ORDER BY l.timestamp_location DESC
        """, nativeQuery = true)
    List<Location> findNearbyLocations(
            @Param("latitude") Double latitude,
            @Param("longitude") Double longitude,
            @Param("radiusKm") Double radiusKm,
            @Param("since") LocalDateTime since
    );
}