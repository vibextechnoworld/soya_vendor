import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:soya_app/features/home/view/billing_screen.dart';
import 'package:soya_app/features/home/view/farmer_kyc_screen.dart';
import 'package:soya_app/features/home/view/stock_transfer_screen.dart';
import 'package:soya_app/features/profile/view/profile_screen.dart';
import 'package:soya_app/features/reports/view/reports_hub_screen.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';

import 'package:soya_app/features/login_and_signup/view/select_form_screen.dart';
import 'package:soya_app/features/home/view/bag_summary_screen.dart';
import '../controller/bottom_navbar_controller.dart';

class BottomNavBarScreen extends StatelessWidget {
  const BottomNavBarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BottomNavBarController>();

    Widget firstTab;
    switch (controller.currentFormView) {
      case FormView.selection:
        firstTab = const SelectFormScreen();
        break;
      case FormView.farmerKYC:
        firstTab = const FarmerKYCScreen();
        break;
      case FormView.billing:
        firstTab = const BillingScreen();
        break;
      case FormView.stockTransfer:
        firstTab = const StockTransferScreen();
        break;
      case FormView.bagSummary:
        firstTab = const BagSummaryScreen();
        break;
    }

    final List<Widget> screens = [
      firstTab,
      const ReportsHubScreen(),
      const ProfileScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Not on the first (Home/Form) tab -> go back to Home tab.
        if (controller.currentIndex != 0) {
          controller.setIndex(0);
          return;
        }

        // On the Home tab but inside a form sub-view (e.g. KYC, Billing,
        // Stock Transfer, Bag Summary) -> return to Monthly Billing Trend
        // home (the form selection screen).
        if (controller.currentFormView != FormView.selection) {
          controller.updateFormView(FormView.selection);
          return;
        }

        // Already on the Monthly Billing Trend home -> show exit confirmation.
        _confirmExit(context);
      },
      child: Scaffold(
        backgroundColor: lightGreenColor,
        body: PageView(
          controller: controller.pageController,
          onPageChanged: (index) {
            controller.onPageChanged(index);
          },
          physics:
              const NeverScrollableScrollPhysics(), // Generally better for bottom navs
          children: screens,
        ),
        bottomNavigationBar: Container(
          height: 70.h,
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
            boxShadow: [
              BoxShadow(
                color: blackColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.list_alt, "Form", controller),
              _buildNavItem(1, Icons.bar_chart, "Reports", controller),
              _buildNavItem(2, Icons.person, "Profile", controller),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text(
          'Exit App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: FontFamily.jost,
          ),
        ),
        content: const Text(
          'Are you sure you want to exit the app?',
          style: TextStyle(fontFamily: FontFamily.jost),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: FontFamily.jost)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Exit', style: TextStyle(fontFamily: FontFamily.jost)),
          ),
        ],
      ),
    );

    if (shouldExit == true && context.mounted) {
      SystemNavigator.pop();
    }
  }

  Widget _buildNavItem(int index, IconData icon, String label,
      BottomNavBarController controller) {
    bool isSelected = controller.currentIndex == index;
    return GestureDetector(
      onTap: () => controller.setIndex(index),
      child: AnimatedContainer(
        curve: Curves.easeInOut,
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
        decoration: isSelected
            ? BoxDecoration(
                color: primeryColor,
                borderRadius: BorderRadius.circular(25.r),
              )
            : null,
        child: Row(
          children: [
            Icon(
              index == 2
                  ? Icons.account_circle
                  : icon, // Using account_circle for profile
              color: isSelected ? whiteColor : blackColor,
              size: 26.sp,
            ),
            if (isSelected) ...[
              SizedBox(width: 4.w),
              Text(
                label,
                style: TextStyle(
                  color: whiteColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                  fontFamily: FontFamily.jost,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
