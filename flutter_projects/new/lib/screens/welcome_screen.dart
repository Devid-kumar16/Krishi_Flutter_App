import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final FlutterTts flutterTts = FlutterTts();
  bool welcomePlayed = false;

  @override
  void initState() {
    super.initState();
    _speakWelcome();
  }

  Future<void> _speakWelcome() async {
    if (!welcomePlayed) {
      await flutterTts.setLanguage("en-IN");
      await flutterTts.setPitch(1.0);
      await flutterTts.speak("Welcome to Krishi. Smart farming starts here.");
      welcomePlayed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFA8E063), Color(0xFF56AB2F)],
              ),
            ),
          ),

          // Top Navigation
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.eco, color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      Text(
                        "Krishi",
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.lock),
                    label: Text("Login"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, "/login");
                    },
                  )
                ],
              ),
            ),
          ),

          // Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: Icon(Icons.eco, size: 55, color: Colors.white),
                ),
                SizedBox(height: 30),
                Text(
                  "Krishi",
                  style: TextStyle(fontSize: 60, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  "AI Based Smart Farming Application",
                  style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  onPressed: () {
                    Navigator.pushNamed(context, "/home");
                  },
                  child: Text("Get Started", style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
