import 'dart:convert';
import 'package:soya_app/core/services/api_service.dart';
import 'package:soya_app/core/constants/api_constants.dart';

/// Example controller showing how to use ApiService for authenticated API calls
class ExampleApiUsage {
  final _apiService = ApiService.instance;

  /// Example: GET request with authentication (token automatically included)
  Future<void> getFarmerProfile() async {
    try {
      final response = await _apiService.get(
        ApiConstants.farmerProfile,
        // includeAuth defaults to true, so token is automatically added
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Process your data here
        print('Farmer profile: $data');
      } else {
        // Handle error
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  /// Example: POST request with authentication
  Future<void> createFarmer(Map<String, dynamic> farmerData) async {
    try {
      final response = await _apiService.post(
        ApiConstants.createFarmer,
        body: farmerData,
        // Token is automatically included in headers
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('Farmer created: $data');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  /// Example: PUT request with authentication
  Future<void> updateFarmer(
      String farmerId, Map<String, dynamic> updates) async {
    try {
      final url =
          ApiConstants.updateFarmerById.replaceAll('{{farmerId}}', farmerId);

      final response = await _apiService.put(
        url,
        body: updates,
        // Token is automatically included
      );

      if (response.statusCode == 200) {
        print('Farmer updated successfully');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  /// Example: GET request WITHOUT authentication (rare case)
  Future<void> getPublicData() async {
    try {
      final response = await _apiService.get(
        'https://api.example.com/public/data',
        includeAuth: false, // Explicitly disable auth header
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Public data: $data');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  /// Example: POST with custom headers
  Future<void> uploadWithCustomHeaders() async {
    try {
      final response = await _apiService.post(
        ApiConstants.createFarmer,
        body: {'name': 'John Doe'},
        headers: {
          'X-Custom-Header': 'custom-value',
          // Authorization header is still automatically added
        },
      );

      if (response.statusCode == 200) {
        print('Upload successful');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }
}
