import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/models/appointment_models.dart';
import 'package:frontend/models/user_models.dart';
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
    } else {
      final errorData = jsonDecode(response.body);
      final message = errorData['detail'] ?? 'An unknown error occurred';
      throw Exception(message);
    }
  }

  static Future<String> login(String email, String password) async {
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
      final errorData = jsonDecode(response.body);
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

  static Future<List<AppointmentPublic>> getUserAppointments(int year) async {
    final String? token = await StorageService.getToken();

    if (token == null) {
      throw Exception('No token found. Please log in again.');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/appointments/');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => AppointmentPublic.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      await StorageService.deleteToken();
      throw Exception('Session expired');
    } else {
      throw Exception('Failed to load appointments');
    }
  }

  static Future<UserPublic> updateUser(int userId, UserUpdate updateData) async {
    final String? token = await StorageService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/user/$userId/');

    final Map<String, dynamic> body = updateData.toJson();
    // Remove nulls so we don't overwrite existing data with nulls
    body.removeWhere((key, value) => value == null);

    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
    if (response.body.isEmpty) {
      return await getUserProfile(); 
    }
    return UserPublic.fromJson(jsonDecode(response.body));
  } else {
      final errorData = jsonDecode(response.body);
      final message = errorData['detail'] ?? 'Failed to update profile';
      throw Exception(message);
    }
  }

  static Future<void> deleteAccount(int userId) async {
    final String? token = await StorageService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/user/$userId/');

    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete account');
    } else {
      await StorageService.deleteToken();

    }
  }
}
