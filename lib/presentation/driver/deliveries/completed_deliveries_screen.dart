import 'package:flutter/material.dart';
import 'package:app_mobile/common/model/delivery.dart';
import 'package:app_mobile/common/widgets/loading_indicator.dart';

class CompletedDeliveriesScreen extends StatefulWidget {
  const CompletedDeliveriesScreen({Key? key}) : super(key: key);

  @override
  State<CompletedDeliveriesScreen> createState() =>
      _CompletedDeliveriesScreenState();
}

class _CompletedDeliveriesScreenState extends State<CompletedDeliveriesScreen> {
  // Exemplo de dados de entregas concluídas
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
    // Inicializar carregamento de entregas concluídas com o BLoC
    // _driverBloc.add(LoadCompletedDeliveriesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entregas Concluídas'),
           actions: [
        // Botão de filtro
        IconButton(
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filtrar',
          onPressed: () {
            // Implementação similar ao filtro do histórico de cliente
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Filtrar entregas (a implementar)')),
            );
          },
        ),
      ],
      ),
      
      body: _buildCompletedDeliveriesList(),
    );
  }

  Widget _buildCompletedDeliveriesList() {
    if (_completedDeliveries.isEmpty) {
      return const Center(child: Text('Nenhuma entrega concluída encontrada.'));
    }

    return ListView.builder(
      itemCount: _completedDeliveries.length,
      itemBuilder: (context, index) {
        final delivery = _completedDeliveries[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(delivery.description),
            subtitle: Text('Cliente: ${delivery.clientName}\n' +
                'Endereço: ${delivery.deliveryAddress}\n' +
                'Concluída em: ${delivery.timestamp.toString().substring(0, 16)}'),
            isThreeLine: true,
            onTap: () {
              // Mostrar detalhes da entrega concluída em um diálogo
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Entrega ${delivery.id}'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Cliente: ${delivery.clientName}'),
                          Text('Descrição: ${delivery.description}'),
                          Text('Endereço: ${delivery.deliveryAddress}'),
                          Text('Concluída em: ${delivery.timestamp.toString().substring(0, 16)}'),
                          if (delivery.photoPath != null) 
                            const Text('\nFoto da entrega disponível'),
                          if (delivery.latitude != null && delivery.longitude != null)
                            Text('\nLocalização: ${delivery.latitude}, ${delivery.longitude}'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Fechar'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}