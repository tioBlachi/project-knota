import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _environment = String.fromEnvironment(
    'API_ENV',
    defaultValue: 'lambda',
  );

  static const String _lambdaBaseUrl = String.fromEnvironment(
    'LAMBDA_API_BASE_URL',
    defaultValue: 'https://3onb2vpyn3k4ramtqd3yvqk3py0uecfj.lambda-url.us-east-1.on.aws/',
  );

  static const String _androidLocalBaseUrl = String.fromEnvironment(
    'ANDROID_LOCAL_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String _defaultLocalBaseUrl = String.fromEnvironment(
    'LOCAL_API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static String get baseUrl {
    if (_environment == 'local') {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return _androidLocalBaseUrl;
      }
      return _defaultLocalBaseUrl;
    }

    return _lambdaBaseUrl;
  }
}
