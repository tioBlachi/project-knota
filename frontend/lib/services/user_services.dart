import 'dart:convert';

import 'package:frontend/models/user_models.dart';
import 'package:http/http.dart' as http;
// import 'package:frontend/services/user_services.dart';
import 'package:frontend/config/api_config.dart';


class UserServices {
  static Future<Map<String, dynamic>> createUser(UserCreate user) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/users/');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create user: ${response.body}');
      }
  }
}
