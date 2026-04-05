import 'package:flutter/material.dart';

// Screens
import 'screens/home_screen.dart';
import 'screens/detection_screen.dart';
import 'screens/chat_screen.dart'; // ✅ IMPORTANT (ADD THIS)
import 'screens/market_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/welcome_screen.dart';

class AppRoutes {
  static const welcome = '/welcome';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const disease = '/disease';
  static const advisory = '/advisory';
  static const market = '/market';
  static const profile = '/profile';

  static Map<String, WidgetBuilder> routes = {
    welcome: (_) => const WelcomeScreen(),
    login: (_) => const LoginScreen(),
    signup: (_) => const SignupScreen(),
    home: (_) => const HomeScreen(),
    disease: (_) => const DetectionScreen(),

    // ✅ FIXED HERE → OPEN CHAT SCREEN
    advisory: (_) => const ChatScreen(),

    market: (_) => const MarketScreen(),
    profile: (_) => const ProfileScreen(),
  };
}