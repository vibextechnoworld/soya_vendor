import 'package:flutter/material.dart';
import 'package:soya_app/features/splash/model/on_bording_model.dart';

class OnBoardingController extends ChangeNotifier {
  int currentPage = 0;
  List<OnBoardingModel> onBoardingList = OnBoardingModel.onBoardingList;
  void setCurrentPage(int page) {
    currentPage = page;
    notifyListeners();
  }
}
