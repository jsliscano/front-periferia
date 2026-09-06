import 'package:flutter/foundation.dart';

/// Configuración de la API del backend Spring Boot.
class ApiConfig {
  ApiConfig._();

  /// Prioridad:
  /// 1) `--dart-define=API_BASE_URL=...` (APK en dispositivo físico)
  /// 2) Web / Windows → localhost
  /// 3) Emulador Android → 10.0.2.2
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    if (kIsWeb) {
      return 'http://localhost:8181';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8181';
    }
    return 'http://localhost:8181';
  }

  static const String registerPath = '/api/users/register';
  static const String loginPath = '/api/users/login';
  static const String tasksPath = '/api/tasks';
}
