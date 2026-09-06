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

    final bool isProfileCompleted = await _isProfileCompleted(token);

    // if profile is completed, navigate to home. The session persists until
    // explicit logout, so token presence alone is enough.
    if (isProfileCompleted) {
      Navigator.pushReplacementNamed(context, AppRoutes.bottomNavBar);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  // Mock profile completion check
  Future<bool> _isProfileCompleted(String? token) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Profile is considered "session active" as long as a token exists.
    // Closing and reopening the app keeps the user logged in until logout.
    return token != null && token.isNotEmpty;
  }
}
