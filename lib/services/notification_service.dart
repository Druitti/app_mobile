import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dartz/dartz.dart';
import 'package:app_mobile/common/utils/failures.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<Either<Failure, bool>> init() async {
    // Solicitar permissão para notificações (Android 13+)
    final PermissionStatus status = await Permission.notification.request();
    if (!status.isGranted) {
      return Left(PermissionFailure("Permissão de notificação negada."));
    }

    // Configurações de inicialização para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            '@mipmap/ic_launcher'); // Use o ícone padrão do app

    // Configurações de inicialização para iOS (solicita permissões)
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // onDidReceiveLocalNotification: onDidReceiveLocalNotification, // Callback para iOS < 10
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    try {
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        // onDidReceiveNotificationResponse: onDidReceiveNotificationResponse, // Callback para quando a notificação é tocada
      );
      return const Right(true);
    } catch (e) {
      print("Erro ao inicializar notificações: $e");
      return Left(UnknownFailure(
          "Falha ao inicializar serviço de notificação: ${e.toString()}"));
    }
  }

  // Função para exibir uma notificação simples
  Future<Either<Failure, Unit>> showNotification(
      int id, String title, String body) async {
    // Detalhes da notificação para Android
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'delivery_channel_id', // ID do canal
      'Atualizações de Entrega', // Nome do canal
      channelDescription: 'Canal para notificações sobre o status da entrega',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    // Detalhes da notificação para iOS
    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
            // sound: 'default',
            // badgeNumber: 1,
            );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    try {
      await _flutterLocalNotificationsPlugin.show(
        id, // ID único da notificação
        title,
        body,
        notificationDetails,
        // payload: 'item x', // Dados opcionais para passar quando a notificação é tocada
      );
      return const Right(unit);
    } catch (e) {
      print("Erro ao exibir notificação: $e");
      return Left(
          UnknownFailure("Falha ao exibir notificação: ${e.toString()}"));
    }
  }

  // --- Callbacks Opcionais ---

  // Callback para quando uma notificação é recebida enquanto o app está em primeiro plano (iOS < 10)
  // static void onDidReceiveLocalNotification(
  //     int id, String? title, String? body, String? payload) async {
  //   // Exibir um diálogo, ou fazer outra coisa?
  //   print('Notificação recebida em foreground (iOS < 10): $title');
  // }

  // Callback para quando o usuário toca na notificação
  // static void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
  //   final String? payload = notificationResponse.payload;
  //   if (notificationResponse.payload != null) {
  //     print('Payload da notificação: $payload');
  //   }
  //   // Navegar para uma tela específica, por exemplo
  //   // await Navigator.push(context, MaterialPageRoute<void>(builder: (context) => SecondScreen(payload)));
  // }
}
