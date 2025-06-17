import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Chave para armazenar o token FCM nas preferências
const String _keyFcmToken = 'fcm_token';

/// Define um canal de notificação de alto nível para notificações de entregas
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'entrega_status_channel', // id
  'Atualizações de Entregas', // title
  description:
      'Notificações sobre status e atualizações de entregas', // description
  importance: Importance.high,
  enableVibration: true,
  playSound: true,
);

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  // Instância do Firebase Messaging
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Plugin de notificações locais para Android/iOS
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Stream controller para notificações recebidas
  final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Stream pública para ouvir notificações
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStreamController.stream;

  String? _fcmToken;

  /// Inicializa o serviço de notificações
  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        print('Push notifications não são suportadas na web. Serviço não inicializado.');
        return;
      }
      // Inicializa Firebase (certifique-se que Firebase.initializeApp() já foi chamado no main.dart)
      if (!kIsWeb) {
        // Configurar permissões para iOS
        if (Platform.isIOS) {
          await _firebaseMessaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
          await _firebaseMessaging.setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
        }

        // Configurar canal de notificação para Android
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        // Inicializar plugin de notificações locais
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        final DarwinInitializationSettings initializationSettingsIOS =
            DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          onDidReceiveLocalNotification:
              (int id, String? title, String? body, String? payload) async {
            // Tratar notificação local iOS (versões antigas)
            _handleLocalNotification(id, title, body, payload);
          },
        );

        final InitializationSettings initializationSettings =
            InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

        await _flutterLocalNotificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse:
              (NotificationResponse notificationResponse) {
            // Tratar toque em notificação
            _handleNotificationTap(notificationResponse.payload);
          },
        );
      }

      // Obter token atual do FCM
      await _getAndSaveToken();

      // Configurar handlers para diferentes estados de notificação
      _configureNotificationHandlers();

      print('Serviço de notificações inicializado com sucesso');
    } catch (e) {
      print('Erro ao inicializar serviço de notificações: $e');
    }
  }

  // Obtém e salva o token FCM
  Future<String?> _getAndSaveToken() async {
    if (kIsWeb) return null;
    try {
      _fcmToken = await _firebaseMessaging.getToken();

      if (_fcmToken != null) {
        print('Token FCM: $_fcmToken');

        // Salvar o token para uso futuro
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyFcmToken, _fcmToken!);

        // Enviar o token para seu servidor backend (se necessário)
        // await _sendTokenToServer(_fcmToken!);
      }

      return _fcmToken;
    } catch (e) {
      print('Erro ao obter token FCM: $e');
      return null;
    }
  }

  /// Obtém o token FCM armazenado
  Future<String?> getFcmToken() async {
    if (kIsWeb) return null;
    if (_fcmToken != null) return _fcmToken;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFcmToken);
  }

  // Configura handlers para diferentes estados de notificação
  void _configureNotificationHandlers() {
    if (kIsWeb) return;
    // 1. Notificação recebida com app em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
          'Notificação recebida com app em primeiro plano: ${message.notification?.title}');

      _processNotification(message);
    });

    // 2. Notificação tocada com app em segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
          'Notificação tocada com app em segundo plano: ${message.notification?.title}');

      _processNotification(message, isAppOpened: true);
    });

    // 3. Verificar notificação inicial (app aberto a partir de notificação com app fechado)
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print(
            'App aberto a partir de notificação: ${message.notification?.title}');

        _processNotification(message, isAppOpened: true);
      }
    });
  }

  // Processa notificação recebida
  void _processNotification(RemoteMessage message, {bool isAppOpened = false}) {
    if (kIsWeb) return;
    final notification = message.notification;
    final data = message.data;

    print('Dados da notificação: $data');

    // Se temos uma notificação e estamos em primeiro plano, mostrar notificação local
    if (notification != null && !kIsWeb) {
      // No Android, mostrar notificação local para melhor controle
      if (Platform.isAndroid) {
        _flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: json.encode(data),
        );
      }
    }

    // Adicionar notificação ao stream
    _notificationStreamController.add({
      'title': notification?.title,
      'body': notification?.body,
      'data': data,
      'isAppOpened': isAppOpened,
    });
  }

  // Trata toque em notificação local
  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      try {
        final data = json.decode(payload) as Map<String, dynamic>;
        _notificationStreamController.add({
          'data': data,
          'isAppOpened': true,
        });
      } catch (e) {
        print('Erro ao processar payload da notificação: $e');
      }
    }
  }

  // Trata notificação local iOS (versões antigas)
  void _handleLocalNotification(
      int id, String? title, String? body, String? payload) {
    print('Notificação local recebida: $title - $body');
    if (payload != null) {
      try {
        final data = json.decode(payload) as Map<String, dynamic>;
        _notificationStreamController.add({
          'title': title,
          'body': body,
          'data': data,
        });
      } catch (e) {
        print('Erro ao processar payload da notificação local: $e');
      }
    }
  }

  // Envia token para o servidor
  Future<void> _sendTokenToServer(String token) async {
    try {
      // Implementar lógica para enviar token ao seu servidor
      // Exemplo:
      // await http.post(
      //   Uri.parse('https://seu-servidor.com/api/tokens'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode({'token': token}),
      // );
    } catch (e) {
      print('Erro ao enviar token para o servidor: $e');
    }
  }

  /// Envia uma notificação local (útil para testes ou notificações geradas pelo app)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    required String orderId,
    String status = 'atualizado',
    Map<String, dynamic>? additionalData,
  }) async {
    final Map<String, dynamic> payload = {
      'order_id': orderId,
      'status': status,
      ...?additionalData,
    };

    await _flutterLocalNotificationsPlugin.show(
      orderId.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          priority: Priority.high,
          importance: Importance.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(payload),
    );

    // Adicionar ao stream para atualizar a UI
    _notificationStreamController.add(payload);
  }

  /// Envia uma notificação para outro dispositivo (requer servidor)
  Future<bool> sendPushNotification({
    required String targetToken,
    required String title,
    required String body,
    required String orderId,
    required String status,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // IMPORTANTE: Em produção, isto deve ser feito pelo seu servidor backend
      // por razões de segurança. Esta implementação é apenas para demonstração.

      const String fcmUrl = 'https://fcm.googleapis.com/fcm/send';

      // Sua chave de servidor FCM (normalmente estaria segura no backend)
      const String serverKey =
          'SUA_CHAVE_DE_SERVIDOR_FCM'; // Substitua pela sua chave real

      final Map<String, dynamic> data = {
        'order_id': orderId,
        'status': status,
        ...?additionalData,
      };

      final Map<String, dynamic> notification = {
        'title': title,
        'body': body,
        'sound': 'default',
      };

      final Map<String, dynamic> request = {
        'notification': notification,
        'data': data,
        'to': targetToken,
        'priority': 'high',
      };

      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(request),
      );

      if (response.statusCode == 200) {
        print('Notificação enviada com sucesso: ${response.body}');
        return true;
      } else {
        print(
            'Falha ao enviar notificação: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Erro ao enviar notificação: $e');
      return false;
    }
  }

  /// Notifica o usuário sobre uma alteração no status de entrega
  Future<void> notifyOrderStatusChange({
    required String orderId,
    required String status,
    String? titulo,
    String? mensagem,
  }) async {
    // Determinar título e mensagem com base no status
    String notificationTitle = titulo ?? 'Status da Entrega Atualizado';
    String notificationBody = mensagem ?? 'Sua entrega #$orderId está $status';

    // Personalizar mensagem com base no status
    if (titulo == null || mensagem == null) {
      switch (status.toLowerCase()) {
        case 'em trânsito':
          notificationTitle = 'Entrega a Caminho';
          notificationBody =
              'Sua entrega #$orderId está a caminho com nosso motorista';
          break;
        case 'entregue':
          notificationTitle = 'Entrega Concluída';
          notificationBody = 'Sua entrega #$orderId foi concluída com sucesso!';
          break;
        case 'cancelado':
          notificationTitle = 'Entrega Cancelada';
          notificationBody = 'Sua entrega #$orderId foi cancelada';
          break;
        case 'preparando':
          notificationTitle = 'Preparando Entrega';
          notificationBody = 'Estamos preparando sua entrega #$orderId';
          break;
      }
    }

    // Mostrar notificação local para o usuário atual
    await showLocalNotification(
      title: notificationTitle,
      body: notificationBody,
      orderId: orderId,
      status: status,
    );
  }

  /// Limpa todas as notificações
  Future<void> clearAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Cancela uma notificação específica pelo ID da entrega
  Future<void> cancelNotification(String orderId) async {
    await _flutterLocalNotificationsPlugin.cancel(orderId.hashCode);
  }

  /// Limpa recursos ao descartar o serviço
  void dispose() {
    _notificationStreamController.close();
  }

  /// Envia o token FCM para o backend para associar ao usuário logado
  Future<void> sendFcmTokenToBackend(String userId) async {
    final token = await getFcmToken();
    if (token == null) return;
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/auth/fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'fcmToken': token}),
      );
      if (response.statusCode == 200) {
        print('Token FCM enviado ao backend com sucesso');
      } else {
        print('Falha ao enviar token FCM ao backend: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao enviar token FCM ao backend: $e');
    }
  }
}
