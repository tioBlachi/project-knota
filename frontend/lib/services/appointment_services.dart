import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:frontend/config/api_config.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:http/http.dart' as http;

Future<void> createAppointment({
  required String clientName,
  required String address,
  required String date,
}) async {
  final token = await StorageService.getToken();
  final uri = Uri.parse('${ApiConfig.baseUrl}/appointments/');

  final response = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'client_name': clientName,
      'destination_address': address,
      'appointment_date': date,
    }),
  );

  if (response.statusCode != 201) {
    if (response.body.isEmpty) {
      debugPrint('Success ,but received an empty body');
      return;
    }
    final data = jsonDecode(response.body);
    debugPrint('Created: $data');
  } else {
    final errorMessage = response.body.isNotEmpty ?
      jsonDecode(response.body)['detail'] :
      'Failed to create appointment';
      throw errorMessage;
  }
}

