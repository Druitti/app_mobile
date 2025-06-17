import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_mobile/common/model/order.dart';

class OrderService {
  static const String baseUrl = 'http://localhost:8080/api/orders';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Order>> getOrdersForCustomer(String customerId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/customer/$customerId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
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
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/status/$status'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
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
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(order.toJson()),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> assignDriver(String orderId, String driverId) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/$orderId/assign-driver'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'driverId': driverId}),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/$orderId/status'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteOrder(String orderId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/$orderId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }
}
