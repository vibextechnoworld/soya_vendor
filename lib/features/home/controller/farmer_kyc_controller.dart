import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soya_app/core/constants/api_constants.dart';
import 'package:soya_app/core/services/api_service.dart';
import 'package:soya_app/core/utils/api_helper.dart';
import 'package:soya_app/core/widgets/tost_message.dart';
import 'package:soya_app/features/home/model/bank_detail_model.dart';
import 'package:soya_app/features/home/model/farmer_bank_model.dart';
import 'package:soya_app/features/home/model/farmer_document_model.dart';
import 'package:soya_app/features/home/model/farmer_land_model.dart';
import 'package:soya_app/features/home/model/farmer_list_model.dart';
import 'package:soya_app/features/home/model/farmer_model.dart';

enum FarmerSearchType { name, aadhaar, phone }

class FarmerKycController with ChangeNotifier {
  final _apiService = ApiService.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Store created farmer ID for subsequent API calls
  String? _createdFarmerId;
  String? get createdFarmerId => _createdFarmerId;

  // Search results for farmer search
  List<FarmerData> _searchResults = [];
  List<FarmerData> get searchResults => _searchResults;

  int _currentPage = 1;
  int get currentPage => _currentPage;

  int _totalPages = 1;
  int get totalPages => _totalPages;

  int _totalItems = 0;
  int get totalItems => _totalItems;

  String _searchQuery = "";
  String get searchQuery => _searchQuery;

  bool _isMyFarmersOnly = false;
  bool get isMyFarmersOnly => _isMyFarmersOnly;

  String? _vendorId;
  FarmerSearchType _searchType = FarmerSearchType.aadhaar;
  FarmerSearchType get searchType => _searchType;

  void setSearchType(FarmerSearchType type) {
    _searchType = type;
    _searchResults = [];
    notifyListeners();
  }

  static const String _prefFarmerIdKey = 'pending_kyc_farmer_id';

  Timer? _searchDebounce;
  Timer? _suggestionSearchDebounce;
  int _lastSuggestionSearchTimestamp = 0;

  // Fetched details for existing farmer
  List<DocumentData>? _fetchedDocuments;
  List<DocumentData>? get fetchedDocuments => _fetchedDocuments;

  List<LandData>? _fetchedLands;
  List<LandData>? get fetchedLands => _fetchedLands;

  List<BankData>? _fetchedBank;
  List<BankData>? get fetchedBank => _fetchedBank;

  FarmerData? _fetchedFarmerDetail;
  FarmerData? get fetchedFarmerDetail => _fetchedFarmerDetail;

  // Current step in the multi-step form
  int _currentStep = 0;
  int get currentStep => _currentStep;

  // Bank names master list
  List<BankDetailData> _bankDetails = [];
  List<BankDetailData> get bankDetails => _bankDetails;

  // Non-KYC/Pending/Rejected farmers list
  List<FarmerData> _nonKycFarmers = [];
  List<FarmerData> get nonKycFarmers => _nonKycFarmers;
  bool _isLoadingNonKycFarmers = false;
  bool get isLoadingNonKycFarmers => _isLoadingNonKycFarmers;

  String _nonKycSearchQuery = "";
  String get nonKycSearchQuery => _nonKycSearchQuery;

  bool _isNonKycMyFarmersOnly = false;
  bool get isNonKycMyFarmersOnly => _isNonKycMyFarmersOnly;

  Timer? _nonKycSearchDebounce;

  // Track submission status of each step
  bool _isFarmerSubmitted = false;
  bool get isFarmerSubmitted => _isFarmerSubmitted || _createdFarmerId != null;

  bool _isIdSubmitted = false;
  bool get isIdSubmitted => _isIdSubmitted;

  bool _isLandSubmitted = false;
  bool get isLandSubmitted => _isLandSubmitted;

  bool _isBankSubmitted = false;
  bool get isBankSubmitted => _isBankSubmitted;

  bool _isJustCreated = false;
  bool get isJustCreated => _isJustCreated;

  void setFarmerSubmitted(bool value) {
    _isFarmerSubmitted = value;
    notifyListeners();
  }

  void setIdSubmitted(bool value) {
    _isIdSubmitted = value;
    notifyListeners();
  }

  void setLandSubmitted(bool value) {
    _isLandSubmitted = value;
    notifyListeners();
  }

  void setBankSubmitted(bool value) {
    _isBankSubmitted = value;
    notifyListeners();
  }

  void setCurrentStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  void nextStep() {
    _currentStep++;
    notifyListeners();
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void onSuggestionSearchChanged(String query) {
    _searchQuery = query;
    if (_suggestionSearchDebounce?.isActive ?? false) {
      _suggestionSearchDebounce!.cancel();
    }
    _suggestionSearchDebounce = Timer(const Duration(milliseconds: 500), () {
      searchFarmers(query);
    });
  }

  /// Search Farmers by name
  Future<List<FarmerData>> searchFarmers(String query) async {
    final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    _lastSuggestionSearchTimestamp = currentTimestamp;
    _isSearching = true;
    notifyListeners();

    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false; // Reset loading state
      notifyListeners();
      return [];
    }

    try {
      // Use the same search parameter strategy as BillingController
      String url = "${ApiConstants.farmerProfile}?page=1&limit=20";

      if (_searchType == FarmerSearchType.name) {
        url += '&search=${Uri.encodeComponent(query)}';
      } else if (_searchType == FarmerSearchType.aadhaar) {
        url += '&adhar_no=${Uri.encodeComponent(query)}';
      } else if (_searchType == FarmerSearchType.phone) {
        url += '&phone=${Uri.encodeComponent(query)}';
      }

      if (_vendorId != null) {
        url += '&vendorId=$_vendorId';
      }

      debugPrint('🔍 Farmer Search URL: $url');
      final response = await _apiService.get(url);

      if (_lastSuggestionSearchTimestamp != currentTimestamp) {
        return _searchResults;
      }

      debugPrint('🔍 Farmer Search Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        debugPrint('🔍 Farmer Search Body: ${response.body}');
        final responseData = jsonDecode(response.body);
        final farmerListModel = FarmerListModel.fromJson(responseData);
        _searchResults = farmerListModel.data ?? [];
        notifyListeners();
        return _searchResults;
      } else {
        _searchResults = [];
        notifyListeners();
        debugPrint('❌ Search failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (_lastSuggestionSearchTimestamp == currentTimestamp) {
        _searchResults = [];
        notifyListeners();
        debugPrint('❌ Error searching farmers: $e');
      }
    } finally {
      if (_lastSuggestionSearchTimestamp == currentTimestamp) {
        _isSearching = false;
        notifyListeners();
      }
    }
    return [];
  }

  /// List Farmers for reports
  Future<void> listFarmers(
      {int page = 1,
      int limit = 10,
      String search = "",
      String? vendorId}) async {
    _setLoading(true);
    _searchQuery = search;
    _currentPage = page;

    try {
      // If vendorId is not provided but isMyFarmersOnly is true, try to use stored _vendorId
      String? effectiveVendorId = vendorId;
      if (effectiveVendorId == null && _isMyFarmersOnly) {
        if (_vendorId == null) {
          final prefs = await SharedPreferences.getInstance();
          _vendorId = prefs.getString('userId');
        }
        effectiveVendorId = _vendorId;
      }

      String url = '${ApiConstants.farmerProfile}?page=$page&limit=$limit';
      if (search.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(search)}';
      }
      if (effectiveVendorId != null && effectiveVendorId.isNotEmpty) {
        url += '&vendorId=$effectiveVendorId';
      }
      final response = await _apiService.get(url);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final farmerListModel = FarmerListModel.fromJson(responseData);
        _searchResults = farmerListModel.data ?? [];
        _currentPage = farmerListModel.currentPage ?? page;
        _totalItems = farmerListModel.totalItems ?? _searchResults.length;
        // Fallback for totalPages calculation
        _totalPages = farmerListModel.totalPages ??
            (_totalItems > 0 ? (_totalItems / limit).ceil() : 1);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error listing farmers: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Debounced search for reports
  void onSearchChanged(String query) {
    _searchQuery = query;
    _currentPage = 1;
    _searchDebounce?.cancel(); // Cancel previous debounce
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      listFarmers(
          page: 1,
          search: query,
          vendorId: _isMyFarmersOnly ? _vendorId : null);
    });
  }

  Future<void> toggleMyFarmers(bool value) async {
    _isMyFarmersOnly = value;
    _currentPage = 1;
    if (_vendorId == null) {
      final prefs = await SharedPreferences.getInstance();
      _vendorId = prefs.getString('userId');
    }
    await listFarmers(
        page: 1,
        search: _searchQuery,
        vendorId: _isMyFarmersOnly ? _vendorId : null);
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _suggestionSearchDebounce?.cancel();
    _nonKycSearchDebounce?.cancel();
    super.dispose();
  }

  /// Fetch master bank details list
  Future<void> fetchBankDetails() async {
    try {
      final response = await _apiService.get(ApiConstants.getBankDetails);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final model = BankDetailModel.fromJson(responseData);
        _bankDetails = model.data ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching master bank details: $e');
    }
  }

  /// Fetch non-KYC farmers list (pending or rejected status)
  Future<void> fetchNonKycFarmers({
    String? search,
    bool? myFarmersOnly,
  }) async {
    if (search != null) {
      _nonKycSearchQuery = search;
    }
    if (myFarmersOnly != null) {
      _isNonKycMyFarmersOnly = myFarmersOnly;
    }

    _isLoadingNonKycFarmers = true;
    notifyListeners();
    try {
      String? effectiveVendorId;
      if (_isNonKycMyFarmersOnly) {
        if (_vendorId == null) {
          final prefs = await SharedPreferences.getInstance();
          _vendorId = prefs.getString('userId');
        }
        effectiveVendorId = _vendorId;
      }

      String url = ApiConstants.nonKycFarmerList;
      List<String> queryParams = [];
      if (_nonKycSearchQuery.isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(_nonKycSearchQuery)}');
      }
      if (effectiveVendorId != null && effectiveVendorId.isNotEmpty) {
        queryParams.add('vendorId=$effectiveVendorId');
      }
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await _apiService.get(url);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final model = FarmerListModel.fromJson(responseData);
        _nonKycFarmers = model.data ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching non-KYC farmers list: $e');
    } finally {
      _isLoadingNonKycFarmers = false;
      notifyListeners();
    }
  }

  void onNonKycSearchChanged(String query) {
    _nonKycSearchQuery = query;
    _nonKycSearchDebounce?.cancel();
    _nonKycSearchDebounce = Timer(const Duration(milliseconds: 500), () {
      fetchNonKycFarmers(search: query);
    });
  }

  Future<void> toggleNonKycMyFarmers(bool value) async {
    _isNonKycMyFarmersOnly = value;
    await fetchNonKycFarmers(myFarmersOnly: value);
  }

  /// Create a new master bank detail
  Future<BankDetailData?> createMasterBankDetail(String bankName) async {
    _setLoading(true);
    try {
      final response = await _apiService.post(
        Uri.parse(ApiConstants.createBankDetail).toString(),
        body: {'bankName': bankName.trim()},
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final model = CreateBankResponse.fromJson(responseData);
        if (model.success == true && model.data != null) {
          // Check if it already exists to avoid duplicates in local list
          if (!_bankDetails.any((b) => b.id == model.data!.id)) {
            _bankDetails.add(model.data!);
          }
          notifyListeners();
          return model.data;
        }
      }
    } catch (e) {
      debugPrint('Error creating master bank detail: $e');
    } finally {
      _setLoading(false);
    }
    return null;
  }

  /// Set selected farmer and mark as submitted
  void setSelectedFarmer(FarmerData farmer) {
    _isJustCreated = false;
    _isFarmerSubmitted = true;
    _isIdSubmitted = false;
    _isLandSubmitted = false;
    _isBankSubmitted = false;
    _fetchedDocuments = null;
    _fetchedLands = null;
    _fetchedBank = null;
    _createdFarmerId = farmer.id;
    _fetchedFarmerDetail = farmer;
    _searchResults = []; // Clear suggestions
    _searchQuery = "";
    notifyListeners();

    // Persist progress
    if (_createdFarmerId != null) {
      _saveProgress(_createdFarmerId!);
      fetchFarmerDetails(farmer.id!);
    }
  }

  Future<void> _saveProgress(String farmerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefFarmerIdKey, farmerId);
  }

  Future<String?> getPendingFarmerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefFarmerIdKey);
  }

  Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefFarmerIdKey);
    reset();
  }

  /// Fetch all KYC details for a farmer using a single API call
  Future<void> fetchFarmerDetails(String farmerId) async {
    _setLoading(true);
    try {
      final url =
          ApiConstants.getFarmerById.replaceAll('{{farmerId}}', farmerId);
      debugPrint('🚀 fetchFarmerDetails GET URL: $url');

      final token = await _apiService.getToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Workaround: Send a GET request with a JSON body workaround to prevent the backend from crashing if it reads req.body.name
      final request = http.Request('GET', Uri.parse(url))
        ..headers.addAll(headers)
        ..body = jsonEncode({'name': ''});

      final streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      debugPrint(
          '🚀 fetchFarmerDetails Response: ${response.statusCode} - ${response.body}');

      // Fallback: If GET still fails with the req.body destructuring error, try calling it as a POST request!
      if (response.statusCode == 500 &&
          response.body.contains("Cannot destructure property 'name'")) {
        debugPrint(
            '⚠️ GET request failed with req.body error. Trying POST fallback...');
        response = await _apiService.post(url, body: {'name': ''});
        debugPrint(
            '🚀 fetchFarmerDetails POST Fallback Response: ${response.statusCode} - ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('Farmer detail response: $responseData');
        final model = FarmerModel.fromJson(responseData);

        if (model.success == true && model.data != null) {
          final farmer = model.data!;
          _fetchedFarmerDetail = farmer;

          // 1. Sync Documents
          _fetchedDocuments = farmer.documents;
          if (_fetchedDocuments != null) {
            final hasAadhaar =
                _fetchedDocuments!.any((d) => d.type == 'AADHAAR');
            final hasPan = _fetchedDocuments!.any((d) => d.type == 'PAN');
            final hasLicense =
                _fetchedDocuments!.any((d) => d.type == 'DRIVING_LICENSE');
            if (hasAadhaar) {
              _isIdSubmitted = true;
            }

            // Land doc check
            final hasLandDoc =
                _fetchedDocuments!.any((d) => d.type == 'LAND_712');
            if (hasLandDoc) {
              _isLandSubmitted = true;
            }
          }

          // 2. Sync Lands
          _fetchedLands = farmer.lands;
          if (_fetchedLands != null && _fetchedLands!.isNotEmpty) {
            _isLandSubmitted = true;
          }

          // 3. Sync Banks
          _fetchedBank = farmer.banks;
          if (_fetchedBank != null && _fetchedBank!.isNotEmpty) {
            _isBankSubmitted = true;
          }

          // 4. Auto-jump to the first incomplete step
          if (!_isIdSubmitted) {
            _currentStep = 1;
          } else if (!_isLandSubmitted) {
            _currentStep = 2;
          } else if (!_isBankSubmitted) {
            _currentStep = 3;
          } else {
            _currentStep =
                0; // Everything done, stay at first step for overview if needed or maybe 3
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching farmer full details: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Step 1: Create Farmer
  Future<bool> createFarmer({
    required BuildContext context,
    required String name,
    required String aadhaarNo,
    required String phone,
    String? email,
    String? villageAdd,
    String? gutNumber,
    String? taluka,
    String? district,
    String? panNo,
    File? profileImage,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final Map<String, String> fields = {
        'name': name.trim(),
        'aadhaarNo': aadhaarNo.trim(),
        'phone': phone.trim(),
      };

      if (email != null && email.isNotEmpty) fields['email'] = email.trim();
      if (villageAdd != null && villageAdd.isNotEmpty) {
        fields['villageAdd'] = villageAdd.trim();
      }
      if (gutNumber != null && gutNumber.isNotEmpty) {
        fields['gutNumber'] = gutNumber.trim();
      }
      if (taluka != null && taluka.isNotEmpty) {
        fields['taluka'] = taluka.trim();
      }
      if (district != null && district.isNotEmpty) {
        fields['district'] = district.trim();
      }
      if (panNo != null && panNo.isNotEmpty) {
        fields['panNo'] = panNo.trim();
      }

      http.Response response;
      if (profileImage != null && await profileImage.exists()) {
        final List<http.MultipartFile> files = [];
        files.add(await http.MultipartFile.fromPath(
          'profile',
          profileImage.path,
          contentType: MediaType.parse(_getMimeType(profileImage.path)),
        ));

        debugPrint(
            '🚀 createFarmer MULTIPART URL: ${ApiConstants.createFarmer}');
        debugPrint('🚀 createFarmer MULTIPART Fields: $fields');
        response = await _apiService.multipartRequest(
          ApiConstants.createFarmer,
          fields: fields,
          files: files,
        );
      } else {
        debugPrint('🚀 createFarmer JSON URL: ${ApiConstants.createFarmer}');
        debugPrint('🚀 createFarmer JSON Body: $fields');
        response = await _apiService.post(
          ApiConstants.createFarmer,
          body: fields,
        );
      }
      debugPrint(
          '🚀 createFarmer Response: ${response.statusCode} - ${response.body}');

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Farmer created successfully!',
        defaultErrorMessage: 'Failed to create farmer',
      );

      if (result.success) {
        final farmerModel = FarmerModel.fromJson(result.data);
        if (farmerModel.data?.id != null) {
          _isJustCreated = true;
          _createdFarmerId = farmerModel.data!.id;
          _fetchedFarmerDetail = farmerModel.data;
          _isFarmerSubmitted = true;
          _saveProgress(_createdFarmerId!);
          _setLoading(false);
          if (context.mounted) {
            ToastMessage.show(
              context,
              message: result.message,
              isError: false,
            );
          }
          return true;
        } else {
          _errorMessage = 'Invalid response data';
          _setLoading(false);
          if (context.mounted) {
            ToastMessage.show(context, message: _errorMessage!, isError: true);
          }
          return false;
        }
      } else {
        _errorMessage = result.message;
        _setLoading(false);

        // Check if error is "Farmer already exists" and we have an Aadhaar to search by
        if (_errorMessage?.contains('already exist') == true) {
          if (context.mounted) {
            ToastMessage.show(context,
                message:
                    'Farmer Profile already exists. Fetching existing data...',
                isError: false);
          }
          // Attempt to search by Aadhaar to find the existing farmer
          await searchFarmers(aadhaarNo.trim());
          if (_searchResults.isNotEmpty) {
            final existingFarmer = _searchResults.firstWhere(
                (f) => f.aadhaarNo == aadhaarNo.trim(),
                orElse: () => _searchResults.first);
            setSelectedFarmer(existingFarmer);
            return true; // Return true as we successfully transitioned to the existing farmer
          }
        }

        if (context.mounted) {
          ToastMessage.show(context, message: _errorMessage!, isError: true);
        }
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _setLoading(false);
      if (context.mounted) {
        ToastMessage.show(context, message: _errorMessage!, isError: true);
      }
      return false;
    }
  }

  /// Update Farmer Details
  Future<bool> updateFarmer({
    required BuildContext context,
    required String farmerId,
    required String name,
    required String aadhaarNo,
    required String phone,
    String? email,
    String? villageAdd,
    String? gutNumber,
    String? taluka,
    String? district,
    String? panNo,
    File? profileImage,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final url =
          ApiConstants.updateFarmerById.replaceAll('{{farmerId}}', farmerId);

      final Map<String, String> fields = {
        'name': name.trim(),
        'aadhaarNo': aadhaarNo.trim(),
        'phone': phone.trim(),
      };

      if (email != null && email.isNotEmpty) fields['email'] = email.trim();
      if (villageAdd != null && villageAdd.isNotEmpty) {
        fields['villageAdd'] = villageAdd.trim();
      }
      if (gutNumber != null && gutNumber.isNotEmpty) {
        fields['gutNumber'] = gutNumber.trim();
      }
      if (taluka != null && taluka.isNotEmpty) {
        fields['taluka'] = taluka.trim();
      }
      if (district != null && district.isNotEmpty) {
        fields['district'] = district.trim();
      }
      if (panNo != null && panNo.isNotEmpty) {
        fields['panNo'] = panNo.trim();
      }

      http.Response response;
      if (profileImage != null && await profileImage.exists()) {
        final List<http.MultipartFile> files = [];
        files.add(await http.MultipartFile.fromPath(
          'profile',
          profileImage.path,
          contentType: MediaType.parse(_getMimeType(profileImage.path)),
        ));

        debugPrint('🚀 updateFarmer MULTIPART URL: $url');
        debugPrint('🚀 updateFarmer MULTIPART Fields: $fields');
        response = await _apiService.multipartRequest(
          url,
          method: 'PUT',
          fields: fields,
          files: files,
        );
      } else {
        debugPrint('🚀 updateFarmer JSON URL: $url');
        debugPrint('🚀 updateFarmer JSON Body: $fields');
        response = await _apiService.put(
          url,
          body: fields,
        );

        // Fallback: If PUT fails with the req.body destructuring error, try calling it as a POST request!
        if (response.statusCode == 500 &&
            response.body.contains("Cannot destructure property 'name'")) {
          debugPrint(
              '⚠️ PUT request failed with req.body error. Trying POST fallback...');
          response = await _apiService.post(
            url,
            body: fields,
          );
          debugPrint(
              '🚀 updateFarmer POST Fallback Response: ${response.statusCode} - ${response.body}');
        }
      }
      debugPrint(
          '🚀 updateFarmer Response: ${response.statusCode} - ${response.body}');

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Farmer details updated successfully!',
        defaultErrorMessage: 'Failed to update farmer',
      );

      _setLoading(false);
      if (context.mounted) {
        ToastMessage.show(
          context,
          message: result.message,
          isError: !result.success,
        );
        if (!result.success) {
          _errorMessage = result.message;
        }
      }
      return result.success;
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _setLoading(false);
      if (context.mounted) {
        ToastMessage.show(context, message: _errorMessage!, isError: true);
      }
      return false;
    }
  }

  /// Step 2: Upload Multiple Identification Documents
  Future<bool> uploadFarmerIdentificationDocuments({
    required BuildContext context,
    required String farmerId,
    File? aadhaar,
    File? pan,
    File? license,
    String? panNo,
    bool isUpdate = false,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Always use the plural documents endpoint and POST method as backend supports upserting.
      final url = ApiConstants.createFarmerDocuments
          .replaceAll('{{farmerId}}', farmerId);

      final Map<String, String> fields = {'farmerId': farmerId};
      if (panNo != null && panNo.isNotEmpty) fields['panNo'] = panNo;

      final List<http.MultipartFile> files = [];
      if (aadhaar != null && await aadhaar.exists()) {
        files.add(await http.MultipartFile.fromPath(
          'AADHAAR',
          aadhaar.path,
          contentType: MediaType.parse(_getMimeType(aadhaar.path)),
        ));
      }

      if (pan != null && await pan.exists()) {
        files.add(await http.MultipartFile.fromPath(
          'PAN',
          pan.path,
          contentType: MediaType.parse(_getMimeType(pan.path)),
        ));
      }

      if (license != null && await license.exists()) {
        files.add(await http.MultipartFile.fromPath(
          'DRIVING_LICENSE',
          license.path,
          contentType: MediaType.parse(_getMimeType(license.path)),
        ));
      }

      debugPrint('Uploading to: $url');
      final response = await _apiService.multipartRequest(
        url,
        method: 'POST',
        fields: fields,
        files: files,
      );
      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Documents uploaded successfully!',
        defaultErrorMessage: 'Failed to upload documents',
      );

      if (result.success) {
        _isIdSubmitted = true;
        if (context.mounted) {
          ToastMessage.show(context, message: result.message, isError: false);
        }
        return true;
      } else {
        _errorMessage = result.message;
        /*
        if (context.mounted) {
           ToastMessage.show(context, message: _errorMessage!, isError: true);
        }
        */
        // Let the finally block handle error toast if needed or handled here
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during upload: $e';
      return false;
    } finally {
      _setLoading(false);
      if (_errorMessage != null && context.mounted) {
        ToastMessage.show(context, message: _errorMessage!, isError: true);
      }
    }
  }

  String _getMimeType(String filePath) {
    final extension = p.extension(filePath).toLowerCase();
    if (extension == '.png') return 'image/png';
    return 'image/jpeg';
  }

  /// Upload/Update Farmer Document
  Future<bool> uploadFarmerDocument({
    required BuildContext context,
    required String farmerId,
    required String type,
    required File document,
    String? area,
    bool isUpdate = false,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final url = (isUpdate
              ? ApiConstants.updateFarmerDocumentById
              : ApiConstants.createFarmerDocument)
          .replaceAll('{{farmerId}}', farmerId);

      final Map<String, String> fields = {
        'farmerId': farmerId,
        'type': type,
      };

      final List<http.MultipartFile> files = [];
      if (await document.exists()) {
        files.add(await http.MultipartFile.fromPath(
          'document',
          document.path,
          contentType: MediaType.parse(_getMimeType(document.path)),
        ));
      }

      final response = await _apiService.multipartRequest(
        url,
        method: isUpdate ? 'PUT' : 'POST',
        fields: fields,
        files: files,
      );

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Document uploaded successfully!',
        defaultErrorMessage: 'Failed to upload document',
      );

      if (context.mounted) {
        ToastMessage.show(
          context,
          message: result.message,
          isError: !result.success,
        );
      }

      if (!result.success) {
        _errorMessage = result.message;
      }
      return result.success;
    } catch (e) {
      _errorMessage = 'An error occurred during upload: $e';
      return false;
    } finally {
      _setLoading(false);
      if (_errorMessage != null && context.mounted) {
        ToastMessage.show(context, message: _errorMessage!, isError: true);
      }
    }
  }

  /// Alias for uploadFarmerDocument to handle specific LAND_712 logic
  Future<bool> uploaddocuments({
    required BuildContext context,
    required String farmerId,
    required String type,
    required File document,
    String? area,
    bool isUpdate = false,
  }) async {
    final success = await uploadFarmerDocument(
      context: context,
      farmerId: farmerId,
      type: type,
      document: document,
      area: area,
      isUpdate: isUpdate,
    );
    if (success) {
      _isLandSubmitted = true;
      notifyListeners();
    }
    return success;
  }

  /// Step 3: Add Farmer Land
  Future<bool> addFarmerLand({
    required BuildContext context,
    required String farmerId,
    required String landType,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final url =
          ApiConstants.createFarmerLands.replaceAll('{{farmerId}}', farmerId);
      final response =
          await _apiService.post(url, body: {'landType': landType});

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage:
            'Land details added successfully', // No default provided in original code success path but implied? No, original had no default success message in Toast? Wait, it did check responseData['message'].
        // Let's set a sensible default.
        defaultErrorMessage: 'Failed to add land details',
      );

      if (result.success) {
        _isLandSubmitted = true;
        // Note: The original code returned responseData['message'] ?? 'Failed to add land details' in the error path,
        // but didn't seem to show a success toast? Ah, looking at previous code block:
        /*
         if (responseData['success'] == true) {
           _isLandSubmitted = true;
           return true; 
         }
         */
        // It returned true but didn't show a toast on success?
        // Wait, let's check correct behavior. Usually we want feedback.
        // Let's add toast for success too if not present, or maybe it was intended to be silent?
        // Looking at `createFarmer`, `updateFarmer` etc they show toasts.
        // Let's assume silent success was NOT intended or handled by UI?
        // Actually, if I look at `addFarmerLands` in `LandController`, it shows toast.
        // Here in `FarmerKycController`, `addFarmerLand` (singular) is used.
        // I will add toast for consistency.
        if (context.mounted) {
          ToastMessage.show(context, message: result.message, isError: false);
        }
        return true;
      } else {
        _errorMessage = result.message;
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred adding land: $e';
      return false;
    } finally {
      _setLoading(false);
      if (_errorMessage != null && context.mounted) {
        ToastMessage.show(context, message: _errorMessage!, isError: true);
      }
    }
  }

  /// Update Farmer Land
  Future<bool> updateFarmerLand({
    required BuildContext context,
    required String farmerId,
    required String landType,
    String? villageAdd,
    String? taluka,
    String? district,
    String? area,
    String? landOwnerName,
    String? relationType,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final url = ApiConstants.updateFarmerLandById
          .replaceAll('{{farmerId}}', farmerId);
      
      final Map<String, String> body = {
        'landType': landType,
      };
      if (villageAdd != null) body['villageAdd'] = villageAdd;
      if (taluka != null) body['taluka'] = taluka;
      if (district != null) body['district'] = district;
      if (area != null) body['area'] = area;
      if (landOwnerName != null) body['landOwnerName'] = landOwnerName;
      if (relationType != null) body['relationType'] = relationType;

      final response = await _apiService.put(url, body: body);

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Land details updated!',
        defaultErrorMessage: 'Failed to update land details',
      );

      if (context.mounted) {
        ToastMessage.show(
          context,
          message: result.message,
          isError: !result.success,
        );
      }

      if (!result.success) {
        _errorMessage = result.message;
      }
      return result.success;
    } catch (e) {
      _errorMessage = 'An error occurred updating land: $e';
      return false;
    } finally {
      _setLoading(false);
      if (_errorMessage != null && context.mounted) {
        ToastMessage.show(context, message: _errorMessage!, isError: true);
      }
    }
  }

  /// Step 4: Add Farmer Bank Details
  Future<bool> addFarmerBank({
    required BuildContext context,
    required String farmerId,
    String? bankId,
    required String bankName,
    required String accountNo,
    required String ifsc,
    required String holderName,
    String? branchName,
    required File passbookImage,
    bool isPrimary = true,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final url =
          ApiConstants.createFarmerBank.replaceAll('{{farmerId}}', farmerId);

      final Map<String, String> fields = {
        'bankName': bankName,
        'accountNo': accountNo,
        'ifsc': ifsc,
        'holderName': holderName,
      };
      if (branchName != null && branchName.isNotEmpty) {
        fields['branchName'] = branchName;
      }

      debugPrint('🏦 addFarmerBank URL: $url');
      debugPrint('🏦 addFarmerBank fields: $fields');

      final List<http.MultipartFile> files = [];
      if (await passbookImage.exists()) {
        files.add(await http.MultipartFile.fromPath(
          'document',
          passbookImage.path,
          contentType: MediaType.parse(_getMimeType(passbookImage.path)),
        ));
      }

      final response = await _apiService.multipartRequest(
        url,
        fields: fields,
        files: files,
      );

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Bank details added successfully!',
        defaultErrorMessage: 'Failed to add bank details',
      );

      if (result.success) {
        _isBankSubmitted = true;
        _setLoading(false);
        if (context.mounted) {
          ToastMessage.show(
            context,
            message: result.message,
            isError: false,
          );
        }
        return true;
      } else {
        _errorMessage = result.message;
        _setLoading(false);
        if (context.mounted) {
          ToastMessage.show(context, message: _errorMessage!, isError: true);
        }
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _setLoading(false);
      if (context.mounted) {
        ToastMessage.show(context, message: _errorMessage!, isError: true);
      }
      return false;
    }
  }

  /// Update Farmer Bank Details
  Future<bool> updateFarmerBank({
    required BuildContext context,
    required String farmerId,
    String? bankId,
    String? farmerBankRecordId,
    required String bankName,
    required String accountNo,
    required String ifsc,
    required String holderName,
    String? branchName,
    File? passbookImage,
    bool isPrimary = true,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Use the farmer's bank record ID in the URL
      final bankRecordId = farmerBankRecordId ?? '';
      final url = ApiConstants.updateFarmerBankById
          .replaceAll('{{farmerId}}', farmerId)
          .replaceAll('{{bankRecordId}}', bankRecordId);

      final Map<String, String> fields = {
        'bankName': bankName,
        'accountNo': accountNo,
        'ifsc': ifsc,
        'holderName': holderName,
      };
      if (branchName != null && branchName.isNotEmpty) {
        fields['branchName'] = branchName;
      }

      debugPrint('🏦 updateFarmerBank URL: $url');
      debugPrint('🏦 updateFarmerBank farmerBankRecordId: $farmerBankRecordId');
      debugPrint('🏦 updateFarmerBank fields: $fields');

      final List<http.MultipartFile> files = [];
      if (passbookImage != null && await passbookImage.exists()) {
        files.add(await http.MultipartFile.fromPath(
          'document',
          passbookImage.path,
          contentType: MediaType.parse(_getMimeType(passbookImage.path)),
        ));
      }

      final response = await _apiService.multipartRequest(
        url,
        method: 'PUT',
        fields: fields,
        files: files,
      );

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Bank details updated successfully!',
        defaultErrorMessage: 'Failed to update bank details',
      );

      if (result.success) {
        _setLoading(false);
        if (context.mounted) {
          ToastMessage.show(
            context,
            message: result.message,
            isError: false,
          );
        }
        return true;
      } else {
        _errorMessage = result.message;
        _setLoading(false);
        if (context.mounted) {
          ToastMessage.show(context, message: _errorMessage!, isError: true);
        }
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _setLoading(false);
      if (context.mounted) {
        ToastMessage.show(context, message: _errorMessage!, isError: true);
      }
      return false;
    }
  }

  void reset() {
    _isJustCreated = false;
    _createdFarmerId = null;
    _currentStep = 0;
    _isFarmerSubmitted = false;
    _isIdSubmitted = false;
    _isLandSubmitted = false;
    _isBankSubmitted = false;
    _searchResults = [];
    _fetchedDocuments = null;
    _fetchedLands = null;
    _fetchedBank = null;
    _fetchedFarmerDetail = null;
    _errorMessage = null;
    _isLoading = false;
    _nonKycSearchQuery = "";
    _isNonKycMyFarmersOnly = false;
    fetchNonKycFarmers();
    notifyListeners();
  }

  Future<bool> finishKyc() async {
    await clearProgress();
    return true;
  }
}
