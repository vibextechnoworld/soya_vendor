import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:soya_app/core/widgets/header_widget.dart';
import 'package:soya_app/features/bottom_navigation_bar/controller/bottom_navbar_controller.dart';
import 'package:soya_app/features/home/controller/billing_controller.dart';
import 'package:soya_app/routes/app_routes.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';
import 'package:fl_chart/fl_chart.dart';

class SelectFormScreen extends StatefulWidget {
  const SelectFormScreen({super.key});

  @override
  State<SelectFormScreen> createState() => _SelectFormScreenState();
}

class _SelectFormScreenState extends State<SelectFormScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillingController>().fetchBillGraph();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<BottomNavBarController>();
    return Scaffold(
      backgroundColor: lightGreenColor,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header Image
                    Container(
                      //height: 460.h,
                      child: Image.asset(
                        'assets/farm_header.png',
                        width: double.infinity,
                        height: 360.h,
                        fit: BoxFit.fill,
                      ),
                    ),
                    // const SizedBox(
                    //   height: 50,
                    // ),

                    //last six mont graph
                    SizedBox(height: 20.h),
                    _buildBillGraphSection(),
                    SizedBox(height: 25.h),

                    // Selection Buttons
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18.w),
                      child: Column(
                        children: [
                          // _buildDashboardButton(
                          //   context,
                          //   title: 'Farmer KYC',
                          //   isPrimary: false,
                          //   onTap: () {
                          //     controller.updateFormView(FormView.farmerKYC);
                          //   },
                          // ),
                          // SizedBox(height: 20.h),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDashboardButton(
                                  context,
                                  title: 'Billing',
                                  isPrimary: true,
                                  onTap: () {
                                    Navigator.pushNamed(
                                        context, AppRoutes.billing);
                                  },
                                  isSmall: true,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: _buildDashboardButton(
                                  context,
                                  title: 'Bag Summary',
                                  isPrimary: false,
                                  onTap: () {
                                    controller
                                        .updateFormView(FormView.bagSummary);
                                  },
                                  isSmall: true,
                                ),
                              ),
                            ],
                          ),
                          // SizedBox(height: 20.h),
                          // _buildDashboardButton(
                          //   context,
                          //   title: 'Stock transfer',
                          //   isPrimary: false,
                          //   onTap: () {
                          //     controller.updateFormView(FormView.stockTransfer);
                          //   },
                          // ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillGraphSection() {
    return Consumer<BillingController>(
      builder: (context, controller, child) {
        final graphData = controller.billGraphData?.data?.data;
        if (controller.isLoading && (graphData == null || graphData.isEmpty)) {
          return Container(
            height: 150.h,
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 18.w),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (graphData == null || graphData.isEmpty) {
          return Container(
            height: 150.h,
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            margin: EdgeInsets.symmetric(horizontal: 18.w),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Center(
              child: Text(
                "No billing data available for the last 6 months",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: greyColor,
                  fontSize: 14.sp,
                  fontFamily: FontFamily.jost,
                ),
              ),
            ),
          );
        }

        double maxAmount =
            graphData.map((e) => e.amount ?? 0).reduce((a, b) => a > b ? a : b);
        if (maxAmount == 0) maxAmount = 100;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Billing Trend',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: FontFamily.jost,
                  color: blackColor,
                ),
              ),
              SizedBox(height: 10.h),
              Container(
                height: 140.h,
                padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 16.h),
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
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxAmount * 1.2,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => greyColor.withOpacity(0.8),
                        tooltipRoundedRadius: 8,
                        tooltipPadding: EdgeInsets.all(8.r),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${graphData[groupIndex].month}\n',
                            TextStyle(
                                color: whiteColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                                fontFamily: FontFamily.jost),
                            children: [
                              // TextSpan(
                              //   text:
                              //       'Amount: ₹ ${rod.toY.toStringAsFixed(2)}\n',
                              //   style: TextStyle(
                              //       color: Colors.yellow,
                              //       fontSize: 12.sp,
                              //       fontWeight: FontWeight.normal,
                              //       fontFamily: FontFamily.jost),
                              // ),
                              TextSpan(
                                text:
                                    'Quantity: ${graphData[groupIndex].quantity ?? 0} qtl',
                                style: TextStyle(
                                    color: whiteColor.withOpacity(0.9),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.normal,
                                    fontFamily: FontFamily.jost),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= graphData.length) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              meta: meta,
                              space: 8.h,
                              child: Text(
                                graphData[index].month?.split(' ').first ?? '',
                                style: TextStyle(
                                    color: greyColor,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: FontFamily.jost),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: graphData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: item.amount ?? 0,
                            color: primeryColor,
                            width: 14.w,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(6.r),
                              topRight: Radius.circular(6.r),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxAmount * 1.2,
                              color: primeryColor.withOpacity(0.05),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.elasticOut,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardButton(
    BuildContext context, {
    required String title,
    required bool isPrimary,
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
                  : BorderSide(
                      color: isPrimary ? Colors.transparent : Colors.grey[200]!,
                    ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isSmall ? 15.sp : 18.sp,
                fontWeight: FontWeight.bold,
                fontFamily: FontFamily.jost,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
