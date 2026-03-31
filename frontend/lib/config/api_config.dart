import 'dart:io';

class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.4.117:80',
  );

  static String get baseUrl {
    if (Platform.isAndroid || Platform.isIOS) {
      return _configuredBaseUrl;
    }
    return _configuredBaseUrl;
  }
}
