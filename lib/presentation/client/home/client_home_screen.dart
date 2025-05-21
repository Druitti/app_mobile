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

class ClientHomeScreen extends StatefulWidget {
  final bool showAppBar; 

  const ClientHomeScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}


class _ClientHomeScreenState extends State<ClientHomeScreen> {
  // Exemplo de dados para demonstração
  final List<Order> _activeOrders =[] ;
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  final PushNotificationService _notificationService = PushNotificationService();
  // final Future<bool> Function(String description, String address, [LatLng? coordinates]) onSave;
  // Método para carregar entregas do banco de dados
  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Buscar entregas do banco de dados
      final entregasDb = await _databaseService.listarEntregas();
      
      // Se não houver entregas no banco, mantenha os dados de exemplo
   // Se não houver entregas no banco, mantenha os dados de exemplo
    if (entregasDb.isNotEmpty) {
      final List<Order> ordersFromDb = entregasDb
          .where((map) => map['status']?.toLowerCase() != 'entregue') // Filtra os que não são 'Entregue'
          .map((map) {
            // Converter do formato do banco para Order
            return Order(
              id: map['codigo'] ?? map['id'].toString(),
              description: map['descricao'] ?? 'Entrega #${map['id']}',
              status: map['status'] ?? 'Pendente',
              estimatedDelivery: DateTime.parse(map['data_atualizacao'] ?? DateTime.now().toIso8601String()),
              driverName: 'Motorista Designado',
            );
          }).toList();


        
        setState(() {
          // Se tiver dados no banco, substitua os dados de exemplo
          if (ordersFromDb.isNotEmpty) {
          
            _activeOrders.addAll(ordersFromDb);
          }
        });
      }
    } catch (e) {
      print('Erro ao carregar entregas: $e');
      // Tratar erro (opcional)
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
    );}
  
  // Método atualizado para salvar nova entrega no banco de dados com coordenadas
  Future<bool> _saveNewOrder(
    String description, 
    String address, 
    LatLng? coordinates
  ) async {
    try {
      // Criar um ID único para a entrega
      final String orderId = 'order_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
      
      // Preparar dados para o banco incluindo coordenadas de localização
      final Map<String, dynamic> newOrder = {
        'codigo': orderId,
        'descricao': description,
        'status': 'Pendente',
        'data_criacao': DateTime.now().toIso8601String(),
        'data_atualizacao': DateTime.now().toIso8601String(),
        'endereco': address,
        'observacoes': 'Criado pelo cliente',
        'latitude': coordinates?.latitude,
        'longitude': coordinates?.longitude,
      };
      
      // Notificar sobre a nova entrega
      await _notificationService.notifyOrderStatusChange(
        orderId: orderId,
        status: 'Pendente',
        titulo: 'Nova Entrega Criada',
        mensagem: 'Um novo pedido #$orderId foi criado e está aguardando processamento.',
      );
      
      // Inserir no banco de dados
      final int result = await _databaseService.inserirEntrega(newOrder);
      
      // Verificar se inserção foi bem-sucedida
      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrega criada com sucesso!'), 
            backgroundColor: Colors.green,
          ),
        );
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
  
  
  // Método para salvar nova entrega no banco de dados
 
  
  
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
  
  // Se confirmado, excluir entrega
  if (confirm == true) {
    try {
      // Usa diretamente o orderId como código da entrega
      final result = await _databaseService.deletarEntrega(orderId);
      
      if (result > 0) {
        // Remover da lista local
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
    // ------>>> alterando aqui: decide se mostra AppBar com base no parâmetro
    Widget content = _isLoading 
      ? const Center(child: LoadingIndicator()) 
      : _buildActiveOrdersList();
    return Scaffold(
           appBar: widget.showAppBar ? AppBar(
              title: const Text('Minhas Entregas'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () {

                     Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ClientHistoryScreen(),
                        ),
                      );
                  },
                  tooltip: 'Histórico de Pedidos',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadOrders,
                  tooltip: 'Atualizar Lista',
                ),      // Menu popup
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
                                 Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomeScreen(),
                                  ),
                                );// Volta para a tela inicial
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
            ) : null,
            floatingActionButton: FloatingActionButton(
               onPressed: _createNewOrder,
              tooltip: 'Novo Pedido',
              child: const Icon(Icons.add),
            ),
            body: content
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
            leading: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteOrder(order.id),
              tooltip: 'Excluir',
            ),
            trailing: ElevatedButton(
  child: const Text('Rastrear'),
  onPressed: () {
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
    
  },
),
            isThreeLine: true,
          ),
        );
      },
    );
  }


}
class CreateOrderDialog extends StatefulWidget {
  final Future<bool> Function(String description, String address, LatLng? coordinates) onSave;
  
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
    return AlertDialog(
      title: const Text('Nova Entrega'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição da Entrega',
                  hintText: 'Ex: Pacote de Roupas',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Descrição é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _openMapPicker,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Endereço de Entrega',
                    hintText: 'Selecione no mapa',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.map),
                      onPressed: _openMapPicker,
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
              if (_selectedLocation != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Localização selecionada: ${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveOrder,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}