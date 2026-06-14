import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:soya_app/core/widgets/header_widget.dart';
import 'package:soya_app/core/widgets/logout_dialog.dart';
import 'package:soya_app/features/bottom_navigation_bar/controller/bottom_navbar_controller.dart';
import 'package:soya_app/features/login_and_signup/controller/login_controller.dart';
import 'package:soya_app/routes/app_routes.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';

import 'package:soya_app/features/home/controller/billing_controller.dart';
import 'package:soya_app/core/services/location_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _liveLocation;
  bool _isLocationLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLiveLocation();
    // Fetch live vendor rate from the same API used in Billing screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillingController>().fetchTodaysRates();
    });
  }

  Future<void> _fetchLiveLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    final location = await LocationService.getCurrentLocationAddress();

    if (mounted) {
      setState(() {
        _liveLocation = location;
        _isLocationLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: lightGreenColor,
          body: SafeArea(
            child: Column(
              children: [
                const HeaderWidget(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      children: [
                        SizedBox(height: 30.h),

                        // Profile Image
                        _buildProfileImage(controller.userName),
                        SizedBox(height: 16.h),

                        // Name
                        Text(
                          controller.userName ?? 'User Name',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            color: blackColor,
                            fontFamily: FontFamily.jost,
                          ),
                        ),
                        if (controller.masterVendor == true) ...[
                          SizedBox(height: 8.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: const Color(0xFFFFC107).withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified,
                                    size: 16.sp,
                                    color: const Color(0xFFFFB300)),
                                SizedBox(width: 6.w),
                                Text(
                                  'Master Vendor',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFF57F17),
                                    fontFamily: FontFamily.jost,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: 8.h),

                        // Contact Info
                        Text(
                          controller.userEmail ?? 'No Email',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.blue,
                            fontFamily: FontFamily.jost,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          controller.userPhone ?? 'No Phone',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: greyColor,
                            fontFamily: FontFamily.jost,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        // Location Info
                        if (controller.villageAdd != null ||
                            controller.taluka != null ||
                            controller.district != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 14.sp, color: greyColor),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(
                                  [
                                    if (controller.villageAdd != null &&
                                        controller.villageAdd!.isNotEmpty)
                                      controller.villageAdd,
                                    if (controller.taluka != null &&
                                        controller.taluka!.isNotEmpty)
                                      controller.taluka,
                                    if (controller.district != null &&
                                        controller.district!.isNotEmpty)
                                      controller.district,
                                  ].join(', '),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: greyColor,
                                    fontFamily: FontFamily.jost,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                        Consumer<BillingController>(
                          builder: (context, billingController, child) {
                            if (billingController.vendorRate > 0) {
                              return Column(
                                children: [
                                  SizedBox(height: 20.h),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16.w, vertical: 12.h),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                          0xFFE3F2FD), // Billing theme blue
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                          color: const Color(0xFF2196F3)
                                              .withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.trending_up,
                                            size: 18.sp,
                                            color: const Color(0xFF2196F3)),
                                        SizedBox(width: 8.w),
                                        Text(
                                          'Current Rate: ',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                            color: greyColor,
                                            fontFamily: FontFamily.jost,
                                          ),
                                        ),
                                        Text(
                                          '₹${billingController.vendorRate}',
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                            color: blackColor,
                                            fontFamily: FontFamily.jost,
                                          ),
                                        ),
                                        Text(
                                          ' per Quintal',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: greyColor,
                                            fontFamily: FontFamily.jost,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        SizedBox(height: 12.h),

                        // Live Location Info
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: whiteColor,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.gps_fixed,
                                          size: 16.sp, color: primeryColor),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Live Location',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: blackColor,
                                          fontFamily: FontFamily.jost,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_isLocationLoading)
                                    SizedBox(
                                      width: 12.w,
                                      height: 12.w,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                primeryColor),
                                      ),
                                    )
                                  else
                                    GestureDetector(
                                      onTap: _fetchLiveLocation,
                                      child: Icon(Icons.refresh,
                                          size: 16.sp, color: primeryColor),
                                    ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                _liveLocation ?? 'Fetching location...',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: greyColor,
                                  fontFamily: FontFamily.jost,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 30.h),

                        // Menu Items
                        _buildMenuItem(
                          icon: Icons.receipt_long,
                          title: 'View Bills',
                          subtitle:
                              'See all soybean bills and transaction records.',
                          iconBgColor: const Color(0xFFE3F2FD),
                          iconColor: const Color(0xFF1E88E5),
                          onTap: () {
                            final controller =
                                context.read<BottomNavBarController>();
                            // controller.setReportsView(0); // Removed
                            controller.setIndex(1);
                          },
                        ),
                        SizedBox(height: 16.h),

                        _buildMenuItem(
                          icon: Icons.credit_card,
                          title: 'Payment Details',
                          subtitle:
                              'Check paid, pending amounts and payment history.',
                          iconBgColor: const Color(0xFFFFF3E0),
                          iconColor: const Color(0xFFFB8C00),
                          onTap: () {
                            final controller =
                                context.read<BottomNavBarController>();
                            // controller.setReportsView(1); // Removed
                            controller.setIndex(1);
                          },
                        ),
                        SizedBox(height: 16.h),

                        _buildMenuItem(
                          icon: Icons.description,
                          title: 'Official Documents',
                          subtitle:
                              'View and manage KYC and other required documents.',
                          iconBgColor: const Color(0xFFF3E5F5),
                          iconColor: const Color(0xFF8E24AA),
                          onTap: () {
                            final controller =
                                context.read<BottomNavBarController>();
                            controller.updateFormView(FormView.selection);
                          },
                        ),
                        SizedBox(height: 16.h),

                        _buildMenuItem(
                          icon: Icons.inventory_2_outlined,
                          title: 'Bag Summary',
                          subtitle: 'View your current bag stock and history.',
                          iconBgColor: const Color(0xFFE8F5E9),
                          iconColor: const Color(0xFF2E7D32),
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.bagSummary);
                          },
                        ),
                        SizedBox(height: 16.h),

                        // Logout Button
                        _buildMenuItem(
                          icon: Icons.logout,
                          title: 'Logout',
                          subtitle: 'Sign out of your account.',
                          iconBgColor: const Color(0xFFFFEBEE),
                          iconColor: const Color(0xFFD32F2F),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => LogoutDialog(
                                onLogout: () => controller.logout(context),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 30.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              )
            ]),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: blackColor,
                      fontFamily: FontFamily.jost,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: greyColor,
                      fontFamily: FontFamily.jost,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(String? name) {
    final initials = _getInitials(name ?? 'Vendor');

    return Container(
      width: 120.w,
      height: 120.w,
      decoration: BoxDecoration(
        color: appColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: appColor.withOpacity(0.2), width: 2.w),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 40.sp,
          fontWeight: FontWeight.bold,
          color: appColor,
          fontFamily: FontFamily.georgia,
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
