import 'package:flutter/material.dart';
import 'package:app_mobile/common/model/order.dart';
import 'package:app_mobile/common/widgets/loading_indicator.dart';
import 'package:app_mobile/services/database_service.dart';

class ClientHistoryScreen extends StatefulWidget {
  const ClientHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ClientHistoryScreen> createState() => _ClientHistoryScreenState();
}

class _ClientHistoryScreenState extends State<ClientHistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Order> _historyOrders = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filtro selecionado
  String _selectedFilter = 'Todos';
  final List<String> _filterOptions = ['Todos', 'Entregues', 'Cancelados', 'Em Andamento', 'Pendentes'];

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
      final orders = entregas.map((e) => Order(
        id: e['id'],
        description: e['description'],
        status: e['status'],
        estimatedDelivery: DateTime.parse(e['estimatedDelivery']),
        driverName: e['driverName'],
        actualDeliveryTime: e['status'] == 'Entregue' || e['status'] == 'Concluída'
            ? DateTime.parse(e['timestamp'])
            : null,
      )).toList();
      
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
          return e['status'] == 'Em Andamento' || e['status'] == 'Em andamento' || e['status'] == 'Em Trânsito' || e['status'] == 'Em trânsito';
        } else if (status == 'Pendentes') {
          return e['status'] == 'Pendente' || e['status'] == 'Aguardando';
        }
        return true;
      }).toList();

      // Converter para o formato Order
      final filteredOrders = filteredEntregas.map((e) => Order(
        id: e['id'],
        description: e['description'],
        status: e['status'],
        estimatedDelivery: DateTime.parse(e['estimatedDelivery']),
        driverName: e['driverName'],
        actualDeliveryTime: e['status'] == 'Entregue' || e['status'] == 'Concluída'
            ? DateTime.parse(e['timestamp'])
            : null,
      )).toList();

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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  children: _filterOptions.map((status) => FilterChip(
                    label: Text(status),
                    selected: _selectedFilter == status,
                    checkmarkColor: Colors.white,
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: _selectedFilter == status ? Colors.white : null,
                    ),
                    onSelected: (selected) {
                      setModalState(() {
                        _selectedFilter = status;
                      });
                    },
                  )).toList(),
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
  void _showOrderDetails(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _OrderDetailsScreen(order: order, databaseService: _databaseService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Pedidos'),
        actions: [
          // Botão de filtro
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar por status',
            onPressed: _showFilterDialog,
          ),
          // Botão de atualizar
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar histórico',
            onPressed: _loadOrderHistory,
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
              onPressed: _loadOrderHistory,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    
    // Mostra mensagem se não houver pedidos
    if (_historyOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'Todos'
                ? 'Nenhum pedido no histórico'
                : 'Nenhum pedido com status "$_selectedFilter"',
              style: const TextStyle(fontSize: 16),
            ),
            if (_selectedFilter != 'Todos') ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() => _selectedFilter = 'Todos');
                  _loadOrderHistory();
                },
                child: const Text('Ver todos os pedidos'),
              ),
            ],
          ],
        ),
      );
    }
    
    // Mostra lista de pedidos
    return RefreshIndicator(
      onRefresh: _loadOrderHistory,
      child: ListView.builder(
        itemCount: _historyOrders.length,
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, index) {
          final order = _historyOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    // Determinar cor e ícone com base no status
    Color statusColor;
    IconData statusIcon;
    
    switch (order.status.toLowerCase()) {
      case 'entregue':
      case 'concluída':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelado':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'em andamento':
      case 'em trânsito':
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.description,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(order.status, style: TextStyle(color: statusColor)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('Motorista: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(order.driverName),
                ],
              ),
              const SizedBox(height: 4),
              if (order.actualDeliveryTime != null) ...[
                Row(
                  children: [
                    const Text('Entregue em: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${order.actualDeliveryTime!.day}/${order.actualDeliveryTime!.month}/${order.actualDeliveryTime!.year} às ${order.actualDeliveryTime!.hour}:${order.actualDeliveryTime!.minute.toString().padLeft(2, '0')}',
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    const Text('Previsão: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${order.estimatedDelivery.day}/${order.estimatedDelivery.month}/${order.estimatedDelivery.year} às ${order.estimatedDelivery.hour}:${order.estimatedDelivery.minute.toString().padLeft(2, '0')}',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Tela de detalhes do pedido
class _OrderDetailsScreen extends StatefulWidget {
  final Order order;
  final DatabaseService databaseService;

  const _OrderDetailsScreen({
    Key? key,
    required this.order,
    required this.databaseService,
  }) : super(key: key);

  @override
  State<_OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<_OrderDetailsScreen> {
  Map<String, dynamic>? _orderDetails;
  List<Map<String, dynamic>>? _orderHistory;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Carregar detalhes completos do pedido
      final details = await widget.databaseService.buscarEntrega(widget.order.id);
      
      // Carregar histórico de status
      final history = await widget.databaseService.buscarHistoricoEntrega(widget.order.id);
      
      setState(() {
        _orderDetails = details;
        _orderHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar detalhes: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido ${widget.order.id}'),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOrderDetails,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _buildOrderDetailsContent(),
    );
  }

  Widget _buildOrderDetailsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com status
          _buildStatusHeader(),
          
          const SizedBox(height: 24),
          
          // Detalhes do pedido
          const Text(
            'Detalhes do Pedido',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildDetailCard(),
          
          const SizedBox(height: 24),
          
          // Histórico de status
          if (_orderHistory != null && _orderHistory!.isNotEmpty) ...[
            const Text(
              'Histórico de Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildHistoryTimeline(),
          ],
          
          const SizedBox(height: 24),
          
          // Localização da entrega
          if (_orderDetails != null && 
              _orderDetails!['latitude'] != null && 
              _orderDetails!['longitude'] != null) ...[
            const Text(
              'Localização da Entrega',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildLocationCard(),
          ],
          
          const SizedBox(height: 24),
          
          // Observações
          if (_orderDetails != null && 
              _orderDetails!['observacoes'] != null &&
              _orderDetails!['observacoes'].toString().isNotEmpty) ...[
            const Text(
              'Observações',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_orderDetails!['observacoes']),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    // Determinar cor e ícone com base no status
    Color statusColor;
    IconData statusIcon;
    
    switch (widget.order.status.toLowerCase()) {
      case 'entregue':
      case 'concluída':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelado':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'em andamento':
      case 'em trânsito':
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(statusIcon, size: 48, color: statusColor),
          const SizedBox(height: 8),
          Text(
            widget.order.status,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 4),
          if (widget.order.actualDeliveryTime != null)
            Text(
              'Entregue em ${widget.order.actualDeliveryTime!.day}/${widget.order.actualDeliveryTime!.month}/${widget.order.actualDeliveryTime!.year} às ${widget.order.actualDeliveryTime!.hour}:${widget.order.actualDeliveryTime!.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 14),
            )
          else
            Text(
              'Previsão: ${widget.order.estimatedDelivery.day}/${widget.order.estimatedDelivery.month}/${widget.order.estimatedDelivery.year} às ${widget.order.estimatedDelivery.hour}:${widget.order.estimatedDelivery.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailCard() {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.description, 'Descrição', widget.order.description),
            const Divider(),
            _buildDetailRow(Icons.local_shipping, 'Motorista', widget.order.driverName),
            if (_orderDetails != null && _orderDetails!['endereco'] != null) ...[
              const Divider(),
              _buildDetailRow(
                Icons.location_on, 
                'Endereço', 
                _orderDetails!['endereco'],
              ),
            ],
            const Divider(),
            _buildDetailRow(
              Icons.calendar_today, 
              'Data do Pedido', 
              '${widget.order.estimatedDelivery.day}/${widget.order.estimatedDelivery.month}/${widget.order.estimatedDelivery.year}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
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

  Widget _buildHistoryTimeline() {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: List.generate(_orderHistory!.length, (index) {
            final historyItem = _orderHistory![index];
            final DateTime dataMudanca = DateTime.parse(historyItem['data_mudanca']);
            
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                        if (index < _orderHistory!.length - 1)
                          Container(
                            width: 2,
                            height: 40,
                            color: Colors.grey[400],
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'De "${historyItem['status_anterior']}" para "${historyItem['status_novo']}"',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dataMudanca.day}/${dataMudanca.month}/${dataMudanca.year} às ${dataMudanca.hour}:${dataMudanca.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      'Mapa: ${_orderDetails!['latitude']}, ${_orderDetails!['longitude']}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Aqui iria a lógica para abrir o mapa em um aplicativo externo
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Abrindo mapa no aplicativo...')),
                );
              },
              icon: const Icon(Icons.directions),
              label: const Text('Ver no Mapa'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}