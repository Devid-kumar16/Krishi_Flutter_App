import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/bottom_nav.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "Farmer Name";
  String email = "farmer@email.com";

  @override
  void initState() {
    super.initState();
    fetchProfile(); // 🔥 Fetch profile on load
  }

  // 🔥 FIXED: FETCH PROFILE WITH TOKEN
  Future<void> fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      print("TOKEN: $token");

      final response = await http.get(
        Uri.parse("http://10.37.241.138:5000/api/auth/profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("RESPONSE: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        setState(() {
          name = data["user"]["name"] ?? "No Name";
          email = data["user"]["email"] ?? "No Email";
        });
      } else {
        loadLocalData(); // fallback
      }
    } catch (e) {
      print("ERROR: $e");
      loadLocalData(); // fallback
    }
  }


    // 🔥 FALLBACK (VERY IMPORTANT)
  Future<void> loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      name = prefs.getString("name") ?? "Farmer Name";
      email = prefs.getString("email") ?? "farmer@email.com";
    });
  }

  // 🔥 LOGOUT FUNCTION
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            // 🔥 PROFILE HEADER
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              width: double.infinity,
              color: Colors.white,
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    email,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // ✏️ EDIT BUTTON
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                      name: name,
                      email: email,
                    ),
                  ),
                );

                if (result != null) {
                  setState(() {
                    name = result['name'];
                    email = result['email'];
                  });
                }
              },
              child: const Text("Edit Profile"),
            ),

            const SizedBox(height: 20),

            _buildSectionTitle("Settings"),

            _buildTile(Icons.language, "Language (हिंदी / English)", () {
              _showLanguageDialog(context);
            }),

            _buildTile(Icons.notifications, "Notifications", () {
              _showNotificationDialog(context);
            }),

            _buildTile(Icons.lock, "Privacy & Security", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyScreen()),
              );
            }),

            const SizedBox(height: 20),

            _buildSectionTitle("App Features"),

            _buildTile(Icons.camera_alt, "Disease Detection", () {
              Navigator.pushNamed(context, '/disease');
            }),

            _buildTile(Icons.smart_toy, "AI Advisory", () {
              Navigator.pushNamed(context, '/advisory');
            }),

            _buildTile(Icons.store, "Market Prices", () {
              Navigator.pushNamed(context, '/market');
            }),

            const SizedBox(height: 20),

            // 🔥 FIXED LOGOUT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: logout,
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),

      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.green),
          title: Text(title),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select Language"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ListTile(title: Text("English")),
            ListTile(title: Text("हिंदी")),
          ],
        ),
      ),
    );
  }

  void _showNotificationDialog(BuildContext context) {
    bool isEnabled = true;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Notifications"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SwitchListTile(
              title: const Text("Enable Notifications"),
              value: isEnabled,
              onChanged: (value) {
                setState(() => isEnabled = value);
              },
            );
          },
        ),
      ),
    );
  }
}

// 🔐 PRIVACY SCREEN
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Privacy & Security")),
      body: const Center(
        child: Text("Privacy settings coming soon"),
      ),
    );
  }
}