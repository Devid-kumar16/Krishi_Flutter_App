import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class DiseaseService {

  static Future<Map<String, dynamic>> detectDisease(File image) async {

    var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.disease)
    );

    request.files.add(
      await http.MultipartFile.fromPath('file', image.path),
    );

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    return jsonDecode(responseData);
  }
}
