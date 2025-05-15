import 'package:equatable/equatable.dart';
import 'package:app_mobile/common/utils/constants.dart';

// Representa uma entrega do ponto de vista do motorista, incluindo dados para SQLite.
class Delivery extends Equatable {
  final String id; // Pode ser um ID da API ou um ID local
  final String description;
  final String
      status; // Ex: "Pendente", "Aceita", "Em Rota", "Entregue", "Falha"
  final String clientName;
  final String deliveryAddress;
  final String? photoPath; // Caminho local da foto da assinatura
  final double? latitude; // Latitude no momento da atualização (ex: entrega)
  final double? longitude; // Longitude no momento da atualização
  final DateTime timestamp; // Data/Hora da criação ou última atualização

  const Delivery({
    required this.id,
    required this.description,
    required this.status,
    required this.clientName,
    required this.deliveryAddress,
    this.photoPath,
    this.latitude,
    this.longitude,
    required this.timestamp,
  });

  // Construtor de fábrica para criar Delivery a partir de um Map (ex: JSON da API)
  // Adapte os nomes das chaves conforme a resposta da sua API
  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      clientName: json['client_name'] as String,
      deliveryAddress: json['delivery_address'] as String,
      photoPath: json['photo_path'] as String?, // API pode ou não enviar isso
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  // Método para converter Delivery em um Map (útil para enviar para API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'status': status,
      'client_name': clientName,
      'delivery_address': deliveryAddress,
      'photo_path': photoPath,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Construtor de fábrica para criar Delivery a partir de um Map do SQLite
  factory Delivery.fromMap(Map<String, dynamic> map) {
    return Delivery(
      id: map[columnId] as String,
      description: map[columnDescription] as String,
      status: map[columnStatus] as String,
      clientName: map[columnClientName] as String,
      deliveryAddress: map[columnDeliveryAddress] as String,
      photoPath: map[columnPhotoPath] as String?,
      latitude: map[columnLatitude] as double?,
      longitude: map[columnLongitude] as double?,
      // SQLite armazena timestamp como String (ISO8601) ou INTEGER (millisSinceEpoch)
      // Ajuste conforme a sua implementação no database_helper
      timestamp: DateTime.parse(map[columnTimestamp] as String),
    );
  }

  // Método para converter Delivery em um Map para inserir/atualizar no SQLite
  Map<String, dynamic> toMap() {
    return {
      columnId: id,
      columnDescription: description,
      columnStatus: status,
      columnClientName: clientName,
      columnDeliveryAddress: deliveryAddress,
      columnPhotoPath: photoPath,
      columnLatitude: latitude,
      columnLongitude: longitude,
      // Armazenar como String ISO8601 é geralmente mais simples
      columnTimestamp: timestamp.toIso8601String(),
    };
  }

  // Método copyWith para facilitar atualizações imutáveis
  Delivery copyWith({
    String? id,
    String? description,
    String? status,
    String? clientName,
    String? deliveryAddress,
    String? photoPath,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
  }) {
    return Delivery(
      id: id ?? this.id,
      description: description ?? this.description,
      status: status ?? this.status,
      clientName: clientName ?? this.clientName,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      photoPath: photoPath ?? this.photoPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
        id,
        description,
        status,
        clientName,
        deliveryAddress,
        photoPath,
        latitude,
        longitude,
        timestamp,
      ];
}
