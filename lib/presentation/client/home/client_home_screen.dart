import 'package:flutter/material.dart';
import 'package:app_mobile/common/widgets/loading_indicator.dart'; // Exemplo de uso de widget comum
import 'package:app_mobile/presentation/client/bloc/client_bloc.dart'; // Exemplo de import do BLoC
// Importe outros BLoCs, repositórios ou serviços necessários

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({Key? key}) : super(key: key);

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  // Instancie seu BLoC aqui (geralmente via Provider ou outra injeção de dependência)
  // final ClientBloc _clientBloc = ClientBloc(); // Exemplo

  @override
  void initState() {
    super.initState();
    // Dispare eventos iniciais no BLoC, se necessário
    // _clientBloc.add(LoadActiveOrdersEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Encomendas'),
        // Adicione ações, como ir para o histórico ou configurações
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navegar para a tela de histórico
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const ClientHistoryScreen())); // Certifique-se que ClientHistoryScreen existe
            },
          ),
          // Adicionar botão para configurações, etc.
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Tela Principal do Cliente (WIP)',
            ),
            const SizedBox(height: 20),
            // Aqui você pode exibir uma lista de encomendas ativas
            // ou um botão para rastrear uma encomenda específica.
            ElevatedButton(
              onPressed: () {
                // Navegar para a tela de rastreamento (passando um ID de encomenda)
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ClientTrackingScreen(
                            orderId:
                                'dummy_order_123'))); // Certifique-se que ClientTrackingScreen existe
              },
              child: const Text('Rastrear Encomenda (Exemplo)'),
            ),
            // Exemplo de uso do BLoC (substitua pelo seu estado real)
            /*
            BlocBuilder<ClientBloc, ClientState>(
              bloc: _clientBloc,
              builder: (context, state) {
                if (state is ClientLoading) {
                  return const LoadingIndicator();
                } else if (state is ActiveOrdersLoaded) {
                  // Construa a lista de encomendas ativas
                  return ListView.builder(...);
                } else if (state is ClientError) {
                  return Text('Erro: ${state.message}');
                } else {
                  return const Text('Nenhuma encomenda ativa.');
                }
              },
            ),
            */
          ],
        ),
      ),
    );
  }
}

// --- Definições de Placeholder para Navegação ---
// Remova ou substitua pelas implementações reais

class ClientHistoryScreen extends StatelessWidget {
  const ClientHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Pedidos')),
      body: const Center(child: Text('Histórico de Pedidos (WIP)')),
    );
  }
}

class ClientTrackingScreen extends StatelessWidget {
  final String orderId;
  const ClientTrackingScreen({Key? key, required this.orderId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rastreando Pedido $orderId')),
      body: const Center(child: Text('Tela de Rastreamento (WIP)')),
    );
  }
}
