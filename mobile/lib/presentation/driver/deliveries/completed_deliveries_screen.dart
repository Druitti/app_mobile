import 'package:flutter/material.dart';
import 'package:app_mobile/common/model/delivery.dart';
import 'package:app_mobile/common/widgets/loading_indicator.dart';
import 'package:app_mobile/services/database_service.dart';
import 'package:app_mobile/services/order_service.dart';
import 'package:app_mobile/common/model/order.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompletedDeliveriesScreen extends StatefulWidget {
  const CompletedDeliveriesScreen({Key? key}) : super(key: key);

  @override
  State<CompletedDeliveriesScreen> createState() =>
      _CompletedDeliveriesScreenState();
}

class _CompletedDeliveriesScreenState extends State<CompletedDeliveriesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final OrderService _orderService = OrderService();
  List<Delivery> _completedDeliveries = [];
  List<Order> _completedOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filtro de período
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadCompletedOrders();
  }

  Future<void> _loadCompletedOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final driverId = prefs.getString('userId');
      if (driverId == null) throw Exception('Motorista não autenticado');
      final allDelivered = await _orderService.getOrdersByStatus('ENTREGUE');
      // Filtrar apenas as entregas atribuídas a este motorista
      final myDelivered =
          allDelivered.where((o) => o.driverName == driverId).toList();
      setState(() {
        _completedOrders = myDelivered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar entregas: $e';
        _isLoading = false;
      });
    }
  }

  // Função para filtrar entregas por período
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filtrar por período'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Data inicial'),
                    subtitle: Text(_startDate == null
                        ? 'Não definida'
                        : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Data final'),
                    subtitle: Text(_endDate == null
                        ? 'Não definida'
                        : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) {
                        setState(() {
                          _endDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Limpar Filtros'),
                  onPressed: () {
                    this.setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                    Navigator.of(context).pop();
                    _loadCompletedOrders();
                  },
                ),
                TextButton(
                  child: const Text('Aplicar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _applyFilters();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Aplica os filtros selecionados
  void _applyFilters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Em um cenário real, idealmente você teria um método específico no DatabaseService
      // para filtrar entregas por data. Como alternativa, podemos filtrar em memória:

      final stream = _databaseService.getCompletedDeliveries();
      stream.listen((deliveries) {
        if (mounted) {
          // Filtra as entregas baseado nas datas selecionadas
          final filteredDeliveries = deliveries.where((delivery) {
            // Converte para o início do dia para a data inicial
            final deliveryDate = delivery.timestamp;

            bool matchesStart = true;
            bool matchesEnd = true;

            if (_startDate != null) {
              final start = DateTime(
                  _startDate!.year, _startDate!.month, _startDate!.day);
              matchesStart = deliveryDate.isAfter(start) ||
                  deliveryDate.isAtSameMomentAs(start);
            }

            if (_endDate != null) {
              // Usar o final do dia para a data final
              final end = DateTime(
                  _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
              matchesEnd = deliveryDate.isBefore(end) ||
                  deliveryDate.isAtSameMomentAs(end);
            }

            return matchesStart && matchesEnd;
          }).toList();

          setState(() {
            _completedDeliveries = filteredDeliveries;
            _isLoading = false;
          });
        }
      }, onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Erro ao filtrar entregas: $error';
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao filtrar entregas: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Exibe detalhes completos da entrega
  void _showDeliveryDetails(Delivery delivery) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Text(
                      'Entrega ${delivery.id}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                      Icons.description, 'Descrição', delivery.description),
                  _buildDetailRow(Icons.person, 'Cliente', delivery.clientName),
                  _buildDetailRow(
                      Icons.location_on, 'Endereço', delivery.deliveryAddress),
                  _buildDetailRow(Icons.calendar_today, 'Data',
                      '${delivery.timestamp.day}/${delivery.timestamp.month}/${delivery.timestamp.year} - ${delivery.timestamp.hour}:${delivery.timestamp.minute.toString().padLeft(2, '0')}'),
                  if (delivery.photoPath != null &&
                      delivery.photoPath!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text('Comprovante de Entrega:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.asset(
                            delivery.photoPath!,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Text('Imagem não disponível'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  if (delivery.latitude != null && delivery.longitude != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text('Localização da Entrega:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Center(
                            child: Text(
                              'Mapa: ${delivery.latitude}, ${delivery.longitude}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Constrói uma linha de detalhes
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
            tooltip: 'Filtrar por período',
            onPressed: _showFilterDialog,
          ),
          // Botão de atualizar
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar lista',
            onPressed: _loadCompletedOrders,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Mostra indicador de carregamento
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    // Mostra mensagem de erro se houver
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCompletedOrders,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    // Mostra mensagem se não houver entregas
    if (_completedDeliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Nenhuma entrega concluída encontrada',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            if (_startDate != null || _endDate != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  _loadCompletedOrders();
                },
                child: const Text('Limpar filtros'),
              ),
          ],
        ),
      );
    }

    // Mostra lista de entregas concluídas
    return RefreshIndicator(
      onRefresh: _loadCompletedOrders,
      child: ListView.builder(
        itemCount: _completedDeliveries.length,
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, index) {
          final delivery = _completedDeliveries[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: InkWell(
              onTap: () => _showDeliveryDetails(delivery),
              borderRadius: BorderRadius.circular(12.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.green,
                          radius: 20,
                          child: Icon(Icons.check, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                delivery.description,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cliente: ${delivery.clientName}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 16, color: Colors.grey[700]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  delivery.deliveryAddress,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 16, color: Colors.grey[700]),
                            const SizedBox(width: 4),
                            Text(
                              '${delivery.timestamp.day}/${delivery.timestamp.month}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
