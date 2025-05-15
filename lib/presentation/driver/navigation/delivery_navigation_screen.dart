import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:app_mobile/common/model/delivery.dart';
import 'package:app_mobile/common/widgets/custom_button.dart';
import 'package:app_mobile/presentation/driver/update_status/update_status_screen.dart';
import 'package:app_mobile/services/location_service.dart'; // Para obter localização atual
import 'package:app_mobile/common/utils/failures.dart'; // Para tratar falhas
import 'package:app_mobile/common/utils/helpers.dart'; // Para showSnackBar
import 'package:dartz/dartz.dart' as dartz;
import 'package:geolocator/geolocator.dart';
// Importar geocoding ou similar para converter endereço em LatLng (opcional, mas recomendado)
// import 'package:geocoding/geocoding.dart';

class DeliveryNavigationScreen extends StatefulWidget {
  final Delivery delivery;

  const DeliveryNavigationScreen({Key? key, required this.delivery})
      : super(key: key);

  @override
  State<DeliveryNavigationScreen> createState() =>
      _DeliveryNavigationScreenState();
}

class _DeliveryNavigationScreenState extends State<DeliveryNavigationScreen> {
  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;
  StreamSubscription<dartz.Either<Failure, Position>>? _locationSubscription;

  LatLng? _driverPosition;
  LatLng? _destinationPosition; // Posição do endereço de entrega
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getDestinationCoordinates();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  // Função para converter endereço em coordenadas (Placeholder)
  // Idealmente, use um pacote como 'geocoding'
  Future<void> _getDestinationCoordinates() async {
    // Simulação - Substitua por geocoding real
    // Exemplo: List<Location> locations = await locationFromAddress(widget.delivery.deliveryAddress);
    // if (locations.isNotEmpty) { ... }
    // Usando uma coordenada fixa como placeholder:
    _destinationPosition = const LatLng(-23.5610, -46.6400); // Exemplo
    _updateMarkers();
  }

  void _startLocationUpdates() {
    _locationSubscription =
        _locationService.getLocationStream().listen((result) {
      result.fold(
        (failure) {
          // Tratar erro ao obter localização (ex: mostrar SnackBar)
          if (mounted) {
            showSnackBar(
                context, 'Erro ao obter localização: ${failure.message}',
                isError: true);
          }
          print("Erro no stream de localização: ${failure.message}");
        },
        (position) {
          if (mounted) {
            setState(() {
              _driverPosition = LatLng(position.latitude, position.longitude);
              _updateMarkers();
            });
            // Opcional: Animar câmera para seguir o motorista
            // _mapController?.animateCamera(CameraUpdate.newLatLng(_driverPosition!));
          }
        },
      );
    });
  }

  void _updateMarkers() {
    Set<Marker> newMarkers = {};
    if (_driverPosition != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverPosition!,
          infoWindow: const InfoWindow(title: 'Sua Posição'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }
    if (_destinationPosition != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationPosition!,
          infoWindow:
              InfoWindow(title: 'Destino: ${widget.delivery.clientName}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    setState(() {
      _markers = newMarkers;
    });

    // Ajustar câmera para mostrar ambos os marcadores, se possível
    if (_driverPosition != null &&
        _destinationPosition != null &&
        _mapController != null) {
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          _driverPosition!.latitude < _destinationPosition!.latitude
              ? _driverPosition!.latitude
              : _destinationPosition!.latitude,
          _driverPosition!.longitude < _destinationPosition!.longitude
              ? _driverPosition!.longitude
              : _destinationPosition!.longitude,
        ),
        northeast: LatLng(
          _driverPosition!.latitude > _destinationPosition!.latitude
              ? _driverPosition!.latitude
              : _destinationPosition!.latitude,
          _driverPosition!.longitude > _destinationPosition!.longitude
              ? _driverPosition!.longitude
              : _destinationPosition!.longitude,
        ),
      );
      _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50.0)); // 50.0 é o padding
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMarkers(); // Garante que os marcadores sejam exibidos quando o mapa estiver pronto
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navegação da Entrega'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                // Começa centralizado no destino ou na posição inicial do motorista
                target: _destinationPosition ??
                    _driverPosition ??
                    const LatLng(-23.5505, -46.6333),
                zoom: 14.0,
              ),
              markers: _markers,
              myLocationEnabled:
                  false, // Usamos nosso próprio marcador para o motorista
              myLocationButtonEnabled: false,
              // Adicionar Polyline para a rota (requer Directions API ou similar)
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entrega: ${widget.delivery.description}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Cliente: ${widget.delivery.clientName}'),
                    const SizedBox(height: 8),
                    Text('Endereço: ${widget.delivery.deliveryAddress}'),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Atualizar Status / Cheguei',
                      onPressed: () {
                        // Navegar para a tela de atualização de status
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UpdateStatusScreen(delivery: widget.delivery),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    // Opcional: Botão para abrir navegação externa
                    /*
                    CustomButton(
                      text: 'Abrir no Google Maps / Waze',
                      onPressed: () {
                        // Implementar lógica para abrir app de navegação externo
                        // (usando url_launcher e coordenadas de destino)
                      },
                      color: Colors.grey,
                    ),
                    */
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
