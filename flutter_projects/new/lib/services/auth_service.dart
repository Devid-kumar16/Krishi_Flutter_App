import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class AuthService {

  // ================= LOGIN =================
static Future<Map<String, dynamic>> login(
    String email, String password) async {
  try {
    final response = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email.trim(),
        "password": password.trim(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["success"] == true) {
      final prefs = await SharedPreferences.getInstance();

      // ✅ SAVE TOKEN (VERY IMPORTANT)
      await prefs.setString("token", data["token"]);

      // ✅ SAVE USER DATA
      final user = data["user"];

      await prefs.setString("name", user["name"] ?? "");
      await prefs.setString("email", user["email"] ?? "");

      return {
        "success": true,
        "user": user,
      };
    }

    return {
      "success": false,
      "message": data["message"] ?? "Login failed",
    };
  } catch (e) {
    return {
      "success": false,
      "message": "Server error",
    };
  }
}

  // ================= SIGNUP =================
  static Future<Map<String, dynamic>> signup(
      String name, String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.signup), // ✅ FIXED
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "name": name.trim(),
              "email": email.trim(),
              "password": password.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty server response"};
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "message": data["message"] ?? "Signup successful"
        };
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Signup failed"
        };
      }
    } catch (e) {
      print("SIGNUP ERROR: $e");
      return {
        "success": false,
        "message": "Server unreachable. Check backend or IP."
      };
    }
  }

  // ================= GET PROFILE =================
static Future<Map<String, dynamic>> getProfile() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("${ApiConfig.authBase}/profile"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // ✅ MUST
      },
    );

    final data = jsonDecode(response.body);

    return data;

  } catch (e) {
    return {"success": false, "message": "Server error"};
  }
}

  // ================= UPDATE PROFILE =================
  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http
          .put(
            Uri.parse("${ApiConfig.authBase}/profile"), // ✅ FIXED
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      print("UPDATE STATUS: ${response.statusCode}");
      print("UPDATE BODY: ${response.body}");

      if (response.body.isEmpty) {
        return {"success": false, "message": "Empty response"};
      }

      final res = jsonDecode(response.body);

      return res;
    } catch (e) {
      print("UPDATE ERROR: $e");
      return {"success": false, "message": "Server error"};
    }
  }

  // ================= GET LOCAL USER =================
  static Future<Map<String, String>> getLocalUser() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      "name": prefs.getString("name") ?? "Farmer Name",
      "email": prefs.getString("email") ?? "farmer@email.com",
    };
  }

  // ================= LOGOUT =================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}