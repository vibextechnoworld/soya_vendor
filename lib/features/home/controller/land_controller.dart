import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:soya_app/core/constants/api_constants.dart';
import 'package:soya_app/core/services/api_service.dart';
import 'package:soya_app/core/utils/api_helper.dart';
import 'package:soya_app/core/widgets/tost_message.dart';
import 'package:soya_app/features/home/model/location_model.dart';

class LandController with ChangeNotifier {
  final _apiService = ApiService.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<LocationData> _locations = [];
  List<LocationData> get locations => _locations;

  String? _selectedLocationId;
  String? get selectedLocationId => _selectedLocationId;

  void setSelectedLocation(String? id) {
    _selectedLocationId = id;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Fetch all locations
  Future<void> fetchLocations() async {
    _setLoading(true);
    try {
      final response = await _apiService.get(ApiConstants.getLocations);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final model = LocationModel.fromJson(responseData);
        _locations = model.data ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching locations: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addFarmerLands({
    required BuildContext context,
    required String farmerId,
    required String villageAdd,
    required String taluka,
    required String district,
    required String landType,
    required String area,
    String? landOwnerName,
    String? relationType,
    required List<File> landImages,
  }) async {
    _setLoading(true);
    try {
      final url =
          ApiConstants.createFarmerLands.replaceAll('{{farmerId}}', farmerId);

      final Map<String, String> fields = {
        'villageAdd': villageAdd,
        'taluka': taluka,
        'district': district,
        'landType': landType,
        'area': area,
      };

      if (landOwnerName != null && landOwnerName.isNotEmpty) {
        fields['landOwnerName'] = landOwnerName;
      }
      if (relationType != null && relationType.isNotEmpty) {
        fields['relationType'] = relationType;
      }

      final List<http.MultipartFile> files = [];
      for (final img in landImages) {
        final extension = p.extension(img.path).toLowerCase();
        String mimeType = (extension == '.png') ? 'image/png' : 'image/jpeg';
        if (await img.exists()) {
          files.add(await http.MultipartFile.fromPath(
            'land',
            img.path,
            contentType: MediaType.parse(mimeType),
          ));
        }
      }

      debugPrint('Uploading land to: $url (${files.length} files)');
      final response = await _apiService.multipartRequest(
        url,
        fields: fields,
        files: files,
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Farmer land added successfully!',
        defaultErrorMessage: 'Failed to add land',
      );

      if (context.mounted) {
        ToastMessage.show(
          context,
          message: result.message,
          isError: !result.success,
        );
      }
      return result.success;
    } catch (e) {
      debugPrint('Error adding farmer lands: $e');
      if (context.mounted) {
        ToastMessage.show(
          context,
          message: 'An error occurred: $e',
          isError: true,
        );
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
