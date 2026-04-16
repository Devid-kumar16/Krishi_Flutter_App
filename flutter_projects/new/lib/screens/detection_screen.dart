import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';

import '../services/disease_service.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  final ImagePicker _picker = ImagePicker();

  XFile? _image;
  bool _loading = false;

  Map<String, dynamic>? _result;

  // ================= IMAGE PICK =================
  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (file != null) {
      setState(() {
        _image = file;
        _result = null;
      });
    }
  }

  // ================= DETECT =================
  Future<void> _detectDisease() async {
    if (_image == null) return;

    setState(() => _loading = true);

    try {
      String lang = Localizations.localeOf(context).languageCode;

      final result = await DiseaseService.detectDisease(
        File(_image!.path),
        lang,
      );

      setState(() {
        _loading = false;
        _result = result;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _result = null;
      });
    }
  }

  // ================= TRUST MESSAGE =================
  String _getTrustMessage(double confidence) {
    if (confidence > 85) return "✅ High Trust";
    if (confidence > 60) return "⚠ Medium Trust";
    return "❌ Low Trust - Please verify image";
  }

  // ================= SMART TREATMENT =================
  String _getSmartTreatment(String disease, double confidence) {
    if (confidence < 60) {
      return """
⚠️ Low confidence result.

Please:
• Take a clear close-up photo
• Ensure good lighting
• Capture affected leaf properly

Do NOT apply chemicals based on this result.
""";
    }

    switch (disease.toLowerCase()) {
      case "rust disease":
        return """
• Spray Propiconazole 25% EC (1 ml/liter water)
• OR Hexaconazole 5% EC (2 ml/liter)

Repeat after 7–10 days if needed.
""";

      case "leaf spot":
        return """
• Spray Mancozeb 75% WP (2.5 gm/liter)

Repeat every 7 days.
""";

      default:
        return "Consult nearby agriculture expert for exact treatment.";
    }
  }

  // ================= SMART CAUSE =================
  String _getSmartCause(String disease) {
    switch (disease.toLowerCase()) {
      case "rust disease":
        return "Fungal infection (Puccinia species), spreads in humid weather.";
      case "leaf spot":
        return "Caused by bacteria or fungi due to excess moisture.";
      default:
        return "Disease cause not clearly identified.";
    }
  }

  // ================= CHART =================
  Widget _buildChart(Map<String, dynamic> eval) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          barGroups: [
            _bar(0, (eval['accuracy'] ?? 0).toDouble()),
            _bar(1, (eval['precision'] ?? 0).toDouble()),
            _bar(2, (eval['recall'] ?? 0).toDouble()),
            _bar(3, (eval['f1_score'] ?? 0).toDouble()),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: y, width: 16),
      ],
    );
  }

  // ================= IMAGE PREVIEW =================
  Widget _buildImagePreview() {
    if (_image == null) {
      return const Center(child: Text("No image selected"));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: kIsWeb
          ? Image.network(_image!.path, fit: BoxFit.cover)
          : Image.file(File(_image!.path), fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.detectDisease),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildImagePreview(),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.camera),
              child: const Text("Camera"),
            ),

            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              child: const Text("Gallery"),
            ),

            const SizedBox(height: 20),

            if (_image != null)
              ElevatedButton(
                onPressed: _detectDisease,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text("Detect Disease"),
              ),

            const SizedBox(height: 20),

            if (_result != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Disease: ${_result!["disease"]}"),

                      Text(
                        "Confidence: ${_result!["confidence"]}%",
                        style: const TextStyle(color: Colors.orange),
                      ),

                      Text(_getTrustMessage(
                          (_result!["confidence"] ?? 0).toDouble())),

                      const SizedBox(height: 10),

                      Text("🌱 Cause:\n${_getSmartCause(_result!["disease"] ?? "")}"),
                      const SizedBox(height: 6),

                      Text("💊 Treatment:\n${_getSmartTreatment(
                        _result!["disease"] ?? "",
                        (_result!["confidence"] ?? 0).toDouble(),
                      )}"),
                      const SizedBox(height: 6),

                      Text("🌿 Fertilizer:\nUse balanced NPK fertilizer."),
                      const SizedBox(height: 6),

                      Text("🛡 Prevention:\nMonitor crops regularly and avoid excess moisture."),

                      const SizedBox(height: 10),

                      if (_result!["evaluation"] != null)
                        _buildChart(_result!["evaluation"]),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}