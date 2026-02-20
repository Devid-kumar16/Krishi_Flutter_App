import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

import '../services/ai_services.dart'; // adjust path if needed

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  final ImagePicker _picker = ImagePicker();
  final AIService _aiService = AIService();

  XFile? _image;
  bool _loading = false;

  String? _disease;
  String? _confidence;
  String? _recommendation;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (file != null) {
      setState(() {
        _image = file;
        _disease = null;
        _confidence = null;
        _recommendation = null;
      });
    }
  }

  Future<void> _detectDisease() async {
    if (_image == null) return;

    setState(() {
      _loading = true;
    });

    final result = await _aiService.detectDisease(_image!.path);

    setState(() {
      _loading = false;

      if (result.containsKey("error")) {
        _disease = result["error"];
        _confidence = "";
        _recommendation = "";
      } else {
        _disease = result["disease"];
        _confidence = "${result["confidence"]}%";
        _recommendation = result["recommendation"];
      }
    });
  }

  Widget _buildImagePreview() {
    if (_image == null) {
      return const Center(
        child: Text(
          "No image selected",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(_image!.path, fit: BoxFit.cover),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(File(_image!.path), fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Disease Detection"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildImagePreview(),
            ),

            const SizedBox(height: 30),

            Wrap(
              spacing: 20,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo),
                  label: const Text("Gallery"),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),

            const SizedBox(height: 30),

            if (_image != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 14),
                ),
                onPressed: _detectDisease,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Detect Disease"),
              ),

            const SizedBox(height: 30),

            if (_disease != null)
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Detection Result",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text("Disease: $_disease"),
                      Text("Confidence: $_confidence"),
                      const SizedBox(height: 10),
                      const Text(
                        "Recommendation:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(_recommendation ?? ""),
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
