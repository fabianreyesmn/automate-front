import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/vehicle.dart';
import '../models/document.dart';

class VehicleService {
  static final String _baseUrl = dotenv.env['BACKEND_URL']!;

  static Future<List<Vehicle>> getVehicles(String token) async {
    final url = Uri.parse('$_baseUrl/api/vehicles');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> vehicleList = data['vehicles'];
      return vehicleList.map((json) => Vehicle.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load vehicles');
    }
  }

  static Future<Vehicle> addVehicle(String token, Vehicle vehicle) async {
    final url = Uri.parse('$_baseUrl/api/vehicles');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(vehicle.toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Vehicle.fromJson(data['vehicle']);
    } else {
      throw Exception('Failed to add vehicle');
    }
  }

  static Future<List<Document>> getDocuments(String token, String vehicleId) async {
    final url = Uri.parse('$_baseUrl/api/vehicles/$vehicleId/documents');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> docList = data['documents'];
      return docList.map((json) => Document.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load documents');
    }
  }

  static Future<Document> uploadDocument({
    required String token,
    required String vehicleId,
    required String documentType,
    required File file,
    DateTime? expiryDate,
  }) async {
    final url = Uri.parse('$_baseUrl/api/vehicles/$vehicleId/documents');
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['documentType'] = documentType;

    if (expiryDate != null) {
      request.fields['expiryDate'] = expiryDate.toIso8601String();
    }

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType('application', 'octet-stream'),
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Document.fromJson(data['document']);
    } else {
      throw Exception('Failed to upload document. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }
}
