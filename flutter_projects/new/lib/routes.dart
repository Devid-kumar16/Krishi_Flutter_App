import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/detection_screen.dart';
import 'screens/advisory_screen.dart';
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
    welcome: (_) => WelcomeScreen(),
    login: (_) => LoginScreen(),
    signup: (_) => SignupScreen(),
    home: (_) => HomeScreen(),
    disease: (_) => DetectionScreen(),
    advisory: (_) => AdvisoryScreen(),
    market: (_) => MarketScreen(),
    profile: (_) => ProfileScreen(),
  };
}
