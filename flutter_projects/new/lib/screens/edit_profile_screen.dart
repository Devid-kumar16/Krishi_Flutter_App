import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String email;

  const EditProfileScreen({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController emailController;
  final phoneController = TextEditingController();
  final villageController = TextEditingController();
  final landController = TextEditingController();

  List<String> crops = [
    "Wheat",
    "Rice",
    "Maize",
    "Cotton",
    "Sugarcane",
    "Vegetables",
  ];

  String? selectedCrop;

  File? _image;
  final picker = ImagePicker();

  bool isLoading = false;

  // 🎤 Speech
  late stt.SpeechToText speech;
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    emailController = TextEditingController(text: widget.email);

    speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    villageController.dispose();
    landController.dispose();
    super.dispose();
  }

  // 📸 IMAGE
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  // 📍 LOCATION
String? locationCoords;

Future<void> getLocation() async {
  LocationPermission permission = await Geolocator.requestPermission();

  if (permission == LocationPermission.denied) {
    showError("Location permission denied");
    return;
  }

  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  locationCoords =
      "${position.latitude},${position.longitude}";

  print("📍 LOCATION: $locationCoords");

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Location detected")),
  );
}

  // 🎤 VOICE INPUT
  void startListening(TextEditingController controller) async {
    bool available = await speech.initialize();

    if (available) {
      setState(() => isListening = true);

      speech.listen(onResult: (result) {
        setState(() {
          controller.text = result.recognizedWords;
        });
      });
    }
  }

  // 🔥 UPDATE PROFILE
  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCrop == null) {
      showError("Please select a crop");
      return;
    }

    setState(() => isLoading = true);

    try {
final result = await AuthService.updateProfile({
  "name": nameController.text.trim(),
  "email": emailController.text.trim(),
  "phone": phoneController.text.trim(),
  "village": villageController.text.trim(), // ✅ REAL village
  "land": landController.text.trim(),
  "crop": selectedCrop,
  "location": locationCoords ?? "", // ✅ GPS separately
});

      if (result["success"] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully")),
        );

        Navigator.pop(context, {
          "name": nameController.text,
          "email": emailController.text,
        });
      } else {
        showError(result["message"] ?? "Update failed");
      }
    } catch (e) {
      showError("Server error");
    }

    if (mounted) setState(() => isLoading = false);
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // 🔥 FIELD WITH MIC
  Widget buildField(
    TextEditingController controller,
    String label, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: (value) =>
            value == null || value.isEmpty ? "Enter $label" : null,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            icon: const Icon(Icons.mic, color: Colors.green),
            onPressed: () => startListening(controller),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Form(
              key: _formKey,

              child: Column(
                children: [

                  // 📸 IMAGE
                  GestureDetector(
                    onTap: pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.green,
                      backgroundImage:
                          _image != null ? FileImage(_image!) : null,
                      child: _image == null
                          ? const Icon(Icons.camera_alt,
                              color: Colors.white, size: 30)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 20),

                  buildField(nameController, "Name"),
                  buildField(emailController, "Email",
                      type: TextInputType.emailAddress),

                  DropdownButtonFormField<String>(
                    value: selectedCrop,
                    items: crops.map((crop) {
                      return DropdownMenuItem(
                        value: crop,
                        child: Text(crop),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCrop = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Select Crop",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  buildField(phoneController, "Phone",
                      type: TextInputType.phone),
                  buildField(villageController, "Village"),

                  ElevatedButton.icon(
                    onPressed: getLocation,
                    icon: const Icon(Icons.location_on),
                    label: const Text("Auto Detect Location"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 15),

                  buildField(landController, "Land (acres)",
                      type: TextInputType.number),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text("Save"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}