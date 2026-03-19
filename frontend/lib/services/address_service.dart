import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/config/api_config.dart';

class AddressService {
  static Future<List<String>> fetchSuggestions(String query) async {
    final normalizedQuery = query.trim().toUpperCase();

    if (normalizedQuery.isEmpty) {
      return [];
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/addresses/autocomplete?q=$normalizedQuery',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => item.toString()).toList();
    } else {
      throw Exception('Failed to load address suggestions');
    }
  }
}