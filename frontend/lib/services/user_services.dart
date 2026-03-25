import 'dart:convert';

import 'package:frontend/models/user_models.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/config/api_config.dart';


class UserServices {
  static Future<UserPublic> createUser(UserCreate user) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/user/');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return UserPublic.fromJson(jsonData);
        // return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        final message = errorData['detail'] ?? 'An unknow error occured';
        throw Exception(message);
      }
  }

  static Future<String> login(String email, String password) async{
    final uri = Uri.parse('${ApiConfig.baseUrl}/user/login');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['access_token'] as String;
    } else {
      final errorData =jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Login failed');
    }
  }
}
