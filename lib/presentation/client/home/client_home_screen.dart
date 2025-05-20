import 'package:flutter/material.dart';
import 'package:app_mobile/common/widgets/loading_indicator.dart';
import 'package:app_mobile/presentation/client/bloc/client_bloc.dart';
import 'package:app_mobile/common/model/order.dart'; // Importar modelo Order para exemplo

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({Key? key}) : super(key: key);

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Encomendas'),
       automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            
            onPressed: () {
              // Navegar para a tela de histórico usando rota nomeada
              Navigator.pushNamed(context, '/client_history');
            },
            tooltip: 'Histórico de Pedidos',
          ),
          PopupMenuButton<String>(
          tooltip: 'Menu',
          onSelected: (value) {
            if (value == 'settings') {
              // @TO-DO Navegação para configurações (a ser implementada)
              // Navigator.pushNamed(context, '/client_settings');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configurações (a implementar)')),
              );
            } else if (value == 'help') {
              // Mostrar ajuda
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ajuda (a implementar)')),
              );
            } else if (value == 'logout') {
              // Voltar para a tela de seleção
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
    );
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
                // Navegar para a tela de rastreamento passando o ID como argumento
                Navigator.pushNamed(
                  context, 
                  '/client_tracking',
                  arguments: order.id,
                );
              },
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
