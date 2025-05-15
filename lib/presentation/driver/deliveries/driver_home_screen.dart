import 'package:flutter/material.dart';
import 'package:app_mobile/common/model/delivery.dart'; // Importar modelo Delivery
import 'package:app_mobile/common/widgets/loading_indicator.dart';
import 'package:app_mobile/presentation/driver/bloc/driver_bloc.dart'; // Importar BLoC
import 'package:app_mobile/presentation/driver/deliveries/completed_deliveries_screen.dart'; // Para navegação
import 'package:app_mobile/presentation/driver/navigation/delivery_navigation_screen.dart'; // Para navegação
import 'package:app_mobile/common/utils/helpers.dart'; // Para showConfirmationDialog

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({Key? key}) : super(key: key);

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  // Instanciar BLoC (via Provider ou DI)
  // final DriverBloc _driverBloc = DriverBloc(); // Exemplo

  // Exemplo de dados de entregas disponíveis (substituir com dados do BLoC)
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
    // Disparar evento para carregar entregas disponíveis
    // _driverBloc.add(LoadAvailableDeliveriesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entregas Disponíveis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Entregas Concluídas',
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CompletedDeliveriesScreen()));
            },
          ),
          // Adicionar outras ações se necessário (ex: perfil, configurações)
        ],
      ),
      body: _buildAvailableDeliveriesList(), // Usar método separado
      // Exemplo com BlocBuilder:
      /*
      body: BlocBuilder<DriverBloc, DriverState>(
        bloc: _driverBloc,
        builder: (context, state) {
          if (state is DriverLoading) {
            return const LoadingIndicator();
          } else if (state is AvailableDeliveriesLoaded) {
            if (state.deliveries.isEmpty) {
              return const Center(child: Text('Nenhuma entrega disponível no momento.'));
            }
            return _buildAvailableDeliveriesList(state.deliveries);
          } else if (state is DriverError) {
            return Center(child: Text('Erro ao carregar entregas: ${state.message}'));
          } else {
            return const Center(child: Text('Carregando entregas...'));
          }
        },
      ),
      */
    );
  }

  Widget _buildAvailableDeliveriesList(/* List<Delivery> deliveries */) {
    // Usando a lista de exemplo _availableDeliveries por enquanto
    final deliveries = _availableDeliveries;

    if (deliveries.isEmpty) {
      return const Center(
          child: Text('Nenhuma entrega disponível no momento.'));
    }

    return ListView.builder(
      itemCount: deliveries.length,
      itemBuilder: (context, index) {
        final delivery = deliveries[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            title: Text(delivery.description),
            subtitle: Text(
                'Cliente: ${delivery.clientName}\nEndereço: ${delivery.deliveryAddress}'),
            trailing: ElevatedButton(
              child: const Text('Aceitar'),
              onPressed: () async {
                // Lógica para aceitar a entrega
                bool? confirmed = await showConfirmationDialog(
                  context,
                  'Confirmar Entrega',
                  'Deseja aceitar esta entrega?\n${delivery.description}',
                );
                if (confirmed == true) {
                  print('Aceitando entrega: ${delivery.id}');
                  // Disparar evento no BLoC para aceitar
                  // _driverBloc.add(AcceptDeliveryEvent(delivery.id));

                  // Navegar para a tela de navegação/detalhes após aceitar
                  Navigator.pushReplacement(
                    // Use pushReplacement se não quiser voltar para esta tela
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DeliveryNavigationScreen(delivery: delivery),
                    ),
                  );
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
