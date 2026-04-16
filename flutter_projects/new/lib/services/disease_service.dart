import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class DiseaseService {

  // ================= MAIN FUNCTION =================
  static Future<Map<String, dynamic>> detectDisease(
    File image,
    String language,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.aiBase}/predict'),
      );

      // 📸 Image
      request.files.add(
        await http.MultipartFile.fromPath('file', image.path),
      );

      // 🌍 Language
      request.fields['lang'] = language;

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      print("API RESPONSE: $responseData");

      final data = jsonDecode(responseData);

      double confidence =
          double.tryParse(data["confidence"].toString()) ?? 0.0;

      String disease = data["disease"] ?? "Unknown";

      // ✅ Confidence Label
      String confidenceLabel = _getConfidenceLabel(confidence);

      return {
        "disease": disease,
        "confidence": confidence,
        "confidence_label": confidenceLabel,

        // ✅ USE BACKEND DATA
        "cause": data["cause"] ?? "N/A",
        "treatment": data["treatment"] ?? "N/A",
        "fertilizer": data["fertilizer"] ?? "N/A",
        "prevention": data["prevention"] ?? "N/A",
        "source": data["source"] ?? "System",

        // ✅ Updated Warning (No expert line)
        "warning": _getWarning(confidence),
      };
    } catch (e) {
      print("❌ Disease Error: $e");

      return {
        "disease": "Unknown",
        "confidence": 0.0,
        "confidence_label": "Low ❌",
        "cause": "Unable to detect",
        "treatment": "Please try again",
        "fertilizer": "N/A",
        "prevention": "N/A",
        "source": "System",
        "warning": "Detection failed. Retry.",
      };
    }
  }

  // ================= CONFIDENCE LOGIC =================
  static String _getConfidenceLabel(double confidence) {
    if (confidence > 85) {
      return "High Confidence ✅";
    } else if (confidence > 60) {
      return "Medium ⚠";
    } else {
      return "Low ❌";
    }
  }

  static String _getWarning(double confidence) {
    if (confidence > 85) {
      return "✔ Recommendation is reliable.";
    } else if (confidence > 60) {
      return "⚠ Check carefully before applying.";
    } else {
      return "❌ Not reliable. Retake image.";
    }
  }
}