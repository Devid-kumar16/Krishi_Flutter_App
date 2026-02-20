import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isHindi = false;
  bool isLoading = false;

  Future<void> handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final result = await AuthService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (result["token"] != null) {
        // Save token
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", result["token"]);

        if (!mounted) return;

        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        showError(result["message"] ?? "Login failed");
      }
    } catch (e) {
      showError("Server error. Try again.");
    }

    setState(() => isLoading = false);
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),

                const Icon(Icons.agriculture,
                    size: 80, color: Colors.green),

                const SizedBox(height: 20),

                Text(
                  isHindi ? "कृषि ऐप में लॉगिन करें" : "Login to Krishi",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                TextFormField(
                  controller: emailController,
                  validator: (value) =>
                      value == null || value.isEmpty
                          ? "Enter Email"
                          : null,
                  decoration: InputDecoration(
                    labelText: isHindi ? "ईमेल" : "Email",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  validator: (value) =>
                      value == null || value.isEmpty
                          ? "Enter Password"
                          : null,
                  decoration: InputDecoration(
                    labelText: isHindi ? "पासवर्ड" : "Password",
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : Text(
                            isHindi ? "लॉगिन करें" : "Login",
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.signup);
                  },
                  child: Text(
                    isHindi
                        ? "नया खाता बनाएं"
                        : "Don't have an account? Sign Up",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
