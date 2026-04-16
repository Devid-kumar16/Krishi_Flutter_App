import 'package:flutter/material.dart';
import 'package:agri_advisor/l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../routes.dart';
import '../main.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      showMessage("All fields required");
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await AuthService.signup(name, email, password);

      setState(() => isLoading = false);

      if (result["success"] == true) {
        showMessage("Account created successfully");

        Navigator.pushReplacementNamed(context, AppRoutes.login);
      } else {
        showMessage(result["message"] ?? "Signup failed");
      }
    } catch (e) {
      setState(() => isLoading = false);
      showMessage("Server error, try again");
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.signup),

        // 🌍 LANGUAGE SWITCH
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'en') {
                MyApp.setLocale(context, const Locale('en'));
              } else {
                MyApp.setLocale(context, const Locale('hi'));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'en', child: Text("English")),
              const PopupMenuItem(value: 'hi', child: Text("हिंदी")),
            ],
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),

              TextFormField(
                controller: nameController,
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? "Enter name"
                        : null,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: const Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return loc.email;
                  }
                  if (!value.contains("@")) {
                    return "Invalid email";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: loc.email,
                  prefixIcon: const Icon(Icons.email),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: passwordController,
                obscureText: true,
                validator: (value) =>
                    value == null || value.length < 6
                        ? loc.password
                        : null,
                decoration: InputDecoration(
                  labelText: loc.password,
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleSignup,
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white)
                      : Text(
                          loc.signup,
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                      context, AppRoutes.login);
                },
                child: Text(loc.login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}