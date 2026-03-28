import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://192.168.4.117:80';
    } else if (Platform.isIOS) {
      return 'http://192.168.4.117:80';
    } else {
      return 'http://192.168.4.117:80';
    }
  }
}