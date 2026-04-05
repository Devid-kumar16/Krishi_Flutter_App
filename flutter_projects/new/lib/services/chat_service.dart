import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String baseUrl = "http://10.37.241.138:8000"; 

  static Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/advisory"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "question": message,
          "language": "en" // change to "hi" for Hindi
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["response"] ?? "No response";
      } else {
        return "Server error (${response.statusCode})";
      }
    } catch (e) {
      return "Connection failed";
    }
  }
}