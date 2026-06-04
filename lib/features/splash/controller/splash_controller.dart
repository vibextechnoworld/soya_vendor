// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soya_app/routes/app_routes.dart';

class SplashController extends ChangeNotifier {
  // Call this from Splash Screen
  Future<void> decideNavigation(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 2)); //splash delay

    // User logged in → check profile

    final SharedPreferences sp = await SharedPreferences.getInstance();
    final String? token = sp.getString('token');
    final bool isRememberMe = sp.getBool('isRememberMe') ?? false;

    final bool isProfileCompleted = await _isProfileCompleted(token, isRememberMe);

    // if profile is completed and remember me is checked, navigate to home
    if (isProfileCompleted && isRememberMe) {
      Navigator.pushReplacementNamed(context, AppRoutes.bottomNavBar);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  // Mock profile completion check
  Future<bool> _isProfileCompleted(String? token, bool isRememberMe) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Profile is considered "session active" if token exists and user asked to be remembered
    if (token == null || !isRememberMe) {
      return false;
    } else {
      return true;
    }
  }
}
