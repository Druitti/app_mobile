import 'package:flutter/material.dart';
import 'package:app_mobile/services/order_service.dart';
import 'package:app_mobile/common/model/order.dart';
import 'package:app_mobile/common/widgets/loading_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AcceptedDeliveriesScreen extends StatefulWidget {
  const AcceptedDeliveriesScreen({Key? key}) : super(key: key);

  @override
  State<AcceptedDeliveriesScreen> createState() =>
      _AcceptedDeliveriesScreenState();
}

class _AcceptedDeliveriesScreenState extends State<AcceptedDeliveriesScreen> {
  final OrderService _orderService = OrderService();
  List<Order> _acceptedOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAcceptedOrders();
  }

  Future<void> _loadAcceptedOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final driverId = prefs.getString('userId');
      if (driverId == null) throw Exception('Motorista não autenticado');

      print('=== DEBUG: Motorista logado ID: $driverId ===');

      final orders = await _orderService.getOrdersForDriver(driverId);
      print(
          '=== DEBUG: Total de pedidos retornados pelo backend: ${orders.length} ===');

      // Filtro adicional para garantir que só apareçam pedidos com driverId não nulo
      final filteredOrders = orders.where((order) {
        print(
            '=== DEBUG: Pedido ${order.id} - driverId: "${order.driverId}" (tipo: ${order.driverId.runtimeType}) ===');
        print(
            '=== DEBUG: Comparando "${order.driverId}" == "$driverId" = ${order.driverId == driverId} ===');
        return order.driverId != null && order.driverId == driverId;
      }).toList();

      print('=== DEBUG: Pedidos filtrados: ${filteredOrders.length} ===');

      setState(() {
        _acceptedOrders = filteredOrders;
        _isLoading = false;
      });
    } catch (e) {
      print('=== DEBUG: Erro: $e ===');
      setState(() {
        _errorMessage = 'Erro ao carregar entregas: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Entregas Aceitas'),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _acceptedOrders.isEmpty
                  ? const Center(child: Text('Nenhuma entrega aceita.'))
                  : ListView.builder(
                      itemCount: _acceptedOrders.length,
                      itemBuilder: (context, index) {
                        final order = _acceptedOrders[index];
                        String selectedStatus = order.status ?? 'ACCEPTED';
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  title: Text(
                                      order.description ?? 'Sem descrição'),
                                  subtitle: Text(
                                      'Origem: ${order.originAddress}\nDestino: ${order.destinationAddress}\nStatus atual: ${order.status ?? 'Desconhecido'}'),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButton<String>(
                                        value: selectedStatus,
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'ACCEPTED',
                                            child: Text('Aceito'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'IN_PROGRESS',
                                            child: Text('Em andamento'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'IN_ROUTE',
                                            child: Text('Em rota'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'DELIVERED',
                                            child: Text('Entregue'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'CANCELLED',
                                            child: Text('Cancelado'),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            _acceptedOrders[index] =
                                                order.copyWith(status: value);
                                          });
                                        },
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final success = await _orderService
                                            .updateOrderStatus(
                                                order.id ?? '',
                                                _acceptedOrders[index].status ??
                                                    'ACCEPTED');
                                        if (success) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Status atualizado com sucesso!'),
                                                backgroundColor: Colors.green),
                                          );
                                          _loadAcceptedOrders();
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Erro ao atualizar status!'),
                                                backgroundColor: Colors.red),
                                          );
                                        }
                                      },
                                      child: const Text('Salvar'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
