import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soya_app/core/widgets/header_widget.dart';
import 'package:soya_app/features/home/model/vendor_transfer_list_model.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';

import 'package:provider/provider.dart';
import 'package:soya_app/features/home/controller/stock_controller.dart';
import 'package:soya_app/features/home/model/vendor_stock_summary_model.dart';
import 'package:soya_app/features/reports/view/widgets/pagination_widget.dart';
import 'package:soya_app/core/widgets/empty_state_widget.dart';
import 'package:soya_app/features/reports/view/widgets/report_generation_date.dart';

class StockReportScreen extends StatefulWidget {
  const StockReportScreen({super.key});

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = "";
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<StockController>();
      controller.fetchVendorStockSummary();
      controller.getVendorTransfers();
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
            _buildCustomAppBar(context),
            _buildTabBar(),
            _buildSearchBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStockList(),
                  _buildTransferList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(25.r),
        boxShadow: [
          BoxShadow(
            color: blackColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25.r),
          color: primeryColor,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: whiteColor,
        unselectedLabelColor: greyColor,
        labelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          fontFamily: FontFamily.jost,
        ),
        tabs: const [
          Tab(text: "Stock Summary"),
          Tab(text: "Transfer History"),
        ],
      ),
    );
  }

  Widget _buildStockList() {
    return Consumer<StockController>(
      builder: (context, controller, child) {
        final summaryData = controller.stockSummary?.data;

        if (summaryData == null && !controller.isLoading) {
          return EmptyStateWidget(
            icon: Icons.inventory_2_outlined,
            title: "No Data Available",
            description: "No stock summary available at the moment.",
            actionLabel: "Refresh",
            onAction: () => controller.fetchVendorStockSummary(),
          );
        }

        return Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (summaryData != null) ...[
                    _buildTotalStockCard(summaryData.totalAvailable),
                    SizedBox(height: 20.h),
                    if (summaryData.summary != null) ...[
                      Text(
                        "Stock Breakdown",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: FontFamily.jost,
                          color: blackColor,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      ...summaryData.summary!
                          .map((item) => _buildStockSummaryItem(item)),
                    ],
                  ],
                ],
              ),
            ),
            if (controller.isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(appColor),
                ),
              ),
            if (controller.isLoading && summaryData == null)
              const Center(child: CircularProgressIndicator()),
          ],
        );
      },
    );
  }

  Widget _buildTotalStockCard(TotalAvailable? total) {
    if (total == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primeryColor, primeryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: primeryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Available Stock",
                style: TextStyle(
                  fontSize: 16.sp,
                  color: whiteColor.withOpacity(0.9),
                  fontFamily: FontFamily.jost,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(Icons.inventory_2_outlined, color: whiteColor, size: 24.sp),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${total.weight ?? 0}",
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: whiteColor,
                        fontFamily: FontFamily.jost,
                      ),
                    ),
                    Text(
                      "Weight (KG)",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: whiteColor.withOpacity(0.8),
                        fontFamily: FontFamily.jost,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40.h,
                width: 1.w,
                color: whiteColor.withOpacity(0.3),
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${total.bagCount ?? 0}",
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: whiteColor,
                        fontFamily: FontFamily.jost,
                      ),
                    ),
                    Text(
                      "Total Bags",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: whiteColor.withOpacity(0.8),
                        fontFamily: FontFamily.jost,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockSummaryItem(SummaryItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: blackColor.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: appColor.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: _getStatusColor(item.status ?? "").withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.assignment_turned_in_outlined,
              color: _getStatusColor(item.status ?? ""),
              size: 20.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.status ?? "Unknown",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: FontFamily.jost,
                    color: blackColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "${item.sCount ?? 0} Categories",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: greyColor,
                    fontFamily: FontFamily.jost,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${item.sSum?.weight ?? 0} KG",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: primeryColor,
                  fontFamily: FontFamily.jost,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                "${item.sSum?.bagCount ?? 0} Bags",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: greyColor,
                  fontFamily: FontFamily.jost,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransferList() {
    return Consumer<StockController>(
      builder: (context, controller, child) {
        final filteredTransfers = controller.vendorTransfers.where((transfer) {
          final transferNo = transfer.transferNo?.toLowerCase() ?? "";
          return transferNo.contains(_searchQuery.toLowerCase());
        }).toList();

        if (filteredTransfers.isEmpty && !controller.isLoading) {
          return EmptyStateWidget(
            icon: Icons.history,
            title: "No Records Found",
            description: "No transfer records found for your search.",
            actionLabel: "Clear Search",
            onAction: () => setState(() => _searchQuery = ""),
          );
        }

        return Column(
          children: [
            if (controller.isLoading)
              LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(appColor),
              ),
            if (filteredTransfers.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Transfer Records",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: FontFamily.jost,
                        color: blackColor,
                      ),
                    ),
                    _buildPageDetails(controller),
                  ],
                ),
              ),
            if (filteredTransfers.isNotEmpty)
              Expanded(child: _buildTransferTable(filteredTransfers))
            else if (controller.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              const SizedBox.shrink(),
            if (filteredTransfers.isNotEmpty)
              PaginationWidget(
                currentPage: controller.currentPage,
                totalPages: controller.totalPages,
                onPageChanged: (page) =>
                    controller.getVendorTransfers(page: page),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 20.sp, color: blackColor),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Stock Report",
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: FontFamily.georgia,
                  color: blackColor,
                ),
              ),
              const ReportGenerationDate(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: blackColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: "Search...",
          hintStyle: TextStyle(color: greyColor, fontSize: 14.sp),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: appColor, size: 20.sp),
        ),
      ),
    );
  }

  Widget _buildPageDetails(StockController controller) {
    final start = (controller.currentPage - 1) * controller.pageSize + 1;
    final end = (controller.currentPage * controller.pageSize)
        .clamp(0, controller.totalItems);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: appColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        "Showing $start-$end of ${controller.totalItems}",
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: appColor,
          fontFamily: FontFamily.jost,
        ),
      ),
    );
  }


  Widget _buildTransferTable(List<VendorTransferData> transfers) {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      itemCount: transfers.length,
      separatorBuilder: (context, index) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        final transfer = transfers[index];
        return _buildTransferCard(transfer);
      },
    );
  }

  Widget _buildTransferCard(VendorTransferData transfer) {
    final status = transfer.status ?? "PENDING";
    final vendorWeight =
        "${transfer.vendorEnteredWeight ?? transfer.weight} ${transfer.vendorEnteredUnit ?? transfer.unit}";
    final adminWeight = transfer.adminAdjustedWeight != null
        ? "${transfer.adminAdjustedWeight} ${transfer.adminAdjustedUnit}"
        : "Pending";

    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: blackColor.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: appColor.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // Header: ID and Status
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: appColor.withOpacity(0.05),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 18.sp, color: appColor),
                    SizedBox(width: 8.w),
                    Text(
                      transfer.transferNo ?? "N/A",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: FontFamily.jost,
                        color: blackColor,
                      ),
                    ),
                  ],
                ),
                _buildStatusChip(status),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoDetail(
                        label: "Source",
                        value:
                            transfer.sourceLocation?.name ?? transfer.vendor?.name ?? "N/A",
                        icon: Icons.login_outlined,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoDetail(
                        label: "Destination",
                        value: transfer.destinationLocation?.name ?? transfer.toVendor?.name ?? "N/A",
                        icon: Icons.location_on_outlined,
                      ),
                    ),
                  ],
                ),
                Divider(height: 24.h, thickness: 0.5, color: Colors.grey[200]),

                // Quantity Breakdown
                Row(
                  children: [
                    Expanded(
                      child: _buildQuantitySection(
                        label: "Vendor Entered",
                        value: vendorWeight,
                        color: Colors.blue[700]!,
                      ),
                    ),
                    Container(
                      height: 40.h,
                      width: 1.w,
                      color: Colors.grey[200],
                      margin: EdgeInsets.symmetric(horizontal: 12.w),
                    ),
                    Expanded(
                      child: _buildQuantitySection(
                        label: "Admin Adjusted",
                        value: adminWeight,
                        color: Colors.orange[800]!,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Bag Details
                if (transfer.items != null && transfer.items!.isNotEmpty)
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 4.h,
                    children: transfer.items!.map((item) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: primeryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                              color: primeryColor.withOpacity(0.2),
                              width: 0.5),
                        ),
                        child: Text(
                          '${item.bagCount} x ${item.goniType?.name ?? 'Bags'}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: primeryColor,
                            fontFamily: FontFamily.jost,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: primeryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                          color: primeryColor.withOpacity(0.2), width: 0.5),
                    ),
                    child: Text(
                      '${transfer.bagCount} x ${transfer.goniType?.name ?? 'Bags'}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: primeryColor,
                        fontFamily: FontFamily.jost,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: color,
          fontFamily: FontFamily.jost,
        ),
      ),
    );
  }

  Widget _buildInfoDetail({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: greyColor),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: greyColor,
                  fontFamily: FontFamily.jost,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: blackColor,
                  fontFamily: FontFamily.jost,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySection({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9.sp,
            color: greyColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontFamily: FontFamily.jost,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: FontFamily.jost,
          ),
        ),
      ],
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
        return greyColor;
    }
  }
}
