import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String baseUrl = "http://10.37.241.138:8000";

  /// 🤖 Send message to AI (Hindi + English supported)
  static Future<String> sendMessage(
    String message, {
    String language = "en",
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/chat"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "message": message,
              "lang": language,
            }),
          )
          .timeout(const Duration(seconds: 25));

      print("📡 Status: ${response.statusCode}");
      print("📩 Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ NEW FORMAT (IMPORTANT FIX)
        final reply = data["reply"] ?? "";

        if (reply.trim().isEmpty) {
          return language == "hi"
              ? "⚠️ कोई उत्तर नहीं मिला"
              : "⚠️ No response from AI";
        }

        return reply; // 🔥 RETURN DIRECT AI RESPONSE
      } else {
        return language == "hi"
            ? "❌ सर्वर त्रुटि (${response.statusCode})"
            : "❌ Server error (${response.statusCode})";
      }
    } catch (e) {
      print("❌ Chat Error: $e");

      return language == "hi"
          ? "⚠️ कनेक्शन विफल। सर्वर जांचें।"
          : "⚠️ Connection failed. Check server.";
    }
  }
}