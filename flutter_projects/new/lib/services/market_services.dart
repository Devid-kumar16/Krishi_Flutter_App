import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class MarketService {

  // 🔑 Replace with your real Data.gov API key
  static const String agmarknetApiKey = "579b464db66ec23bdd000001ac3ddec914f74b546477ab9b011094c7";

  // ================= FETCH ALL CROPS =================
  static Future<List<dynamic>> getAllMarketData() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.market))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        return jsonData["data"] ?? [];
      } else {
        print("Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error in getAllMarketData: $e");
      return [];
    }
  }

  // ================= SEARCH CROP =================
static Future<List<dynamic>> searchCrop(String crop) async {
  try {
    String translatedCrop = translateCropName(crop);

    // 🔹 1. Your backend API
    final response = await http.get(
      Uri.parse("${ApiConfig.market}?crop=${translatedCrop.trim()}"),
    );

    List backendData = [];

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      backendData = jsonData["data"] ?? [];
    }

    // 🔹 2. Govt API (for complete data)
    final govtUrl =
        "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
        "?api-key=$agmarknetApiKey"
        "&format=json"
        "&filters[commodity]=$translatedCrop"
        "&limit=20";

    final govtResponse = await http.get(Uri.parse(govtUrl));

    List govtData = [];

    if (govtResponse.statusCode == 200) {
      final jsonData = jsonDecode(govtResponse.body);
      govtData = jsonData["records"] ?? [];
    }

    // 🔥 3. MERGE BOTH DATA
    List mergedData = backendData.map((item) {

      // find matching govt record
      final match = govtData.firstWhere(
        (g) => g["market"] == item["market"],
        orElse: () => {},
      );

      return {
        "crop": item["commodity"] ?? item["crop"] ?? "",
        "market": item["market"] ?? "",
        "state": item["state"] ?? match["state"] ?? "",
        "district": item["district"] ?? match["district"] ?? "N/A",
        "price": item["modal_price"] ?? item["price"] ?? "0",
        "date": item["arrival_date"] ??
                match["arrival_date"] ??
                "N/A",

        // 🔥 NEW DATA (important)
        "min_price": match["min_price"] ?? "N/A",
        "max_price": match["max_price"] ?? "N/A",
      };
    }).toList();

    return mergedData;

  } catch (e) {
    print("Error: $e");
    return [];
  }
}

  // ================= 🔥 REAL PRICE HISTORY =================
  static Future<List<double>> getPriceHistory(String crop) async {
    try {
      String translatedCrop = translateCropName(crop);

      final url =
          "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
          "?api-key=$agmarknetApiKey"
          "&format=json"
          "&filters[commodity]=$translatedCrop"
          "&limit=10";

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        List records = jsonData["records"] ?? [];

        List<double> prices = records.map((e) {
          return double.tryParse(e["modal_price"].toString()) ?? 0.0;
        }).toList();

        return prices.reversed.toList(); // oldest → latest
      } else {
        print("History API Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error in getPriceHistory: $e");
      return [];
    }
  }

  // ================= MULTI LANGUAGE SUPPORT =================
  static String translateCropName(String crop) {

    Map<String, String> hindiMap = {
      "गेहूं": "Wheat",
      "चावल": "Rice",
      "सोयाबीन": "Soybean",
      "कपास": "Cotton",
      "टमाटर": "Tomato",
      "प्याज": "Onion",
      "आलू": "Potato",
    };

    return hindiMap[crop.trim()] ?? crop;
  }
}