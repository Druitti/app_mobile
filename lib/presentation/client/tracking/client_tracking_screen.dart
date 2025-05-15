import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Importar Google Maps
import 'package:app_mobile/common/widgets/loading_indicator.dart';
import 'package:app_mobile/presentation/client/bloc/client_bloc.dart'; // Importar BLoC
// Importar modelos e serviços necessários

class ClientTrackingScreen extends StatefulWidget {
  final String orderId;

  const ClientTrackingScreen({Key? key, required this.orderId})
      : super(key: key);

  @override
  State<ClientTrackingScreen> createState() => _ClientTrackingScreenState();
}

class _ClientTrackingScreenState extends State<ClientTrackingScreen> {
  // Instanciar BLoC (via Provider ou DI)
  // final ClientBloc _clientBloc = ClientBloc(); // Exemplo

  GoogleMapController? _mapController;
  final LatLng _center =
      const LatLng(-23.5505, -46.6333); // Exemplo: Centro de SP
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Disparar evento para carregar dados de rastreamento
    // _clientBloc.add(LoadTrackingInfoEvent(widget.orderId));
    _addInitialMarker(); // Adiciona um marcador de exemplo
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // Exemplo: Adiciona um marcador inicial (substituir com dados reais)
  void _addInitialMarker() {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('delivery_location'),
          position: _center, // Posição inicial de exemplo
          infoWindow: const InfoWindow(title: 'Localização da Entrega'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    });
  }

  // Função para atualizar o marcador com a nova localização (chamada pelo BLoC)
  void _updateMarkerLocation(LatLng newPosition) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('delivery_location'),
          position: newPosition,
          infoWindow: const InfoWindow(title: 'Localização Atual'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        )
      };
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(newPosition));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rastreando Pedido ${widget.orderId}'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3, // Mapa ocupa mais espaço
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 11.0,
              ),
              markers: _markers,
              // Adicionar polylines para rota, se necessário
            ),
          ),
          Expanded(
            flex: 2, // Área de status ocupa menos espaço
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status da Entrega:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    // Aqui viria a lógica para exibir o status vindo do BLoC
                    // Exemplo com BlocBuilder:
                    /*
                    BlocConsumer<ClientBloc, ClientState>(
                      bloc: _clientBloc,
                      listener: (context, state) {
                        if (state is TrackingInfoLoaded && state.currentLocation != null) {
                           _updateMarkerLocation(state.currentLocation!);
                        }
                      },
                      builder: (context, state) {
                        if (state is ClientLoading) {
                          return const LoadingIndicator();
                        } else if (state is TrackingInfoLoaded) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status: ${state.orderStatus ?? 'Indisponível'}'),
                              const SizedBox(height: 5),
                              Text('Motorista: ${state.driverName ?? 'N/A'}'),
                              const SizedBox(height: 5),
                              Text('Previsão: ${state.estimatedDelivery != null ? formatDateTime(state.estimatedDelivery!) : 'N/A'}'),
                              // Adicionar mais detalhes se necessário
                            ],
                          );
                        } else if (state is ClientError) {
                          return Text('Erro ao carregar rastreamento: ${state.message}');
                        } else {
                          return const Text('Carregando informações de rastreamento...');
                        }
                      },
                    ),
                    */
                    // Placeholder enquanto o BLoC não está implementado:
                    const Text('Status: Em trânsito (Exemplo)'),
                    const SizedBox(height: 5),
                    const Text('Motorista: João Silva (Exemplo)'),
                    const SizedBox(height: 5),
                    Text(
                        'Previsão: ${DateTime.now().add(const Duration(hours: 2)).toString().substring(0, 16)} (Exemplo)'),
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
