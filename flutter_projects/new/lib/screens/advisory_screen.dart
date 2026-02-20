import 'package:flutter/material.dart';
import '../services/ai_services.dart';

class AdvisoryScreen extends StatefulWidget {
  const AdvisoryScreen({super.key});

  @override
  _AdvisoryScreenState createState() => _AdvisoryScreenState();
}

class _AdvisoryScreenState extends State<AdvisoryScreen> {
  String userQuery = "";
  String aiResponse = "";

  final AIService aiService = AIService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Voice Advisory")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Icon(Icons.mic, color: Colors.green[700], size: 80),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.mic),
              label: const Text("Start Speaking"),
              onPressed: () async {
                String speech = await aiService.listenToVoice();
                setState(() => userQuery = speech);
                String response = await aiService.getAIAdvice(speech);
                setState(() => aiResponse = response);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            ),
            const SizedBox(height: 30),
            if (userQuery.isNotEmpty)
              Text("You said: $userQuery", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (aiResponse.isNotEmpty)
              Card(
                color: Colors.green[50],
                elevation: 2,
                margin: const EdgeInsets.only(top: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(aiResponse),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
