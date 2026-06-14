import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:soya_app/features/bottom_navigation_bar/controller/bottom_navbar_controller.dart';
import 'package:soya_app/features/login_and_signup/controller/login_controller.dart';
import 'package:soya_app/routes/app_routes.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';

import 'package:soya_app/features/home/view/widgets/add_opening_bag_dialog.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginController>(
      builder: (context, controller, child) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r)),
            boxShadow: [
              BoxShadow(
                color: blackColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildProfileImage(controller.userName),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Welcome,',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: greyColor,
                        fontFamily: FontFamily.jost,
                      ),
                    ),
                    Text(
                      controller.userName ?? 'Vendor Name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        color: blackColor,
                        fontFamily: FontFamily.jost,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.menu, color: blackColor, size: 24.sp),
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.r),
                ),
                onSelected: (value) {
                  final navProvider = Provider.of<BottomNavBarController>(
                      context,
                      listen: false);

                  // Pop existing sub-screens if we are above the BottomNavBar
                  // Only pop if NOT selecting opening_bag (which shows a dialog)
                  if (value != 'opening_bag' && Navigator.canPop(context)) {
                    Navigator.popUntil(
                        context,
                        (route) =>
                            route.settings.name == AppRoutes.bottomNavBar ||
                            route.isFirst);
                  }

                  switch (value) {
                    case 'opening_bag':
                      _showAddOpeningBagDialog(context);
                      break;
                    case 'kyc':
                      navProvider.updateFormView(FormView.farmerKYC);
                      break;
                    case 'billing':
                      navProvider.updateFormView(FormView.billing);
                      break;
                    case 'transfer':
                      navProvider.updateFormView(FormView.stockTransfer);
                      break;
                    case 'reports':
                      navProvider.setIndex(1);
                      break;
                    case 'profile':
                      navProvider.setIndex(2);
                      break;
                    case 'logout':
                      _showLogoutDialog(context, controller);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  _buildMenuItem('opening_bag', Icons.shopping_bag_outlined,
                      'Add Opening Bag'),
                  _buildMenuItem(
                      'kyc', Icons.person_add_alt_1_outlined, 'Farmer KYC'),
                  _buildMenuItem(
                      'billing', Icons.receipt_long_outlined, 'Farmer Billing'),
                  _buildMenuItem('transfer', Icons.local_shipping_outlined,
                      'Stock Transfer'),
                  _buildMenuItem(
                      'reports', Icons.bar_chart_outlined, 'Reports'),
                  _buildMenuItem('profile', Icons.person_outline, 'Profile'),
                  const PopupMenuDivider(),
                  _buildMenuItem('logout', Icons.logout, 'Logout',
                      isDestructive: true),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddOpeningBagDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddOpeningBagDialog(),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
      String value, IconData icon, String title,
      {bool isDestructive = false}) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 20.sp, color: isDestructive ? redColor : primeryColor),
          SizedBox(width: 12.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDestructive ? redColor : blackColor,
              fontFamily: FontFamily.jost,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, LoginController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontFamily: FontFamily.jost,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontFamily: FontFamily.jost),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: greyColor, fontFamily: FontFamily.jost),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.logout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: redColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              'Logout',
              style: TextStyle(color: whiteColor, fontFamily: FontFamily.jost),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String? name) {
    final initials = _getInitials(name ?? 'Vendor');

    return Container(
      width: 45.w,
      height: 45.w,
      decoration: BoxDecoration(
        color: appColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: appColor.withOpacity(0.2)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: appColor,
          fontFamily: FontFamily.jost,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
