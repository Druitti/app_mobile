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
      id: json['id']?.toString() ?? json['codigo']?.toString() ?? '',
      description: json['description'] ?? json['descricao'] ?? '',
      status: json['status'] ?? '',
      estimatedDelivery: DateTime.parse(json['estimatedDelivery'] ?? json['estimated_delivery'] ?? DateTime.now().toIso8601String()),
      driverName: json['driverName'] ?? json['driver_name'] ?? '',
      actualDeliveryTime: json['actualDeliveryTime'] != null
          ? DateTime.parse(json['actualDeliveryTime'])
          : (json['actual_delivery_time'] != null ? DateTime.parse(json['actual_delivery_time']) : null),
      latitude: (json['latitude'] is int)
          ? (json['latitude'] as int).toDouble()
          : json['latitude'] as double?,
      longitude: (json['longitude'] is int)
          ? (json['longitude'] as int).toDouble()
          : json['longitude'] as double?,
      endereco: json['endereco'],
      cep: json['cep'],
      contatoCliente: json['contatoCliente'] ?? json['contato_cliente'],
      observacoes: json['observacoes'],
      fotosUrl: json['fotosUrl'] ?? json['fotos_url'],
    );
  }

  // Método para converter Order em um Map (útil para testes ou outras operações)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'status': status,
      'estimatedDelivery': estimatedDelivery.toIso8601String(),
      'driverName': driverName,
      'actualDeliveryTime': actualDeliveryTime?.toIso8601String(),
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

