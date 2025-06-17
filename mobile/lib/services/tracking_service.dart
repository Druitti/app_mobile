import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrackingService {
  static const String baseUrl = 'http://localhost:8080/api/tracking';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<bool> sendLocation({
    required String orderId,
    required double latitude,
    required double longitude,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/location'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'orderId': orderId,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<LatLng?> getCurrentLocation(String orderId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/order/$orderId/current'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['latitude'] != null && data['longitude'] != null) {
        return LatLng(
          (data['latitude'] as num).toDouble(),
          (data['longitude'] as num).toDouble(),
        );
      }
    }
    return null;
  }

  Future<List<LatLng>> getLocationHistory(String orderId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/order/$orderId/history'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map<LatLng>((e) => LatLng((e['latitude'] as num).toDouble(),
              (e['longitude'] as num).toDouble()))
          .toList();
    }
    return [];
  }
}
