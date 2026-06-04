import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:soya_app/features/location/model/location_model.dart';

class LocationProvider extends ChangeNotifier {
  static const String _assetPath = 'assets/maharashtra_locations_official.json';

  List<LocationModel> _districts = [];
  List<LocationModel> get districts => _districts;

  List<LocationModel> _talukas = [];
  List<LocationModel> get talukas => _talukas;

  List<LocationModel> _villages = [];
  List<LocationModel> get villages => _villages;

  // Optimized hierarchical data
  Map<String, List<LocationModel>> _talukasByDistrict = {};
  Map<String, List<LocationModel>> _villagesByTaluka = {};

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

  Future<void> loadData() async {
    if (_districts.isNotEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final String jsonString = await rootBundle.loadString(_assetPath);

      // Use compute to parse large JSON in background
      final Map<String, dynamic> data =
          await compute(_parseLocationData, jsonString);

      _districts = data['districts'] as List<LocationModel>;
      _talukasByDistrict = data['talukas'] as Map<String, List<LocationModel>>;
      _villagesByTaluka = data['villages'] as Map<String, List<LocationModel>>;

      if (_pendingDistrictName != null) {
        _matchPendingDistrict();
      }
    } catch (e) {
      debugPrint("Error loading local location data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Background parsing function
  static Map<String, dynamic> _parseLocationData(String jsonString) {
    final Map<String, dynamic> root = json.decode(jsonString);

    final List<LocationModel> districts = (root['districts'] as List)
        .map((e) => LocationModel(
              id: e['id'] as int,
              name: e['name'] as String,
              code: e['code'] as String,
            ))
        .toList();

    final Map<String, dynamic> talukasRaw = root['talukas'];
    final Map<String, List<LocationModel>> talukasMap = {};
    talukasRaw.forEach((key, value) {
      talukasMap[key] = (value as List)
          .map((e) => LocationModel(
                id: e['id'] as int,
                name: e['name'] as String,
                code: e['code'] as String,
              ))
          .toList();
    });

    final Map<String, dynamic> villagesRaw = root['villages'];
    final Map<String, List<LocationModel>> villagesMap = {};
    villagesRaw.forEach((key, value) {
      villagesMap[key] = (value as List)
          .map((e) => LocationModel(
                id: e['id'] as int,
                name: e['name'] as String,
                code: e['code'] as String,
              ))
          .toList();
    });

    return {
      'districts': districts,
      'talukas': talukasMap,
      'villages': villagesMap,
    };
  }

  void selectDistrict(LocationModel? value) {
    if (value == _selectedDistrict) return;

    _selectedDistrict = value;
    _selectedTaluka = null;
    _selectedVillage = null;
    _talukas = [];
    _villages = [];

    if (value != null && value.code != null) {
      _talukas = _talukasByDistrict[value.code] ?? [];
      if (_pendingTalukaName != null) {
        _matchPendingTaluka();
      }
    }
    notifyListeners();
  }

  void selectTaluka(LocationModel? value) {
    if (value == _selectedTaluka) return;

    _selectedTaluka = value;
    _selectedVillage = null;
    _villages = [];

    if (value != null && value.code != null) {
      _villages = List.from(_villagesByTaluka[value.code] ?? []);
      _villages.add(LocationModel.other);
      if (_pendingVillageName != null) {
        _matchPendingVillage();
      }
    }
    notifyListeners();
  }

  void selectVillage(LocationModel? value) {
    if (value == _selectedVillage) return;
    _selectedVillage = value;
    notifyListeners();
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
      selectDistrict(match);
      _pendingDistrictName = null;
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
      selectTaluka(match);
      _pendingTalukaName = null;
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
    notifyListeners();
  }
}
