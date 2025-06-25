package com.logistics.tracking.repository;

import com.logistics.tracking.model.DeliveryTracking;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DeliveryTrackingRepository extends JpaRepository<DeliveryTracking, Long> {
    Optional<DeliveryTracking> findByOrderId(Long orderId);
    List<DeliveryTracking> findByDriverId(Long driverId);
    List<DeliveryTracking> findByStatus(DeliveryTracking.TrackingStatus status);
}
