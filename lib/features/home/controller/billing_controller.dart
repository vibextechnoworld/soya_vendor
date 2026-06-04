import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soya_app/core/constants/api_constants.dart';
import 'package:soya_app/core/services/api_service.dart';
import 'package:soya_app/core/utils/api_helper.dart';
import 'package:soya_app/core/widgets/tost_message.dart';
import 'package:soya_app/features/home/model/bill_model.dart';
import 'package:soya_app/features/home/model/create_bill_model.dart';
import 'package:soya_app/features/home/model/farmer_list_model.dart';
import 'package:soya_app/features/home/model/farmer_model.dart';
import 'package:soya_app/features/home/model/deduction_master_model.dart';
import 'package:soya_app/features/home/model/goni_type_model.dart';
import 'package:soya_app/features/home/model/quality_rate_model.dart';
import 'package:soya_app/features/home/model/save_bill_request.dart';
import 'package:soya_app/core/services/location_service.dart';
import 'package:soya_app/features/home/model/bill_graph_model.dart';

enum FarmerSearchType { name, aadhaar }

class BillingController extends ChangeNotifier {
  final _apiService = ApiService.instance;

  BillingController() {
    _loadVendorSession();
  }

  Future<void> _loadVendorSession() async {
    final prefs = await SharedPreferences.getInstance();
    _vendorRate = prefs.getInt('vendorRate') ?? 0;
    _vendorName = prefs.getString('userName') ?? 'My Rate';
    if (_vendorRate > 0) {
      _selectedQuality = QualityRateData(
        quality: 'my_rate',
        rate: _vendorRate,
      );
    }
    notifyListeners();
  }

  Map<String, dynamic>? _summaryTotals;
  Map<String, dynamic>? get summaryTotals => _summaryTotals;

  double _currentDeductionAmount = 0.0;
  double get currentDeductionAmount => _currentDeductionAmount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Farmer Search
  Timer? _searchDebounce;
  int _lastSearchTimestamp = 0;
  List<FarmerData> _searchedFarmers = [];
  List<FarmerData> get searchedFarmers => _searchedFarmers;

  // Bill Report Search
  String _billSearchQuery = "";
  String get billSearchQuery => _billSearchQuery;
  Timer? _billSearchDebounce;

  FarmerData? _selectedFarmer;
  FarmerData? get selectedFarmer => _selectedFarmer;

  double _farmerAdvanceBalance = 0.0;
  double get farmerAdvanceBalance => _farmerAdvanceBalance;

  // Bill Report Filters
  DateTime? _billStartDate;
  DateTime? _billEndDate;
  List<String> _selectedBillStatuses = [];
  bool _ignoreVendorId = false;

  DateTime? get billStartDate => _billStartDate;
  DateTime? get billEndDate => _billEndDate;
  List<String> get selectedBillStatuses => _selectedBillStatuses;
  bool get ignoreVendorId => _ignoreVendorId;

  FarmerSearchType _searchType = FarmerSearchType.name;
  FarmerSearchType get searchType => _searchType;

  String _selectedUnit = 'QTL';
  String get selectedUnit => _selectedUnit;

  // Today's Rates
  List<QualityRateData> _todaysRates = [];
  List<QualityRateData> get todaysRates => _todaysRates;

  // Rate History
  List<QualityRateData> _rateHistory = [];
  List<QualityRateData> get rateHistory => _rateHistory;

  int _rateHistoryPage = 1;
  int get rateHistoryPage => _rateHistoryPage;

  int _rateHistoryTotalPages = 1;
  int get rateHistoryTotalPages => _rateHistoryTotalPages;

  int _rateHistoryTotalItems = 0;
  int get rateHistoryTotalItems => _rateHistoryTotalItems;

  DateTime? _rateHistoryStartDate;
  DateTime? get rateHistoryStartDate => _rateHistoryStartDate;

  DateTime? _rateHistoryEndDate;
  DateTime? get rateHistoryEndDate => _rateHistoryEndDate;

  DateTime? _selectedBillingDate;
  DateTime? get selectedBillingDate => _selectedBillingDate;

  void setSelectedBillingDate(DateTime? date) {
    _selectedBillingDate = date;
    notifyListeners();
  }

  QualityRateData? _selectedQuality;
  QualityRateData? get selectedQuality => _selectedQuality;

  int _vendorRate = 0;
  int get vendorRate => _vendorRate;

  String _vendorName = 'My Rate';
  String get vendorName => _vendorName;

  // New Billing Flow State
  List<DeductionMaster> _deductionMasters = [];
  List<DeductionMaster> get deductionMasters => _deductionMasters;

  void setDeductionMasters(List<DeductionMaster> masters) {
    _deductionMasters = masters;
    notifyListeners();
  }

  DeductionMaster? _selectedDeductionMaster;
  DeductionMaster? get selectedDeductionMaster => _selectedDeductionMaster;

  // Single selection for formula masters
  String? _selectedVariationValue; // Keeps "10+2+2" or similar
  DeductionMaster?
      _selectedVariationMaster; // The master this variation belongs to

  String? get selectedVariationValue => _selectedVariationValue;
  DeductionMaster? get selectedVariationMaster => _selectedVariationMaster;

  List<GoniType> _goniTypes = [];
  List<GoniType> get goniTypes => _goniTypes;

  GoniType? _selectedGoniType;
  GoniType? get selectedGoniType => _selectedGoniType;

  List<SelectedBag> _selectedBags = [];
  List<SelectedBag> get selectedBags => _selectedBags;

  void addBag(GoniType type, int count) {
    _selectedBags.add(SelectedBag(goniType: type, bagCount: count));
    notifyListeners();
  }

  void removeBag(int index) {
    if (index >= 0 && index < _selectedBags.length) {
      _selectedBags.removeAt(index);
      notifyListeners();
    }
  }

  String? _vehicleNumber;
  String? get vehicleNumber => _vehicleNumber;

  String? _vehicleType = "Truck"; // Default
  String? get vehicleType => _vehicleType;

  String? _driverName;
  String? get driverName => _driverName;

  Map<String, double> _deductionVariableValues = {};
  Map<String, double> get deductionVariableValues => _deductionVariableValues;

  // Allowed Quality Values (Fetched from API with Code-based Mapping)
  double allowedValueByCode(String code,
      {DeductionMaster? master, double defaultValue = 0.0}) {
    final targetMaster = master ?? _selectedVariationMaster;
    if (targetMaster != null && _selectedVariationValue != null) {
      final delimiter = _selectedVariationValue!.contains('+') ? '+' : '*';
      final parts = _selectedVariationValue!.split(delimiter);
      final variables = targetMaster.variables ?? [];

      int index = variables.indexWhere((v) => v.code == code);

      if (index != -1 && index < parts.length) {
        return double.tryParse(parts[index]) ?? defaultValue;
      }
    }
    return defaultValue;
  }

  double getUnitHint(String? masterId, String? code) {
    if (masterId == null || code == null) return 1.0;
    try {
      final master = _deductionMasters.firstWhere((m) => m.id == masterId);
      final variable = master.variables?.firstWhere((v) => v.code == code);
      final hint = variable?.unitHint;

      if (hint == null || hint.isEmpty) return 1.0;
      if (hint.contains('/')) {
        final parts = hint.split('/');
        if (parts.length == 2) {
          final n = double.tryParse(parts[0]) ?? 1.0;
          final d = double.tryParse(parts[1]) ?? 1.0;
          return n / d;
        }
      }
      return double.tryParse(hint) ?? 1.0;
    } catch (e) {
      return 1.0;
    }
  }

  // Quality Inputs
  Map<String, double> _actualQualityValues = {};
  Map<String, double> get actualQualityValues => _actualQualityValues;

  void updateQualityValue(String code, double value) {
    _actualQualityValues[code] = value;
    notifyListeners();
  }

  // Legacy/Backwards Compatibility for specific methods if needed
  void updateManualQuality({double? moisture, double? dagi, double? fm}) {
    if (moisture != null) _actualQualityValues['moisture'] = moisture;
    if (dagi != null) _actualQualityValues['dagi'] = dagi;
    if (fm != null) _actualQualityValues['mati'] = fm;
    notifyListeners();
  }

  String? _draftBillId;
  String? get draftBillId => _draftBillId;

  List<BillModel> _bills = [];
  List<BillModel> get bills => _bills;

  int _currentPage = 1;
  int get currentPage => _currentPage;

  int _totalPages = 1;
  int get totalPages => _totalPages;

  int _totalItems = 0;
  int get totalItems => _totalItems;

  num _averageRate = 0;
  num get averageRate => _averageRate;

  BillModel? _selectedBillDetails;
  BillModel? get selectedBillDetails => _selectedBillDetails;

  String? _editingBillId;
  String? get editingBillId => _editingBillId;

  CalculationDetails? _calculationDetails;
  CalculationDetails? get calculationDetails =>
      _calculationDetails ?? _selectedBillDetails?.calculationDetails;

  List<BillDeduction> _previewDeductions = [];
  List<BillDeduction> get previewDeductions =>
      _previewDeductions.isNotEmpty == true
          ? _previewDeductions
          : (_selectedBillDetails?.deductions ?? []);

  BillGraphModel? _billGraphData;
  BillGraphModel? get billGraphData => _billGraphData;

  // Create Bill Result
  BillData? _lastCreatedBill;
  BillData? get lastCreatedBill => _lastCreatedBill;

  // Return Bags to Farmer State
  GoniType? _returnGoniType;
  int _returnBagCount = 0;
  String _returnNotes = "";

  bool _isReturnBagsLoading = false;
  bool get isReturnBagsLoading => _isReturnBagsLoading;

  GoniType? get returnGoniType => _returnGoniType;
  int get returnBagCount => _returnBagCount;
  String get returnNotes => _returnNotes;

  void selectReturnGoniType(GoniType? goniType) {
    _returnGoniType = goniType;
    notifyListeners();
  }

  void setReturnBagCount(int count) {
    _returnBagCount = count;
    notifyListeners();
  }

  void setReturnNotes(String notes) {
    _returnNotes = notes;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setReturnBagsLoading(bool value) {
    _isReturnBagsLoading = value;
    notifyListeners();
  }

  // Selection Methods
  void selectFarmer(FarmerData farmer) {
    _selectedFarmer = farmer;
    _searchedFarmers = [];
    if (farmer.id != null) {
      fetchFarmerAdvanceBalance(farmer.id!);
    }
    notifyListeners();
  }

  void setSearchType(FarmerSearchType type) {
    _searchType = type;
    _searchedFarmers = [];
    notifyListeners();
  }

  void setUnit(String unit) {
    _selectedUnit = unit;
    notifyListeners();
  }

  void onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      searchFarmers(query);
    });
  }

  // API Call Methods
  Future<void> searchFarmers(String query) async {
    final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    _lastSearchTimestamp = currentTimestamp;

    if (query.isEmpty) {
      _searchedFarmers = [];
      notifyListeners();
      return;
    }

    _setLoading(true);

    try {
      String url = "${ApiConstants.farmerProfile}?page=1&limit=10";
      if (_searchType == FarmerSearchType.name) {
        url += '&search=${Uri.encodeComponent(query)}';
      } else {
        url += '&adhar_no=${Uri.encodeComponent(query)}';
      }

      final response = await _apiService.get(url);

      // Ignore if a newer search has been initiated
      if (_lastSearchTimestamp != currentTimestamp) return;

      final responseData = jsonDecode(response.body);
      final farmerListModel = FarmerListModel.fromJson(responseData);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          farmerListModel.success == true) {
        _searchedFarmers = farmerListModel.data ?? [];
      } else {
        _searchedFarmers = [];
      }
    } catch (e) {
      if (_lastSearchTimestamp == currentTimestamp) {
        debugPrint('Error searching farmers: $e');
        _searchedFarmers = [];
      }
    } finally {
      if (_lastSearchTimestamp == currentTimestamp) {
        _setLoading(false);
      }
    }
  }

  Future<void> fetchDeductionMasters() async {
    _setLoading(true);
    try {
      final response = await _apiService.get(ApiConstants.getDeductionMasters);
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        _deductionMasters = (responseData['data'] as List)
            .map((e) => DeductionMaster.fromJson(e))
            .toList();

        // Set default selected variation (if any exists)
        if (_deductionMasters.any((m) => m.type == "FORMULA")) {
          final firstFormula =
              _deductionMasters.firstWhere((m) => m.type == "FORMULA");
          if (firstFormula.variableValues?.isNotEmpty == true) {
            _selectedVariationMaster = firstFormula;
            _selectedVariationValue = firstFormula.variableValues!.first;
          }
        }
        _deductionVariableValues.clear();
      }
    } catch (e) {
      debugPrint('Error fetching deduction masters: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchGoniTypes() async {
    try {
      final response = await _apiService.get(ApiConstants.getGoniTypes);
      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Goni types fetched',
        defaultErrorMessage: 'Failed to fetch goni types',
      );

      if (result.success) {
        final model = GoniTypeModel.fromJson(result.data);
        if (model.success == true) {
          _goniTypes =
              (model.data ?? []).where((e) => e.isActive == true).toList();
          // Auto-select "Kaltani Katta" as default if it exists
          const defaultGoniId = "134b6ab2-1fd3-4ce9-ab39-fb13feec1096";
          if (_selectedGoniType == null && _goniTypes.isNotEmpty) {
            final defaultGoni =
                _goniTypes.where((e) => e.id == defaultGoniId).firstOrNull;
            if (defaultGoni != null) {
              _selectedGoniType = defaultGoni;
            }
          }
          // Auto-select first tracked goni type for return if not already set
          if (_goniTypes.isNotEmpty && _returnGoniType == null) {
            final defaultGoni = _goniTypes
                .where((e) => e.id == defaultGoniId && e.isTracked == true)
                .firstOrNull;
            if (defaultGoni != null) {
              _returnGoniType = defaultGoni;
            } else {
              _returnGoniType = _goniTypes
                  .where((element) => element.isTracked == true)
                  .firstOrNull;
            }
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching goni types: $e');
    }
  }

  /// Fetch Today's Rates
  Future<void> fetchTodaysRates() async {
    try {
      final response = await _apiService.get(ApiConstants.getTodaysRate);
      log("Today's Rates API response: ${response.body}");
      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Rates fetched successfully',
        defaultErrorMessage: 'Failed to fetch rates',
      );

      if (result.success) {
        final model = QualityRateModel.fromJson(result.data);
        if (model.success == true) {
          _todaysRates = model.data ?? [];
          _vendorRate = model.vendorRate ?? 0;
          // Auto-fill selected quality with vendor rate if available
          if (_vendorRate > 0) {
            _selectedQuality = QualityRateData(
              quality: 'my_rate',
              rate: _vendorRate,
            );
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching today\'s rates: $e');
    }
  }

  /// Fetch Rates By Date
  Future<void> fetchRatesByDate(DateTime date, {BuildContext? context}) async {
    _setLoading(true);
    try {
      final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final response = await _apiService.get("${ApiConstants.getTodaysRate}?startDate=$formattedDate&endDate=$formattedDate");
      log("Rates for $formattedDate API response: ${response.body}");
      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Rates fetched successfully',
        defaultErrorMessage: 'Failed to fetch rates',
      );

      if (result.success) {
        final model = QualityRateModel.fromJson(result.data);
        if (model.success == true) {
          _todaysRates = model.data ?? [];
          _vendorRate = model.vendorRate ?? 0;
          // Sort by createdAt descending to get the latest one first
          if (_todaysRates.isNotEmpty) {
            _todaysRates.sort((a, b) {
              if (a.createdAt == null) return 1;
              if (b.createdAt == null) return -1;
              return b.createdAt!.compareTo(a.createdAt!);
            });
            _selectedQuality = _todaysRates.first;
          } else if (_vendorRate > 0) {
            _selectedQuality = QualityRateData(
              quality: 'my_rate',
              rate: _vendorRate,
            );
          } else {
            _selectedQuality = null;
          }
          if (_todaysRates.isEmpty && _vendorRate <= 0) {
            if (context != null && context.mounted) {
              ToastMessage.show(
                context,
                message: 'No active quality rates found',
                isError: true,
              );
            }
          }
          notifyListeners();
        } else {
          _todaysRates = [];
          _selectedQuality = null;
          notifyListeners();
          if (context != null && context.mounted) {
            ToastMessage.show(
              context,
              message: model.message ?? 'No active quality rates found',
              isError: true,
            );
          }
        }
      } else {
        _todaysRates = [];
        _selectedQuality = null;
        notifyListeners();
        if (context != null && context.mounted) {
          ToastMessage.show(
            context,
            message: result.message,
            isError: true,
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching rates for date $date: $e');
      if (context != null && context.mounted) {
        ToastMessage.show(
          context,
          message: 'Error fetching rates: $e',
          isError: true,
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch Rate History
  Future<void> fetchRateHistory({int page = 1, int limit = 10}) async {
    _setLoading(true);
    _rateHistoryPage = page;
    try {
      final start = _rateHistoryStartDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = _rateHistoryEndDate ?? DateTime.now();

      final formattedStart = "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";
      final formattedEnd = "${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}";

      String url = "${ApiConstants.getTodaysRate}?startDate=$formattedStart&endDate=$formattedEnd";
      debugPrint("FETCH RATE HISTORY URL: $url");
      final response = await _apiService.get(url);
      
      print('🌐 RATE HISTORY RESPONSE CODE: ${response.statusCode}');
      print('🌐 RATE HISTORY RESPONSE BODY: ${response.body}');
      
      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Rates fetched successfully',
        defaultErrorMessage: 'Failed to fetch rates',
      );

      if (result.success && result.data != null) {
        final model = QualityRateModel.fromJson(result.data);
        final List<QualityRateData> allRates = model.data ?? [];

        // Handle pagination response if server returns it
        if (result.data['totalPages'] != null) {
          _rateHistoryTotalPages = result.data['totalPages'];
          _rateHistoryTotalItems = result.data['totalItems'] ?? allRates.length;
          _rateHistory = allRates;
        } else if (result.data['data'] != null && result.data['data']['pagination'] != null) {
          final pag = result.data['data']['pagination'];
          _rateHistoryTotalPages = pag['totalPages'] ?? 1;
          _rateHistoryTotalItems = pag['total'] ?? allRates.length;
          _rateHistory = allRates;
        } else {
          // Client-side fallback pagination
          _rateHistoryTotalItems = allRates.length;
          _rateHistoryTotalPages = (_rateHistoryTotalItems / limit).ceil();
          if (_rateHistoryTotalPages < 1) _rateHistoryTotalPages = 1;

          final startIndex = (page - 1) * limit;
          final endIndex = startIndex + limit;
          
          if (startIndex < allRates.length) {
            _rateHistory = allRates.sublist(
              startIndex,
              endIndex.clamp(0, allRates.length),
            );
          } else {
            _rateHistory = [];
          }
        }
        notifyListeners();
      }
    } catch (e, stack) {
      debugPrint("❌ Error fetching rate history: $e");
      debugPrint(stack.toString());
    } finally {
      _setLoading(false);
    }
  }

  void setRateHistoryFilters({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (startDate != null) _rateHistoryStartDate = startDate;
    if (endDate != null) _rateHistoryEndDate = endDate;
    notifyListeners();
    fetchRateHistory(page: 1);
  }

  void clearRateHistoryFilters() {
    _rateHistoryStartDate = null;
    _rateHistoryEndDate = null;
    notifyListeners();
    fetchRateHistory(page: 1);
  }

  // Multi-step Flow Implementations

  void selectQuality(QualityRateData? quality) {
    _selectedQuality = quality;
    notifyListeners();
  }

  void selectDeductionMaster(DeductionMaster? master) {
    _selectedDeductionMaster = master;
    // _selectedDeductionVariation = null; // Reset variation - now handled by map
    _deductionVariableValues
        .clear(); // Clear previous values when master changes
    notifyListeners();
  }

  void selectDeductionVariation(String value, DeductionMaster master) {
    _selectedVariationValue = value;
    _selectedVariationMaster = master;
    notifyListeners();
  }

  void selectGoniType(GoniType? goniType) {
    _selectedGoniType = goniType;
    notifyListeners();
  }

  void setVehicleNumber(String value) {
    _vehicleNumber = value;
    notifyListeners();
  }

  void setVehicleType(String value) {
    _vehicleType = value;
    notifyListeners();
  }

  void setDriverName(String value) {
    _driverName = value;
    notifyListeners();
  }

  Future<bool> createDraftBill({
    required BuildContext context,
    required SaveBillRequest request,
  }) async {
    _setLoading(true);
    try {
      // Fetch current location name
      final locationName = await LocationService.getCurrentLocationAddress();
      log('Billing Location Name (Draft): $locationName');

      // Update request with location
      final updatedRequest = SaveBillRequest(
        billId: request.billId,
        farmerId: request.farmerId,
        billDate: request.billDate,
        productId: request.productId,
        quantity: request.quantity,
        unit: request.unit,
        rate: request.rate,
        bagCount: request.bagCount,
        slipNo: request.slipNo,
        gross: request.gross,
        tare: request.tare,
        vehicleNumber: request.vehicleNumber,
        vehicleType: request.vehicleType,
        driverName: request.driverName,
        billLocation: locationName,
      );

      final response = await _apiService.post(
        ApiConstants.createBillDraft,
        body: updatedRequest.toJson(),
      );

      final result = ApiHelper.handleResponse(
        response,
        defaultErrorMessage: 'Failed to create draft',
      );

      if (result.success) {
        final responseData = result.data;
        if (responseData['data'] is Map &&
            responseData['data'].containsKey('bill')) {
          _draftBillId = responseData['data']['bill']['id'].toString();
        } else {
          // Fallback for direct structure if API changes
          _draftBillId = responseData['data']['id'].toString();
        }
        if (context.mounted) {
          ToastMessage.show(context,
              message: 'Draft bill created successfully', isError: false);
        }
        return true;
      } else {
        if (context.mounted) {
          ToastMessage.show(context, message: result.message, isError: true);
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error creating draft: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> calculateDraftDeductions({
    required BuildContext context,
    bool silent = false,
  }) async {
    if (_draftBillId == null) return false;
    _setLoading(true);
    try {
      // Construct deductions payload from masters and variable values
      List<Map<String, dynamic>> deductions = [];

      // Process ONLY the selected formula master variation
      if (_selectedVariationMaster != null && _selectedVariationValue != null) {
        final master = _selectedVariationMaster!;
        Map<String, dynamic> actualInputs = {};
        Map<String, dynamic> customInputs = {};

        // Parse tokens from formulaExpression (e.g., "Moisture + FM + Damage")
        List<String> tokens = [];
        if (master.formulaExpression != null) {
          tokens = master.formulaExpression!
              .split(RegExp(r'[\+\*\-\/\s]'))
              .where(
                  (t) => t.trim().isNotEmpty && !RegExp(r'^\d+$').hasMatch(t))
              .map((t) => t.trim())
              .toList();
        }

        // 1. Get Actual Inputs from Variation (Allowed Values)
        final delimiter = _selectedVariationValue!.contains('+') ? '+' : '*';
        final values = _selectedVariationValue!.split(delimiter);
        final variables = master.variables ?? [];

        for (int i = 0; i < variables.length; i++) {
          final code = variables[i].code ?? "";
          // Use token from formula if available, else fallback to code
          final key = (i < tokens.length) ? tokens[i] : code;

          if (i < values.length) {
            actualInputs[key] = double.tryParse(values[i]) ?? 0.0;
          }
        }

        // 2. Get Custom Inputs from User Entered Values
        for (int i = 0; i < variables.length; i++) {
          final variable = variables[i];
          final code = variable.code ?? "";
          final key = (i < tokens.length) ? tokens[i] : code;

          final actual = _actualQualityValues[code] ?? 0.0;

          // Use custom inputs if actual exceeds or matches allowed (threshold)
          if (actual > 0) {
            customInputs[key] = actual;
          }
        }

        // Add to payload
        deductions.add({
          "masterId": master.id,
          "actualInputs": actualInputs,
          "customInputs": customInputs,
        });
      }
      final body = {
        'deductions': deductions,
      };

      final url = ApiConstants.calculateDeductions
          .replaceAll('{{billId}}', _draftBillId!);

      final response = await _apiService.post(
        url,
        body: body,
      );

      final result = ApiHelper.handleResponse(
        response,
        defaultErrorMessage: 'Calculation failed',
      );

      if (result.success) {
        // Parse individual deduction values from response if available
        try {
          final data = result.data;
          // Look for total deduction amount in nested data
          if (data != null && data['data'] != null) {
            final billData = data['data']['bill'] ?? data['data'];
            _currentDeductionAmount =
                (billData['totalDeductions'] as num?)?.toDouble() ?? 0.0;
          }

          List? deductionsList;
          if (data is Map && data['deductions'] != null) {
            deductionsList = data['deductions'];
          } else if (data is List) {
            deductionsList = data;
          }

          if (deductionsList != null) {
            for (var d in deductionsList) {
              final payload = d['payload'] as Map<String, dynamic>?;
              if (payload != null && payload.containsKey('deductedAmounts')) {
                final deductedAmounts =
                    payload['deductedAmounts'] as Map<String, dynamic>;
                deductedAmounts.forEach((key, value) {
                  // This is just for UI feedback if needed
                });
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing live deductions: $e');
        }

        if (context.mounted && !silent) {
          ToastMessage.show(context,
              message: 'Deductions calculated successfully', isError: false);
        }
        notifyListeners();
        return true;
      } else {
        if (context.mounted && !silent) {
          ToastMessage.show(context,
              message: "${result.message} (ID: $_draftBillId)", isError: true);
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error calculating deductions: $e');
      if (context.mounted) {
        ToastMessage.show(context, message: "Error: $e", isError: true);
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> applyDraftGoniDeduction({
    required BuildContext context,
  }) async {
    if (_draftBillId == null) {
      if (context.mounted) {
        ToastMessage.show(context,
            message: "Draft Bill ID is missing", isError: true);
      }
      return false;
    }
    _setLoading(true);
    try {
      final gonisPayload = _selectedBags.map((bag) {
        return {
          'goniTypeId': bag.goniType.id,
          'bagCount': bag.bagCount,
        };
      }).toList();

      final body = {
        'gonis': gonisPayload,
      };

      final url = ApiConstants.applyGoniDeduction
          .replaceAll('{{billId}}', _draftBillId!);

      final response = await _apiService.post(
        url,
        body: body,
      );

      final result = ApiHelper.handleResponse(
        response,
        defaultErrorMessage: 'Bag deduction application failed',
      );

      if (result.success) {
        if (context.mounted) {
          ToastMessage.show(context,
              message: 'Bag deduction applied successfully', isError: false);
        }

        // Parse the response data to update live totals and calculation details
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['data'] != null) {
            final data = responseData['data'];

            if (data['totals'] != null) {
              _summaryTotals = data['totals'];
            }
            if (data['calculationDetails'] != null) {
              _calculationDetails =
                  CalculationDetails.fromJson(data['calculationDetails']);
            }
            if (data['deductions'] != null) {
              _previewDeductions = (data['deductions'] as List)
                  .map((d) => BillDeduction.fromJson(d))
                  .toList();
            }
          }
        } catch (e) {
          debugPrint('Error parsing bag deduction response: $e');
        }

        return true;
      } else {
        if (context.mounted) {
          ToastMessage.show(context,
              message: "${result.message} (ID: $_draftBillId)", isError: true);
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error applying goni: $e');
      if (context.mounted) {
        ToastMessage.show(context, message: "Error: $e", isError: true);
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchBillPreview(String billId) async {
    _setLoading(true);
    try {
      final url =
          ApiConstants.previewBillDraft.replaceAll('{{billId}}', billId);
      final response = await _apiService.get(url);
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        // The API returns data: { bill: {...}, totals: {...} }
        if (responseData['data'] != null) {
          final data = responseData['data'];
          if (data['bill'] != null) {
            _selectedBillDetails = BillModel.fromJson(data['bill']);
          } else {
            _selectedBillDetails = BillModel.fromJson(data);
          }

          // Store totals for summary display
          if (data['totals'] != null) {
            _summaryTotals = data['totals'];
          } else {
            _summaryTotals = null;
          }

          // Store calculation details
          if (data['calculationDetails'] != null) {
            _calculationDetails =
                CalculationDetails.fromJson(data['calculationDetails']);
          } else {
            _calculationDetails = _selectedBillDetails?.calculationDetails;
          }

          // Store deductions
          if (data['deductions'] != null) {
            _previewDeductions = (data['deductions'] as List)
                .map((i) => BillDeduction.fromJson(i))
                .toList();
          } else {
            _previewDeductions = [];
          }

          // Important: Set selected farmer from bill details
          _selectedFarmer = _selectedBillDetails?.farmer;
          if (_selectedFarmer != null && _selectedFarmer!.id != null) {
            fetchFarmerAdvanceBalance(_selectedFarmer!.id!);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching bill preview: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchBillGraph() async {
    _setLoading(true);
    try {
      final response = await _apiService.get(ApiConstants.getBillGraph);
      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Graph data fetched successfully',
        defaultErrorMessage: 'Failed to fetch graph data',
      );

      if (result.success) {
        _billGraphData = BillGraphModel.fromJson(result.data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching bill graph: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> confirmDraftBill({
    required BuildContext context,
    String? billId,
  }) async {
    final targetBillId = billId ?? _draftBillId;
    if (targetBillId == null) return false;
    _setLoading(true);
    try {
      // Fetch current location name for confirmation as well
      final locationName = await LocationService.getCurrentLocationAddress();
      debugPrint('Billing Location Name (Confirm): $locationName');

      final url =
          ApiConstants.confirmBillDraft.replaceAll('{{billId}}', targetBillId);
      final response = await _apiService.post(
        url,
        body: {
          if (locationName != null) 'billLocation': locationName,
        },
      );

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Bill saved successfully',
        defaultErrorMessage: 'Failed to confirm bill',
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
      debugPrint('Error confirming bill: $e');
      if (context.mounted) {
        ToastMessage.show(context, message: "Error: $e", isError: true);
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> returnBagsToFarmer({required BuildContext context}) async {
    if (_selectedFarmer == null) {
      if (context.mounted) {
        ToastMessage.show(context, message: 'Select a farmer', isError: true);
      }
      return false;
    }
    if (_returnGoniType == null || _returnBagCount <= 0) {
      // If no bags to return, we just proceed (optional step)
      return true;
    }

    _setReturnBagsLoading(true);
    try {
      final body = {
        "farmerId": _selectedFarmer!.id,
        "goniTypeId": _returnGoniType!.id,
        "bagCount": _returnBagCount,
        if (_returnNotes.trim().isNotEmpty) "notes": _returnNotes,
      };

      final response = await _apiService.post(
        ApiConstants.returnBagsToFarmer,
        body: body,
      );

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Bags returned to farmer successfully',
        defaultErrorMessage: 'Failed to return bags',
      );

      if (context.mounted && !result.success) {
        ToastMessage.show(
          context,
          message: result.message,
          isError: true,
        );
      }
      return result.success;
    } catch (e) {
      debugPrint('Error returning bags: $e');
      if (context.mounted) {
        ToastMessage.show(context, message: "Error: $e", isError: true);
      }
      return false;
    } finally {
      _setReturnBagsLoading(false);
    }
  }

  // Fetching methods
  Future<void> fetchBills(
      {int page = 1, int limit = 10, String search = ""}) async {
    _setLoading(true);
    _billSearchQuery = search;
    _averageRate = 0; // Reset average rate when fetching new data
    try {
      final prefs = await SharedPreferences.getInstance();
      final vendorId = _ignoreVendorId ? "" : (prefs.getString('userId') ?? "");

      String url = '${ApiConstants.getBills}?page=$page&limit=$limit';
      if (vendorId.isNotEmpty) {
        url += '&vendorId=$vendorId';
      }
      if (search.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(search)}';
      }
      if (_billStartDate != null) {
        url += '&startDate=${_billStartDate!.toIso8601String().split('T')[0]}';
      }
      if (_billEndDate != null) {
        url += '&endDate=${_billEndDate!.toIso8601String().split('T')[0]}';
      }
      if (_selectedBillStatuses.isNotEmpty) {
        url += '&status=${_selectedBillStatuses.join(',')}';
      }

      debugPrint('FETCH BILLS URL: $url');
      final response = await _apiService.get(url);
      final responseData = jsonDecode(response.body);
      final billListModel = BillListModel.fromJson(responseData);
      if (billListModel.success == true) {
        _bills = billListModel.data ?? [];
        _currentPage = billListModel.currentPage ?? page;
        _totalItems = billListModel.totalItems ?? _bills.length;
        _totalPages = billListModel.totalPages ??
            (_totalItems > 0 ? (_totalItems / limit).ceil() : 1);
        _averageRate = billListModel.averageRate ?? 0;

        // Fallback: If averageRate is 0 but bills are available, calculate locally from the results
        if (_averageRate == 0 && _bills.isNotEmpty) {
          double totalRate = 0;
          int count = 0;
          for (var bill in _bills) {
            final rate = bill.ratePerUnit ?? 0;
            if (rate > 0) {
              totalRate += rate;
              count++;
            }
          }
          if (count > 0) {
            _averageRate = totalRate / count;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching bills: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Debounced search for bill reports
  void onBillSearchChanged(String query) {
    if (_billSearchDebounce?.isActive ?? false) _billSearchDebounce!.cancel();
    _billSearchDebounce = Timer(const Duration(milliseconds: 500), () {
      fetchBills(page: 1, search: query);
    });
  }

  void setBillFilters({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? statuses,
    bool? ignoreVendorId,
  }) {
    if (startDate != null) _billStartDate = startDate;
    if (endDate != null) _billEndDate = endDate;
    if (statuses != null) _selectedBillStatuses = statuses;
    if (ignoreVendorId != null) _ignoreVendorId = ignoreVendorId;
    notifyListeners();
    fetchBills(page: 1, search: _billSearchQuery);
  }

  void clearBillFilters() {
    _billStartDate = null;
    _billEndDate = null;
    _selectedBillStatuses = [];
    _ignoreVendorId = false;
    notifyListeners();
    fetchBills(page: 1, search: _billSearchQuery);
  }

  Future<void> fetchBillDetails(String billId) async {
    _setLoading(true);
    try {
      final url = ApiConstants.getbillDetails.replaceAll('{{billId}}', billId);
      final response = await _apiService.get(url);
      final responseData = jsonDecode(response.body);
      debugPrint('FETCH BILL DETAILS RESPONSE: ${response.body}');
      final billDetailModel = BillDetailModel.fromJson(responseData);
      if (billDetailModel.success == true && billDetailModel.data != null) {
        final bill = billDetailModel.data!;
        _selectedBillDetails = bill;

        // Manually populate summaryTotals for UI consistency
        _summaryTotals = {
          'grossAmount': bill.grossAmount,
          'totalDeductions':
              bill.deductions?.fold<num>(0, (sum, d) => sum + (d.value ?? 0)) ??
                  0,
          'goniWeight': bill.goniWeight,
          'netPayable': bill.netPayable,
        };

        // Important: Set selected farmer from bill details
        _selectedFarmer = bill.farmer;
        if (_selectedFarmer != null && _selectedFarmer!.id != null) {
          fetchFarmerAdvanceBalance(_selectedFarmer!.id!);
        }
      }
    } catch (e) {
      debugPrint('Error fetching bill details: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void updateDeductionVariable(String code, double value) {
    _deductionVariableValues[code] = value;
    notifyListeners();
  }

  // --- Farmer Advances Section ---

  Future<void> fetchFarmerAdvanceBalance(String farmerId) async {
    try {
      final url = ApiConstants.getFarmerAdvanceBalance.replaceAll('{{farmerId}}', farmerId);
      final response = await _apiService.get(url);
      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Advance balance fetched',
        defaultErrorMessage: 'Failed to fetch advance balance',
      );

      if (result.success && result.data != null) {
        _farmerAdvanceBalance = (result.data['data']?['balance'] ?? 0).toDouble();
      } else {
        _farmerAdvanceBalance = 0.0;
      }
    } catch (e) {
      debugPrint('Error fetching farmer advance balance: $e');
      _farmerAdvanceBalance = 0.0;
    }
    notifyListeners();
  }

  Future<bool> recordInstantAdvance({
    required BuildContext context,
    required String farmerId,
    required double amount,
    required String reason,
    String? remarks,
    String? billId,
  }) async {
    _setLoading(true);
    try {
      final url = ApiConstants.addFarmerAdvance.replaceAll('{{farmerId}}', farmerId);
      final response = await _apiService.post(
        url,
        body: {
          'amount': amount,
          'source': 'BILLING',
          'reason': reason,
          if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
          if (billId != null) 'billId': billId,
        },
      );

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Instant advance recorded successfully',
        defaultErrorMessage: 'Failed to record instant advance',
      );

      if (context.mounted) {
        ToastMessage.show(
          context,
          message: result.message,
          isError: !result.success,
        );
      }

      if (result.success) {
        await fetchFarmerAdvanceBalance(farmerId);
        // Refresh bill preview or details so deduction adjusts
        final targetBillId = billId ?? _draftBillId;
        if (targetBillId != null) {
          if (targetBillId == _draftBillId) {
            await fetchBillPreview(targetBillId);
          } else {
            await fetchBillDetails(targetBillId);
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error recording instant advance: $e');
      if (context.mounted) {
        ToastMessage.show(context, message: "Error: $e", isError: true);
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset ALL state for a fresh new bill creation.
  /// Clears user selections but preserves fetched reference data
  /// (todaysRates, goniTypes, deductionMasters).
  void resetForNewBill() {
    _selectedFarmer = null;
    _searchedFarmers = [];
    _editingBillId = null;
    _draftBillId = null;
    _lastCreatedBill = null;
    _selectedUnit = 'QTL';
    _isLoading = false;
    _selectedBillingDate = null;

    // Quality & Rate
    // Re-apply vendor rate as default selection
    if (_vendorRate > 0) {
      _selectedQuality = QualityRateData(
        quality: 'my_rate',
        rate: _vendorRate,
      );
    } else {
      _selectedQuality = null;
    }
    _actualQualityValues = {};
    _currentDeductionAmount = 0.0;

    // Bags
    _selectedGoniType = null;
    _selectedBags = [];

    // Deductions
    _deductionVariableValues = {};
    _selectedVariationValue = null;
    _selectedVariationMaster = null;
    // Re-select default variation if available
    if (_deductionMasters.any((m) => m.type == "FORMULA")) {
      final firstFormula =
          _deductionMasters.firstWhere((m) => m.type == "FORMULA");
      if (firstFormula.variableValues?.isNotEmpty == true) {
        _selectedVariationMaster = firstFormula;
        _selectedVariationValue = firstFormula.variableValues!.first;
      }
    }

    // Vehicle
    _vehicleNumber = null;
    _vehicleType = "Truck";
    _driverName = null;

    // Bill preview/summary
    _selectedBillDetails = null;
    _summaryTotals = null;
    _calculationDetails = null;
    _previewDeductions = [];

    // Return bags
    if (_goniTypes.isNotEmpty) {
      _returnGoniType =
          _goniTypes.where((element) => element.isTracked == true).firstOrNull;
    } else {
      _returnGoniType = null;
    }
    _returnBagCount = 0;
    _returnNotes = "";
    _isReturnBagsLoading = false;

    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    notifyListeners();
  }

  /// Full reset including report filters. Used when navigating away entirely.
  void reset() {
    resetForNewBill();
    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _billSearchQuery = "";
    _billStartDate = null;
    _billEndDate = null;
    _selectedBillStatuses = [];
    _ignoreVendorId = false;
    _rateHistory = [];
    _rateHistoryPage = 1;
    _rateHistoryTotalPages = 1;
    _rateHistoryTotalItems = 0;
    _rateHistoryStartDate = null;
    _rateHistoryEndDate = null;
    if (_billSearchDebounce?.isActive ?? false) _billSearchDebounce!.cancel();
    notifyListeners();
  }
}

class SelectedBag {
  final GoniType goniType;
  final int bagCount;

  SelectedBag({required this.goniType, required this.bagCount});
}
