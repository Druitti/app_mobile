import 'package:flutter/material.dart';
import 'package:app_mobile/app.dart';
import 'package:app_mobile/services/notification_service.dart'; // Importar serviço de notificação
// Importar outros serviços que precisam ser inicializados globalmente, se houver

Future<void> main() async {
  // Garante que os bindings do Flutter sejam inicializados antes de chamar código nativo
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar serviços essenciais antes de rodar o app
  // Exemplo: Inicializar serviço de notificações
  final notificationService = NotificationService();
  final notificationResult = await notificationService.init();
  notificationResult.fold(
    (failure) => print("Erro ao inicializar notificações: ${failure.message}"),
    (_) => print("Serviço de notificações inicializado com sucesso."),
  );

  // Inicializar outros serviços aqui (ex: SharedPreferences, etc.)

  // Rodar o aplicativo principal
  runApp(const App());
}
