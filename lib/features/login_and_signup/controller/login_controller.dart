import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soya_app/core/constants/api_constants.dart';
import 'package:soya_app/core/services/api_service.dart';
import 'package:soya_app/core/utils/api_helper.dart';
import 'package:soya_app/core/widgets/tost_message.dart';
import 'package:soya_app/features/login_and_signup/model/login_model.dart';
import 'package:provider/provider.dart';
import 'package:soya_app/features/bottom_navigation_bar/controller/bottom_navbar_controller.dart';
import 'package:soya_app/routes/app_routes.dart';

class LoginController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isRememberMeChecked = false;
  bool get isRememberMeChecked => _isRememberMeChecked;

  void toggleRememberMe(bool value) {
    _isRememberMeChecked = value;
    notifyListeners();
  }

  // User Data
  String? _userName;
  String? _userEmail;
  String? _userPhone;
  String? _userRole;
  int? _vendorRate;
  String? _villageAdd;
  String? _taluka;
  String? _district;
  bool? _masterVendor;

  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userPhone => _userPhone;
  String? get userRole => _userRole;
  int? get vendorRate => _vendorRate;
  String? get villageAdd => _villageAdd;
  String? get taluka => _taluka;
  String? get district => _district;
  bool? get masterVendor => _masterVendor;

  LoginController() {
    _loadUserSession();
  }

  Future<void> login(
      BuildContext context, String email, String password,
      {String role = 'VENDOR'}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await ApiService.instance.post(
        ApiConstants.login, //login api for vendor
        body: {
          'email': email,
          'password': password,
          'role': role,
        },
        includeAuth: false, // No token needed for login
      );

      log('Login API status code: ${response.statusCode}');
      log('Login API body: ${response.body}');

      final result = ApiHelper.handleResponse(
        response,
        defaultErrorMessage: 'Login failed. Please try again.',
      );

      if (result.success) {
        final loginModel = LoginModel.fromJson(result.data);
        if (loginModel.data?.token != null) {
          // Success
          await _saveUserSession(loginModel, _isRememberMeChecked);
          if (context.mounted) {
            _navigateToBottomNavBar(context);
            ToastMessage.show(
              context,
              message: result.message,
              isError: false,
            );
          }
        } else {
          _errorMessage = 'Invalid response data';
          if (context.mounted) {
            ToastMessage.show(context, message: _errorMessage!, isError: true);
          }
        }
      } else {
        _errorMessage = result.message;
        if (context.mounted) {
          ToastMessage.show(context, message: _errorMessage!, isError: true);
        }
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      if (context.mounted) {
        ToastMessage.show(context, message: _errorMessage!, isError: true);
      }
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _saveUserSession(LoginModel model, bool rememberMe) async {
    final token = model.data?.token;
    final prefs = await SharedPreferences.getInstance();

    // Always store token in SharedPreferences for the current session
    if (token != null) {
      await prefs.setString('token', token);
      log('Token stored in SharedPreferences: $token');
    }

    // Store Remember Me flag
    await prefs.setBool('isRememberMe', rememberMe);

    if (model.data?.safeUser != null) {
      final user = model.data!.safeUser!;

      // Always store essential user data in SharedPreferences for the session
      if (user.name != null) await prefs.setString('userName', user.name!);
      if (user.email != null) await prefs.setString('userEmail', user.email!);
      if (user.phone != null) await prefs.setString('userPhone', user.phone!);
      if (user.role != null) await prefs.setString('userRole', user.role!);
      if (user.id != null) await prefs.setString('userId', user.id!);
      if (user.villageAdd != null) {
        await prefs.setString('villageAdd', user.villageAdd!);
      }
      if (user.taluka != null) await prefs.setString('taluka', user.taluka!);
      if (user.district != null) {
        await prefs.setString('district', user.district!);
      }
      if (user.masterVendor != null) {
        await prefs.setBool('masterVendor', user.masterVendor!);
      }
      if (user.vendorRate != null) {
        await prefs.setInt('vendorRate', user.vendorRate!);
      }

      // Update local state immediately (always done for current session)
      _userName = user.name;
      _userEmail = user.email;
      _userPhone = user.phone;
      _userRole = user.role;
      _vendorRate = user.vendorRate;
      _villageAdd = user.villageAdd;
      _taluka = user.taluka;
      _district = user.district;
      _masterVendor = user.masterVendor;
      notifyListeners();
    }
  }

  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('userName');
    _userEmail = prefs.getString('userEmail');
    _userPhone = prefs.getString('userPhone');
    _userRole = prefs.getString('userRole');
    _vendorRate = prefs.getInt('vendorRate');
    _villageAdd = prefs.getString('villageAdd');
    _taluka = prefs.getString('taluka');
    _district = prefs.getString('district');
    _masterVendor = prefs.getBool('masterVendor');
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all data including token and isRememberMe

    // Reset navigation state
    if (context.mounted) {
      try {
        context.read<BottomNavBarController>().reset();
      } catch (e) {
        log("Error resetting bottom navbar on logout: $e");
      }
    }

    // Clear local state
    _userName = null;
    _userEmail = null;
    _userPhone = null;
    _userRole = null;
    _vendorRate = null;
    _villageAdd = null;
    _taluka = null;
    _district = null;
    _masterVendor = null;
    notifyListeners();

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  void _navigateToBottomNavBar(BuildContext context) {
    // Reset navigation state before entering
    try {
      context.read<BottomNavBarController>().reset();
    } catch (e) {
      log("Error resetting bottom navbar on login: $e");
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.bottomNavBar,
      (route) => false,
    );
  }
}
