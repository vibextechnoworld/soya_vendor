import 'package:flutter/material.dart';

enum FormView { selection, farmerKYC, billing, stockTransfer, bagSummary }

class BottomNavBarController extends ChangeNotifier {
  int _currentIndex = 0;
  FormView _currentFormView = FormView.selection;
  final PageController _pageController = PageController();

  int get currentIndex => _currentIndex;
  FormView get currentFormView => _currentFormView;
  PageController get pageController => _pageController;

  void setIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    notifyListeners();
  }

  void updateFormView(FormView view) {
    _currentFormView = view;
    if (_currentIndex != 0) {
      setIndex(0);
    }
    notifyListeners();
  }

  void onPageChanged(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void reset() {
    _currentIndex = 0;
    _currentFormView = FormView.selection;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
