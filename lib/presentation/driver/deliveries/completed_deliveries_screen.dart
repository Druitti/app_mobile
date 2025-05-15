import 'package:flutter/material.dart';
import 'package:app_mobile/common/model/delivery.dart'; // Importar modelo Delivery
import 'package:app_mobile/common/widgets/loading_indicator.dart';
import 'package:app_mobile/presentation/driver/bloc/driver_bloc.dart'; // Importar BLoC
import 'package:app_mobile/common/utils/helpers.dart'; // Para formatDateTime

class CompletedDeliveriesScreen extends StatefulWidget {
  const CompletedDeliveriesScreen({Key? key}) : super(key: key);

  @override
  State<CompletedDeliveriesScreen> createState() =>
      _CompletedDeliveriesScreenState();
}

class _CompletedDeliveriesScreenState extends State<CompletedDeliveriesScreen> {
  // Instanciar BLoC (via Provider ou DI)
  // final DriverBloc _driverBloc = DriverBloc(); // Exemplo

  // Exemplo de dados de entregas concluídas (substituir com dados do BLoC/SQLite)
  final List<Delivery> _completedDeliveries = [
    Delivery(
      id: 'delivery_999',
      description: 'Pacote Grande - Móveis',
      status: 'Entregue',
      clientName: 'Cliente Feliz',
      deliveryAddress: 'Rua da Paz, 789, Bairro Tranquilo',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      photoPath: '/path/to/photo1.jpg', // Exemplo
      latitude: -23.5600,
      longitude: -46.6400,
    ),
    Delivery(
      id: 'delivery_888',
      description: 'Envelope - Contrato Importante',
      status: 'Entregue',
      clientName: 'Advocacia Legal',
      deliveryAddress: 'Avenida Jurídica, 101, Centro Cívico',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      photoPath: '/path/to/photo2.jpg', // Exemplo
      latitude: -23.5550,
      longitude: -46.6350,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Disparar evento para carregar entregas concluídas (do SQLite)
    // _driverBloc.add(LoadCompletedDeliveriesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entregas Concluídas'),
      ),
      body: _buildCompletedDeliveriesList(), // Usar método separado
      // Exemplo com BlocBuilder:
      /*
      body: BlocBuilder<DriverBloc, DriverState>(
        bloc: _driverBloc,
        builder: (context, state) {
          if (state is DriverLoading) {
            return const LoadingIndicator();
          } else if (state is CompletedDeliveriesLoaded) {
            if (state.deliveries.isEmpty) {
              return const Center(child: Text('Nenhuma entrega concluída encontrada.'));
            }
            return _buildCompletedDeliveriesList(state.deliveries);
          } else if (state is DriverError) {
            return Center(child: Text('Erro ao carregar entregas concluídas: ${state.message}'));
          } else {
            return const Center(child: Text('Carregando histórico...'));
          }
        },
      ),
      */
    );
  }

  Widget _buildCompletedDeliveriesList(/* List<Delivery> deliveries */) {
    // Usando a lista de exemplo _completedDeliveries por enquanto
    final deliveries = _completedDeliveries;

    if (deliveries.isEmpty) {
      return const Center(child: Text('Nenhuma entrega concluída encontrada.'));
    }

    return ListView.builder(
      itemCount: deliveries.length,
      itemBuilder: (context, index) {
        final delivery = deliveries[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(delivery.description),
            subtitle: Text('Cliente: ${delivery.clientName}\n' +
                'Endereço: ${delivery.deliveryAddress}\n' +
                'Concluída em: ${formatDateTime(delivery.timestamp)}'),
            isThreeLine: true,
            onTap: () {
              // Opcional: Mostrar detalhes da entrega concluída, incluindo a foto
              // showDialog(...);
            },
          ),
        );
      },
    );
  }
}
