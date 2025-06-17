import 'package:app_mobile/main.dart';
import 'package:app_mobile/presentation/client/tracking/client_tracking_screen.dart';
import 'package:app_mobile/presentation/driver/deliveries/completed_deliveries_screen.dart';
import 'package:app_mobile/presentation/driver/navigation/delivery_navigation_screen.dart';
import 'package:app_mobile/presentation/shared/setting/setting_screen.dart';
import 'package:flutter/material.dart';
import 'package:app_mobile/common/model/delivery.dart';
import 'package:app_mobile/common/widgets/loading_indicator.dart';
import 'package:app_mobile/common/utils/helpers.dart';
import 'package:app_mobile/services/database_service.dart'; // Importe o serviço de banco de dados
import 'package:app_mobile/services/order_service.dart';
import 'package:app_mobile/common/model/order.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverHomeScreen extends StatefulWidget {
  final bool showAppBar;

  const DriverHomeScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isLoading = true;
  List<Order> _availableOrders = [];
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    // Cancelar quaisquer subscriptions para evitar memory leaks
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final orders = await _orderService.getOrdersByStatus('PENDENTE');
      setState(() {
        _availableOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar entregas: $e')),
      );
    }
  }

  Future<void> _acceptOrder(Order order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final driverId = prefs.getString('userId');
      if (driverId == null) throw Exception('Motorista não autenticado');
      final assigned = await _orderService.assignDriver(order.id, driverId);
      if (assigned) {
        final updated = await _orderService.updateOrderStatus(order.id, 'EM_ANDAMENTO');
        if (updated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entrega aceita com sucesso!'), backgroundColor: Colors.green),
          );
          await _loadOrders();
        } else {
          throw Exception('Erro ao atualizar status da entrega');
        }
      } else {
        throw Exception('Erro ao aceitar entrega');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aceitar entrega: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _refreshDeliveries() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Atualizando entregas disponíveis...')),
    );
    _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CompletedDeliveriesScreen(),
                      ),
                    );
                  },
                ),IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(), // ------>>> alterando aqui: usa SettingScreen diretamente
                ),
              );
            },
          ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _refreshDeliveries,
              tooltip: 'Atualizar',
              child: const Icon(Icons.refresh),
            ),
            body: _isLoading 
                ? const LoadingIndicator() 
                : _buildAvailableDeliveriesList(),
          )
        : _isLoading // Retorna apenas o conteúdo se não mostrar AppBar
            ? const LoadingIndicator() 
            : _buildAvailableDeliveriesList();
  }

  Widget _buildAvailableDeliveriesList() {
    if (_availableOrders.isEmpty) {
      return const Center(
          child: Text('Nenhuma entrega disponível no momento.'));
    }

    return ListView.builder(
      itemCount: _availableOrders.length,
      itemBuilder: (context, index) {
        final order = _availableOrders[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            title: Text(order.description),
            subtitle: Text('Endereço: ${order.endereco ?? 'Não informado'}'),
            trailing: ElevatedButton(
              child: const Text('Aceitar'),
              onPressed: () async {
                bool? confirmed = await showConfirmationDialog(
                  context,
                  'Confirmar Entrega',
                  'Deseja aceitar esta entrega?\n${order.description}',
                );
                if (confirmed != null && confirmed) {
                  await _acceptOrder(order);
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