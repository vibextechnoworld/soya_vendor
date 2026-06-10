import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soya_app/features/home/controller/stock_controller.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';

class BagSummaryContentView extends StatefulWidget {
  final StockController controller;

  const BagSummaryContentView({super.key, required this.controller});

  @override
  State<BagSummaryContentView> createState() => _BagSummaryContentViewState();
}

class _BagSummaryContentViewState extends State<BagSummaryContentView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10.h),
          _buildBagSummaryTotals(widget.controller),
          SizedBox(height: 24.h),
          _buildBagSummaryByType(widget.controller),
          SizedBox(height: 24.h),

          // Detail Tabs Label
          Text('Detailed Transactions',
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: FontFamily.jost,
                  color: blackColor)),
          SizedBox(height: 12.h),

          // Custom Tab-like selector for details
          Container(
            padding: EdgeInsets.all(4.r),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabController.index = 0),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      decoration: BoxDecoration(
                        color: _tabController.index == 0
                            ? whiteColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: _tabController.index == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      child: Text(
                        'Received',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: _tabController.index == 0
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _tabController.index == 0
                              ? primeryColor
                              : greyColor,
                          fontFamily: FontFamily.jost,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabController.index = 1),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      decoration: BoxDecoration(
                        color: _tabController.index == 1
                            ? whiteColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: _tabController.index == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      child: Text(
                        'Returned',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: _tabController.index == 1
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _tabController.index == 1
                              ? primeryColor
                              : greyColor,
                          fontFamily: FontFamily.jost,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Detail Content based on selected index
          _tabController.index == 0
              ? _buildReceivedFromAdmin(widget.controller)
              : _buildReturnedToFarmers(widget.controller),

          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _buildBagSummaryTotals(StockController controller) {
    final totals = controller.bagSummary?.data?.totals;
    if (totals == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bag Stock Overview',
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: FontFamily.jost,
                  color: blackColor)),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildSummaryBox(
                  'Available\nBags',
                  '${totals.currentWithVendor ?? 0}',
                  Colors.green,
                  Icons.inventory_2_outlined,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _buildSummaryBox(
                  'Received\nFrom Farmers',
                  '${totals.receivedFromFarmers ?? 0}',
                  primeryColor,
                  Icons.groups_outlined,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildSummaryBox(
                  'Received\nFrom Admin',
                  '${totals.receivedFromAdmin ?? 0}',
                  Colors.purple,
                  Icons.admin_panel_settings_outlined,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildSummaryBox(
                  'Opening\nStock (Self)',
                  '${totals.receivedFromVendorSelf ?? 0}',
                  Colors.blue,
                  Icons.home_outlined,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _buildSummaryBox(
                  'Bags\n by Admin',
                  '${totals.receivedAdminAdd ?? 0}',
                  Colors.teal,
                  Icons.add_moderator_outlined,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildSummaryBox(
                  'Bags Sent\nto Admin',
                  '${totals.sentToAdmin ?? 0}',
                  Colors.orange,
                  Icons.local_shipping_outlined,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildSummaryBox(
                  'Bags Returned\nto Farmers',
                  '${totals.returnedToFarmers ?? 0}',
                  Colors.red,
                  Icons.assignment_return_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 8.h),
          Text(value,
              style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: FontFamily.jost)),
          SizedBox(height: 4.h),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10.sp,
                  color: greyColor,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  fontFamily: FontFamily.jost)),
        ],
      ),
    );
  }

  Widget _buildBagSummaryByType(StockController controller) {
    final byType = controller.bagSummary?.data?.byType;
    if (byType == null || byType.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Breakdown by Bag Type',
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                fontFamily: FontFamily.jost,
                color: blackColor)),
        SizedBox(height: 12.h),
        ...byType.map((type) => Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.goniTypeName ?? 'Unknown Type',
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: blackColor,
                          fontFamily: FontFamily.jost)),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat(
                          'Rx from Farmer', '${type.receivedFromFarmers}',
                          color: primeryColor),
                      _buildMiniStat(
                          'Rx from Admin', '${type.receivedFromAdmin}',
                          color: Colors.purple),
                      _buildMiniStat('Current', '${type.currentWithVendor}',
                          color: Colors.green),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat('Ret. Farmer', '${type.returnedToFarmers}',
                          color: Colors.red),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat(
                          'Opening', '${type.receivedFromVendorSelf}',
                          color: Colors.blue),
                      _buildMiniStat('Admin Add', '${type.receivedAdminAdd}',
                          color: Colors.teal),
                      _buildMiniStat('Sent Admin', '${type.sentToAdmin}',
                          color: Colors.orange),
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10.sp,
                color: greyColor,
                fontFamily: FontFamily.jost)),
        Text(value,
            style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: color ?? blackColor,
                fontFamily: FontFamily.jost)),
      ],
    );
  }

  Widget _buildReceivedFromAdmin(StockController controller) {
    final received = controller.bagSummary?.data?.receivedFromAdminByAdmin;
    if (received == null || received.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.admin_panel_settings_outlined,
                color: Colors.purple, size: 20.sp),
            SizedBox(width: 8.w),
            Text('Received from Admin Details',
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: FontFamily.jost,
                    color: blackColor)),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: received.length,
            separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey.withOpacity(0.1),
                indent: 16,
                endIndent: 16),
            itemBuilder: (context, index) {
              final item = received[index];

              // Find the bag type name from the byType list
              String bagName = 'Unknown Bag Type';
              final byTypeInfo = controller.bagSummary?.data?.byType;
              if (byTypeInfo != null) {
                try {
                  final matchedType = byTypeInfo
                      .firstWhere((type) => type.goniTypeId == item.goniTypeId);
                  if (matchedType.goniTypeName != null &&
                      matchedType.goniTypeName!.isNotEmpty) {
                    bagName = matchedType.goniTypeName!;
                  }
                } catch (e) {
                  // No match found
                }
              }

              return ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.inventory_2_outlined,
                      color: Colors.purple, size: 16.sp),
                ),
                title: Text(bagName,
                    style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: FontFamily.jost)),
                subtitle: Text('ID: ${item.goniTypeId ?? 'N/A'}',
                    style: TextStyle(
                        fontSize: 10.sp,
                        color: greyColor,
                        fontFamily: FontFamily.jost)),
                trailing: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text('${item.bagCount} Bags',
                      style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                          fontFamily: FontFamily.jost)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReturnedToFarmers(StockController controller) {
    final returned = controller.bagSummary?.data?.returnedToFarmersByFarmer;
    if (returned == null || returned.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Returned to Farmers (Detailed)',
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                fontFamily: FontFamily.jost,
                color: blackColor)),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: returned.length,
            separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey.withOpacity(0.1),
                indent: 16,
                endIndent: 16),
            itemBuilder: (context, index) {
              final item = returned[index];
              return ListTile(
                title: Text(item.farmer?.name ?? 'Unknown Farmer',
                    style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: FontFamily.jost)),
                subtitle: Text(item.farmer?.phone ?? '',
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: greyColor,
                        fontFamily: FontFamily.jost)),
                trailing: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text('${item.bagCount} Bags',
                      style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontFamily: FontFamily.jost)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
