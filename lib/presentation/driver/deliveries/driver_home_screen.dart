
import 'package:app_mobile/presentation/client/tracking/client_tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:app_mobile/common/model/delivery.dart';
import 'package:app_mobile/common/widgets/loading_indicator.dart';
import 'package:app_mobile/common/utils/helpers.dart';

class DriverHomeScreen extends StatefulWidget {
  final bool showAppBar;

  const DriverHomeScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isLoading = false;
  
  // Exemplo de dados de entregas disponíveis
  final List<Delivery> _availableDeliveries = [
    Delivery(
      id: 'delivery_111',
      description: 'Pacote Pequeno - Documentos Urgentes',
      status: 'Pendente',
      clientName: 'Empresa X',
      deliveryAddress: 'Rua das Flores, 123, São Paulo',
      timestamp: DateTime.now().add(const Duration(minutes: 30)),
    ),
    Delivery(
      id: 'delivery_222',
      description: 'Caixa Média - Eletrônicos',
      status: 'Pendente',
      clientName: 'Loja Y',
      deliveryAddress: 'Avenida Principal, 456, Centro',
      timestamp: DateTime.now().add(const Duration(hours: 1)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar carregamento de entregas com o BLoC
  }

  @override
  Widget build(BuildContext context) {
    // ------>>> alterando aqui: decide se mostra AppBar com base no parâmetro
    return widget.showAppBar 
        ? Scaffold(
            appBar: AppBar(
              title: const Text('Entregas Disponíveis'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: 'Entregas Concluídas',
                  onPressed: () {
                    Navigator.pushNamed(context, '/driver_completed');
                  },
                ),
                PopupMenuButton<String>(
                  tooltip: 'Menu',
                  onSelected: (value) {
                    if (value == 'profile') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Perfil (a implementar)')),
                      );
                    } else if (value == 'settings') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Configurações (a implementar)')),
                      );
                    } else if (value == 'logout') {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Sair'),
                          content: const Text('Deseja sair do modo Motorista?'),
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
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('Meu Perfil'),
                        ],
                      ),
                    ),
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
                  const SnackBar(content: Text('Atualizando entregas disponíveis...')),
                );
                // Implementar atualização da lista de entregas
              },
              tooltip: 'Atualizar',
              child: const Icon(Icons.refresh),
            ),
            body: _isLoading 
                ? const LoadingIndicator() 
                : _buildAvailableDeliveriesList(),
          )
        : _isLoading // ------>>> alterando aqui: retorna apenas o conteúdo se não mostrar AppBar
            ? const LoadingIndicator() 
            : _buildAvailableDeliveriesList();
  }

  Widget _buildAvailableDeliveriesList() {
    if (_availableDeliveries.isEmpty) {
      return const Center(
          child: Text('Nenhuma entrega disponível no momento.'));
    }

    return ListView.builder(
      itemCount: _availableDeliveries.length,
      itemBuilder: (context, index) {
        final delivery = _availableDeliveries[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            title: Text(delivery.description),
            subtitle: Text(
                'Cliente: ${delivery.clientName}\nEndereço: ${delivery.deliveryAddress}'),
            trailing: ElevatedButton(
              child: const Text('Aceitar'),
              onPressed: () async {
                bool? confirmed = await showConfirmationDialog(
                  context,
                  'Confirmar Entrega',
                  'Deseja aceitar esta entrega?\n${delivery.description}',
                );
                
                if (confirmed != null && confirmed) {
                  // Lógica para aceitar a entrega com o BLoC
                  
                  // Navegar para a tela de navegação/detalhes após aceitar
                  try {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClientTrackingScreen(orderId: delivery.id.toString()),
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