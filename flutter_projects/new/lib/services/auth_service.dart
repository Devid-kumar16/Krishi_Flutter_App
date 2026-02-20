import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  static const String baseUrl =
      "http://10.193.156.138:5000/api/auth";

  // ================= LOGIN =================
  static Future<Map<String, dynamic>> login(
      String email, String password) async {

    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email.trim(),
              "password": password.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {

        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", data["token"]);
        await prefs.setInt("userId", data["user"]["id"]);

        return {
          "success": true,
          "message": data["message"],
          "user": data["user"],
        };
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Login failed"
        };
      }

    } catch (e) {
      return {
        "success": false,
        "message": "Server unreachable. Please check connection."
      };
    }
  }

  // ================= SIGNUP =================
  static Future<Map<String, dynamic>> signup(
      String name, String email, String password) async {

    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/signup"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "full_name": name.trim(),
              "email": email.trim(),
              "password": password.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": data["message"]
        };
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Signup failed"
        };
      }

    } catch (e) {
      return {
        "success": false,
        "message": "Server unreachable. Please check connection."
      };
    }
  }

  // ================= GET PROFILE =================
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.get(
        Uri.parse("$baseUrl/profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": "Failed to load profile"};
      }

    } catch (e) {
      return {"success": false, "message": "Server error"};
    }
  }

  // ================= LOGOUT =================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
