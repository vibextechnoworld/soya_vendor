import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeController extends ChangeNotifier {
  //---------------------To set theme as system theme---------------------//
  //ThemeMode _themeMode = ThemeMode.system;
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeController() {
    _loadTheme();
  }

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    StorageService.saveTheme(mode.name);
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final savedTheme = await StorageService.getTheme();
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == savedTheme,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }
}
