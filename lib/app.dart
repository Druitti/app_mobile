import 'package:app_mobile/presentation/client/history/client_history_screen.dart';
import 'package:app_mobile/presentation/client/tracking/client_tracking_screen.dart';
import 'package:app_mobile/presentation/driver/deliveries/driver_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:app_mobile/common/utils/constants.dart';
import 'package:app_mobile/presentation/client/home/client_home_screen.dart';
import 'package:app_mobile/presentation/driver/deliveries/completed_deliveries_screen.dart';
import 'package:app_mobile/presentation/driver/navigation/delivery_navigation_screen.dart';
import 'package:app_mobile/presentation/driver/update_status/update_status_screen.dart';
import 'package:app_mobile/common/model/delivery.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        primarySwatch:  Colors.blue,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          accentColor: kSecondaryColor,
          backgroundColor: kBackgroundColor,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 1,
          color: kPrimaryColor,
          foregroundColor: Colors.white,
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: kPrimaryColor,
          textTheme: ButtonTextTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
      home: const InitialSelectionScreen(),
      // Definindo rotas nomeadas para navegação consistente
      routes: {
        '/client_home': (context) => const ClientHomeScreen(),
        '/driver_home': (context) => const DriverHomeScreen(),
        '/client_history': (context) => const ClientHistoryScreen(),
        '/driver_completed': (context) => const CompletedDeliveriesScreen(),
      },
      // Usando onGenerateRoute para rotas que precisam de argumentos
      onGenerateRoute: (settings) {
        if (settings.name == '/client_tracking') {
          final String orderId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => ClientTrackingScreen(orderId: orderId),
          );
        } else if (settings.name == '/delivery_navigation') {
          final Delivery delivery = settings.arguments as Delivery;
          return MaterialPageRoute(
            builder: (context) => DeliveryNavigationScreen(delivery: delivery),
          );
        } else if (settings.name == '/update_status') {
          final Delivery delivery = settings.arguments as Delivery;
          return MaterialPageRoute(
            builder: (context) => UpdateStatusScreen(delivery: delivery),
          );
        }
        return null;
      },
    );
  }
}

// Tela de seleção inicial
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