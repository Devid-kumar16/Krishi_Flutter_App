import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class MarketService {

  // ================= FETCH ALL CROPS =================
  static Future<List<dynamic>> getAllMarketData() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.market))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // ================= SEARCH CROP =================
  static Future<List<dynamic>> searchCrop(String crop) async {
    try {
      final response = await http
          .get(
            Uri.parse("${ApiConfig.market}?crop=${crop.trim()}"),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // ================= MULTI LANGUAGE SEARCH =================
  static String translateCropName(String crop) {

    Map<String, String> hindiMap = {
      "गेहूं": "Wheat",
      "चावल": "Rice",
      "सोयाबीन": "Soybean",
      "कपास": "Cotton",
    };

    return hindiMap[crop] ?? crop;
  }
}
