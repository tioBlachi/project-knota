class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://3onb2vpyn3k4ramtqd3yvqk3py0uecfj.lambda-url.us-east-1.on.aws/',
  );

  static String get baseUrl => _configuredBaseUrl;
}
