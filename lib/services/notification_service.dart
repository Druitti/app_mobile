import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Handler para mensagens em background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Precisamos inicializar o Firebase antes de processar mensagens em background
  await Firebase.initializeApp();
  
  print('Mensagem em background: ${message.messageId}');
  print('Dados: ${message.data}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  // NÃO use late para o _firebaseMessaging
  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Canal de notificação para Android
  final AndroidNotificationChannel _deliveryChannel = const AndroidNotificationChannel(
    'entregas_channel', // ID do canal
    'Entregas', // Nome do canal
    description: 'Canal de notificações de entregas',
    importance: Importance.max,
  );
  
  // Para navegação a partir de notificações
  GlobalKey<NavigatorState>? navigatorKey;

  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<void> initialize({GlobalKey<NavigatorState>? navKey}) async {
    try {
      // Guardar a chave de navegação
      navigatorKey = navKey;
      
      // Verificar se o Firebase está inicializado
      if (Firebase.apps.isEmpty) {
        print('Firebase não inicializado ao chamar NotificationService.initialize()');
        // Tentar inicializar o Firebase, mas em produção é melhor fazer isso no main.dart
        await Firebase.initializeApp();
        print('Firebase inicializado dentro do NotificationService');
      } else {
        print('Firebase já inicializado antes de chamar NotificationService');
      }
      
      // Inicializar FirebaseMessaging após verificar que o Firebase está pronto
      _firebaseMessaging = FirebaseMessaging.instance;
      print('FirebaseMessaging instanciado com sucesso');
      
      // Registrar handler para mensagens em background
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Configurar notificações locais
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
      
      // Criar canal para Android
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_deliveryChannel);

      // Verificar se _firebaseMessaging foi inicializado corretamente
      if (_firebaseMessaging == null) {
        throw Exception('FirebaseMessaging não foi inicializado corretamente');
      }

      // Configurar Firebase Messaging
      NotificationSettings settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      print('Status de permissão de notificações: ${settings.authorizationStatus}');

      // Configurar handlers para diferentes estados do app
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);
      
      // Verificar se o app foi aberto a partir de uma notificação
      RemoteMessage? initialMessage = await _firebaseMessaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleInitialMessage(initialMessage);
      }
      
      // Obter e logar o token FCM
      String? token = await getToken();
      print('Token FCM: $token');
      
      // Configurar callback para atualização do token
      _firebaseMessaging!.onTokenRefresh.listen((newToken) {
        print('Token FCM atualizado: $newToken');
        // Você deve enviar este token atualizado para seu backend
      });
      
      // Configuração para tópicos específicos da app de entrega
      try {
        await subscribeToTopic('entregas_gerais');
        print('Inscrito no tópico entregas_gerais com sucesso');
      } catch (e) {
        print('Erro ao se inscrever no tópico: $e');
      }
      
      print('Serviço de notificações inicializado com sucesso');
    } catch (e) {
      print('Erro ao inicializar serviço de notificações: $e');
      rethrow; // Re-lançar o erro para ser tratado por quem chamou este método
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      print('Mensagem recebida em primeiro plano: ${message.notification?.title}');
      print('Dados da mensagem: ${message.data}');
      
      // Extrair título e corpo da notificação (com fallbacks)
      String title = message.notification?.title ?? 'Nova notificação';
      String body = message.notification?.body ?? '';
      
      // Criar payload personalizado com os dados
      String payload = json.encode({
        'messageId': message.messageId,
        ...message.data,
      });
      
      // Mostrar notificação local
      await _showLocalNotification(
        title: title,
        body: body,
        payload: payload,
      );
    } catch (e) {
      print('Erro ao processar mensagem em primeiro plano: $e');
    }
  }

  void _handleNotificationOpened(RemoteMessage message) {
    try {
      print('App aberto a partir de notificação (background): ${message.messageId}');
      print('Dados: ${message.data}');
      
      // Criar payload para processamento
      String payload = json.encode({
        'messageId': message.messageId,
        ...message.data,
      });
      
      // Processar o toque na notificação
      _processNotificationTap(payload);
    } catch (e) {
      print('Erro ao processar notificação aberta: $e');
    }
  }
  
  void _handleInitialMessage(RemoteMessage message) {
    try {
      print('App aberto a partir de notificação (terminado): ${message.messageId}');
      print('Dados: ${message.data}');
      
      // Criar payload para processamento
      String payload = json.encode({
        'messageId': message.messageId,
        ...message.data,
      });
      
      // Processar o toque na notificação
      _processNotificationTap(payload);
    } catch (e) {
      print('Erro ao processar mensagem inicial: $e');
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _localNotifications.show(
        DateTime.now().millisecond, // ID único para cada notificação
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _deliveryChannel.id,
            _deliveryChannel.name,
            channelDescription: _deliveryChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'Nova notificação de entrega',
            color: const Color(0xFF2196F3), // Cor azul para identificação visual
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      print('Erro ao mostrar notificação local: $e');
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    print('Notificação local tocada com payload: ${response.payload}');
    
    if (response.payload != null) {
      _processNotificationTap(response.payload!);
    }
  }
  
  void _processNotificationTap(String payload) {
    try {
      // Converter payload para mapa
      Map<String, dynamic> data = json.decode(payload);
      print('Processando notificação com dados: $data');
      
      // Verificar o tipo de notificação
      String? notificationType = data['type'] as String?;
      String? entityId = data['id'] as String?;
      
      // Se não tem navegador ou não temos informações suficientes, sair
      if (navigatorKey?.currentState == null) {
        print('Não foi possível navegar: falta navigatorKey');
        return;
      }
      
      if (notificationType == null) {
        print('Tipo de notificação não encontrado no payload, usando rota padrão');
        navigatorKey!.currentState!.pushNamed('/');
        return;
      }
      
      // Navegar com base no tipo de notificação
      switch (notificationType) {
        case 'new_delivery': // Nova entrega disponível para motoristas
          navigatorKey!.currentState!.pushNamed('/driver_home');
          break;
          
        case 'delivery_accepted': // Cliente recebe notificação que entrega foi aceita
          if (entityId != null) {
            navigatorKey!.currentState!.pushNamed('/client_tracking', arguments: entityId);
          } else {
            print('ID da entidade não encontrado para notificação delivery_accepted');
            navigatorKey!.currentState!.pushNamed('/client_home');
          }
          break;
          
        case 'delivery_status': // Atualização de status para cliente
          if (entityId != null) {
            navigatorKey!.currentState!.pushNamed('/client_tracking', arguments: entityId);
          } else {
            print('ID da entidade não encontrado para notificação delivery_status');
            navigatorKey!.currentState!.pushNamed('/client_home');
          }
          break;
          
        case 'delivery_completed': // Entrega concluída
          navigatorKey!.currentState!.pushNamed('/client_history');
          break;
          
        case 'new_order': // Admin/Sistema - nova ordem criada
          navigatorKey!.currentState!.pushNamed('/driver_home');
          break;
          
        default:
          // Para notificações genéricas, ir para a tela inicial correspondente
          bool isClientRelated = notificationType.contains('client') || 
                              notificationType.contains('order');
          
          if (isClientRelated) {
            navigatorKey!.currentState!.pushNamed('/client_home');
          } else {
            navigatorKey!.currentState!.pushNamed('/driver_home');
          }
      }
    } catch (e) {
      print('Erro ao processar payload da notificação: $e');
      // Em caso de erro, tentar navegar para a tela inicial
      navigatorKey?.currentState?.pushNamed('/');
    }
  }

  // Obter o token do dispositivo para envio de notificações direcionadas
  Future<String?> getToken() async {
    try {
      if (_firebaseMessaging == null) {
        print('FirebaseMessaging não inicializado, não é possível obter token');
        return null;
      }
      return await _firebaseMessaging!.getToken();
    } catch (e) {
      print('Erro ao obter token FCM: $e');
      return null;
    }
  }

  // Inscrever o usuário em um tópico (ex: 'motoristas', 'clientes', 'admin')
  Future<void> subscribeToTopic(String topic) async {
    try {
      if (_firebaseMessaging == null) {
        print('FirebaseMessaging não inicializado, não é possível inscrever no tópico');
        return;
      }
      await _firebaseMessaging!.subscribeToTopic(topic);
      print('Inscrito no tópico: $topic');
    } catch (e) {
      print('Erro ao se inscrever no tópico $topic: $e');
    }
  }

  // Cancelar inscrição em um tópico
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      if (_firebaseMessaging == null) {
        print('FirebaseMessaging não inicializado, não é possível cancelar inscrição no tópico');
        return;
      }
      await _firebaseMessaging!.unsubscribeFromTopic(topic);
      print('Inscrição cancelada para o tópico: $topic');
    } catch (e) {
      print('Erro ao cancelar inscrição no tópico $topic: $e');
    }
  }
  
  // Método para enviar o token para o backend
  Future<void> sendTokenToServer(String? token, String userId) async {
    if (token == null) {
      print('Token FCM é nulo, não é possível enviar para o servidor');
      return;
    }
    
    //implementar a lógica para enviar o token para seu backend
   
    print('Enviando token para o servidor para o usuário $userId: $token');
    
    // Implementação real usaria uma API para enviar:
    /*
    try {
      final response = await http.post(
        Uri.parse('https://seu-backend.com/api/device-tokens'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'token': token,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        }),
      );
      
      if (response.statusCode == 200) {
        print('Token registrado com sucesso no servidor');
      } else {
        print('Falha ao registrar token: ${response.body}');
      }
    } catch (e) {
      print('Erro ao enviar token para o servidor: $e');
    }
    */
  }
  
  // Método para enviar uma notificação local com dados personalizados
  Future<void> showCustomNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    String? imageUrl,
  }) async {
    try {
      // Adicionar timestamp para identificação
      data['timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Converter dados para JSON
      String payload = json.encode(data);
      
      // Configuração específica para Android com imagem (se fornecida)
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _deliveryChannel.id,
        _deliveryChannel.name,
        channelDescription: _deliveryChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        // Se uma URL de imagem for fornecida, poderia ser processada aqui
        // para exibição (requer plugin adicional para carregamento de imagem)
      );
      
      // Configuração para iOS
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      // Mostrar a notificação
      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: payload,
      );
    } catch (e) {
      print('Erro ao mostrar notificação personalizada: $e');
    }
  }
}