import 'package:equatable/equatable.dart';

// Representa uma encomenda/pedido do ponto de vista do cliente.
class Order extends Equatable {
  final String id;
  final String description;
  final String status; 
  final DateTime estimatedDelivery;
  final String? trackingUrl; // URL para rastreamento externo, se houver
  final String driverName; 
  final DateTime? actualDeliveryTime; 
  final double? latitude;
  final double? longitude;

  final String? endereco;
  final String? cep;
  final String? contatoCliente;
  final String? observacoes;
  final String? fotosUrl;

  const Order({
    required this.id,
    required this.description,
    required this.status,
    required this.estimatedDelivery,
    this.trackingUrl,
    required this.driverName,
    this.actualDeliveryTime,
    this.latitude,
    this.longitude,
    this.endereco,
    this.cep,
    this.contatoCliente,
    this.observacoes,
    this.fotosUrl,
  });

  // Construtor de fábrica para criar Order a partir de um Map (ex: JSON da API)
 factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      estimatedDelivery: DateTime.parse(json['estimatedDelivery'] as String),
      driverName: json['driverName'] as String,
      actualDeliveryTime: json['actualDeliveryTime'] != null
          ? DateTime.parse(json['actualDeliveryTime'] as String)
          : null,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      endereco: json['endereco'] as String?,
      cep: json['cep'] as String?,
      contatoCliente: json['contatoCliente'] as String?,
      observacoes: json['observacoes'] as String?,
      fotosUrl: json['fotosUrl'] as String?,
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
      'latitude': latitude,
      'longitude': longitude,
      'endereco': endereco,
      'cep': cep,
      'contatoCliente': contatoCliente,
      'observacoes': observacoes,
      'fotosUrl': fotosUrl,
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

      Order copyWith({
    String? id,
    String? description,
    String? status,
    DateTime? estimatedDelivery,
    String? driverName,
    DateTime? actualDeliveryTime,
    double? latitude,
    double? longitude,
    String? endereco,
    String? cep,
    String? contatoCliente,
    String? observacoes,
    String? fotosUrl,
  }) {
    return Order(
      id: id ?? this.id,
      description: description ?? this.description,
      status: status ?? this.status,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      driverName: driverName ?? this.driverName,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      endereco: endereco ?? this.endereco,
      cep: cep ?? this.cep,
      contatoCliente: contatoCliente ?? this.contatoCliente,
      observacoes: observacoes ?? this.observacoes,
      fotosUrl: fotosUrl ?? this.fotosUrl,
    );
  }
}

