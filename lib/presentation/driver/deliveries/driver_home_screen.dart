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
 // Importe o Firestore

class DriverHomeScreen extends StatefulWidget {
  final bool showAppBar;

  const DriverHomeScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isLoading = true;
  List<Delivery> _availableDeliveries = [];
  late DatabaseService _databaseService;
  // Possível stream subscription para o Firebase
  Stream<List<Delivery>>? _deliveriesStream;

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
    _loadDeliveries();
  }

  @override
  void dispose() {
    // Cancelar quaisquer subscriptions para evitar memory leaks
    super.dispose();
  }

  // Carregar entregas do Firebase
  void _loadDeliveries() {
    setState(() {
      _isLoading = true;
    });

    _deliveriesStream = _databaseService.getAvailableDeliveries();
    
    // Se preferir usar um listener em vez de StreamBuilder
    _deliveriesStream!.listen((deliveries) {
      if (mounted) {
        setState(() {
          _availableDeliveries = deliveries;
          _isLoading = false;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar entregas: $error')),
        );
      }
    });
  }

  // Método para atualizar manualmente a lista de entregas
  void _refreshDeliveries() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Atualizando entregas disponíveis...')),
    );
    _loadDeliveries();
  }

  // Método para aceitar uma entrega
  Future<void> _acceptDelivery(Delivery delivery) async {
    try {
      _databaseService.getDeliveryById(delivery.id);
      // Navegação para a tela de navegação após aceitar
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryNavigationScreen(delivery: delivery),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao aceitar entrega: $e')),
        );
      }
    }
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
                  await _acceptDelivery(delivery);
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