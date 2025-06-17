import 'package:app_mobile/firebase_options.dart';
import 'package:app_mobile/presentation/client/history/client_history_screen.dart';
import 'package:app_mobile/presentation/client/home/client_home_screen.dart';
import 'package:app_mobile/presentation/driver/deliveries/completed_deliveries_screen.dart';
import 'package:app_mobile/presentation/driver/deliveries/driver_home_screen.dart';
import 'package:app_mobile/presentation/shared/setting/setting_screen.dart';
import 'package:app_mobile/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_mobile/services/auth_service.dart';
import 'package:app_mobile/presentation/auth/login_screen.dart';
import 'package:app_mobile/providers/theme_provider.dart';
import 'package:app_mobile/app.dart';

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  print("Mensagem em background recebida: ${message.notification?.title}");
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    final pushService = PushNotificationService();
    await pushService.initialize();
    print('Serviço de notificações inicializado com sucesso');
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
  } catch (e) {
    print('Erro ao inicializar serviço de notificações: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => UserTypeProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class UserTypeProvider extends ChangeNotifier {
  bool _isMotorista = false;

  bool get isMotorista => _isMotorista;

  void toggleUserType() {
    _isMotorista = !_isMotorista;
    notifyListeners();
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final authService = AuthService();
    final isLogged = await authService.validateToken();
    if (!mounted) return;
    if (isLogged) {
      // Enviar token FCM ao backend
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId != null) {
        await PushNotificationService().sendFcmTokenToBackend(userId);
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlutterLogo(size: 100),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMotorista = context.watch<UserTypeProvider>().isMotorista;

    return Scaffold(
      appBar: AppBar(
        title: Text(isMotorista
            ? 'Entregas Pendentes'
            : 'Minhas Entregas'), // ------>>> alterando aqui: título único
        automaticallyImplyLeading: false,
        actions: [
          !isMotorista
              ? IconButton(
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
                )
              : IconButton(
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
                ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const SettingsScreen(), // ------>>> alterando aqui: usa SettingScreen diretamente
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(isMotorista ? Icons.person : Icons.delivery_dining),
            onPressed: () {
              context.read<UserTypeProvider>().toggleUserType();
            },
          ),
        ],
      ),
      // ------>>> alterando aqui: remover AppBar das telas filhas adicionando parâmetro
      body: isMotorista
          ? const DriverHomeScreen(showAppBar: false)
          : const ClientHomeScreen(showAppBar: false),
      // ------>>> alterando aqui: FloatingActionButton já será exibido por cada tela
    );
  }
}
