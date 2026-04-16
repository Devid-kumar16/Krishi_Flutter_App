import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class AIService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  // 🔥 IMPORTANT: Use correct IP (your backend must be running)
  static const String baseUrl = "http://10.37.241.138:8000";

  bool _isListening = false;

  // ================= SPEECH TO TEXT =================

  Future<bool> initSpeech() async {
    return await _speech.initialize(
      onStatus: (status) {
        if (status == "done" || status == "notListening") {
          _isListening = false;
        }
      },
      onError: (error) {
        _isListening = false;
      },
    );
  }

  Future<String> listenToVoice({String language = "en"}) async {
    bool available = await initSpeech();

    if (!available) return "Speech not available";

    String spokenText = "";
    String locale = language == "hi" ? "hi_IN" : "en_IN";

    _isListening = true;

    await _speech.listen(
      localeId: locale,
      listenMode: stt.ListenMode.dictation,
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 10),
      onResult: (result) {
        spokenText = result.recognizedWords;
      },
    );

    while (_isListening) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    await _speech.stop();

    return spokenText.isEmpty ? "No speech detected" : spokenText;
  }

  // ================= AI ADVISORY =================

  Future<String> getAIAdvice(
    String question, {
    String language = "en",
  }) async {
    try {
      final url = Uri.parse("$baseUrl/chat");

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "message": question,
              "lang": language,
            }),
          )
          .timeout(const Duration(seconds: 20));

      print("📡 Status Code: ${response.statusCode}");
      print("📩 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 🔥 Handle different backend formats
        String aiResponse =
            data["reply"] ??
            data["response"] ??
            data["message"] ??
            "";

        if (aiResponse.trim().isEmpty) {
          return "⚠️ AI returned empty response";
        }

        // 🔊 Speak response
        await speak(aiResponse, language: language);

        return aiResponse;
      } else {
        return "❌ Server Error (${response.statusCode})";
      }
    } catch (e) {
      print("❌ Advisory Error: $e");

      return "⚠️ Unable to connect. Check server or internet.";
    }
  }

  // ================= DISEASE DETECTION =================

  Future<Map<String, dynamic>> detectDisease(
    String imagePath,
    String language,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/predict?lang=$language"),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', imagePath),
      );

      var response =
          await request.send().timeout(const Duration(seconds: 25));

      var responseData = await response.stream.bytesToString();

      print("🧪 Disease API Response: $responseData");

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);

        return {
          "disease": data["disease"] ?? "Unknown",
          "confidence": data["confidence"] ?? 0,
          "solution": data["solution"] ?? "No solution available",
        };
      } else {
        return {"error": "Server Error (${response.statusCode})"};
      }
    } catch (e) {
      print("❌ Disease API Error: $e");

      return {"error": "Unable to connect to AI service"};
    }
  }

  // ================= TEXT TO SPEECH =================

  Future<void> speak(String text, {String language = "en"}) async {
    try {
      await _tts.setLanguage(language == "hi" ? "hi-IN" : "en-US");
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      await _tts.stop(); // 🔥 prevent overlap
      await _tts.speak(text);
    } catch (e) {
      print("❌ TTS Error: $e");
    }
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }
}