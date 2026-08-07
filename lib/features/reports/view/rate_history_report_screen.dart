import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:soya_app/core/widgets/header_widget.dart';
import 'package:soya_app/features/home/controller/billing_controller.dart';
import 'package:soya_app/features/home/model/quality_rate_model.dart';
import 'package:soya_app/features/reports/view/widgets/pagination_widget.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';
import 'package:intl/intl.dart';
import 'package:soya_app/core/widgets/empty_state_widget.dart';
import 'package:soya_app/features/reports/view/widgets/report_generation_date.dart';

class RateHistoryReportScreen extends StatefulWidget {
  const RateHistoryReportScreen({super.key});

  @override
  State<RateHistoryReportScreen> createState() => _RateHistoryReportScreenState();
}

class _RateHistoryReportScreenState extends State<RateHistoryReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<BillingController>();
      controller.fetchRateHistory(page: 1);
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final controller = context.read<BillingController>();
    final initialRange = DateTimeRange(
      start: controller.rateHistoryStartDate ?? DateTime.now().subtract(const Duration(days: 30)),
      end: controller.rateHistoryEndDate ?? DateTime.now(),
    );

    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primeryColor,
              onPrimary: whiteColor,
              surface: whiteColor,
              onSurface: blackColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      controller.setRateHistoryFilters(
        startDate: pickedRange.start,
        endDate: pickedRange.end,
      );
    }
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
            _buildFilterBar(),
            Consumer<BillingController>(
              builder: (context, controller, child) {
                if (controller.rateHistory.isEmpty) return const SizedBox.shrink();

                final total = controller.rateHistoryTotalItems;
                final itemsCount = controller.rateHistory.length;
                final start = total == 0 ? 0 : ((controller.rateHistoryPage - 1) * 10) + 1;
                final end = (start + itemsCount - 1).clamp(0, total);
                final displayStart = start.clamp(0, total);

                return _buildResultsSummary(
                  total: total,
                  start: displayStart,
                  end: end,
                );
              },
            ),
            Expanded(
              child: Consumer<BillingController>(
                builder: (context, controller, child) {
                  final history = controller.rateHistory;

                  if (history.isEmpty && !controller.isLoading) {
                    return _buildEmptyState();
                  }

                  return Column(
                    children: [
                      if (controller.isLoading)
                        LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(appColor),
                        ),
                      if (history.isNotEmpty)
                        Expanded(child: _buildReportTable(history))
                      else if (controller.isLoading)
                        const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        const SizedBox.shrink(),
                      if (history.isNotEmpty)
                        PaginationWidget(
                          currentPage: controller.rateHistoryPage,
                          totalPages: controller.rateHistoryTotalPages,
                          onPageChanged: (page) => controller.fetchRateHistory(page: page),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
                "Rate History",
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

  Widget _buildFilterBar() {
    return Consumer<BillingController>(
      builder: (context, controller, child) {
        final start = controller.rateHistoryStartDate ?? DateTime.now().subtract(const Duration(days: 30));
        final end = controller.rateHistoryEndDate ?? DateTime.now();
        final dateStr = "${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}";
        final hasFilters = controller.rateHistoryStartDate != null || controller.rateHistoryEndDate != null;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDateRange(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: appColor, size: 18.sp),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: blackColor,
                              fontWeight: FontWeight.w500,
                              fontFamily: FontFamily.jost,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: greyColor),
                      ],
                    ),
                  ),
                ),
              ),
              if (hasFilters) ...[
                SizedBox(width: 12.w),
                GestureDetector(
                  onTap: () => controller.clearRateHistoryFilters(),
                  child: Container(
                    padding: EdgeInsets.all(12.w),
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
                    child: Icon(Icons.clear_all, color: Colors.red.shade400, size: 24.sp),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultsSummary({
    required int total,
    required int start,
    required int end,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: appColor.withOpacity(0.1)),
            ),
            child: Text(
              "Showing $start-$end of $total rates",
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: appColor,
                fontFamily: FontFamily.jost,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.history_toggle_off_outlined,
      title: "No Rate History Found",
      description: "We couldn't find any historical rate records within the selected date range.",
    );
  }

  Widget _buildReportTable(List<QualityRateData> history) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        margin: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: blackColor.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 60.w,
              headingRowHeight: 60.h,
              dataRowMinHeight: 60.h,
              dataRowMaxHeight: 60.h,
              headingRowColor: WidgetStateProperty.all(appColor.withOpacity(0.1)),
              border: TableBorder(
                horizontalInside: BorderSide(color: lightGreenColor, width: 1.h),
              ),
              columns: [
                _buildColumn("Date"),
                _buildColumn("Standard Rate (₹)"),
              ],
              rows: history.map((item) {
                // Parse date from 'date' field or 'createdAt' fallback
                String displayDate = item.date ?? "";
                if (displayDate.isNotEmpty) {
                  displayDate = formatReportDate(displayDate);
                }
                if (displayDate.isEmpty || displayDate == "N/A") {
                  displayDate =
                      item.createdAt != null ? formatReportDate(item.createdAt) : "";
                }
                if (displayDate.isEmpty) {
                  displayDate = "N/A";
                }

                final rateStr = item.rate != null ? "₹ ${item.rate}" : "N/A";

                return DataRow(
                  cells: [
                    DataCell(Text(displayDate, style: _cellStyle())),
                    DataCell(
                      Text(
                        rateStr,
                        style: _cellStyle(color: primeryColor, isBold: true),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataColumn _buildColumn(String label) {
    return DataColumn(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          fontFamily: FontFamily.jost,
          color: appColor,
        ),
      ),
    );
  }

  TextStyle _cellStyle({bool isBold = false, Color? color}) => TextStyle(
        fontSize: 14.sp,
        color: color ?? blackColor,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        fontFamily: FontFamily.jost,
      );
}
