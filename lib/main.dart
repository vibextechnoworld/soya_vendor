import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:soya_app/core/controller/theme_controller.dart';
import 'package:soya_app/features/bottom_navigation_bar/controller/bottom_navbar_controller.dart';
import 'package:soya_app/features/splash/controller/on_bording_controller.dart';
import 'package:soya_app/features/splash/controller/splash_controller.dart';
import 'package:soya_app/features/login_and_signup/controller/login_controller.dart';
import 'package:soya_app/features/home/controller/farmer_kyc_controller.dart';
import 'package:soya_app/features/home/controller/product_controller.dart';
import 'package:soya_app/features/home/controller/stock_controller.dart';
import 'package:soya_app/features/home/controller/billing_controller.dart';
import 'package:soya_app/features/home/controller/land_controller.dart';
import 'package:soya_app/features/location/controller/location_provider.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => SplashController(),
          ),
          ChangeNotifierProvider(create: (_) => ThemeController()),
          ChangeNotifierProvider(create: (_) => OnBoardingController()),
          ChangeNotifierProvider(create: (_) => BottomNavBarController()),
          ChangeNotifierProvider(create: (_) => LoginController()),
          ChangeNotifierProvider(create: (_) => FarmerKycController()),
          ChangeNotifierProvider(create: (_) => ProductController()),
          ChangeNotifierProvider(create: (_) => StockController()),
          ChangeNotifierProvider(create: (_) => BillingController()),
          ChangeNotifierProvider(create: (_) => LandController()),
          ChangeNotifierProvider(create: (_) => LocationProvider()),
        ],
        child: const SoyaApp(),
      ),
      child: const SizedBox(), // prevent black screen
    ),
  );
}
