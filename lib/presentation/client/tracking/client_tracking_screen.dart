import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:app_mobile/common/widgets/loading_indicator.dart';

class ClientTrackingScreen extends StatefulWidget {
  final String orderId;

  const ClientTrackingScreen({Key? key, required this.orderId})
      : super(key: key);

  @override
  State<ClientTrackingScreen> createState() => _ClientTrackingScreenState();
}

class _ClientTrackingScreenState extends State<ClientTrackingScreen> {
  GoogleMapController? _mapController;
  final LatLng _center = const LatLng(-23.5505, -46.6333); // Exemplo: Centro de SP
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Iniciar rastreamento com o BLoC
    // _clientBloc.add(LoadTrackingInfoEvent(widget.orderId));
    _addInitialMarker();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _addInitialMarker() {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('delivery_location'),
          position: _center,
          infoWindow: const InfoWindow(title: 'Localização da Entrega'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rastreando Pedido ${widget.orderId}'),
        actions: [
          IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Atualizar',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Atualizando localização...')),
            );
            // TO-DO implementar a lógica para atualizar a localização
          },
        ),      IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'Informações',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Informações de Rastreamento'),
                content: const Text(
                  'Este mapa mostra a localização atual da sua entrega.\n\n'
                  'O marcador azul indica onde o entregador está neste momento.',
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
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 11.0,
              ),
              markers: _markers,
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
                    const Text(
                      'Status da Entrega:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    // Placeholder enquanto o BLoC não está implementado:
                    const Text('Status: Em trânsito'),
                    const SizedBox(height: 5),
                    const Text('Motorista: João Silva'),
                    const SizedBox(height: 5),
                    Text('Previsão: ${DateTime.now().add(const Duration(hours: 2)).toString().substring(0, 16)}'),
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
