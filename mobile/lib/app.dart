import 'package:app_mobile/common/model/delivery.dart';
import 'package:app_mobile/firebase_options.dart';
import 'package:app_mobile/presentation/client/history/client_history_screen.dart';
import 'package:app_mobile/presentation/client/home/client_home_screen.dart';
import 'package:app_mobile/presentation/client/tracking/client_tracking_screen.dart';
import 'package:app_mobile/presentation/driver/deliveries/completed_deliveries_screen.dart';
import 'package:app_mobile/presentation/driver/deliveries/driver_home_screen.dart';
import 'package:app_mobile/common/utils/constants.dart';
import 'package:app_mobile/presentation/driver/navigation/delivery_navigation_screen.dart';
import 'package:app_mobile/presentation/driver/update_status/update_status_screen.dart';
import 'package:app_mobile/presentation/shared/setting/setting_screen.dart';
import 'package:app_mobile/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_mobile/presentation/auth/login_screen.dart';
import 'package:app_mobile/presentation/auth/register_screen.dart';
import 'package:app_mobile/presentation/auth/forgot_password_screen.dart';


@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  print("Mensagem em background recebida: ${message.notification?.title}");
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializar serviço de notificações
  try {
    final pushService = PushNotificationService();
    await pushService.initialize();
    print('Serviço de notificações inicializado com sucesso');
    
    // Configurar manipulador de mensagens em background
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
  } catch (e) {
    print('Erro ao inicializar serviço de notificações: $e');
  }
  
  // Obter preferências compartilhadas
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => UserTypeProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
        primaryColor: kPrimaryColor,
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: context.watch<ThemeProvider>().themeMode,
      
      // Definição das rotas do aplicativo
      initialRoute: '/login',
      
      
      // Rotas estáticas definidas aqui
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const ClientHomeScreen(),
        '/tracking': (context) => const ClientTrackingScreen(),
        '/history': (context) => const ClientHistoryScreen(),
        '/client_home': (context) => const ClientHomeScreen(),
        '/driver_home': (context) => const DriverHomeScreen(),
        '/client_history': (context) => const ClientHistoryScreen(),
        '/driver_completed': (context) => const CompletedDeliveriesScreen(),
        '/settings': (context) => const SettingsScreen(),
          
    

       
      },
      
      // Rotas dinâmicas que precisam de argumentos
      onGenerateRoute: (settings) {
        print('Gerando rota para: ${settings.name} com argumentos: ${settings.arguments}');
        
        // Rota para rastreamento de cliente
        if (settings.name == '/client_tracking') {
          final String orderId = settings.arguments as String;
          return MaterialPageRoute(
            settings: settings, // Importante passar as settings!
            builder: (context) => ClientTrackingScreen(orderId: orderId),
          );
        }
        
        // Rota para navegação de entrega
        else if (settings.name == '/delivery_navigation') {
          final Delivery delivery = settings.arguments as Delivery;
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => DeliveryNavigationScreen(delivery: delivery),
          );
        }
        
        // Rota para atualização de status
        else if (settings.name == '/update_status') {
          final Delivery delivery = settings.arguments as Delivery;
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => UpdateStatusScreen(delivery: delivery),
          );
        }
        
        // Rota desconhecida
        return null;
      },
      
      // Tratamento para rotas desconhecidas
      onUnknownRoute: (settings) {
        print('Rota desconhecida: ${settings.name}');
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Página não encontrada')),
            body: Center(
              child: Text('A página "${settings.name}" não existe.'),
            ),
          ),
        );
      },
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  ThemeMode _themeMode;

  ThemeProvider(this._prefs) : _themeMode = _loadThemeMode(_prefs);

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final isDark = prefs.getBool('isDarkMode') ?? false;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    notifyListeners();
  }
}

class UserTypeProvider extends ChangeNotifier {
  bool _isMotorista = false;

  bool get isMotorista => _isMotorista;

  void toggleUserType() {
    _isMotorista = !_isMotorista;
    notifyListeners();
  }
  
  void setUserType(bool isMotorista) {
    _isMotorista = isMotorista;
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
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const UserSelectionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FlutterLogo(size: 100),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              appTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Modo'),
        automaticallyImplyLeading: false, // Remove o botão voltar
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Selecione o modo de uso:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('Entrar como Cliente'),
              onPressed: () {
                context.read<UserTypeProvider>().setUserType(false);
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('Entrar como Motorista'),
              onPressed: () {
                context.read<UserTypeProvider>().setUserType(true);
                Navigator.pushReplacementNamed(context, '/driver_home');
              },
            ),
            const SizedBox(height: 40),
            TextButton(
              child: const Text('Sobre o App'),
              onPressed: () {
                showAboutDialog(
                  context: context,
                  applicationName: appTitle,
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2023 Sua Empresa',
                  children: [
                    const Text(
                      'Um aplicativo para conectar clientes e motoristas de entrega.',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}