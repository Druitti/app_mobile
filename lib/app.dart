import 'package:flutter/material.dart';
import 'package:app_mobile/common/utils/constants.dart';
import 'package:app_mobile/presentation/client/home/client_home_screen.dart';
import 'package:app_mobile/presentation/driver/deliveries/driver_home_screen.dart';
// Importar outras telas para definir rotas nomeadas, se necessário
import 'package:app_mobile/presentation/client/tracking/client_tracking_screen.dart';
import 'package:app_mobile/presentation/client/history/client_history_screen.dart'
    as history;
import 'package:app_mobile/presentation/driver/deliveries/completed_deliveries_screen.dart';
import 'package:app_mobile/presentation/driver/navigation/delivery_navigation_screen.dart';
import 'package:app_mobile/presentation/driver/update_status/update_status_screen.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        primarySwatch: kPrimaryColor
            as MaterialColor?, // Ajuste se kPrimaryColor não for MaterialColor
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: kPrimaryColor as MaterialColor? ??
              Colors.blue, // Fallback para azul
          accentColor: kSecondaryColor,
          backgroundColor: kBackgroundColor,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 1,
          color: kPrimaryColor, // Cor da AppBar
          foregroundColor: Colors.white, // Cor do texto e ícones na AppBar
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: kPrimaryColor,
          textTheme: ButtonTextTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
      // Definindo uma tela inicial simples para escolher entre Cliente e Motorista
      home: const InitialSelectionScreen(),
      // Definindo rotas nomeadas para facilitar a navegação
      routes: {
        '/client_home': (context) => const ClientHomeScreen(),
        '/driver_home': (context) => const DriverHomeScreen(),
        // Adicione outras rotas conforme necessário
        // '/client_tracking': (context) => ClientTrackingScreen(orderId: ModalRoute.of(context)!.settings.arguments as String), // Exemplo com argumento
        '/client_history': (context) => const history.ClientHistoryScreen(),
        '/driver_completed': (context) => const CompletedDeliveriesScreen(),
        // Rotas que precisam de argumentos podem ser tratadas com onGenerateRoute ou passando argumentos diretamente no Navigator.push
      },
      // Opcional: onGenerateRoute para rotas dinâmicas ou com argumentos complexos
      /*
      onGenerateRoute: (settings) {
        if (settings.name == '/delivery_navigation') {
          final args = settings.arguments as Delivery; // Exemplo de argumento
          return MaterialPageRoute(
            builder: (context) {
              return DeliveryNavigationScreen(delivery: args);
            },
          );
        }
        // Adicionar outras rotas dinâmicas
        assert(false, 'Need to implement ${settings.name}');
        return null;
      },
      */
    );
  }
}

// Tela simples para escolher o modo inicial (Cliente ou Motorista)
class InitialSelectionScreen extends StatelessWidget {
  const InitialSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Modo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: const Text('Entrar como Cliente'),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/client_home');
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Entrar como Motorista'),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/driver_home');
              },
            ),
          ],
        ),
      ),
    );
  }
}
