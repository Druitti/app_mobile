import 'package:app_mobile/firebase_options.dart';
import 'package:app_mobile/presentation/client/home/client_home_screen.dart';
import 'package:app_mobile/presentation/driver/deliveries/driver_home_screen.dart';
import 'package:app_mobile/presentation/shared/setting/setting_screen.dart';
import 'package:app_mobile/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';



@pragma('vm:entry-point')
// Future<void> _onBackgroundMessage(RemoteMessage message) async {
//   //print("--------------------- On Background Message --------------------");

// (message);
// }
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  
 
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();
   try {
      final pushService = PushNotificationService();
      await pushService.initialize();
      print('Serviço de notificações inicializado com sucesso');
    } catch (e) {
      print('Erro ao inicializar serviço de notificações: $e');
    }
  
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
      title: 'Rastreamento de Entregas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: context.watch<ThemeProvider>().themeMode,
      home: const SplashScreen(),
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
        builder: (context) => const HomeScreen(),
      ),
    );
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
        title: Text(isMotorista ? 'Entregas Pendentes' : 'Minhas Entregas'), // ------>>> alterando aqui: título único
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
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


