import 'package:flutter/material.dart';
import '../services/ai_services.dart';

class AdvisoryScreen extends StatefulWidget {
  const AdvisoryScreen({super.key});

  @override
  State<AdvisoryScreen> createState() => _AdvisoryScreenState();
}

class _AdvisoryScreenState extends State<AdvisoryScreen> {
  final AIService aiService = AIService();

  String userQuery = "";
  String aiResponse = "";
  String selectedLang = "en";

  bool isLoading = false;

  final TextEditingController textController = TextEditingController();

  /// 🎤 Voice Input
  Future<void> startVoice() async {
    setState(() {
      isLoading = true;
    });

    String speech =
        await aiService.listenToVoice(language: selectedLang);

    setState(() {
      userQuery = speech;
      textController.text = speech;
    });

    await getResponse(speech);
  }

  /// 💬 Get AI Response
  Future<void> getResponse(String query) async {
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    String response = await aiService.getAIAdvice(
      query,
      language: selectedLang,
    );

    setState(() {
      aiResponse = response;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Voice Advisory"),
        backgroundColor: Colors.green,
        actions: [
          DropdownButton<String>(
            value: selectedLang,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: "en", child: Text("EN")),
              DropdownMenuItem(value: "hi", child: Text("हिं")),
            ],
            onChanged: (value) {
              setState(() {
                selectedLang = value!;
              });
            },
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 20),

            /// 🎤 Mic Icon
            Icon(Icons.mic, color: Colors.green[700], size: 80),

            const SizedBox(height: 20),

            /// 🎤 Voice Button
            ElevatedButton.icon(
              icon: const Icon(Icons.mic),
              label: const Text("Start Speaking"),
              onPressed: startVoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
              ),
            ),

            const SizedBox(height: 20),

            /// ✍️ Manual Input
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: "Ask your question...",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => getResponse(textController.text),
              child: const Text("Get Advice"),
            ),

            const SizedBox(height: 20),

            /// ⏳ Loading
            if (isLoading)
              const CircularProgressIndicator(),

            const SizedBox(height: 20),

            /// 👤 User Query
            if (userQuery.isNotEmpty)
              Text(
                "You said: $userQuery",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

            const SizedBox(height: 20),

            /// 🤖 AI Response
            if (aiResponse.isNotEmpty)
              Card(
                color: Colors.green[50],
                elevation: 3,
                margin: const EdgeInsets.only(top: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    aiResponse,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
