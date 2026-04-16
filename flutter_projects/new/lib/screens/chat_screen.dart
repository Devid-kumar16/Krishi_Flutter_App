import 'package:flutter/material.dart';
import 'package:agri_advisor/l10n/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../services/chat_service.dart';
import '../main.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<Map<String, String>> messages = [];

  late stt.SpeechToText speech;
  bool isListening = false;

  final FlutterTts tts = FlutterTts();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
  }

  /// 🌍 GET CURRENT LANGUAGE (GLOBAL)
  String get currentLang =>
      Localizations.localeOf(context).languageCode;

  /// 🎤 Start voice input
  void startListening() async {
    bool available = await speech.initialize();

    if (available) {
      setState(() => isListening = true);

      speech.listen(
        localeId: currentLang == "hi" ? "hi_IN" : "en_IN",
        onResult: (result) {
          setState(() {
            controller.text = result.recognizedWords;
          });
        },
      );

      Future.delayed(const Duration(seconds: 5), stopListening);
    }
  }

  void stopListening() async {
    await speech.stop();
    setState(() => isListening = false);
  }

  /// 💬 Send message
  void sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": text});
      isLoading = true;
    });

    controller.clear();
    scrollToBottom();

    final reply = await ChatService.sendMessage(
      text,
      language: currentLang, // ✅ FIXED
    );

    setState(() {
      messages.add({"role": "bot", "text": reply});
      isLoading = false;
    });

    scrollToBottom();

    /// 🔊 Speak in selected language
    await tts.setLanguage(currentLang == "hi" ? "hi-IN" : "en-US");
    await tts.speak(reply);
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.chat),

        /// 🌍 LANGUAGE SWITCH
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (value) {
              if (value == 'en') {
                MyApp.setLocale(context, const Locale('en'));
              } else {
                MyApp.setLocale(context, const Locale('hi'));
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'en', child: Text("English")),
              PopupMenuItem(value: 'hi', child: Text("हिंदी")),
            ],
          ),
        ],
      ),

      body: Column(
        children: [

          /// 💬 CHAT LIST
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];

                return Align(
                  alignment: msg["role"] == "user"
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg["role"] == "user"
                          ? Colors.green[200]
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(msg["text"]!),
                  ),
                );
              },
            ),
          ),

          /// ⏳ LOADING
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),

          /// ✍️ INPUT
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: loc.chat,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),

                /// 🎤 MIC
                IconButton(
                  icon: Icon(
                    isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.green,
                  ),
                  onPressed: isListening ? stopListening : startListening,
                ),

                /// 📤 SEND
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}