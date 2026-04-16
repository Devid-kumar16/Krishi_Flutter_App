import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String apiKey = "782dde071ccd01293ffb76e2a8f88de2";
  static const String baseUrl = "https://api.openweathermap.org/data/2.5/weather";

  /// 🌍 Get weather by latitude & longitude (Current Location)
  static Future<Map<String, dynamic>> getWeatherByLocation(
      double lat, double lon,
      {String lang = "en"}) async {
    final url =
        "$baseUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=$lang";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load weather (Location)");
    }
  }

  /// 🔍 Get weather by city name (Search Feature)
  static Future<Map<String, dynamic>> getWeatherByCity(String city,
      {String lang = "en"}) async {
    final url =
        "$baseUrl?q=$city&appid=$apiKey&units=metric&lang=$lang";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("City not found");
    }
  }

  /// 🌦 Format weather data (Cleaner UI)
  static Map<String, dynamic> formatWeatherData(Map<String, dynamic> data) {
    return {
      "city": data["name"],
      "temp": data["main"]["temp"],
      "feels_like": data["main"]["feels_like"],
      "humidity": data["main"]["humidity"],
      "wind": data["wind"]["speed"],
      "description": data["weather"][0]["description"],
      "icon": data["weather"][0]["icon"],
    };
  }
}