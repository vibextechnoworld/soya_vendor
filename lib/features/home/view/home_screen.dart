import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:soya_app/features/home/controller/stock_controller.dart';
import 'package:soya_app/routes/app_routes.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';

class HomeScreen extends StatefulWidget {
  final bool isFarmerKYC;
  final bool isBilling;
  final bool isStockTransfer;

  const HomeScreen({
    super.key,
    this.isFarmerKYC = false,
    this.isBilling = false,
    this.isStockTransfer = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockController>().fetchVendorStockSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreenColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    _buildDashboardButton(
                      context,
                      title: 'Farmer KYC',
                      isPrimary: false,
                      icon: Icons.person_add_alt_1_outlined,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.farmerKyc);
                      },
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDashboardButton(
                            context,
                            title: 'Billing',
                            isPrimary: true,
                            icon: Icons.receipt_long_outlined,
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.billing);
                            },
                            isSmall: true,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _buildDashboardButton(
                            context,
                            title: 'Bag Inventory',
                            isPrimary: false,
                            icon: Icons.inventory_2_outlined,
                            onTap: () {
                              Navigator.pushNamed(
                                  context, AppRoutes.bagSummary);
                            },
                            isSmall: true,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    _buildDashboardButton(
                      context,
                      title: 'Stock transfer',
                      isPrimary: false,
                      icon: Icons.local_shipping_outlined,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.stockTransfer);
                      },
                    ),
                    SizedBox(height: 30.h),
                    _buildStockBreakdownSection(),
                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<StockController>(
      builder: (context, controller, child) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24.w, 40.h, 24.w, 30.h),
          decoration: BoxDecoration(
            color: primeryColor,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32.r),
              bottomRight: Radius.circular(32.r),
            ),
            boxShadow: [
              BoxShadow(
                color: primeryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back!',
                        style: TextStyle(
                          color: whiteColor.withOpacity(0.8),
                          fontSize: 14.sp,
                          fontFamily: FontFamily.jost,
                        ),
                      ),
                      Text(
                        'Vendor Dashboard',
                        style: TextStyle(
                          color: whiteColor,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: FontFamily.jost,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: whiteColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_outlined,
                        color: whiteColor, size: 24.sp),
                  ),
                ],
              ),
              SizedBox(height: 30.h),
              _buildSummaryCard(
                'Total Available Stock',
                '${controller.totalAvailableWeight.toStringAsFixed(2)} QTL',
                '${controller.totalAvailableBags} Bags',
                Icons.inventory_2_outlined,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
      String title, String weight, String bags, IconData icon) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: primeryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primeryColor, size: 28.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: greyColor,
                    fontSize: 12.sp,
                    fontFamily: FontFamily.jost,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  weight,
                  style: TextStyle(
                    color: blackColor,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: FontFamily.jost,
                  ),
                ),
                Text(
                  bags,
                  style: TextStyle(
                    color: primeryColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: FontFamily.jost,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockBreakdownSection() {
    return Consumer<StockController>(
      builder: (context, controller, child) {
        final summary = controller.stockSummary?.data?.summary;
        if (summary == null || summary.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock Breakdown',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                fontFamily: FontFamily.jost,
                color: blackColor,
              ),
            ),
            SizedBox(height: 16.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: 1.5,
              ),
              itemCount: summary.length,
              itemBuilder: (context, index) {
                final item = summary[index];
                return _buildBreakdownCard(
                  item.status ?? 'Unknown',
                  '${item.sSum?.weight ?? 0} QTL',
                  '${item.sSum?.bagCount ?? 0} Bags',
                  _getStatusColor(item.status ?? ''),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBreakdownCard(
      String status, String weight, String bags, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 8.w,
                height: 8.h,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: greyColor,
                    fontFamily: FontFamily.jost,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            weight,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: blackColor,
              fontFamily: FontFamily.jost,
            ),
          ),
          Text(
            bags,
            style: TextStyle(
              fontSize: 11.sp,
              color: color,
              fontWeight: FontWeight.w600,
              fontFamily: FontFamily.jost,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'COMPLETED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildDashboardButton(
    BuildContext context, {
    required String title,
    required bool isPrimary,
    required IconData icon,
    required VoidCallback onTap,
    bool isSmall = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: isSmall ? 56.h : 64.h,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? primeryColor.withOpacity(0.2)
                  : blackColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary ? primeryColor : whiteColor,
            foregroundColor: isPrimary ? whiteColor : blackColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: isPrimary
                  ? BorderSide.none
                  : BorderSide(color: Colors.grey.shade200),
            ),
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 12.w : 20.w),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: isSmall ? 20.sp : 24.sp,
                  color: isPrimary ? whiteColor : primeryColor),
              SizedBox(width: isSmall ? 8.w : 16.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmall ? 14.sp : 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: FontFamily.jost,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isSmall) ...[
                const Spacer(),
                Icon(Icons.arrow_forward_ios,
                    size: 16.sp,
                    color:
                        (isPrimary ? whiteColor : greyColor).withOpacity(0.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 150);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 150,
      size.width,
      size.height - 150,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
