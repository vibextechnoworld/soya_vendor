import 'package:flutter/material.dart';

class ShimmerController extends ChangeNotifier {
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  ShimmerController() {
    _startTimer();
  }

  void _startTimer() async {
    await Future.delayed(const Duration(seconds: 1));
    _isLoading = false;
    notifyListeners();
  }

  /// Call when screen reopens (optional)
  void reset() {
    _isLoading = true;
    notifyListeners();
    _startTimer();
  }
}
