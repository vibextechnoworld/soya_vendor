import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:soya_app/core/constants/api_constants.dart';
import 'package:soya_app/core/services/api_service.dart';
import 'package:soya_app/core/utils/api_helper.dart';
import 'package:soya_app/core/widgets/tost_message.dart';
import 'package:soya_app/features/home/model/add_stock_model.dart';
import 'package:soya_app/features/home/model/vendor_stock_list_model.dart';
import 'package:soya_app/features/home/model/farmer_stock_summary_model.dart';
import 'package:soya_app/features/home/model/vendor_transfer_list_model.dart';
import 'package:soya_app/features/home/model/adjust_stock_model.dart';
import 'package:soya_app/features/home/model/goni_type_model.dart';
import 'package:soya_app/features/home/model/stock_transfer_request.dart';
import 'package:soya_app/features/home/model/vendor_stock_summary_model.dart';
import 'package:soya_app/features/home/model/bag_summary_model.dart';
import 'package:soya_app/features/home/model/farmer_bag_return_due_model.dart';
import 'package:soya_app/features/home/model/inventory_location_model.dart';
import 'package:soya_app/features/home/model/thappi_model.dart';
import 'package:soya_app/core/services/location_service.dart';

class StockController with ChangeNotifier {
  final _apiService = ApiService.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<VendorStockData>? _vendorStocks;
  List<VendorStockData>? get vendorStocks => _vendorStocks;

  int _currentPage = 1;
  int get currentPage => _currentPage;

  int _totalPages = 1;
  int get totalPages => _totalPages;

  int _totalItems = 0;
  int get totalItems => _totalItems;

  int _pageSize = 10;
  int get pageSize => _pageSize;

  List<FarmerStockData>? _farmerStocks;
  List<FarmerStockData>? get farmerStocks => _farmerStocks;

  List<GoniType> _goniTypes = [];
  List<GoniType> get goniTypes => _goniTypes;

  List<VendorTransferData> _vendorTransfers = [];
  List<VendorTransferData> get vendorTransfers => _vendorTransfers;

  List<VendorTransferData> _incomingTransfers = [];
  List<VendorTransferData> get incomingTransfers => _incomingTransfers;

  List<VendorShort> _vendors = [];
  List<VendorShort> get vendors => _vendors;

  double _totalAvailableWeight = 0;
  double get totalAvailableWeight => _totalAvailableWeight;

  int _totalAvailableBags = 0;
  int get totalAvailableBags => _totalAvailableBags;

  int _totalRemainingBags = 0;
  int get totalRemainingBags => _totalRemainingBags;

  List<SelectedBag> _selectedBags = [];
  List<SelectedBag> get selectedBags => _selectedBags;

  BagSummaryModel? _bagSummary;
  BagSummaryModel? get bagSummary => _bagSummary;

  FarmerBagReturnDueData? _farmerBagReturnDue;
  FarmerBagReturnDueData? get farmerBagReturnDue => _farmerBagReturnDue;

  List<InventoryLocation> _inventoryLocations = [];
  List<InventoryLocation> get inventoryLocations => _inventoryLocations;

  List<Thappi> _thappis = [];
  List<Thappi> get thappis => _thappis;

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

  /// 9. Fetch Vendor Bag Summary
  Future<void> fetchVendorBagSummary() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _apiService.get(ApiConstants.getBagSummary);
      final result = ApiHelper.handleResponse(response);

      if (result.success) {
        _bagSummary = BagSummaryModel.fromJson(result.data);
      } else {
        _errorMessage = result.message;
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch bag summary: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// 10. Fetch Farmer Bag Return Due
  Future<void> fetchFarmerBagReturnDue(String farmerId) async {
    _farmerBagReturnDue = null; // Clear previous data
    _setLoading(true);
    _errorMessage = null;

    try {
      final url = ApiConstants.getFarmerBagReturnDue.replaceAll(
        '{{farmerId}}',
        farmerId,
      );

      final response = await _apiService.get(url);
      final result = ApiHelper.handleResponse(response);

      if (result.success) {
        final model = FarmerBagReturnDueModel.fromJson(result.data);
        _farmerBagReturnDue = model.data;
      } else {
        _errorMessage = result.message;
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch farmer bag return due: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// 11. Return Bags to Farmer
  Future<bool> returnBagsToFarmer({
    required BuildContext context,
    required String farmerId,
    required String goniTypeId,
    required int bagCount,
    required String notes,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _apiService.post(
        ApiConstants.returnBagsToFarmer,
        body: {
          'farmerId': farmerId,
          'goniTypeId': goniTypeId,
          'bagCount': bagCount,
          if (notes.trim().isNotEmpty) 'notes': notes,
        },
      );

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Bags returned to farmer successfully!',
        defaultErrorMessage: 'Failed to return bags to farmer',
      );

      if (result.success) {
        _setLoading(false);
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

  /// 11a. Add Own Opening Bags
  Future<bool> addOwnOpeningBags({
    required BuildContext context,
    required String goniTypeId,
    required int bagCount,
    String? notes,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _apiService.post(
        ApiConstants.addOwnOpeningBags,
        body: {
          'goniTypeId': goniTypeId,
          'bagCount': bagCount,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Opening bags added successfully!',
        defaultErrorMessage: 'Failed to add opening bags',
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
        // Refresh bag summary after adding
        fetchVendorBagSummary();
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

  void clearBags() {
    _selectedBags = [];
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// 1. Add Stock
  Future<bool> addStock({
    required BuildContext context,
    required String farmerId,
    required String productId,
    required double quantity,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _apiService.post(
        ApiConstants.addStock,
        body: {
          'farmerId': farmerId,
          'productId': productId,
          'quantity': quantity,
        },
      );

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Stock added successfully!',
        defaultErrorMessage: 'Failed to add stock',
      );

      if (result.success) {
        final stockModel = AddStockModel.fromJson(result.data);
        if (stockModel.success == true) {
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
          _errorMessage = 'Invalid stock data';
          _setLoading(false);
          if (context.mounted) {
            ToastMessage.show(context, message: _errorMessage!, isError: true);
          }
          return false;
        }
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

  /// 2. Get Farmer Stock Summary
  Future<bool> getFarmerStockSummary({
    required BuildContext context,
    required String farmerId,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final url =
          ApiConstants.getStockSummary.replaceAll('{{farmerId}}', farmerId);

      final response = await _apiService.get(url);

      final responseData = jsonDecode(response.body);
      final stockModel = FarmerStockSummaryModel.fromJson(responseData);

      if (response.statusCode == 200) {
        if (stockModel.success == true) {
          _farmerStocks = stockModel.data;
          _setLoading(false);
          if (context.mounted) {
            ToastMessage.show(
              context,
              message:
                  stockModel.message ?? 'Farmer stocks fetched successfully!',
              isError: false,
            );
          }
          return true;
        } else {
          _errorMessage = stockModel.message ?? 'Failed to fetch farmer stocks';
          _setLoading(false);
          if (context.mounted) {
            ToastMessage.show(context, message: _errorMessage!, isError: true);
          }
          return false;
        }
      } else {
        _errorMessage = stockModel.message ??
            'Failed to fetch farmer stocks. Please try again.';
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

  /// 3. Get Vendor Stock (All stocks)
  Future<bool> getVendorStock(
      {required BuildContext context, int page = 1, int limit = 10}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final url = '${ApiConstants.getVendorStock}?page=$page&limit=$limit';
      final response = await _apiService.get(url);

      final responseData = jsonDecode(response.body);
      final stockModel = VendorStockListModel.fromJson(responseData);

      if (response.statusCode == 200) {
        if (stockModel.success == true) {
          _vendorStocks = stockModel.data;
          _currentPage = stockModel.currentPage ?? page;
          _totalPages = stockModel.totalPages ?? 1;
          _totalItems = stockModel.totalItems ?? (_vendorStocks?.length ?? 0);
          _setLoading(false);
          if (context.mounted) {
            ToastMessage.show(
              context,
              message: stockModel.message ?? 'Stocks fetched successfully!',
              isError: false,
            );
          }
          return true;
        } else {
          _errorMessage = stockModel.message ?? 'Failed to fetch stocks';
          _setLoading(false);
          if (context.mounted) {
            ToastMessage.show(context, message: _errorMessage!, isError: true);
          }
          return false;
        }
      } else {
        _errorMessage =
            stockModel.message ?? 'Failed to fetch stocks. Please try again.';
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

  /// 4. Adjust Stock
  Future<bool> adjustStock({
    required BuildContext context,
    required String stockId,
    required double quantity,
    required String reason,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _apiService.post(
        ApiConstants.adjustStock,
        body: {
          'stockId': stockId,
          'quantity': quantity,
          'reason': reason,
        },
      );

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Stock adjusted successfully!',
        defaultErrorMessage: 'Failed to adjust stock',
      );

      if (result.success) {
        final stockModel = AdjustStockModel.fromJson(result.data);
        if (stockModel.success == true) {
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
          _errorMessage = 'Invalid stock data';
          _setLoading(false);
          if (context.mounted) {
            ToastMessage.show(context, message: _errorMessage!, isError: true);
          }
          return false;
        }
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

  /// 5. Stock Transfer
  Future<String?> stockTransfer({
    required BuildContext context,
    required StockTransferRequest request,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _apiService.post(
        ApiConstants.stockTransfer,
        body: request.toJson(),
      );

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Stock transfer created successfully!',
        defaultErrorMessage: 'Failed to create stock transfer',
      );

      if (result.success) {
        _setLoading(false);
        final data = result.data;
        String? transferId;
        if (data != null && data['data'] != null) {
          transferId = data['data']['id']?.toString();
        } else if (data != null) {
          transferId = data['id']?.toString();
        }

        if (context.mounted) {
          ToastMessage.show(
            context,
            message: result.message,
            isError: false,
          );
        }
        return transferId;
      } else {
        _errorMessage = result.message;
        _setLoading(false);
        if (context.mounted) {
          ToastMessage.show(context, message: _errorMessage!, isError: true);
        }
        return null;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _setLoading(false);
      if (context.mounted) {
        ToastMessage.show(context, message: _errorMessage!, isError: true);
      }
      return null;
    }
  }

  /// 6. Fetch Goni Types
  Future<void> fetchGoniTypes() async {
    // Avoid setting loading to true if we just want to fetch in background or init
    // But for safety, let's keep it simple.
    // However, if we are in init, maybe we don't want to show full screen loader.
    // For now, I will not set global loading to avoid flickering if called in init
    try {
      final response = await _apiService.get(ApiConstants.getGoniTypes);
      final responseData = jsonDecode(response.body);
      final model = GoniTypeModel.fromJson(responseData);

      if (model.success == true) {
        _goniTypes =
            (model.data ?? []).where((e) => e.isActive == true).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching goni types: $e');
    }
  }

  /// 7. Get Vendor Transfers
  Future<void> getVendorTransfers({int page = 1, int limit = 10, String? type}) async {
    _setLoading(true);
    try {
      var url =
          '${ApiConstants.getVendorTransferList}?page=$page&limit=$limit';
      if (type != null) {
        url += '&type=$type';
      }
      final response = await _apiService.get(url);
      final responseData = jsonDecode(response.body);

      final model = VendorTransferListModel.fromJson(responseData);

      if (model.success == true && model.data?.transfers != null) {
        if (type == 'incoming') {
          _incomingTransfers = model.data!.transfers!;
        } else {
          _vendorTransfers = model.data!.transfers!;
        }
        _currentPage = model.data?.pagination?.page ?? page;
        _totalPages = model.data?.pagination?.totalPages ?? 1;
        _totalItems = model.data?.pagination?.total ?? (type == 'incoming' ? _incomingTransfers.length : _vendorTransfers.length);
        _pageSize = model.data?.pagination?.limit ?? 10;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching vendor transfers: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch all active vendors
  Future<void> fetchVendors() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('${ApiConstants.baseUrl}/auth/vendor/list?limit=200&isActive=true');
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final rawData = responseData['data'];
        List list = [];
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map) {
          list = rawData['vendors'] ??
              rawData['data'] ??
              rawData['docs'] ??
              rawData['items'] ??
              [];
        }
        _vendors = list.map((e) => VendorShort.fromJson(e)).toList();
      } else {
        _errorMessage = responseData['message'] ?? 'Failed to fetch vendors';
      }
    } catch (e) {
      _errorMessage = 'Error fetching vendors: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  VendorStockSummaryModel? _stockSummary;
  VendorStockSummaryModel? get stockSummary => _stockSummary;

  /// 8. Get Vendor Stock Summary
  Future<void> fetchVendorStockSummary() async {
    _setLoading(true);
    try {
      final response =
          await _apiService.get(ApiConstants.getVendorStockSummary);
      final responseData = jsonDecode(response.body);

      _stockSummary = VendorStockSummaryModel.fromJson(responseData);

      if (_stockSummary?.success == true &&
          _stockSummary?.data?.totalAvailable != null) {
        _totalAvailableWeight =
            _stockSummary!.data!.totalAvailable!.weight ?? 0;
        _totalAvailableBags =
            _stockSummary!.data!.totalAvailable!.bagCount ?? 0;
        _totalRemainingBags =
            _stockSummary!.data!.bagLedgerTotals?.totalRemainingWithVendor ?? 0;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching vendor stock summary: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch all active inventory locations
  Future<void> fetchInventoryLocations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const url =
          '${ApiConstants.getInventoryLocations}?limit=100&isActive=true';
      debugPrint('🌐 fetching locations from url: $url');
      final response = await _apiService.get(url);
      debugPrint(
          '🌐 fetch locations response: status=${response.statusCode}, body=${response.body}');
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final rawData = responseData['data'];
        List list = [];
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map) {
          list = rawData['locations'] ??
              rawData['data'] ??
              rawData['docs'] ??
              rawData['inventoryLocations'] ??
              rawData['items'] ??
              [];
        }
        _inventoryLocations =
            list.map((e) => InventoryLocation.fromJson(e)).toList();
        debugPrint(
            '🌐 successfully parsed ${_inventoryLocations.length} locations');
      } else {
        _errorMessage =
            responseData['message'] ?? 'Failed to fetch inventory locations';
        debugPrint(
            '🌐 API returned success=false or status!=200: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = 'Error fetching locations: $e';
      debugPrint('🌐 Error fetching locations catch block: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch thappis by location
  Future<void> fetchThappisForLocation(String locationId) async {
    _isLoading = true;
    _errorMessage = null;
    _thappis = [];
    notifyListeners();

    try {
      final response = await _apiService
          .get('${ApiConstants.getThappis}?locationId=$locationId');
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final rawData = responseData['data'];
        List list = [];
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map) {
          list = rawData['thappis'] ??
              rawData['data'] ??
              rawData['docs'] ??
              rawData['items'] ??
              [];
        }
        _thappis = list.map((e) => Thappi.fromJson(e)).toList();
      } else {
        _errorMessage = responseData['message'] ?? 'Failed to fetch thappis';
      }
    } catch (e) {
      _errorMessage = 'Error fetching thappis: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new Thappi
  Future<bool> createThappi({
    required BuildContext context,
    required String locationId,
    required double weightQtl,
    double? moisture,
    double? fm,
    double? damage,
    required List<Map<String, dynamic>> bagBreakdown,
    File? image,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final Map<String, String> fields = {
        'locationId': locationId,
        'weightQtl': weightQtl.toString(),
        'bagBreakdown': jsonEncode(bagBreakdown),
      };
      if (moisture != null) fields['moisture'] = moisture.toString();
      if (fm != null) fields['fm'] = fm.toString();
      if (damage != null) fields['damage'] = damage.toString();

      final List<http.MultipartFile> files = [];
      if (image != null && await image.exists()) {
        final ext = p.extension(image.path).toLowerCase();
        final mimeType = ext == '.pdf'
            ? 'application/pdf'
            : (ext == '.bmp'
                ? 'image/bmp'
                : 'image/jpeg');
        files.add(await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: MediaType.parse(mimeType),
        ));
      }

      final response = await _apiService.multipartRequest(
        ApiConstants.getThappis,
        method: 'POST',
        fields: fields,
        files: files,
      );

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Thappi created successfully!',
        defaultErrorMessage: 'Failed to create thappi',
      );

      if (result.success) {
        if (context.mounted) {
          ToastMessage.show(context, message: result.message, isError: false);
        }
        // Refresh thappis for this location
        await fetchThappisForLocation(locationId);
        return true;
      } else {
        _errorMessage = result.message;
        if (context.mounted) {
          ToastMessage.show(context, message: _errorMessage!, isError: true);
        }
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error creating thappi: $e';
      if (context.mounted) {
        ToastMessage.show(context, message: _errorMessage!, isError: true);
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a Thappi
  Future<bool> deleteThappi({
    required BuildContext context,
    required String thappiId,
    required String locationId,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final url = ApiConstants.deleteThappi.replaceAll('{{thappiId}}', thappiId);
      final response = await _apiService.delete(url);

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Thappi deleted successfully!',
        defaultErrorMessage: 'Failed to delete thappi',
      );

      if (result.success) {
        if (context.mounted) {
          ToastMessage.show(context, message: result.message, isError: false);
        }
        await fetchThappisForLocation(locationId);
        return true;
      } else {
        _errorMessage = result.message;
        if (context.mounted) {
          ToastMessage.show(context, message: _errorMessage!, isError: true);
        }
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error deleting thappi: $e';
      if (context.mounted) {
        ToastMessage.show(context, message: _errorMessage!, isError: true);
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Dispatch Stock Transfer
  Future<bool> dispatchStockTransfer({
    required BuildContext context,
    required String transferId,
    required double weight,
    required String unit,
    required int bagCount,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final position = await LocationService.getCurrentLocation();
      double lat = 0.0;
      double lng = 0.0;
      if (position != null) {
        final parts = position.split(',');
        lat = double.tryParse(parts[0]) ?? 0.0;
        lng = double.tryParse(parts[1]) ?? 0.0;
      }
      final locText =
          await LocationService.getCurrentLocationAddress() ?? "Unknown";

      final url = ApiConstants.dispatchTransfer
          .replaceAll('{{transferId}}', transferId);
      final response = await _apiService.put(
        url,
        body: {
          'weight': weight,
          'unit': unit,
          'bagCount': bagCount,
          'dispatchLatitude': lat,
          'dispatchLongitude': lng,
          'dispatchLocationText': locText,
        },
      );

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Transfer Dispatched successfully!',
        defaultErrorMessage: 'Failed to dispatch transfer',
      );

      if (result.success) {
        _setLoading(false);
        if (context.mounted) {
          ToastMessage.show(context, message: result.message, isError: false);
        }
        await getVendorTransfers(limit: 50); // Refresh transfers list
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
      _errorMessage = 'Dispatch error: $e';
      _setLoading(false);
      if (context.mounted) {
        ToastMessage.show(context, message: _errorMessage!, isError: true);
      }
      return false;
    }
  }

  /// Receive Stock Transfer
  Future<bool> receiveStockTransfer({
    required BuildContext context,
    required String transferId,
    required double receivedWeight,
    required String receivedUnit,
    required int receivedBagCount,
    double? receiveLatitude,
    double? receiveLongitude,
    String? receiveLocationText,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      double lat = receiveLatitude ?? 0.0;
      double lng = receiveLongitude ?? 0.0;
      String locText = receiveLocationText ?? "Unknown";

      // If coordinates not provided, fetch them
      if (receiveLatitude == null || receiveLongitude == null) {
        final position = await LocationService.getCurrentLocation();
        if (position != null) {
          final parts = position.split(',');
          lat = double.tryParse(parts[0]) ?? 0.0;
          lng = double.tryParse(parts[1]) ?? 0.0;
        }
      }

      // If location text not provided, fetch it
      if (receiveLocationText == null) {
        locText = await LocationService.getCurrentLocationAddress() ?? "Unknown";
      }

      final url =
          ApiConstants.receiveTransfer.replaceAll('{{transferId}}', transferId);
      final response = await _apiService.put(
        url,
        body: {
          'receivedWeight': receivedWeight,
          'receivedUnit': receivedUnit,
          'receivedBagCount': receivedBagCount,
          'receiveLatitude': lat,
          'receiveLongitude': lng,
          'receiveLocationText': locText,
        },
      );

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Transfer Received successfully!',
        defaultErrorMessage: 'Failed to receive transfer',
      );

      if (result.success) {
        _setLoading(false);
        if (context.mounted) {
          ToastMessage.show(context, message: result.message, isError: false);
        }
        await getVendorTransfers(limit: 50); // Refresh transfers list
        await getVendorTransfers(limit: 50, type: 'incoming'); // Refresh incoming list
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
      _errorMessage = 'Receive error: $e';
      _setLoading(false);
      if (context.mounted) {
        ToastMessage.show(context, message: _errorMessage!, isError: true);
      }
      return false;
    }
  }

  /// Reset controller state
  void reset() {
    _vendorStocks = null;
    _farmerStocks = null;
    _stockSummary = null;
    _bagSummary = null;
    _farmerBagReturnDue = null;
    _inventoryLocations = [];
    _thappis = [];
    _incomingTransfers = [];
    _vendors = [];
    _errorMessage = null;
    _isLoading = false;
    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _totalAvailableWeight = 0;
    _totalAvailableBags = 0;
    _totalRemainingBags = 0;
    _selectedBags = [];
    notifyListeners();
  }
}

class SelectedBag {
  final GoniType goniType;
  final int bagCount;

  SelectedBag({required this.goniType, required this.bagCount});
}
