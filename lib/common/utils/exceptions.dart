/// Exceções personalizadas para representar erros específicos da aplicação.

class ServerException implements Exception {
  final String message;
  ServerException({this.message = 'Erro no servidor'});
}

class CacheException implements Exception {
  final String message;
  CacheException({this.message = 'Erro de cache'});
}

class NetworkException implements Exception {
  final String message;
  NetworkException({this.message = 'Erro de rede'});
}

class PermissionException implements Exception {
  final String message;
  PermissionException({this.message = 'Erro de permissão'});
}

class InvalidDataException implements Exception {
  final String message;
  InvalidDataException({this.message = 'Dados inválidos'});
}

class UnknownException implements Exception {
  final String message;
  UnknownException({this.message = 'Erro desconhecido'});
}

