import 'package:flutter/material.dart';
import 'package:app_mobile/common/model/order.dart';
import 'package:app_mobile/common/widgets/loading_indicator.dart';

class ClientHistoryScreen extends StatefulWidget {
  const ClientHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ClientHistoryScreen> createState() => _ClientHistoryScreenState();
}

class _ClientHistoryScreenState extends State<ClientHistoryScreen> {
  // Exemplo de dados de histórico
  final List<Order> _historyOrders = [
    Order(
      id: 'order_xyz_789',
      description: 'Livro de Ficção Científica',
      status: 'Entregue',
      estimatedDelivery: DateTime.now().subtract(const Duration(days: 2)),
      driverName: 'Maria Oliveira',
      actualDeliveryTime: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
    ),
    Order(
      id: 'order_abc_123',
      description: 'Eletrônicos - Fone de Ouvido',
      status: 'Entregue',
      estimatedDelivery: DateTime.now().subtract(const Duration(days: 5)),
      driverName: 'Carlos Pereira',
      actualDeliveryTime: DateTime.now().subtract(const Duration(days: 5, hours: 1)),
    ),
    Order(
      id: 'order_def_456',
      description: 'Roupas - Camiseta Azul',
      status: 'Cancelado',
      estimatedDelivery: DateTime.now().subtract(const Duration(days: 7)),
      driverName: 'Ana Costa',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Iniciar carregamento do histórico com o BLoC
    // _clientBloc.add(LoadOrderHistoryEvent());
  }

  @override
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Histórico de Pedidos'),
      
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filtrar',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Filtrar por Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Todos'),
                          selected: true,
                          onSelected: (selected) {
                            Navigator.pop(context);
                          },
                        ),
                        FilterChip(
                          label: const Text('Entregues'),
                          selected: false,
                          onSelected: (selected) {
                            Navigator.pop(context);
                          },
                        ),
                        FilterChip(
                          label: const Text('Cancelados'),
                          selected: false,
                          onSelected: (selected) {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      child: const Text('Aplicar'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
    // Resto do conteúdo permanece igual...
    // ...
  );
}

  Widget _buildHistoryList() {
    if (_historyOrders.isEmpty) {
      return const Center(child: Text('Nenhum pedido no histórico.'));
    }

    return ListView.builder(
      itemCount: _historyOrders.length,
      itemBuilder: (context, index) {
        final order = _historyOrders[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            title: Text(order.description),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${order.status}'),
                if (order.actualDeliveryTime != null)
                  Text('Entregue em: ${order.actualDeliveryTime.toString().substring(0, 16)}')
                else
                  Text('Previsão: ${order.estimatedDelivery.toString().substring(0, 16)}'),
                Text('Motorista: ${order.driverName}'),
              ],
            ),
            trailing: Icon(
              order.status == 'Entregue'
                  ? Icons.check_circle
                  : order.status == 'Cancelado'
                      ? Icons.cancel
                      : Icons.history,
              color: order.status == 'Entregue'
                  ? Colors.green
                  : order.status == 'Cancelado'
                      ? Colors.red
                      : Colors.grey,
            ),
            // Opcionalmente, @TO-DO  adicionar navegação para detalhes do pedido
            onTap: () {
              // @TO-DO navegar para uma tela de detalhes aqui
              // Navigator.pushNamed(context, '/order_details', arguments: order.id);
            },
          ),
        );
      },
    );
  }
}