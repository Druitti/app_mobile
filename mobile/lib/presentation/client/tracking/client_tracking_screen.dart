import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:app_mobile/common/model/order.dart';
import 'package:app_mobile/common/widgets/loading_indicator.dart';
import 'package:app_mobile/services/database_service.dart';
import 'package:app_mobile/services/location_service.dart';

class ClientTrackingScreen extends StatefulWidget {
  final String orderId;

  const ClientTrackingScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<ClientTrackingScreen> createState() => _ClientTrackingScreenState();
}

class _ClientTrackingScreenState extends State<ClientTrackingScreen> {
  // Controladores e serviços
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;
  
  // Estado
  bool _isLoading = true;
  Order? _order;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _userLocation;
  Timer? _locationUpdateTimer;
  bool _followVehicle = true;
  String _distanceText = '';
  String _timeText = '';
  
  // Simulação de atualização de localização
  int _simulationStep = 0;
  final List<LatLng> _simulatedRoute = [
    const LatLng(-23.5505, -46.6333), // Início
    const LatLng(-23.5485, -46.6320),
    const LatLng(-23.5465, -46.6310),
    const LatLng(-23.5445, -46.6305),
    const LatLng(-23.5425, -46.6300),
    const LatLng(-23.5405, -46.6295), // Destino final
  ];

  @override
  void initState() {
    super.initState();
    _carregarPedido();
    _iniciarAtualizacaoLocalizacao();
    _obterLocalizacaoUsuario();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // Carrega os dados do pedido a ser rastreado
  Future<void> _carregarPedido() async {
    setState(() => _isLoading = true);
    try {
      final pedidoData = await _databaseService.buscarEntrega(widget.orderId);
      
      if (pedidoData != null) {
        setState(() {
          _order = Order.fromJson(pedidoData);
          _isLoading = false;
        });
        _atualizarMarcadores();
        _atualizarPolylines();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pedido ${widget.orderId} não encontrado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar pedido: $e')),
      );
    }
  }

  // Obtém a localização atual do usuário
  Future<void> _obterLocalizacaoUsuario() async {
    try {
      final location = await _locationService.getCurrentLatLng();
      if (location != null) {
        setState(() {
          _userLocation = location;
        });
        _atualizarMarcadores();
      }
    } catch (e) {
      print('Erro ao obter localização do usuário: $e');
    }
  }

  // Iniciar timer para atualização de localização
  void _iniciarAtualizacaoLocalizacao() {
    // Simular atualizações de localização a cada 5 segundos
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _atualizarLocalizacaoEntregador();
      }
    });
  }

  // Atualização da localização do entregador (simulada)
  void _atualizarLocalizacaoEntregador() {
    if (_simulationStep < _simulatedRoute.length - 1) {
      _simulationStep++;
      final currentLocation = _simulatedRoute[_simulationStep];
      
      setState(() {
        // Atualizar marcador do entregador
        _markers = _markers.where((m) => m.markerId.value != 'entregador').toSet();
        _markers.add(
          Marker(
            markerId: const MarkerId('entregador'),
            position: currentLocation,
            infoWindow: const InfoWindow(
              title: 'Entregador',
              snippet: 'Em movimento',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ),
        );
        
        // Atualizar ordem se existir
        if (_order != null) {
          _order = _order!.copyWith(latitude: currentLocation.latitude, longitude: currentLocation.longitude);
        }
      });
      
      // Atualizar polylines com a rota percorrida
      _atualizarPolylines();
      
      // Atualizar informações de distância e tempo
      _atualizarInfoEntrega();
      
      // Se estiver seguindo o veículo, centralizar no mapa
      if (_followVehicle && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(currentLocation),
        );
      }
    } else {
      // Chegou ao destino, parar a simulação
      _locationUpdateTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrega concluída!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Atualizar status do pedido para "Entregue"
      setState(() {
        if (_order != null) {
          _order = _order!.copyWith(status: 'Entregue');
        }
      });
    }
  }

  // Atualiza marcadores no mapa
  void _atualizarMarcadores() {
    if (_order == null) return;
    
    Set<Marker> markers = {};
    
    // Marcador da localização do usuário
    if (_userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation!,
          infoWindow: const InfoWindow(title: 'Sua localização'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }
    
    // Marcador do destino da entrega
    if (_order!.latitude != null && _order!.longitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destino'),
          position: LatLng(_order!.latitude!, _order!.longitude!),
          infoWindow: InfoWindow(
            title: 'Destino',
            snippet: _order!.endereco ?? _order!.description,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    
    // Marcador do entregador (posição inicial ou simulada)
    final currentLocation = _simulationStep > 0 
        ? _simulatedRoute[_simulationStep]
        : _simulatedRoute[0];
        
    markers.add(
      Marker(
        markerId: const MarkerId('entregador'),
        position: currentLocation,
        infoWindow: const InfoWindow(
          title: 'Entregador',
          snippet: 'Em movimento',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
    
    setState(() {
      _markers = markers;
    });
  }

  // Atualiza as linhas da rota no mapa
  void _atualizarPolylines() {
    if (_simulationStep <= 0) return;
    
    // Criar polyline para a rota percorrida
    List<LatLng> routePoints = _simulatedRoute.sublist(0, _simulationStep + 1);
    
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('rota_entrega'),
          points: routePoints,
          color: Colors.blue,
          width: 5,
        ),
      };
    });
  }

  // Atualiza informações de distância e tempo estimado
  void _atualizarInfoEntrega() {
    if (_simulationStep > 0 && _order != null) {
      // Calcular distância até o destino
      final currentLocation = _simulatedRoute[_simulationStep];
      final destination = LatLng(_order!.latitude ?? 0, _order!.longitude ?? 0);
      final distance = _locationService.calculateDistance(currentLocation, destination);
      
      // Calcular tempo estimado (velocidade média de 30km/h)
      final timeInMinutes = (distance / 500).round(); // Simulação simplificada
      
      setState(() {
        _distanceText = _locationService.formatDistance(distance);
        _timeText = timeInMinutes <= 1 
            ? 'Chegando' 
            : 'Aprox. $timeInMinutes ${timeInMinutes == 1 ? 'minuto' : 'minutos'}';
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // Definir estilo de mapa (opcional)
    // _mapController?.setMapStyle('[]');
    
    // Centralizar em um ponto que mostre tanto usuário quanto entregador
    _centralizarMapa();
  }

  // Centraliza o mapa para mostrar todos os pontos relevantes
  void _centralizarMapa() {
    if (_mapController == null) return;
    
    if (_markers.isNotEmpty) {
      // Calcular os bounds para incluir todos os marcadores
      double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
      
      for (var marker in _markers) {
        if (marker.position.latitude < minLat) minLat = marker.position.latitude;
        if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
        if (marker.position.longitude < minLng) minLng = marker.position.longitude;
        if (marker.position.longitude > maxLng) maxLng = marker.position.longitude;
      }
      
      // Adicionar um padding
      final latPadding = (maxLat - minLat) * 0.2;
      final lngPadding = (maxLng - minLng) * 0.2;
      
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat - latPadding, minLng - lngPadding),
            northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
          ),
          50, // padding em pixels
        ),
      );
    }
  }

  // Atualizar manualmente a localização
  void _atualizarRastreamento() {
    // Em uma implementação real, buscaria os dados mais recentes do servidor
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Atualizando localização...')),
    );
    
    // Forçar uma atualização imediata
    _atualizarLocalizacaoEntregador();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Rastreamento',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? _buildErrorState()
              : Stack(
                  children: [
                    // Mapa
                    GoogleMap(
                      onMapCreated: (controller) => _mapController = controller,
                      initialCameraPosition: CameraPosition(
                        target: _simulatedRoute[0],
                        zoom: 15,
                      ),
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    ),

                    // Painel de informações
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Indicador de arrasto
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            // Status do pedido
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.local_shipping,
                                    color: Theme.of(context).primaryColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Status do Pedido',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _order!.status,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildStatusChip(_order!.status),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Informações de tempo e distância
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoCard(
                                    icon: Icons.access_time,
                                    title: 'Tempo Estimado',
                                    value: _timeText,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildInfoCard(
                                    icon: Icons.route,
                                    title: 'Distância',
                                    value: _distanceText,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Endereço de entrega
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.location_on,
                                      color: Colors.blue[700],
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Endereço de Entrega',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _order!.endereco ?? _order!.description,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Botão de seguir veículo
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() => _followVehicle = !_followVehicle);
                                  if (_followVehicle && _mapController != null) {
                                    final currentLocation = _simulatedRoute[_simulationStep];
                                    _mapController!.animateCamera(
                                      CameraUpdate.newLatLng(currentLocation),
                                    );
                                  }
                                },
                                icon: Icon(
                                  _followVehicle ? Icons.gps_fixed : Icons.gps_not_fixed,
                                ),
                                label: Text(
                                  _followVehicle ? 'Seguindo Entregador' : 'Seguir Entregador',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _followVehicle
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[300],
                                  foregroundColor: _followVehicle
                                      ? Colors.white
                                      : Colors.grey[700],
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Botão de localização atual
                    Positioned(
                      right: 16,
                      bottom: 320,
                      child: FloatingActionButton(
                        heroTag: 'btn_current_location',
                        onPressed: _obterLocalizacaoUsuario,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.my_location,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 40,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar pedido',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _carregarPedido,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar Novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendente':
        return Colors.orange;
      case 'em andamento':
        return Colors.blue;
      case 'entregue':
      case 'concluída':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pendente':
        return 'Pendente';
      case 'em andamento':
        return 'Em Andamento';
      case 'entregue':
      case 'concluída':
        return 'Entregue';
      case 'cancelado':
        return 'Cancelado';
      default:
        return status;
    }
  }
}