import 'package:flutter/material.dart';
import 'package:soya_app/core/constants/api_constants.dart';
import 'package:soya_app/core/services/api_service.dart';
import 'package:soya_app/core/utils/api_helper.dart';
import 'package:soya_app/core/widgets/tost_message.dart';
import 'package:soya_app/features/home/model/product_model.dart';
import 'package:soya_app/features/home/model/product_list_model.dart';

class ProductController with ChangeNotifier {
  final _apiService = ApiService.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ProductListData>? _products;
  List<ProductListData>? get products => _products;

  ProductData? _selectedProduct;
  ProductData? get selectedProduct => _selectedProduct;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Fetch all products (vendor)
  Future<bool> fetchProducts({required BuildContext context}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _apiService.get(
        ApiConstants.getProductsVendor,
      );

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Products fetched successfully!',
        defaultErrorMessage: 'Failed to fetch products',
      );

      if (result.success) {
        final productListModel = ProductListModel.fromJson(result.data);
        if (productListModel.success == true) {
          _products = productListModel.data;
          _setLoading(false);
          // Only show toast if needed, but original code showed it.
          if (context.mounted) {
            ToastMessage.show(
              context,
              message: result.message,
              isError: false,
            );
          }
          return true;
        } else {
          _errorMessage = 'Invalid product data';
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

  /// Fetch product by ID
  Future<bool> fetchProductById({
    required BuildContext context,
    required String productId,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final url = ApiConstants.getProductByIdVendor
          .replaceAll('{{productId}}', productId);

      final response = await _apiService.get(url);

      final result = ApiHelper.handleResponse(
        response,
        defaultSuccessMessage: 'Product fetched successfully!',
        defaultErrorMessage: 'Failed to fetch product',
      );

      if (result.success) {
        final productModel = ProductModel.fromJson(result.data);
        if (productModel.success == true && productModel.data != null) {
          _selectedProduct = productModel.data;
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
          _errorMessage = 'Invalid product data';
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

  /// Clear selected product
  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }

  /// Reset controller state
  void reset() {
    _products = null;
    _selectedProduct = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
