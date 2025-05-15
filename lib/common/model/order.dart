import 'package:equatable/equatable.dart';

// Representa uma encomenda/pedido do ponto de vista do cliente.
class Order extends Equatable {
  final String id;
  final String description;
  final String status; // Ex: "Em trânsito", "Entregue"
  final DateTime estimatedDelivery;
  final String? trackingUrl; // URL para rastreamento externo, se houver
  final String driverName; // Nome do motorista associado
  final DateTime? actualDeliveryTime; // Quando foi entregue de fato

  const Order({
    required this.id,
    required this.description,
    required this.status,
    required this.estimatedDelivery,
    this.trackingUrl,
    required this.driverName,
    this.actualDeliveryTime,
  });

  // Construtor de fábrica para criar Order a partir de um Map (ex: JSON da API)
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      estimatedDelivery: DateTime.parse(json['estimated_delivery'] as String),
      trackingUrl: json['tracking_url'] as String?,
      driverName: json['driver_name'] as String,
      actualDeliveryTime: json['actual_delivery_time'] != null
          ? DateTime.parse(json['actual_delivery_time'] as String)
          : null,
    );
  }

  // Método para converter Order em um Map (útil para testes ou outras operações)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'status': status,
      'estimated_delivery': estimatedDelivery.toIso8601String(),
      'tracking_url': trackingUrl,
      'driver_name': driverName,
      'actual_delivery_time': actualDeliveryTime?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        description,
        status,
        estimatedDelivery,
        trackingUrl,
        driverName,
        actualDeliveryTime,
      ];
}

