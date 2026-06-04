import 'package:flutter/material.dart';
import 'package:soya_app/features/bottom_navigation_bar/view/bottom_navbar_screen.dart';
import 'package:soya_app/features/home/view/home_screen.dart';
import 'package:soya_app/features/login_and_signup/view/login_screen.dart';
import 'package:soya_app/features/login_and_signup/view/otp_screen.dart';
import 'package:soya_app/features/notifications/view/notifications_screen.dart';
import 'package:soya_app/features/splash/view/onbording_screen.dart';
import 'package:soya_app/features/splash/view/splash_screen.dart';
import 'package:soya_app/features/home/view/farmer_kyc_screen.dart';
import 'package:soya_app/features/home/view/billing_screen.dart';
import 'package:soya_app/features/home/view/stock_transfer_screen.dart';
import 'package:soya_app/features/home/view/bill_summary_screen.dart';
import 'package:soya_app/features/home/view/bag_summary_screen.dart';
import 'package:soya_app/features/login_and_signup/view/select_form_screen.dart';
import 'package:soya_app/features/reports/view/reports_hub_screen.dart';
import 'package:soya_app/features/reports/view/billing_report_screen.dart';
import 'package:soya_app/features/reports/view/farmers_report_screen.dart';
import 'package:soya_app/features/reports/view/stock_report_screen.dart';
import 'package:soya_app/features/reports/view/rate_history_report_screen.dart';
import 'app_routes.dart';

class AppPages {
  static Map<String, WidgetBuilder> routes = {
    AppRoutes.splash: (_) => const SplashScreen(),
    AppRoutes.onBoarding: (_) => const OnBoardingScreen(),
    AppRoutes.login: (_) => const LoginScreen(),
    AppRoutes.bottomNavBar: (_) => const BottomNavBarScreen(),
    AppRoutes.otp: (_) => const OtpScreen(),
    AppRoutes.home: (_) => const HomeScreen(),
    AppRoutes.notifications: (_) => const NotificationsScreen(),
    AppRoutes.farmerKyc: (_) => const FarmerKYCScreen(),
    AppRoutes.billing: (_) => const BillingScreen(),
    AppRoutes.stockTransfer: (_) => const StockTransferScreen(),
    AppRoutes.selectForm: (_) => const SelectFormScreen(),
    AppRoutes.billSummary: (context) {
      final billId = ModalRoute.of(context)!.settings.arguments as String;
      return BillSummaryScreen(billId: billId);
    },
    AppRoutes.reportsHub: (_) => const ReportsHubScreen(),
    AppRoutes.billingReport: (_) => const BillingReportScreen(),
    AppRoutes.farmersReport: (_) => const FarmersReportScreen(),
    AppRoutes.stockReport: (_) => const StockReportScreen(),
    AppRoutes.bagSummary: (_) => const BagSummaryScreen(),
    AppRoutes.rateHistoryReport: (_) => const RateHistoryReportScreen(),
  };
}
