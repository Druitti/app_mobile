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
      appBar: AppBar(
        title: Text('Rastreando Pedido ${widget.orderId}'),
        actions: [
          // Botão de atualização
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _atualizarRastreamento,
          ),
          // Botão de informações
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Informações',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Informações de Rastreamento'),
                  content: const Text(
                    'Este mapa mostra a localização atual da sua entrega.\n\n'
                    '• Marcador azul: posição atual do entregador\n'
                    '• Marcador vermelho: destino da entrega\n'
                    '• Marcador verde: sua localização atual\n'
                    '• Linha azul: rota percorrida pelo entregador\n\n'
                    'O horário de entrega é uma estimativa e pode variar conforme o trânsito.',
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Fechar'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : Column(
              children: [
                // Mapa ocupando a maior parte da tela
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      // Mapa principal
                      GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          target: _order?.latitude != null && _order?.longitude != null
                              ? LatLng(_order!.latitude!, _order!.longitude!)
                              : const LatLng(-23.5505, -46.6333), // Centro de SP como fallback
                          zoom: 14.0,
                        ),
                        markers: _markers,
                        polylines: _polylines,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        compassEnabled: true,
                        mapToolbarEnabled: false,
                        zoomControlsEnabled: false,
                        onTap: (_) {
                          // Desativar seguimento automático ao tocar no mapa
                          setState(() {
                            _followVehicle = false;
                          });
                        },
                      ),
                      
                      // Controles personalizados
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Column(
                          children: [
                            // Botão para seguir o veículo
                            FloatingActionButton.small(
                              heroTag: 'follow',
                              backgroundColor: _followVehicle ? Colors.blue : Colors.grey,
                              child: Icon(
                                _followVehicle 
                                    ? Icons.navigation 
                                    : Icons.navigation_outlined,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _followVehicle = !_followVehicle;
                                  
                                  // Se ativar seguimento, centralizar no entregador
                                  if (_followVehicle && _simulationStep < _simulatedRoute.length) {
                                    _mapController?.animateCamera(
                                      CameraUpdate.newLatLng(_simulatedRoute[_simulationStep]),
                                    );
                                  }
                                });
                              },
                              tooltip: _followVehicle 
                                  ? 'Seguindo entregador' 
                                  : 'Clique para seguir o entregador',
                            ),
                            const SizedBox(height: 8),
                            
                            // Botão para centralizar mapa
                            FloatingActionButton.small(
                              heroTag: 'center',
                              child: const Icon(Icons.center_focus_strong),
                              onPressed: _centralizarMapa,
                              tooltip: 'Centralizar mapa',
                            ),
                            const SizedBox(height: 8),
                            
                            // Botões de zoom
                            FloatingActionButton.small(
                              heroTag: 'zoom_in',
                              child: const Icon(Icons.add),
                              onPressed: () {
                                _mapController?.animateCamera(CameraUpdate.zoomIn());
                              },
                              tooltip: 'Ampliar',
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton.small(
                              heroTag: 'zoom_out',
                              child: const Icon(Icons.remove),
                              onPressed: () {
                                _mapController?.animateCamera(CameraUpdate.zoomOut());
                              },
                              tooltip: 'Reduzir',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Informações detalhadas da entrega
                Expanded(
                  flex: 2,
                  child: _order == null
                      ? const Center(child: Text('Informações não disponíveis'))
                      : SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Título e status
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _order!.description,
                                            style: const TextStyle(
                                              fontSize: 18, 
                                              fontWeight: FontWeight.bold
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                _getStatusIcon(_order!.status),
                                                color: _getStatusColor(_order!.status),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _order!.status,
                                                style: TextStyle(
                                                  color: _getStatusColor(_order!.status),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Tempo e distância
                                    if (_distanceText.isNotEmpty && _timeText.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.blue.shade100),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              _timeText,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                            Text(
                                              _distanceText,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                
                                const Divider(height: 24),
                                
                                // Detalhes do entregador
                                const Text(
                                  'Entregador:',
                                  style: TextStyle(
                                    fontSize: 16, 
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.grey.shade200,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _order!.driverName,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const Text('Entregas: 253 | Avaliação: 4.8 ★'),
                                        ],
                                      ),
                                    ),
                                    // Botão para ligar
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.phone),
                                      label: const Text('Ligar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Iniciando chamada... (simulação)'),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Detalhes da entrega
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Endereço:',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(_order!.endereco ?? 'Endereço não disponível'),
                                          
                                          const SizedBox(height: 8),
                                          
                                          const Text(
                                            'Previsão de Entrega:',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(_formatDateTime(_order!.estimatedDelivery)),
                                        ],
                                      ),
                                    ),
                                    
                                    // Observações/instruções
                                    if (_order!.observacoes != null)
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.yellow.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.yellow.shade200),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Observações:',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              Text(_order!.observacoes!),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
            
      // Botão para contatar o entregador
      floatingActionButton: !_isLoading && _order != null
          ? FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Contatar Entregador',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.phone, color: Colors.white),
                          ),
                          title: const Text('Ligar'),
                          subtitle: const Text('Falar diretamente com o entregador'),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Iniciando chamada... (simulação)')),
                            );
                          },
                        ),
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.message, color: Colors.white),
                          ),
                          title: const Text('Enviar Mensagem'),
                          subtitle: const Text('Enviar instruções ou dúvidas'),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Abrindo chat... (simulação)')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.contact_phone),
              label: const Text('Contatar Entregador'),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }

  // Funções auxiliares

  // Cor baseada no status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'preparando':
        return Colors.orange;
      case 'em trânsito':
        return Colors.blue;
      case 'entregue':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Ícone baseado no status
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'preparando':
        return Icons.inventory;
      case 'em trânsito':
        return Icons.local_shipping;
      case 'entregue':
        return Icons.check_circle;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  // Formatação de data/hora
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}