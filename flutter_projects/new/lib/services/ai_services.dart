import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class AIService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  static const String baseUrl = "http://10.193.156.138:8000";

  bool _isListening = false;

  // ================= SPEECH TO TEXT =================

  Future<bool> initSpeech() async {
    return await _speech.initialize(
      onStatus: (status) {
        if (status == "done") {
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

  Future<String> getAIAdvice(String question) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/advisory"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"question": question}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data["response"];

        await speak(aiResponse); // auto detect language
        return aiResponse;
      } else {
        return "Server Error ${response.statusCode}";
      }
    } catch (e) {
      return "Unable to connect to AI service";
    }
  }

  // ================= DISEASE DETECTION =================

  Future<Map<String, dynamic>> detectDisease(
    String imagePath, {
    String language = "en",
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/predict"),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', imagePath),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      print("Disease API Response: $responseData");

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        final prediction = data["prediction"];

        return {
          "disease": prediction["disease"],
          "confidence": prediction["confidence"],
          "recommendation": prediction["recommendation"],
        };
      } else {
        return {"error": "Server Error ${response.statusCode}"};
      }
    } catch (e) {
      return {"error": "Unable to connect to AI service"};
    }
  }

  // ================= TEXT TO SPEECH =================

  Future<void> speak(String text) async {
    try {
      // Auto detect Hindi characters
      if (text.contains(RegExp(r'[अ-ह]'))) {
        await _tts.setLanguage("hi-IN");
      } else {
        await _tts.setLanguage("en-US");
      }

      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      await _tts.speak(text);
    } catch (e) {
      print("TTS Error: $e");
    }
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }
}
