import 'package:flutter/material.dart';
import 'package:app_mobile/common/model/order.dart' as app_order;
import 'package:app_mobile/common/widgets/loading_indicator.dart';
import 'package:app_mobile/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ClientHistoryScreen extends StatefulWidget {
  const ClientHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ClientHistoryScreen> createState() => _ClientHistoryScreenState();
}

class _ClientHistoryScreenState extends State<ClientHistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<app_order.Order> _historyOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filtro selecionado
  String _selectedFilter = 'Todos';
  final List<String> _filterOptions = [
    'Todos',
    'Entregues',
    'Cancelados',
    'Em Andamento',
    'Pendentes'
  ];

  @override
  void initState() {
    super.initState();
    _loadOrderHistory();
  }

  // Carregar histórico de pedidos
  Future<void> _loadOrderHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Buscar todas as entregas do banco de dados
      final entregas = await _databaseService.listarEntregasParaApp();

      // Converter para o formato Order
      final orders = entregas
          .map((e) => app_order.Order(
                id: e['id'],
                description: e['description'],
                status: e['status'],
                estimatedDelivery: DateTime.parse(e['estimatedDelivery']),
                driverName: e['driverName'],
                actualDeliveryTime:
                    e['status'] == 'Entregue' || e['status'] == 'Concluída'
                        ? DateTime.parse(e['timestamp'])
                        : null,
              ))
          .toList();

      setState(() {
        _historyOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar histórico: $e';
        _isLoading = false;
      });
    }
  }

  // Aplicar filtro de status
  void _applyStatusFilter(String status) {
    setState(() {
      _selectedFilter = status;
      _isLoading = true;
    });

    // Se for "Todos", recarrega todos os pedidos
    if (status == 'Todos') {
      _loadOrderHistory();
      return;
    }

    // Caso contrário, busca todas as entregas e filtra por status
    _databaseService.listarEntregasParaApp().then((entregas) {
      // Filtrar por status
      final filteredEntregas = entregas.where((e) {
        if (status == 'Entregues') {
          return e['status'] == 'Entregue' || e['status'] == 'Concluída';
        } else if (status == 'Cancelados') {
          return e['status'] == 'Cancelado';
        } else if (status == 'Em Andamento') {
          return e['status'] == 'Em Andamento' ||
              e['status'] == 'Em andamento' ||
              e['status'] == 'Em Trânsito' ||
              e['status'] == 'Em trânsito';
        } else if (status == 'Pendentes') {
          return e['status'] == 'Pendente' || e['status'] == 'Aguardando';
        }
        return true;
      }).toList();

      // Converter para o formato Order
      final filteredOrders = filteredEntregas
          .map((e) => app_order.Order(
                id: e['id'],
                description: e['description'],
                status: e['status'],
                estimatedDelivery: DateTime.parse(e['estimatedDelivery']),
                driverName: e['driverName'],
                actualDeliveryTime:
                    e['status'] == 'Entregue' || e['status'] == 'Concluída'
                        ? DateTime.parse(e['timestamp'])
                        : null,
              ))
          .toList();

      setState(() {
        _historyOrders = filteredOrders;
        _isLoading = false;
      });
    }).catchError((error) {
      setState(() {
        _errorMessage = 'Erro ao filtrar pedidos: $error';
        _isLoading = false;
      });
    });
  }

  // Métodos auxiliares para status
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'entregue':
      case 'concluída':
        return 'Entregue';
      case 'cancelado':
        return 'Cancelado';
      case 'em andamento':
      case 'em trânsito':
        return 'Em Andamento';
      case 'pendente':
      case 'aguardando':
        return 'Pendente';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'entregue':
      case 'concluída':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      case 'em andamento':
      case 'em trânsito':
        return Colors.orange;
      case 'pendente':
      case 'aguardando':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Exibir diálogo de filtro
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filtrar por Status',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _filterOptions
                      .map((status) => FilterChip(
                            label: Text(status),
                            selected: _selectedFilter == status,
                            checkmarkColor: Colors.white,
                            selectedColor: Theme.of(context).primaryColor,
                            labelStyle: TextStyle(
                              color: _selectedFilter == status
                                  ? Colors.white
                                  : null,
                            ),
                            onSelected: (selected) {
                              setModalState(() {
                                _selectedFilter = status;
                              });
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Aplicar Filtro'),
                  onPressed: () {
                    Navigator.pop(context);
                    _applyStatusFilter(_selectedFilter);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Exibir detalhes do pedido
  void _showOrderDetails(app_order.Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _OrderDetailsScreen(orderId: order.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Histórico de Pedidos',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: _showFilterDialog,
            tooltip: 'Filtrar pedidos',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro atual
          if (_selectedFilter != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getFilterText(_selectedFilter!),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _showFilterDialog,
                    child: const Text('Alterar'),
                  ),
                ],
              ),
            ),

          // Lista de pedidos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _historyOrders.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _historyOrders.length,
                        itemBuilder: (context, index) {
                          final order = _historyOrders[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _showOrderDetails(order),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Cabeçalho do pedido
                                      Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .primaryColor
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.local_shipping,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Pedido',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  order.id,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          _buildStatusChip(order.status),
                                        ],
                                      ),

                                      const SizedBox(height: 16),
                                      const Divider(),
                                      const SizedBox(height: 16),

                                      // Detalhes do pedido
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildInfoCard(
                                              icon: Icons.description,
                                              title: 'Descrição',
                                              value: order.description,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _buildInfoCard(
                                              icon: Icons.access_time,
                                              title: 'Criado em',
                                              value: DateFormat(
                                                      'dd/MM/yyyy HH:mm')
                                                  .format(
                                                      order.estimatedDelivery),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),

                                      // Botão de detalhes
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _showOrderDetails(order),
                                          icon: const Icon(Icons.visibility),
                                          label: const Text('Ver Detalhes'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhum pedido encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Os pedidos aparecerão aqui quando forem criados',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getFilterText(String filter) {
    switch (filter) {
      case 'all':
        return 'Todos os pedidos';
      case 'pending':
        return 'Pendentes';
      case 'in_progress':
        return 'Em andamento';
      case 'delivered':
        return 'Entregues';
      case 'cancelled':
        return 'Cancelados';
      default:
        return filter;
    }
  }
}

// Tela de detalhes do pedido
class _OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const _OrderDetailsScreen({Key? key, required this.orderId})
      : super(key: key);

  @override
  State<_OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<_OrderDetailsScreen> {
  Map<String, dynamic>? _orderDetails;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      final db = FirebaseFirestore.instance;
      final doc = await db.collection('orders').doc(widget.orderId).get();

      if (doc.exists) {
        setState(() {
          _orderDetails = doc.data();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Pedido não encontrado';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar detalhes: $e';
        _isLoading = false;
      });
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'entregue':
      case 'concluída':
        return 'Entregue';
      case 'cancelado':
        return 'Cancelado';
      case 'em andamento':
      case 'em trânsito':
        return 'Em Andamento';
      case 'pendente':
      case 'aguardando':
        return 'Pendente';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'entregue':
      case 'concluída':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      case 'em andamento':
      case 'em trânsito':
        return Colors.orange;
      case 'pendente':
      case 'aguardando':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalhes do Pedido'),
        ),
        body: Center(
          child: Text(_errorMessage!),
        ),
      );
    }

    if (_orderDetails == null) {
      return const Scaffold(
        body: Center(
          child: Text('Pedido não encontrado'),
        ),
      );
    }

    final createdAt = (_orderDetails!['createdAt'] as Timestamp).toDate();
    final updatedAt = (_orderDetails!['updatedAt'] as Timestamp).toDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Pedido'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido #${_orderDetails!['id']}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: ${_getStatusText(_orderDetails!['status'])}',
                      style: TextStyle(
                        color: _getStatusColor(_orderDetails!['status']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Criado em: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}'),
                    Text(
                        'Última atualização: ${DateFormat('dd/MM/yyyy HH:mm').format(updatedAt)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_orderDetails!['description'] != null) ...[
              const Text(
                'Descrição',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_orderDetails!['description']),
              const SizedBox(height: 16),
            ],
            if (_orderDetails!['driverName'] != null) ...[
              const Text(
                'Motorista',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_orderDetails!['driverName']),
              const SizedBox(height: 16),
            ],
            if (_orderDetails!['endereco'] != null) ...[
              const Text(
                'Endereço',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_orderDetails!['endereco']),
              const SizedBox(height: 16),
            ],
            if (_orderDetails!['observacoes'] != null) ...[
              const Text(
                'Observações',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_orderDetails!['observacoes']),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
