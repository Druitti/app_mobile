import 'package:flutter/material.dart';
import 'package:app_mobile/common/model/order.dart'; // Importar modelo Order
import 'package:app_mobile/common/utils/constants.dart';
import 'package:app_mobile/common/widgets/loading_indicator.dart';
import 'package:app_mobile/presentation/client/bloc/client_bloc.dart'; // Importar BLoC
// Importar helpers se necessário para formatação
import 'package:app_mobile/common/utils/helpers.dart';

class ClientHistoryScreen extends StatefulWidget {
  const ClientHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ClientHistoryScreen> createState() => _ClientHistoryScreenState();
}

class _ClientHistoryScreenState extends State<ClientHistoryScreen> {
  // Instanciar BLoC (via Provider ou DI)
  // final ClientBloc _clientBloc = ClientBloc(); // Exemplo

  // Exemplo de dados de histórico (substituir com dados do BLoC)
  final List<Order> _historyOrders = [
    Order(
      id: 'order_xyz_789',
      description: 'Livro de Ficção Científica',
      status: 'Entregue',
      estimatedDelivery: DateTime.now().subtract(const Duration(days: 2)),
      driverName: 'Maria Oliveira',
      actualDeliveryTime:
          DateTime.now().subtract(const Duration(days: 2, hours: 3)),
    ),
    Order(
      id: 'order_abc_123',
      description: 'Eletrônicos - Fone de Ouvido',
      status: 'Entregue',
      estimatedDelivery: DateTime.now().subtract(const Duration(days: 5)),
      driverName: 'Carlos Pereira',
      actualDeliveryTime:
          DateTime.now().subtract(const Duration(days: 5, hours: 1)),
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
    // Disparar evento para carregar histórico
    // _clientBloc.add(LoadOrderHistoryEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Pedidos'),
      ),
      body:
          _buildHistoryList(), // Usar um método separado para construir a lista
      // Exemplo com BlocBuilder:
      /*
      body: BlocBuilder<ClientBloc, ClientState>(
        bloc: _clientBloc,
        builder: (context, state) {
          if (state is ClientLoading) {
            return const LoadingIndicator();
          } else if (state is OrderHistoryLoaded) {
            if (state.orders.isEmpty) {
              return const Center(child: Text('Nenhum pedido no histórico.'));
            }
            return _buildHistoryList(state.orders);
          } else if (state is ClientError) {
            return Center(child: Text('Erro ao carregar histórico: ${state.message}'));
          } else {
            return const Center(child: Text('Carregando histórico...'));
          }
        },
      ),
      */
    );
  }

  // Método para construir a lista de histórico
  Widget _buildHistoryList(/* List<Order> orders */) {
    // Usando a lista de exemplo _historyOrders por enquanto
    final orders = _historyOrders;

    if (orders.isEmpty) {
      return const Center(child: Text('Nenhum pedido no histórico.'));
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            title: Text(order.description),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${order.status}'),
                if (order.actualDeliveryTime != null)
                  Text(
                      'Entregue em: ${formatDateTime(order.actualDeliveryTime!)}')
                else
                  Text('Previsão: ${formatDateTime(order.estimatedDelivery)}'),
                Text('Motorista: ${order.driverName}'),
              ],
            ),
            trailing: Icon(
              order.status == 'Entregue'
                  ? Icons.check_circle
                  : order.status == 'Cancelado'
                      ? Icons.cancel
                      : Icons.history, // Ícone genérico para outros status
              color: order.status == 'Entregue'
                  ? Colors.green
                  : order.status == 'Cancelado'
                      ? Colors.red
                      : Colors.grey,
            ),
            onTap: () {
              // Opcional: Navegar para detalhes do pedido histórico, se houver
              // Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: order.id)));
            },
          ),
        );
      },
    );
  }
}
