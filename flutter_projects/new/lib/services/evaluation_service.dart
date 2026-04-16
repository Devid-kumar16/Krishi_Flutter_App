import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class EvaluationService {
  static Future<Map<String, dynamic>> getMetrics() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.aiBase}/evaluation'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load evaluation data");
    }
  }
}