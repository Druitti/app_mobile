import 'package:flutter/material.dart';

// Cores
import 'package:flutter/material.dart';

// App information

// Colors
const Color kPrimaryColor = Color(0xFF2196F3); // Azul
const Color kSecondaryColor = Color(0xFF4CAF50); // Verde
const Color kAccentColor = Color(0xFFFFC107); // Amarelo
const Color kBackgroundColor = Color(0xFFF5F5F5); // Cinza claro
const Color kTextColor = Color(0xFF212121); // Quase preto
const Color kTextLightColor = Color(0xFF757575); // Cinza

// Strings de navegação
const String routeClientHome = '/client_home';
const String routeDriverHome = '/driver_home';
const String routeClientHistory = '/client_history';
const String routeClientTracking = '/client_tracking';
const String routeDriverCompleted = '/driver_completed';
const String routeDeliveryNavigation = '/delivery_navigation';
const String routeUpdateStatus = '/update_status';

// Valores padrão
const int apiTimeoutSeconds = 10;

// Strings (Exemplos - podem ser movidos para internacionalização)
const String appTitle = 'App de Entregas';
const String errorTitle = 'Erro';
const String successTitle = 'Sucesso';
const String loadingMessage = 'Carregando...';
const String cameraPermissionDenied = 'Permissão da câmera negada.';
const String locationPermissionDenied = 'Permissão de localização negada.';
const String networkError = 'Erro de rede. Verifique sua conexão.';
const String serverError = 'Erro no servidor. Tente novamente mais tarde.';
const String unknownError = 'Ocorreu um erro desconhecido.';

// Nomes de Tabelas e Colunas (SQLite)
const String tableDeliveries = 'deliveries';
const String columnId = 'id';
const String columnDescription = 'description';
const String columnStatus = 'status';
const String columnClientName = 'client_name';
const String columnDeliveryAddress = 'delivery_address';
const String columnPhotoPath = 'photo_path';
const String columnLatitude = 'latitude';
const String columnLongitude = 'longitude';
const String columnTimestamp = 'timestamp';

// Chaves do SharedPreferences
const String prefThemeMode = 'theme_mode'; // 'light', 'dark', 'system'
const String prefLastSync = 'last_sync';

// Outras Constantes
const double kDefaultPadding = 16.0;

