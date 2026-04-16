class ApiConfig {

  // ================= SERVERS =================

  // 🔐 Node.js Backend (Auth)
  static const String authBase = "http://10.37.241.138:5000/api/auth";

  // 🤖 FastAPI Backend (AI + Disease)
  static const String aiBase = "http://10.37.241.138:8000";


  // ================= AUTH =================
  static const String login = "$authBase/login";
  static const String signup = "$authBase/signup";


  // ================= AI =================

  // 🌿 Disease Detection
  static const String disease = "$aiBase/predict";

  // 🤖 AI Advisory (FIXED)
  static const String advisory = "$aiBase/chat";


  // ================= MARKET =================
  // ❌ Only keep this if you actually created /market in backend
  static const String market = "$aiBase/market";

}