import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_mobile/common/utils/constants.dart';
import 'package:app_mobile/common/utils/exceptions.dart';
import 'package:app_mobile/common/utils/failures.dart';
import 'package:dartz/dartz.dart'; // Adicione dartz: ^0.10.1 no pubspec.yaml

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() => _instance;

  LocationService._internal();

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters >= 1000) {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    } else {
      return '${distanceInMeters.round()} m';
    }
  }
  // Obter LatLng da localização atual (formato do Google Maps)
  Future<LatLng?> getCurrentLatLng() async {
    final position = await getCurrentLocation();
    if (position == null) return null;
    
    return LatLng(position.latitude, position.longitude);
  }

  // Calcular distância entre dois pontos (em metros)
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

double calculateDistanceCoordinates(
  double startLat,
  double startLng,
  double endLat,
  double endLng,
) {
  return Geolocator.distanceBetween(
    startLat,
    startLng,
    endLat,
    endLng,
  );
}

  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<bool> checkLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }
    Future<List<String>> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      List<String> formattedAddresses = [];
      
      for (var placemark in placemarks) {
        // Formatar o endereço completo
        final formattedAddress = [
          placemark.street,
          placemark.subLocality,
          placemark.locality,
          placemark.postalCode,
          placemark.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');
        
        formattedAddresses.add(formattedAddress);
      }
      
      return formattedAddresses;
    } catch (e) {
      print('Erro ao obter endereço das coordenadas: $e');
      return [];
    }
  }
}

