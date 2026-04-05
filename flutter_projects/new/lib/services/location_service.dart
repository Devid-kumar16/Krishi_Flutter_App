import 'package:geolocator/geolocator.dart';

class LocationService {

  /// ✅ Main function to get location
  static Future<Position?> getLocation() async {
    try {
      // 1️⃣ Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("❌ Location services are disabled.");
        return null;
      }

      // 2️⃣ Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      // 3️⃣ Request permission if denied
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // 4️⃣ Handle denied cases
      if (permission == LocationPermission.denied) {
        print("❌ Location permission denied");
        return null;
      }

      if (permission == LocationPermission.deniedForever) {
        print("❌ Location permanently denied");
        return null;
      }

      // 5️⃣ Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;

    } catch (e) {
      print("❌ Location Error: $e");
      return null;
    }
  }
}