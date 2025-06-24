import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class TrackingService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api/tracking'; // Para web
    } else {
      return 'http://10.0.2.2:8080/api/tracking'; // Para Android Emulator
    }
  }

  Future<bool> sendLocation({
    required String orderId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/location'),
      headers: {
        'Content-Type': 'application/json',
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
    final response = await http.get(
      Uri.parse('$baseUrl/order/$orderId/current'),
      headers: {
        'Content-Type': 'application/json',
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
    final response = await http.get(
      Uri.parse('$baseUrl/order/$orderId/history'),
      headers: {
        'Content-Type': 'application/json',
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
