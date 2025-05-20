import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/entrega.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  List<Entrega> _entregas = [];
  bool _isLoading = true;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _carregarEntregas();
  }

  Future<void> _carregarEntregas() async {
    setState(() => _isLoading = true);
    try {
      final entregas = await _databaseService.listarEntregas();
      setState(() {
        _entregas = entregas.map((e) => Entrega.fromMap(e)).toList();
        _isLoading = false;
      });
      _atualizarMarcadores();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar entregas: $e')),
      );
    }
  }

  void _atualizarMarcadores() {
    _markers = _entregas
        .where((e) => e.latitude != null && e.longitude != null)
        .map((e) => Marker(
              markerId: MarkerId(e.codigo),
              position: LatLng(e.latitude!, e.longitude!),
              infoWindow: InfoWindow(
                title: 'Entrega ${e.codigo}',
                snippet: 'Status: ${e.status}',
              ),
            ))
        .toSet();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Entregas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarEntregas,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 2,
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(-23.550520, -46.633308), // São Paulo
                      zoom: 12,
                    ),
                    markers: _markers,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ListView.builder(
                    itemCount: _entregas.length,
                    itemBuilder: (context, index) {
                      final entrega = _entregas[index];
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          leading: const Icon(Icons.local_shipping),
                          title: Text('Entrega ${entrega.codigo}'),
                          subtitle: Text('Status: ${entrega.status}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.location_on),
                            onPressed: () {
                              if (entrega.latitude != null &&
                                  entrega.longitude != null) {
                                _mapController?.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                    LatLng(
                                      entrega.latitude!,
                                      entrega.longitude!,
                                    ),
                                    15,
                                  ),
                                );
                              }
                            },
                          ),
                          onTap: () {
                            // Navegar para detalhes da entrega
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
} 