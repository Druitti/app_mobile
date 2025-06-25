import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_mobile/common/model/order.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class OrderService {
  // URL base do backend - ajuste conforme necessário
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api/orders'; // Para web
    } else {
      return 'http://10.0.2.2:8080/api/orders'; // Para Android Emulator
    }
  }

  Future<List<Order>> getOrdersForCustomer(String customerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/customer/$customerId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Order.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao buscar pedidos do cliente');
    }
  }

  Future<List<Order>> getOrdersByStatus(String status) async {
    final response = await http.get(
      Uri.parse('$baseUrl/status/$status'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Order.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao buscar pedidos por status');
    }
  }

  Future<bool> createOrder(Order order) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(order.toJson()),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> assignDriver(String orderId, String driverId) async {
    print(
        '=== DEBUG: Enviando assignDriver - orderId: $orderId, driverId: $driverId ===');

    final response = await http.put(
      Uri.parse('$baseUrl/$orderId/assign-driver?driverId=$driverId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    print(
        '=== DEBUG: Resposta assignDriver - status: ${response.statusCode}, body: ${response.body} ===');

    return response.statusCode == 200;
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$orderId/status?status=$status'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteOrder(String orderId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$orderId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<List<Order>> getOrdersForDriver(String driverId) async {
    // Converter driverId para Long se possível
    final driverIdLong = int.tryParse(driverId);
    if (driverIdLong == null) {
      throw Exception('ID do motorista inválido: $driverId');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/driver/$driverIdLong'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Order.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao buscar pedidos do motorista');
    }
  }

  Future<Order?> getOrderById(String orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$orderId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      return null;
    }
  }
}
