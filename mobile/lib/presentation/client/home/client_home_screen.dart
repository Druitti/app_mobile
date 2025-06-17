// lib/presentation/client/home/client_home_screen.dart
import 'package:app_mobile/app.dart';
import 'package:app_mobile/common/widgets/map_location_pick.dart';
import 'package:app_mobile/debug/database_service_debug.dart';
import 'package:app_mobile/main.dart';
import 'package:app_mobile/presentation/client/history/client_history_screen.dart';
import 'package:app_mobile/presentation/client/tracking/client_tracking_screen.dart';
import 'package:app_mobile/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:app_mobile/common/widgets/loading_indicator.dart';
import 'package:app_mobile/common/model/order.dart';
import 'package:app_mobile/services/database_service.dart';
import 'package:app_mobile/common/model/delivery.dart';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:app_mobile/services/order_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientHomeScreen extends StatefulWidget {
  final bool showAppBar;

  const ClientHomeScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  // Exemplo de dados para demonstração
  final List<Order> _activeOrders = [];
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  final PushNotificationService _notificationService =
      PushNotificationService();
  final OrderService _orderService = OrderService();
  // final Future<bool> Function(String description, String address, [LatLng? coordinates]) onSave;
  // Método para carregar entregas do banco de dados
  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId != null) {
        final orders = await _orderService.getOrdersForCustomer(userId);
        setState(() {
          _activeOrders.clear();
          _activeOrders.addAll(orders);
        });
      } else {
        throw Exception('Usuário não autenticado');
      }
    } catch (e) {
      print('Erro ao carregar entregas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar entregas: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Método para criar uma nova entrega
  Future<void> _createNewOrder() async {
    // Abrir diálogo para criar nova entrega com seleção de mapa
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => CreateOrderDialog(
        onSave: (description, address, [coordinates]) {
          // Chama o método _saveNewOrder passando os parâmetros corretamente
          return _saveNewOrder(description, address, coordinates);
        },
      ),
    );
  }

  // Método atualizado para salvar nova entrega no banco de dados com coordenadas
  Future<bool> _saveNewOrder(
      String description, String address, LatLng? coordinates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) throw Exception('Usuário não autenticado');
      final order = Order(
        id: '', // O backend irá gerar o ID
        description: description,
        status: 'PENDENTE',
        estimatedDelivery: DateTime.now().add(const Duration(days: 1)),
        driverName: '',
        latitude: coordinates?.latitude,
        longitude: coordinates?.longitude,
        endereco: address,
        observacoes: 'Criado pelo cliente',
        cep: null,
        contatoCliente: null,
        fotosUrl: null,
        trackingUrl: null,
        actualDeliveryTime: null,
      );
      final success = await _orderService.createOrder(order);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrega criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadOrders();
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao criar entrega'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      print('Erro ao salvar nova entrega: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar entrega: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Método para excluir uma entrega
  Future<void> _deleteOrder(String orderId) async {
    // Mostrar diálogo de confirmação
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Entrega'),
        content: const Text('Tem certeza que deseja excluir esta entrega?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    // Se confirmado, excluir entrega via backend
    if (confirm == true) {
      try {
        final success = await _orderService.deleteOrder(orderId);
        if (success) {
          setState(() {
            _activeOrders.removeWhere((order) => order.id == orderId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entrega excluída com sucesso')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entrega não encontrada ou não pode ser excluída'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Erro ao excluir entrega: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir entrega: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Aqui você inicializaria seu BLoC
    // _clientBloc.add(LoadActiveOrdersEvent());
    _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = _isLoading
        ? const Center(child: LoadingIndicator())
        : _buildActiveOrdersList();
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: widget.showAppBar
          ? AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              title: const Text(
                'Minhas Entregas',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.black87),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClientHistoryScreen(),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          if (_activeOrders.isEmpty && !_isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma entrega ativa',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crie uma nova entrega para começar',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(child: content),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewOrder,
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Nova Entrega'),
      ),
    );
  }

  Widget _buildActiveOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeOrders.length,
      itemBuilder: (context, index) {
        final order = _activeOrders[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClientTrackingScreen(orderId: order.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          order.description,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusChip(order.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Estimativa: ${_formatDate(order.estimatedDelivery)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (order.driverName != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Motorista: ${order.driverName}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _deleteOrder(order.id),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Excluir'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ClientTrackingScreen(orderId: order.id),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('Acompanhar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pendente':
        color = Colors.orange;
        break;
      case 'em andamento':
        color = Colors.blue;
        break;
      case 'entregue':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class CreateOrderDialog extends StatefulWidget {
  final Future<bool> Function(
      String description, String address, LatLng? coordinates) onSave;

  const CreateOrderDialog({
    Key? key,
    required this.onSave,
  }) : super(key: key);

  @override
  State<CreateOrderDialog> createState() => _CreateOrderDialogState();
}

class _CreateOrderDialogState extends State<CreateOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  LatLng? _selectedLocation;

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLocation: _selectedLocation,
          onLocationSelected: (location, address) {
            setState(() {
              _selectedLocation = location;
              _addressController.text = address;
            });
          },
        ),
      ),
    );

    // Se o resultado for não nulo, significa que uma localização foi selecionada
    if (result != null) {
      setState(() {
        final locationData = result as Map<String, dynamic>;
        _selectedLocation = locationData['location'] as LatLng;
        _addressController.text = locationData['address'] as String;
      });
    }
  }

  Future<void> _saveOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final result = await widget.onSave(
          _descriptionController.text.trim(),
          _addressController.text.trim(),
          _selectedLocation,
        );

        if (result) {
          Navigator.of(context).pop(true); // Retorna true para indicar sucesso
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_shipping,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Nova Entrega',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Formulário
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descrição da Entrega',
                  hintText: 'Ex: Pacote de Roupas',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Descrição é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Seletor de endereço
              InkWell(
                onTap: _openMapPicker,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Endereço de Entrega',
                    hintText: 'Selecione no mapa',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.map),
                      onPressed: _openMapPicker,
                      tooltip: 'Abrir mapa',
                    ),
                  ),
                  child: Text(
                    _addressController.text.isEmpty
                        ? 'Toque para selecionar no mapa'
                        : _addressController.text,
                    style: _addressController.text.isEmpty
                        ? TextStyle(color: Colors.grey[600])
                        : null,
                  ),
                ),
              ),

              // Localização selecionada
              if (_selectedLocation != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Localização selecionada: ${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Criar Entrega'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
