import 'dart:convert';

import 'package:frontend/models/appointment_models.dart';
import 'package:frontend/models/user_models.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/config/api_config.dart';
import 'package:frontend/services/storage_service.dart';


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

    static Future<UserPublic> getUserProfile() async {
    final String? token = await StorageService.getToken();
    
    if (token == null) {
      throw Exception('No token found. Please log in again.');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/user/me');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return UserPublic.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      await StorageService.deleteToken();
      throw Exception('Session expired');
    } else {
      throw Exception('Failed to load profile');
    }
  }

  static Future<List<AppointmentPublic>> getUserAppointments() async {
    final String? token = await StorageService.getToken();
    
    if (token == null) {
      throw Exception('No token found. Please log in again.');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/appointments');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      await StorageService.deleteToken();
      throw Exception('Session expired');
    } else {
      throw Exception('Failed to appointments');
    }
  }
}
