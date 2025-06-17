import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeocodingService {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';
  static const String _apiKey =
      'YOUR_API_KEY'; // Substitua pela sua chave da API do Google

  Future<List<Map<String, dynamic>>> searchAddress(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?address=$query&key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return (data['results'] as List).map((result) {
            final location = result['geometry']['location'];
            return {
              'address': result['formatted_address'],
              'latitude': location['lat'],
              'longitude': location['lng'],
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('Erro ao buscar endereço: $e');
      return [];
    }
  }

  Future<String?> getAddressFromLatLng(LatLng location) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl?latlng=${location.latitude},${location.longitude}&key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
      return null;
    } catch (e) {
      print('Erro ao obter endereço: $e');
      return null;
    }
  }
}
