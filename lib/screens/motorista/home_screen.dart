import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/entrega.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../services/camera_service.dart';

class MotoristaHomeScreen extends StatefulWidget {
  const MotoristaHomeScreen({super.key});

  @override
  State<MotoristaHomeScreen> createState() => _MotoristaHomeScreenState();
}

class _MotoristaHomeScreenState extends State<MotoristaHomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  final CameraService _cameraService = CameraService();
  List<Entrega> _entregasPendentes = [];
  bool _isLoading = true;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _carregarEntregasPendentes();
    _inicializarServicos();
  }

  Future<void> _inicializarServicos() async {
    await _cameraService.initialize();
    await _locationService.requestLocationPermission();
  }

  Future<void> _carregarEntregasPendentes() async {
    setState(() => _isLoading = true);
    try {
      final entregas = await _databaseService.listarEntregas();
      setState(() {
        _entregasPendentes = entregas
            .map((e) => Entrega.fromMap(e))
            .where((e) => e.status == 'PENDENTE')
            .toList();
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
    _markers = _entregasPendentes
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

  Future<void> _iniciarEntrega(Entrega entrega) async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        throw Exception('Não foi possível obter a localização atual');
      }

      final entregaAtualizada = entrega.copyWith(
        status: 'EM_ANDAMENTO',
        latitude: position.latitude,
        longitude: position.longitude,
        dataAtualizacao: DateTime.now(),
      );

      await _databaseService.atualizarEntrega(entregaAtualizada.toMap());
      await _carregarEntregasPendentes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao iniciar entrega: $e')),
      );
    }
  }

  Future<void> _finalizarEntrega(Entrega entrega) async {
    try {
      final foto = await _cameraService.takePicture();
      if (foto == null) {
        throw Exception('Não foi possível capturar a foto');
      }

      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        throw Exception('Não foi possível obter a localização atual');
      }

      final entregaAtualizada = entrega.copyWith(
        status: 'ENTREGUE',
        latitude: position.latitude,
        longitude: position.longitude,
        fotoAssinatura: foto,
        dataAtualizacao: DateTime.now(),
      );

      await _databaseService.atualizarEntrega(entregaAtualizada.toMap());
      await _carregarEntregasPendentes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao finalizar entrega: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entregas Pendentes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarEntregasPendentes,
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
                    itemCount: _entregasPendentes.length,
                    itemBuilder: (context, index) {
                      final entrega = _entregasPendentes[index];
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          leading: const Icon(Icons.local_shipping),
                          title: Text('Entrega ${entrega.codigo}'),
                          subtitle: Text('Status: ${entrega.status}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
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
                              IconButton(
                                icon: const Icon(Icons.play_arrow),
                                onPressed: () => _iniciarEntrega(entrega),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check),
                                onPressed: () => _finalizarEntrega(entrega),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
} 