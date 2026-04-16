import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class MarketService {

  // 🔑 Replace with your real Data.gov API key
  static const String agmarknetApiKey = "579b464db66ec23bdd0000011c30106f268549e6651c74fe4297af2d";

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
    String searchCrop = crop.toLowerCase().trim();

    List allData = [];

    // 🔥 FETCH MULTIPLE PAGES
    for (int offset = 0; offset <= 2000; offset += 1000) {

      final url =
          "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
          "?api-key=$agmarknetApiKey"
          "&format=json"
          "&limit=1000"
          "&offset=$offset";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) continue;

      final jsonData = jsonDecode(response.body);
      List records = jsonData["records"] ?? [];

      allData.addAll(records);
    }

    print("TOTAL LOADED: ${allData.length}");

    // 🔥 FILTER LOCALLY
    List filtered = allData.where((item) {
      String commodity =
          item["commodity"].toString().toLowerCase();
      return commodity.contains(searchCrop);
    }).toList();

    print("FILTERED: ${filtered.length}");

    return filtered.map((g) {
      return {
        "crop": g["commodity"] ?? "",
        "market": g["market"] ?? "",
        "state": g["state"] ?? "",
        "district": g["district"] ?? "",
        "price": g["modal_price"] ?? "0",
        "date": g["arrival_date"] ?? "N/A",
        "min_price": g["min_price"] ?? "N/A",
        "max_price": g["max_price"] ?? "N/A",
      };
    }).toList();

  } catch (e) {
    print("Error: $e");
    return [];
  }
}

  // ================= 🔥 REAL PRICE HISTORY =================
static Future<List<double>> getPriceHistory(String crop) async {
  try {
    String searchCrop = crop.toLowerCase();

    final url =
        "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
        "?api-key=$agmarknetApiKey"
        "&format=json"
        "&limit=200";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) return [];

    final jsonData = jsonDecode(response.body);
    List records = jsonData["records"] ?? [];

    // 🔥 FILTER + SORT BY DATE
    List filtered = records.where((item) {
      String commodity =
          item["commodity"].toString().toLowerCase();
      return commodity.contains(searchCrop);
    }).toList();

    filtered.sort((a, b) =>
  a["state"].toString().compareTo(b["state"].toString()));

    filtered.sort((a, b) {
      return a["arrival_date"]
          .toString()
          .compareTo(b["arrival_date"].toString());
    });

    List<double> prices = [];

    for (var e in filtered) {
      double? price =
          double.tryParse(e["modal_price"].toString());

      if (price != null && price > 0) {
        prices.add(price);
      }
    }

    return prices.take(20).toList();

  } catch (e) {
    print("Graph Error: $e");
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