import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:frontend/config/api_config.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

Future<void> createAppointment({
  required String clientName,
  required String address,
  required String date,
}) async {
  final token = await StorageService.getToken();
  final uri = Uri.parse('${ApiConfig.baseUrl}/appointments');

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

  if (response.statusCode == 201) {
    if (response.body.isNotEmpty) {
      final data = jsonDecode(response.body);
      debugPrint('Created: $data');
    }
    return;
  } else {
    final errorMessage = response.body.isNotEmpty ?
      jsonDecode(response.body)['detail'] :
      'Failed to create appointment';
      throw Exception(errorMessage);
  }
}


Future<void> deleteAppointment(String appointmentId) async {
  final String? token = await StorageService.getToken();
  
  if (token == null) throw Exception('No token found.');

  
  final uri = Uri.parse('${ApiConfig.baseUrl}/appointments/$appointmentId');

  final response = await http.delete(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode != 204) {
    final errorData = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    throw Exception(errorData['detail'] ?? 'Failed to delete appointment');
  }
}


Future<void> updateAppointment({
  required String id,
  String? clientName,
  String? address,
  String? date,
}) async {
  final token = await StorageService.getToken();
  final uri = Uri.parse('${ApiConfig.baseUrl}/appointments/$id');

  // Create a map and only add values that are NOT null
  final Map<String, dynamic> body = {};
  if (clientName != null) body['client_name'] = clientName;
  if (address != null) body['destination_address'] = address;
  if (date != null) body['appointment_date'] = date;

  final response = await http.patch(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(body),
  );

  if (response.statusCode != 200) {
    throw Exception(jsonDecode(response.body)['detail'] ?? 'Update failed');
  }
}


Future<void> generateAndShareReport(int year) async {
  final token = await StorageService.getToken();
  final uri = Uri.parse('${ApiConfig.baseUrl}/reports/mileage?year=$year');

  final response = await http.get(
    uri,
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/mileage_report_$year.pdf';
    final file = File(filePath);

    await file.writeAsBytes(response.bodyBytes);

    final params = ShareParams(
      files: [XFile(filePath)],
      subject: '$year Mileage Report',
      text: 'Attached is the mileage report for $year.',
    );

    await SharePlus.instance.share(params);
    
  } else {
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Failed to generate report');
  }
}
