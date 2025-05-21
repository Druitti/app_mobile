import 'dart:async';

import 'package:app_mobile/presentation/driver/deliveries/driver_home_screen.dart';
import 'package:app_mobile/presentation/driver/update_status/update_status_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:app_mobile/common/model/delivery.dart';
import 'package:app_mobile/services/location_service.dart';


class DeliveryNavigationScreen extends StatefulWidget {
  final Delivery delivery;

  const DeliveryNavigationScreen({Key? key, required this.delivery})
      : super(key: key);

  @override
  State<DeliveryNavigationScreen> createState() => _DeliveryNavigationScreenState();
}

class _DeliveryNavigationScreenState extends State<DeliveryNavigationScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  
  // Coordenadas de exemplo (pode ser substituído por geocoding do endereço real)
 
   LatLng _destination = const LatLng(-23.5505, -46.6333);
  final LocationService _locationService = LocationService();
  bool _mapLoading = true;
  bool _mapError = false;
  String _errorMessage = '';
  StreamSubscription? _locationSubscription;
  LatLng? _currentLocation;
  bool _locationPermissionGranted = false;
  
  @override
  void initState() {
    super.initState();
    // Definir destino com base na entrega ou usar valores padrão
    
    _initializeMap();
    
    _addMarkers();
  }
  Future<void> _initializeMap() async {
    // Verificar permissões e serviços de localização
    final hasPermission = await _locationService.checkLocationPermission();
    if (!hasPermission) {
      final granted = await _locationService.requestLocationPermission();
      setState(() {
        _locationPermissionGranted = granted;
      });
      if (!granted) {
        setState(() {
          _errorMessage = 'É necessário permitir o acesso à localização';
        });
      }
    } else {
      setState(() {
        _locationPermissionGranted = true;
      });
    }

    // Obter localização atual (se tiver permissão)
    if (_locationPermissionGranted) {
      try {
        final currentLatLng = await _locationService.getCurrentLatLng();
        if (currentLatLng != null) {
          setState(() {
            _currentLocation = currentLatLng;
          });
        }
      } catch (e) {
        print('Erro ao obter localização atual: $e');
      }
    }

    // Definir destino com base na entrega ou usar valores padrão
    setState(() {
      _destination = LatLng(
        widget.delivery.latitude ?? -23.5505,
        widget.delivery.longitude ?? -46.6333,
      );
    });
    
    // Adicionar marcadores
    _addMarkers();
    
  }
   @override
  void dispose() {
    
    _locationSubscription?.cancel();
    _mapController?.dispose();
    
    super.dispose();
  }
  
  void _onMapCreated(GoogleMapController controller) {
     setState(() {
      _mapController = controller;
      _mapLoading = false;
    });
    
    // Iniciar tracking de localização se tiver permissão
    if (_locationPermissionGranted) {
      _startLocationTracking();
    }
  }
  void _startLocationTracking() {
    try {
      _locationSubscription = _locationService.getLocationStream().listen((position) {
        final newLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentLocation = newLocation;
          
          // Atualizar marcador de localização atual
          _markers.removeWhere((m) => m.markerId.value == 'current_location');
          _markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: newLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: const InfoWindow(title: 'Sua localização'),
            ),
          );
        });
      });
    } catch (e) {
      print('Erro ao iniciar rastreamento: $e');
    }
  }
  void _addMarkers() {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination,
          infoWindow: InfoWindow(title: widget.delivery.deliveryAddress),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
       if (_currentLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: _currentLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: 'Sua localização'),
          ),
        );
      }
    });
  }
  
  @override
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Navegação para Entrega'),
      // Esta tela precisa de um tratamento especial para o botão voltar
      // já que geralmente vem após aceitar uma entrega
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // Confirmar se deseja cancelar a navegação
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cancelar Navegação'),
              content: const Text('Deseja voltar à lista de entregas disponíveis?'),
              actions: [
                TextButton(
                  child: const Text('Não'),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: const Text('Sim'),
                  onPressed: () {
                    Navigator.pop(context); // Fecha o diálogo
                     Navigator.pushReplacement
                     (
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DriverHomeScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        // Botão para alternar visualização do mapa
       IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Mostrar minha localização',
            onPressed: () async {
              if (_currentLocation != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(_currentLocation!),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Localização não disponível')),
                );
              }
            },
          ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              // Mapa (mantém o existente)
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _destination,
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  mapType: MapType.normal,
                  myLocationEnabled: _locationPermissionGranted,
                  myLocationButtonEnabled: false, // Usamos nosso próprio botão
                  zoomControlsEnabled: false, // Usamos nossos próprios controles
                  compassEnabled: true,
                  buildingsEnabled: true,
                
                ),
                
                // Indicador de carregamento
                if (_mapLoading)
                  Container(
                    color: Colors.white.withOpacity(0.7),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text("Carregando mapa..."),
                        ],
                      ),
                    ),
                  ),
                  
                // Mensagem de erro
                if (_mapError)
                  Container(
                    color: Colors.red.withOpacity(0.3),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              "Erro ao carregar o mapa: $_errorMessage",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _mapError = false;
                                  _mapLoading = true;
                                });
                                // Tentar reiniciar o mapa
                                _initializeMap();
                              },
                              child: const Text("Tentar novamente"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              // Botões de zoom no mapa (adicionado)
              Positioned(
                top: 10,
                right: 10,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: "zoom_in",
                      child: const Icon(Icons.add),
                      onPressed: () {
                        _mapController?.animateCamera(CameraUpdate.zoomIn());
                      },
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: "zoom_out",
                      child: const Icon(Icons.remove),
                      onPressed: () {
                        _mapController?.animateCamera(CameraUpdate.zoomOut());
                      },
                    ),
                  ],
                ),
              ),
               // Botão para centralizar no destino
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: FloatingActionButton.small(
                    heroTag: "center_destination",
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.place),
                    onPressed: () {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLng(_destination),
                      );
                    },
                  ),
                ),
                
                // Mostrar distância até o destino
                if (_currentLocation != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Card(
                      color: Colors.white.withOpacity(0.8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Distância: ${_locationService.formatDistance(
                            _locationService.calculateDistance(_currentLocation!, _destination)
                          )}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detalhes da Entrega:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('Cliente: ${widget.delivery.clientName}'),
                Text('Descrição: ${widget.delivery.description}'),
                Text('Endereço: ${widget.delivery.deliveryAddress}'),
                Text('Prazo: ${widget.delivery.timestamp.toString().substring(0, 16)}'),
                if (_currentLocation != null && _destination != null)
                    Text(
                      'Distância: ${_locationService.formatDistance(
                        _locationService.calculateDistance(_currentLocation!, _destination)
                      )}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botão para ligar para o cliente
                    OutlinedButton.icon(
                      icon: const Icon(Icons.phone),
                      label: const Text('Ligar'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ligando para o cliente... (simulação)')),
                        );
                      },
                    ),
                    // Botão para atualizar status (original)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.update),
                      label: const Text('Atualizar Status'),
                      onPressed: () {
                      
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UpdateStatusScreen(delivery: widget.delivery),
                          ),
                        );
                                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
}