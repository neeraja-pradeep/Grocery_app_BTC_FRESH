import '../../core/config/app_config.dart';

class AppConstants {
  // API Configuration - Now uses centralized AppConfig
  @Deprecated('Use AppConfig.apiBaseUrl instead')
  static String get baseUrl => AppConfig.apiBaseUrl;

  // App Configuration
  static const String appName = 'New App';
  static const String appVersion = '1.0.0';
}
