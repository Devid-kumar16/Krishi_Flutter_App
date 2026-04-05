class ApiConfig {

  // ================= SERVERS =================

  // 🔐 Node.js Backend (Auth)
  static const String authBase = "http://10.37.241.138:5000/api/auth";

  // 🤖 FastAPI Backend (AI + Market)
  static const String aiBase = "http://10.37.241.138:8000";


  // ================= AUTH =================
  static const String login = "$authBase/login";
  static const String signup = "$authBase/signup";


  // ================= AI =================
  static const String disease = "$aiBase/predict";
  static const String advisory = "$aiBase/advisory";


  // ================= MARKET =================
  static const String market = "$aiBase/market";
}