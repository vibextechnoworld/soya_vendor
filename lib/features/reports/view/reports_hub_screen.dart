import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:soya_app/core/widgets/header_widget.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';
import 'package:soya_app/routes/app_routes.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:soya_app/features/home/controller/billing_controller.dart';

class ReportsHubScreen extends StatefulWidget {
  const ReportsHubScreen({super.key});

  @override
  State<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends State<ReportsHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillingController>().fetchBillGraph();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreenColor,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Analytics",
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: FontFamily.georgia,
                      color: blackColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: primeryColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                labelColor: whiteColor,
                unselectedLabelColor: greyColor,
                labelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: FontFamily.jost,
                ),
                tabs: const [
                  Tab(text: "Reports"),
                  Tab(text: "Statistics"),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReportsTab(context),
                  _buildStatisticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBillGraphSection(),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _buildReportsTab(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      children: [
        _buildReportCard(
          context,
          title: "All Farmers Data",
          subtitle: "View comprehensive farmer lists and KYC status",
          icon: Icons.people_outline,
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.farmersReport);
          },
        ),
        SizedBox(height: 16.h),
        _buildReportCard(
          context,
          title: "Billing Report",
          subtitle: "Detailed bills, payments, and settlements",
          icon: Icons.receipt_long_outlined,
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.billingReport);
          },
        ),
        SizedBox(height: 16.h),
        _buildReportCard(
          context,
          title: "Stock Transfer Data",
          subtitle: "Track inventory movements across locations",
          icon: Icons.inventory_2_outlined,
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.stockReport);
          },
        ),
        SizedBox(height: 16.h),
        _buildReportCard(
          context,
          title: "Rate History",
          subtitle: "View and track historical quality rates",
          icon: Icons.history_toggle_off_outlined,
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.rateHistoryReport);
          },
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildBillGraphSection() {
    return Consumer<BillingController>(
      builder: (context, controller, child) {
        final graphData = controller.billGraphData?.data?.data;
        if (controller.isLoading && (graphData == null || graphData.isEmpty)) {
          return Container(
            height: 250.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (graphData == null || graphData.isEmpty) {
          return Container(
            height: 250.h,
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
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

        return Column(
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
            SizedBox(height: 16.h),
            Container(
              height: 300.h,
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
                            //   text: 'Amount: ₹ ${rod.toY.toStringAsFixed(2)}\n',
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
                          width: 18.w,
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
        );
      },
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: blackColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
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
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: FontFamily.jost,
                      color: blackColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: greyColor,
                      fontFamily: FontFamily.jost,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: greyColor, size: 16.sp),
          ],
        ),
      ),
    );
  }
}
