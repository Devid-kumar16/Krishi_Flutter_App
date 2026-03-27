class ApiConfig {

  // ✅ YOUR FASTAPI SERVER (correct IP + port)
  static const String baseUrl = "http://10.168.255.138:8000";

  // ================= ENDPOINTS =================
  static const String disease = "$baseUrl/predict";
  static const String advisory = "$baseUrl/advisory";
  static const String market = "$baseUrl/market";

}