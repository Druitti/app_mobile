import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:app_mobile/common/model/delivery.dart';

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
  late LatLng _destination;
  
  @override
  void initState() {
    super.initState();
    // Definir destino com base na entrega ou usar valores padrão
    _destination = LatLng(
      widget.delivery.latitude ?? -23.5505,
      widget.delivery.longitude ?? -46.6333,
    );
    
    _addMarkers();
  }
  
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
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
                    Navigator.pushReplacementNamed(context, '/driver_home');
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
          icon: const Icon(Icons.layers),
          tooltip: 'Alterar Mapa',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Alternar tipo de mapa (a implementar)')),
            );
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
                        Navigator.pushNamed(
                          context,
                          '/update_status',
                          arguments: widget.delivery,
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