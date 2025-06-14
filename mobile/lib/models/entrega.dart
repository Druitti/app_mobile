class Entrega {
  final int? id;
  final String codigo;
  final String status;
  final DateTime dataCriacao;
  final DateTime dataAtualizacao;
  final double? latitude;
  final double? longitude;
  final String? fotoAssinatura;
  final String? observacoes;

  Entrega({
    this.id,
    required this.codigo,
    required this.status,
    required this.dataCriacao,
    required this.dataAtualizacao,
    this.latitude,
    this.longitude,
    this.fotoAssinatura,
    this.observacoes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'status': status,
      'data_criacao': dataCriacao.toIso8601String(),
      'data_atualizacao': dataAtualizacao.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'foto_assinatura': fotoAssinatura,
      'observacoes': observacoes,
    };
  }

  factory Entrega.fromMap(Map<String, dynamic> map) {
    return Entrega(
      id: map['id'] as int?,
      codigo: map['codigo'] as String,
      status: map['status'] as String,
      dataCriacao: DateTime.parse(map['data_criacao'] as String),
      dataAtualizacao: DateTime.parse(map['data_atualizacao'] as String),
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      fotoAssinatura: map['foto_assinatura'] as String?,
      observacoes: map['observacoes'] as String?,
    );
  }

  Entrega copyWith({
    int? id,
    String? codigo,
    String? status,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    double? latitude,
    double? longitude,
    String? fotoAssinatura,
    String? observacoes,
  }) {
    return Entrega(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      status: status ?? this.status,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fotoAssinatura: fotoAssinatura ?? this.fotoAssinatura,
      observacoes: observacoes ?? this.observacoes,
    );
  }
} 