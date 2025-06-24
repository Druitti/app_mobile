import 'package:equatable/equatable.dart';

// Representa uma encomenda/pedido do ponto de vista do cliente.
class Order extends Equatable {
  final String? id;
  final String customerId;
  final String originAddress;
  final String destinationAddress;
  final String? cargoType;
  final String? description;
  final double? price;
  final String? status;
  final DateTime? estimatedDelivery;
  final String? driverName;
  final String? driverId;
  final DateTime? actualDeliveryTime;

  const Order({
    this.id,
    required this.customerId,
    required this.originAddress,
    required this.destinationAddress,
    this.cargoType,
    this.description,
    this.price,
    this.status,
    this.estimatedDelivery,
    this.driverName,
    this.driverId,
    this.actualDeliveryTime,
  });

  // Construtor de fábrica para criar Order a partir de um Map (ex: JSON da API)
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString(),
      customerId: json['customerId']?.toString() ?? '',
      originAddress: json['originAddress'] ?? '',
      destinationAddress: json['destinationAddress'] ?? '',
      cargoType: json['cargoType'],
      description: json['description'],
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : (json['price'] as double?),
      status: json['status'],
      estimatedDelivery: json['estimatedDelivery'] != null
          ? DateTime.tryParse(json['estimatedDelivery'])
          : null,
      driverName: json['driverName'],
      driverId: json['driverId']?.toString(),
      actualDeliveryTime: json['actualDeliveryTime'] != null
          ? DateTime.tryParse(json['actualDeliveryTime'])
          : null,
    );
  }

  // Método para converter Order em um Map (útil para testes ou outras operações)
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'customerId': int.tryParse(customerId) ?? customerId,
      'originAddress': originAddress,
      'destinationAddress': destinationAddress,
    };
    if (cargoType != null) data['cargoType'] = cargoType;
    if (description != null) data['description'] = description;
    if (price != null) data['price'] = price;
    return data;
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        originAddress,
        destinationAddress,
        cargoType,
        description,
        price,
        status,
        estimatedDelivery,
        driverName,
        driverId,
        actualDeliveryTime,
      ];

  Order copyWith({
    String? id,
    String? customerId,
    String? originAddress,
    String? destinationAddress,
    String? cargoType,
    String? description,
    double? price,
    String? status,
    DateTime? estimatedDelivery,
    String? driverName,
    String? driverId,
    DateTime? actualDeliveryTime,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      originAddress: originAddress ?? this.originAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      cargoType: cargoType ?? this.cargoType,
      description: description ?? this.description,
      price: price ?? this.price,
      status: status ?? this.status,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      driverName: driverName ?? this.driverName,
      driverId: driverId ?? this.driverId,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
    );
  }
}
