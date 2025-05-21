import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:app_mobile/services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MapView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String address;
  final String title;
  
  const MapView({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.title = 'Localização de Entrega',
  }) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final Completer<GoogleMapController> _controller = Completer();
  final LocationService _locationService = LocationService();
  LatLng? _currentLocation;
  String? _distanceText;
  bool _isLoading = true;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);

    try {
      // Adicionar marcador da entrega
      final deliveryLocation = LatLng(widget.latitude, widget.longitude);
      
      // Obter localização atual para calcular distância
      final currentPosition = await _locationService.getCurrentLocation();
      if (currentPosition != null) {
        _currentLocation = LatLng(
          currentPosition.latitude,
          currentPosition.longitude
        );
        
        // Calcular distância
        final distance = _locationService.calculateDistance(
          _currentLocation!,
          deliveryLocation
        );
        
        // Formatar distância
        _distanceText = _locationService.formatDistance(distance);
        
        // Adicionar marcador para localização atual
        _addCurrentLocationMarker();
        
        // Adicionar linha entre os pontos
        _addRouteLine(deliveryLocation);
      }
      
      // Adicionar marcador da entrega em todos os casos
      _addDeliveryMarker(deliveryLocation);
      
    } catch (e) {
      print('Erro ao inicializar mapa: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addDeliveryMarker(LatLng position) {
    setState(() {
      _markers = {
        ..._markers,
        Marker(
          markerId: const MarkerId('delivery_location'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Local de Entrega',
            snippet: widget.address,
          ),
        ),
      };
    });
  }

  void _addCurrentLocationMarker() {
    if (_currentLocation == null) return;
    
    setState(() {
      _markers = {
        ..._markers,
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Sua Localização',
          ),
        ),
      };
    });
  }

  void _addRouteLine(LatLng destination) {
    if (_currentLocation == null) return;
    
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_currentLocation!, destination],
          color: Colors.blue,
          width: 4,
        ),
      };
    });
  }

  Future<void> _openInMapsApp() async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${widget.latitude},${widget.longitude}';
    
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o mapa')),
      );
    }
  }

  Future<void> _centerOnDeliveryLocation() async {
    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(widget.latitude, widget.longitude),
        15,
      ),
    );
  }

  Future<void> _showBothLocations() async {
    if (_currentLocation == null) return;
    
    final controller = await _controller.future;
    
    // Criar limites que incluem ambos os pontos
    final bounds = LatLngBounds(
      southwest: LatLng(
        _currentLocation!.latitude < widget.latitude 
            ? _currentLocation!.latitude 
            : widget.latitude,
        _currentLocation!.longitude < widget.longitude 
            ? _currentLocation!.longitude 
            : widget.longitude,
      ),
      northeast: LatLng(
        _currentLocation!.latitude > widget.latitude 
            ? _currentLocation!.latitude 
            : widget.latitude,
        _currentLocation!.longitude > widget.longitude 
            ? _currentLocation!.longitude 
            : widget.longitude,
      ),
    );
    
    // Adicionar um pequeno padding
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Informação de distância
        if (_distanceText != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                const Icon(Icons.directions, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Distância: $_distanceText',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Mapa
        Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: CameraPosition(
                          target: LatLng(widget.latitude, widget.longitude),
                          zoom: 15,
                        ),
                        markers: _markers,
                        polylines: _polylines,
                        onMapCreated: (GoogleMapController controller) {
                          _controller.complete(controller);
                          
                          // Se tivermos localização atual, mostrar os dois pontos
                          if (_currentLocation != null) {
                            _showBothLocations();
                          }
                        },
                        zoomControlsEnabled: false,
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                      ),
                      
                      // Botões de controle
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Column(
                          children: [
                            // Botão para centralizar no ponto de entrega
                            FloatingActionButton.small(
                              heroTag: 'center_delivery_btn',
                              onPressed: _centerOnDeliveryLocation,
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              child: const Icon(Icons.location_on, color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                            
                            // Botão para mostrar os dois pontos (se tivermos localização atual)
                            if (_currentLocation != null) ...[
                              FloatingActionButton.small(
                                heroTag: 'show_both_btn',
                                onPressed: _showBothLocations,
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                child: const Icon(Icons.fullscreen, color: Colors.blue),
                              ),
                              const SizedBox(height: 8),
                            ],
                            
                            // Botão para abrir no Google Maps
                            FloatingActionButton.small(
                              heroTag: 'open_maps_btn',
                              onPressed: _openInMapsApp,
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              child: Icon(Icons.directions, color: Colors.blue.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        
        // Botão para abrir no Google Maps
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: OutlinedButton.icon(
            onPressed: _openInMapsApp,
            icon: const Icon(Icons.directions),
            label: const Text('Ver rota no Google Maps'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}