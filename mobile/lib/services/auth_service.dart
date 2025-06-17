import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  // URL base do backend - ajuste conforme necessário
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api/auth'; // Para web
    } else {
      return 'http://10.0.2.2:8080/api/auth'; // Para Android Emulator
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        if (data['user'] != null && data['user']['id'] != null) {
          await prefs.setString('userId', data['user']['id'].toString());
        }
        return true;
      }
      print('Erro no login: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('Erro ao fazer login: $e');
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String userType,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      final body = {
        'email': email.toString(),
        'password': password.toString(),
        'userType': userType.toString(),
        'firstName': firstName.toString(),
        'lastName': lastName.toString(),
        'phone': phone.toString(),
      };
      
      print('Enviando dados de registro: $body'); // Log dos dados
      
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('Resposta do servidor: ${response.statusCode} - ${response.body}'); // Log da resposta

      if (response.statusCode == 200) {
        return true;
      }
      print('Erro no registro: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('Erro ao registrar: $e');
      return false;
    }
  }

  Future<bool> validateToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/validate?token=$token'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao validar token: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('userId');
    } catch (e) {
      print('Erro ao fazer logout: $e');
    }
  }
}
