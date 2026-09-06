import 'package:flutter/foundation.dart';
import 'package:soya_app/core/constants/api_constants.dart';
import 'package:soya_app/core/services/api_service.dart';
import 'package:soya_app/core/utils/api_helper.dart';
import 'package:soya_app/features/location/model/location_model.dart';

class LocationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<LocationModel> _districts = [];
  List<LocationModel> get districts => _districts;

  List<LocationModel> _talukas = [];
  List<LocationModel> get talukas => _talukas;

  List<LocationModel> _villages = [];
  List<LocationModel> get villages => _villages;

  LocationModel? _selectedDistrict;
  LocationModel? get selectedDistrict => _selectedDistrict;

  LocationModel? _selectedTaluka;
  LocationModel? get selectedTaluka => _selectedTaluka;

  LocationModel? _selectedVillage;
  LocationModel? get selectedVillage => _selectedVillage;

  String? _pendingDistrictName;
  String? _pendingTalukaName;
  String? _pendingVillageName;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isTalukasLoading = false;
  bool get isTalukasLoading => _isTalukasLoading;

  bool _isVillagesLoading = false;
  bool get isVillagesLoading => _isVillagesLoading;

  /// Fetches districts from the API exactly once.
  Future<void> loadData() async {
    if (_districts.isNotEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get(ApiConstants.getDistricts);
      final result = ApiHelper.handleResponse(
        response,
        defaultErrorMessage: 'Failed to load districts',
      );
      if (result.success) {
        final data = result.data['data'];
        if (data is List) {
          _districts = data
              .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        _matchPendingDistrict();
      }
    } catch (e) {
      debugPrint('Error loading districts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectDistrict(LocationModel? value) {
    if (value == _selectedDistrict) return;

    _selectedDistrict = value;
    _selectedTaluka = null;
    _selectedVillage = null;
    _talukas = [];
    _villages = [];
    notifyListeners();

    if (value != null && value.code != null && value.code!.isNotEmpty) {
      fetchTalukas(value.code!);
    }
  }

  Future<void> fetchTalukas(String districtCode) async {
    _isTalukasLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get(
        ApiConstants.getTalukas.replaceAll('{{districtCode}}', districtCode),
      );
      final result = ApiHelper.handleResponse(
        response,
        defaultErrorMessage: 'Failed to load talukas',
      );
      if (result.success) {
        final data = result.data['data'];
        if (data is List) {
          _talukas = data
              .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        _matchPendingTaluka();
      }
    } catch (e) {
      debugPrint('Error loading talukas: $e');
    } finally {
      _isTalukasLoading = false;
      notifyListeners();
    }
  }

  void selectTaluka(LocationModel? value) {
    if (value == _selectedTaluka) return;

    _selectedTaluka = value;
    _selectedVillage = null;
    _villages = [];
    notifyListeners();

    if (value != null && value.code != null && value.code!.isNotEmpty) {
      fetchVillages(value.code!);
    }
  }

  Future<void> fetchVillages(String talukaCode) async {
    _isVillagesLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get(
        ApiConstants.getVillages.replaceAll('{{talukaCode}}', talukaCode),
      );
      final result = ApiHelper.handleResponse(
        response,
        defaultErrorMessage: 'Failed to load villages',
      );
      if (result.success) {
        final data = result.data['data'];
        if (data is List) {
          _villages = data
              .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        _villages.add(LocationModel.other);
        _matchPendingVillage();
      }
    } catch (e) {
      debugPrint('Error loading villages: $e');
    } finally {
      _isVillagesLoading = false;
      notifyListeners();
    }
  }

  void selectVillage(LocationModel? value) {
    if (value == _selectedVillage) return;
    _selectedVillage = value;
    notifyListeners();
  }

  /// Creates/retrieves a custom village via the API and adds it to the
  /// currently loaded village list. Returns the created/matched village, or
  /// null on any failure (the caller should not block on this).
  Future<LocationModel?> addCustomVillage(
    String name, {
    required String talukaCode,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    try {
      final response = await _apiService.post(
        ApiConstants.addCustomVillage
            .replaceAll('{{talukaCode}}', talukaCode),
        body: {'name': trimmed},
      );
      final result = ApiHelper.handleResponse(
        response,
        defaultErrorMessage: 'Failed to add village',
      );
      if (result.success) {
        final data = result.data['data'];
        if (data is Map<String, dynamic>) {
          // created / already-exists (duplicate) responses carry an id.
          final id = data['id']?.toString().trim() ?? '';
          if (id.isNotEmpty) {
            final created = LocationModel.fromJson(data);
            if (!_villages.any((v) => v.id == created.id)) {
              _villages.insert(
                _villages.length > 0 ? _villages.length - 1 : 0,
                created,
              );
              notifyListeners();
            }
            return created;
          }
          // "already exists in the official list" response has no id; match
          // by name against the loaded list.
          final official = _villages
              .where((v) =>
                  v.name.toLowerCase() == trimmed.toLowerCase())
              .firstOrNull;
          return official;
        }
      }
    } catch (e) {
      debugPrint('Error adding custom village: $e');
    }
    return null;
  }

  void initializeValues({String? district, String? taluka, String? village}) {
    _pendingDistrictName = district;
    _pendingTalukaName = taluka;
    _pendingVillageName = village;

    if (_districts.isNotEmpty) {
      _matchPendingDistrict();
    }
  }

  void _matchPendingDistrict() {
    if (_pendingDistrictName == null) return;
    final match = _districts
        .where(
          (d) => d.name.toLowerCase() == _pendingDistrictName!.toLowerCase(),
        )
        .firstOrNull;

    if (match != null) {
      _pendingDistrictName = null;
      selectDistrict(match);
    }
  }

  void _matchPendingTaluka() {
    if (_pendingTalukaName == null) return;
    final match = _talukas
        .where(
          (t) => t.name.toLowerCase() == _pendingTalukaName!.toLowerCase(),
        )
        .firstOrNull;

    if (match != null) {
      _pendingTalukaName = null;
      selectTaluka(match);
    }
  }

  void _matchPendingVillage() {
    if (_pendingVillageName == null) return;
    final match = _villages
        .where(
          (v) => v.name.toLowerCase() == _pendingVillageName!.toLowerCase(),
        )
        .firstOrNull;

    if (match != null) {
      selectVillage(match);
      _pendingVillageName = null;
    } else if (_pendingVillageName != null && _pendingVillageName!.isNotEmpty) {
      selectVillage(LocationModel.other);
      // We keep _pendingVillageName so the UI can use it to fill the custom text field
    }
  }

  void reset() {
    _selectedDistrict = null;
    _selectedTaluka = null;
    _selectedVillage = null;
    _talukas = [];
    _villages = [];
    _pendingDistrictName = null;
    _pendingTalukaName = null;
    _pendingVillageName = null;
    _isLoading = false;
    _isTalukasLoading = false;
    _isVillagesLoading = false;
    notifyListeners();
  }
}