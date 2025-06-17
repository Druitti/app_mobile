import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isAuthenticated = false;
  String? _userId;
  String? _userType;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userType => _userType;

  Future<bool> login(String email, String password) async {
    try {
      final success = await _authService.login(email, password);
      if (success) {
        _isAuthenticated = true;
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Erro no login: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _userId = null;
    _userType = null;
    notifyListeners();
  }

  Future<bool> checkAuth() async {
    try {
      final isValid = await _authService.validateToken();
      _isAuthenticated = isValid;
      notifyListeners();
      return isValid;
    } catch (e) {
      print('Erro ao verificar autenticação: $e');
      return false;
    }
  }
}
