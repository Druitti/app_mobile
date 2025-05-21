// lib/presentation/client/home/client_home_screen.dart
import 'package:app_mobile/app.dart';
import 'package:app_mobile/presentation/client/tracking/client_tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:app_mobile/common/widgets/loading_indicator.dart';
import 'package:app_mobile/common/model/order.dart';

class ClientHomeScreen extends StatefulWidget {
  final bool showAppBar; // ------>>> alterando aqui: adicionando parâmetro para controlar exibição da AppBar

  const ClientHomeScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  // Exemplo de dados para demonstração
  final List<Order> _activeOrders = [
    Order(
      id: 'order_123',
      description: 'Pacote Eletrônicos',
      status: 'Em Trânsito',
      estimatedDelivery: DateTime.now().add(const Duration(hours: 2)),
      driverName: 'João Silva',
    ),
    Order(
      id: 'order_456',
      description: 'Documento Urgente',
      status: 'Preparando',
      estimatedDelivery: DateTime.now().add(const Duration(hours: 1)),
      driverName: 'Maria Oliveira',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Aqui você inicializaria seu BLoC
    // _clientBloc.add(LoadActiveOrdersEvent());
  }

  @override
  Widget build(BuildContext context) {
    // ------>>> alterando aqui: decide se mostra AppBar com base no parâmetro
    return widget.showAppBar 
        ? Scaffold(
            appBar: AppBar(
              title: const Text('Minhas Entregas'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    Navigator.pushNamed(context, '/client_history');
                  },
                  tooltip: 'Histórico de Pedidos',
                ),
                // Menu popup
                PopupMenuButton<String>(
                  tooltip: 'Menu',
                  onSelected: (value) {
                    if (value == 'settings') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Configurações (a implementar)')),
                      );
                    } else if (value == 'help') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ajuda (a implementar)')),
                      );
                    } else if (value == 'logout') {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Sair'),
                          content: const Text('Deseja sair do modo Cliente?'),
                          actions: [
                            TextButton(
                              child: const Text('Cancelar'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            TextButton(
                              child: const Text('Sair'),
                              onPressed: () {
                                Navigator.pop(context); // Fecha o diálogo
                                Navigator.pushReplacementNamed(context, '/'); // Volta para a tela inicial
                              },
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('Configurações'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'help',
                      child: Row(
                        children: [
                          Icon(Icons.help, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('Ajuda'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('Sair'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Adicionar novo pedido (a implementar)')),
                );
              },
              tooltip: 'Novo Pedido',
              child: const Icon(Icons.add),
            ),
            body: _buildActiveOrdersList(),
          )
        : _buildActiveOrdersList(); // ------>>> alterando aqui: retorna apenas o conteúdo se não mostrar AppBar
  }

  Widget _buildActiveOrdersList() {
    if (_activeOrders.isEmpty) {
      return const Center(
        child: Text('Nenhum pedido ativo no momento.'),
      );
    }

    return ListView.builder(
      itemCount: _activeOrders.length,
      itemBuilder: (context, index) {
        final order = _activeOrders[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            title: Text(order.description),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${order.status}'),
                Text('Previsão: ${order.estimatedDelivery.toString().substring(0, 16)}'),
                Text('Motorista: ${order.driverName}'),
              ],
            ),
            trailing: ElevatedButton(
  child: const Text('Rastrear'),
  onPressed: () {
    try {
      print('Tentando navegar para /client_tracking com ID: ${order.id}');
      
      // Use o navigatorKey global diretamente
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamed(
          '/client_tracking', 
          arguments: order.id.toString() // Força a conversão para String
        );
      } else {
        print('ERRO: navigatorKey.currentState é null!');
        // Tentativa alternativa
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClientTrackingScreen(orderId: order.id.toString()),
          ),
        );
      }
    } catch (e, stack) {
      print('Erro ao navegar: $e');
      print('Stack trace: $stack');
      // Tentativa alternativa
      try {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClientTrackingScreen(orderId: order.id.toString()),
          ),
        );
      } catch (e2) {
        print('Segundo erro ao navegar: $e2');
      }
    }
  },
),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}