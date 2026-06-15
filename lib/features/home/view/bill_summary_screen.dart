import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:soya_app/core/services/pdf_invoice_service.dart';
import 'package:soya_app/core/widgets/header_widget.dart';
import 'package:soya_app/core/widgets/tost_message.dart';
import 'package:soya_app/features/home/controller/billing_controller.dart';
import 'package:soya_app/features/home/model/bill_model.dart';
import 'package:soya_app/features/home/model/goni_type_model.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';
import 'package:soya_app/features/bottom_navigation_bar/controller/bottom_navbar_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:soya_app/core/services/image_picker_service.dart';
import 'package:dotted_border/dotted_border.dart';

class BillSummaryScreen extends StatefulWidget {
  final String billId;
  const BillSummaryScreen({super.key, required this.billId});

  @override
  State<BillSummaryScreen> createState() => _BillSummaryScreenState();
}

class _BillSummaryScreenState extends State<BillSummaryScreen> {
  static const MethodChannel platform = MethodChannel('com.soya_app/share');
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<BillingController>();
      controller.fetchGoniTypes();
      controller.fetchTodaysRates();
      // If the requested bill ID matches the current draft, use preview endpoint
      if (controller.draftBillId == widget.billId) {
        controller.fetchBillPreview(widget.billId);
      } else {
        controller.fetchBillDetails(widget.billId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreenColor,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(),
            Expanded(
              child: Consumer<BillingController>(
                builder: (context, controller, child) {
                  if (controller.isLoading &&
                      controller.selectedBillDetails == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final bill = controller.selectedBillDetails;
                  if (bill == null) {
                    return const Center(child: Text("Bill not found"));
                  }

                  // Use backend values from summaryTotals/calculationDetails if available
                  final calc = controller.calculationDetails;
                  final totals = controller.summaryTotals;

                  final itemTotal =
                      totals?['grossAmount'] ?? bill.grossAmount ?? 0;
                  final qualityDeductions = calc?.totalLabDeductionAmount ??
                      totals?['totalLabDeductionAmount'] ??
                      totals?['totalDeductions'] ??
                      0;
                  final goniDeductionAmount = calc?.goniDeductionAmount ??
                      totals?['goniDeductionAmount'] ??
                      bill.goniDeductionAmount ??
                      0;
                  final netPayable =
                      calc?.recalculatedTotal ?? bill.netPayable ?? 0;
                  // after lab re calculation
                  // Convert to QTL first for consistent fallback
                  final netWeightQTL = calc?.pricedQuantity ??
                      (bill.primaryUnit == 'QTL'
                          ? (bill.primaryQuantity ?? 0)
                          : (bill.primaryQuantity ?? 0) / 100);

                  final netWeightKG = netWeightQTL * 100;

                  final actualRate = calc?.rateAfterLabDeductionRounded ??
                      bill.ratePerUnit ??
                      0;

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 20.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(bill.billNo ?? 'DRAFT'),
                        SizedBox(height: 20.h),
                        _buildEnhancedBasicDetails(bill),
                        if (bill.vehicleNumber != null ||
                            bill.driverName != null) ...[
                          SizedBox(height: 20.h),
                          _buildVehicleDetails(bill),
                        ],
                        SizedBox(height: 20.h),
                        _buildWeightDetailsCard(bill, calc),
                        SizedBox(height: 20.h),
                        _buildRateDetailsCard(bill, calc),
                        //dont show
                        // SizedBox(height: 20.h),
                        // _buildWeightConversionCard(calc),
                        SizedBox(height: 20.h),
                        _buildSectionHeader("Deductions"),
                        //dont show goni deduction
                        // if (bill.goniType != null)
                        //   _buildItemCard(
                        //     "${bill.goniType?.name}",
                        //     "Goni Count: ${bill.bagCount} bags",
                        //     "${((totals?['goniWeight'] ?? bill.goniWeight ?? 0) * 100).toStringAsFixed(2)} KG",
                        //     isCurrency: false,
                        //   ),
                        ...List.generate(
                          controller.previewDeductions.isNotEmpty
                              ? controller.previewDeductions.length
                              : (bill.deductions?.length ?? 0),
                          (index) {
                            final d = controller.previewDeductions.isNotEmpty
                                ? controller.previewDeductions[index]
                                : bill.deductions![index];
                            return _buildDeductionCard(d);
                          },
                        ),
                        if (bill.goniType == null &&
                            (bill.deductions == null ||
                                bill.deductions!.isEmpty))
                          const Text("No deductions applied"),
                        SizedBox(height: 20.h),

                        _buildBillingSummaryCard(
                          bill,
                          netWeightKG,
                          netWeightQTL,
                          actualRate,
                          netPayable,
                        ),
                        SizedBox(height: 20.h),
                        _buildAdvancesCard(context, controller, bill),
                        SizedBox(height: 12.h),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () => _showInstantAdvanceDialog(
                                context, controller, bill),
                            icon: Icon(Icons.bolt,
                                color: whiteColor, size: 16.sp),
                            label: Text(
                              "Advance Payment",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: whiteColor,
                                fontFamily: FontFamily.jost,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[800],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                // Set radius to 8.r to match other buttons in app
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 10.h,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        if (bill.status == 'DRAFT') ...[
                          _buildFinalizeButton(context, controller),
                        ] else ...[
                          _buildReturnBagsOption(context, controller, bill),
                        ],
                        SizedBox(height: 20.h),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String billNo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Billing Summary",
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                fontFamily: FontFamily.georgia,
                color: blackColor,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        Text(
          "View bill details and finalize bill",
          style: TextStyle(
            fontSize: 12.sp,
            color: greyColor,
            fontFamily: FontFamily.jost,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedBasicDetails(BillModel bill) {
    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: appColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: primeryColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
              border: Border(bottom: BorderSide(color: appColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: primeryColor,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "Farmer Information",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: primeryColor,
                        fontFamily: FontFamily.jost,
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(bill.status ?? 'DRAFT'),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                _buildIconDetailRow(
                  Icons.person,
                  "Name",
                  bill.farmer?.name ?? 'N/A',
                ),
                Divider(height: 20, color: appColor),
                Row(
                  children: [
                    Expanded(
                      child: _buildIconDetailRow(
                        Icons.badge_outlined,
                        "Aadhaar",
                        bill.farmer?.aadhaarNo ?? 'N/A',
                      ),
                    ),
                    Expanded(
                      child: _buildIconDetailRow(
                        Icons.phone_android,
                        "Mobile",
                        bill.farmer?.phone ?? 'N/A',
                      ),
                    ),
                  ],
                ),
                Divider(height: 20, color: appColor),
                Row(
                  children: [
                    Expanded(
                      child: _buildIconDetailRow(
                        Icons.location_on_outlined,
                        "Village",
                        bill.farmer?.villageAdd ?? 'N/A',
                      ),
                    ),
                    Expanded(
                      child: _buildIconDetailRow(
                        Icons.grid_3x3,
                        "Gut No",
                        bill.farmer?.gutNumber ?? 'N/A',
                      ),
                    ),
                  ],
                ),
                Divider(height: 20, color: appColor),
                Row(
                  children: [
                    Expanded(
                      child: _buildIconDetailRow(
                        Icons.account_balance_outlined,
                        "Taluka",
                        bill.farmer?.taluka ?? 'N/A',
                      ),
                    ),
                    Expanded(
                      child: _buildIconDetailRow(
                        Icons.map_outlined,
                        "District",
                        bill.farmer?.district ?? 'N/A',
                      ),
                    ),
                  ],
                ),
                Divider(height: 20, color: appColor),
                _buildIconDetailRow(
                  Icons.location_on,
                  "Bill Location",
                  bill.billLocation ?? 'N/A',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetails(BillModel bill) {
    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: appColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
              border: Border(bottom: BorderSide(color: appColor)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  color: Colors.blue,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  "Vehicle & Driver Details",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontFamily: FontFamily.jost,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildIconDetailRow(
                        Icons.numbers,
                        "Vehicle No.",
                        bill.vehicleNumber ?? 'N/A',
                      ),
                    ),
                    Expanded(
                      child: _buildIconDetailRow(
                        Icons.category_outlined,
                        "Vehicle Type",
                        bill.vehicleType ?? 'N/A',
                      ),
                    ),
                  ],
                ),
                Divider(height: 20, color: appColor),
                _buildIconDetailRow(
                  Icons.person_pin_outlined,
                  "Driver Name",
                  bill.driverName ?? 'N/A',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isDraft = status == 'DRAFT';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDraft
            ? Colors.orange.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDraft
              ? Colors.orange.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: isDraft ? Colors.orange : Colors.green,
          fontFamily: FontFamily.jost,
        ),
      ),
    );
  }

  Widget _buildIconDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onAdd}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              fontFamily: FontFamily.jost,
            ),
          ),
          if (onAdd != null)
            TextButton.icon(
              onPressed: onAdd,
              icon: Icon(
                Icons.add_circle_outline,
                size: 18.sp,
                color: primeryColor,
              ),
              label: Text(
                "Add",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: primeryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    String title,
    String subtitle,
    String price, {
    bool isCurrency = true,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: FontFamily.jost,
                ),
              ),
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
          Text(
            price,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isCurrency ? primeryColor : redColor,
              fontFamily: FontFamily.jost,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: greyColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                fontFamily: FontFamily.jost,
                color: blackColor,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRowWithBox(String label, String value, {String? suffix}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: label == "Actual Rate"
                    ? primeryColor
                    : blackColor.withOpacity(0.7),
                fontFamily: FontFamily.jost,
                fontWeight: label == "Actual Rate"
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(
                  color: label == "Actual Rate"
                      ? primeryColor
                      : greyColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: label == "Actual Rate" ? primeryColor : blackColor,
                      fontFamily: FontFamily.jost,
                    ),
                  ),
                  if (suffix != null)
                    Text(
                      suffix,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color:
                            label == "Actual Rate" ? primeryColor : greyColor,
                        fontFamily: FontFamily.jost,
                        fontWeight: label == "Actual Rate"
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? bgColor,
    Color? textColor,
    bool isBold = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: bgColor != null
            ? BorderRadius.only(
                bottomLeft: Radius.circular(8.r),
                bottomRight: Radius.circular(8.r),
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: label == "Actual Rate"
                  ? primeryColor
                  : textColor ?? blackColor.withOpacity(0.7),
              fontFamily: FontFamily.jost,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: label == "Actual Rate"
                  ? primeryColor
                  : textColor ?? blackColor,
              fontFamily: FontFamily.jost,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightDetailsCard(BillModel bill, CalculationDetails? calc) {
    List<Widget> bagRows = [];
    if (bill.gonis != null && bill.gonis!.isNotEmpty) {
      for (int i = 0; i < bill.gonis!.length; i++) {
        var goni = bill.gonis![i];
        bagRows.add(
          _buildInfoRowWithBox(
            "Bag Type ${i + 1}",
            goni.goniType?.name ?? 'N/A',
          ),
        );
        bagRows.add(
          _buildInfoRowWithBox(
            "Bag Quantity",
            "${goni.bagCount ?? '0'}",
            suffix: "bags",
          ),
        );
      }
    } else {
      bagRows.add(
        _buildInfoRowWithBox("Bag Type", bill.goniType?.name ?? 'N/A'),
      );
      bagRows.add(
        _buildInfoRowWithBox(
          "Bag Quantity",
          "${bill.bagCount ?? '0'}",
          suffix: "bags",
        ),
      );
    }

    return _buildSummarySection(
      title: "Weight Details",
      children: [
        _buildInfoRowWithBox(
          "Total Weight",
          ((calc?.totalQuantityReceived ??
                      (bill.primaryUnit == 'QTL'
                          ? bill.primaryQuantity
                          : (bill.primaryQuantity != null
                              ? bill.primaryQuantity! / 100
                              : 0)) ??
                      0) *
                  100)
              .toStringAsFixed(2),
          suffix: "KG",
        ),
        ...bagRows,
        _buildInfoRow(
          "Total Bag Weight",
          "${((calc?.bagWeight ?? (bill.goniWeight ?? 0)) * 100).toStringAsFixed(2)} KG",
        ),
        _buildInfoRow(
          "Net Weight",
          "${((calc?.netWeightForLab ?? (bill.primaryUnit == 'QTL' ? bill.primaryQuantity : (bill.primaryQuantity != null ? bill.primaryQuantity! / 100 : 0)) ?? 0) * 100).toStringAsFixed(2)} KG",
          bgColor: primeryColor,
          textColor: whiteColor,
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildRateDetailsCard(BillModel bill, CalculationDetails? calc) {
    return _buildSummarySection(
      title: "Rate Details",
      children: [
        _buildInfoRowWithBox(
          "Base Rate",
          "${calc?.ratePerUnit ?? bill.ratePerUnit ?? '0'}",
          suffix: "₹/QTL",
        ),
        // perQtlLabDeduction show here
        // _buildInfoRowWithBox(
        //     "Lab Deduction", (bill.perQtlLabDeduction ?? 0).toStringAsFixed(2),
        //     suffix: "₹/QTL"),
        _buildInfoRowWithBox(
          "Actual Rate",
          ((calc?.rateAfterLabDeductionRounded != null &&
                      calc!.rateAfterLabDeductionRounded! > 0)
                  ? calc.rateAfterLabDeductionRounded!
                  : (bill.ratePerUnit ?? 0))
              .toStringAsFixed(2),
          suffix: "₹/QTL",
        ),
        // _buildInfoRow(
        //   "Actual Rate",
        //   "${(calc?.rateAfterLabDeductionRounded ?? 0).toStringAsFixed(2)} ₹/QTL",
        //   isBold: true,
        // ),
      ],
    );
  }

  Widget _buildWeightConversionCard(CalculationDetails? calc) {
    return _buildSummarySection(
      title: "Weight Conversion",
      children: [
        _buildInfoRowWithBox(
          "Net Weight",
          (calc?.finalNetPayableWeight ?? 0).toStringAsFixed(2),
          suffix: "KG",
        ),
      ],
    );
  }

  Widget _buildBillingSummaryCard(
    BillModel bill,
    num netWeightKG,
    num netWeightQTL,
    num actualRate,
    num netPayable,
  ) {
    final billingController = context.read<BillingController>();
    final outstandingAdvance = billingController.farmerAdvanceBalance;

    // Calculate advance dynamically if not already parsed (for draft/preview stage)
    final advance = (bill.advancedAmount != null && bill.advancedAmount! > 0)
        ? bill.advancedAmount!
        : (bill.status == 'DRAFT' && outstandingAdvance > 0
            ? (outstandingAdvance < netPayable
                ? outstandingAdvance
                : netPayable)
            : 0);

    final balance = bill.balanceAmount ?? (netPayable - advance);

    final settled = (bill.settledAmount != null && bill.settledAmount! > 0)
        ? bill.settledAmount!
        : (netPayable - advance);

    final paymentStatus =
        (bill.paymentStatus != null && bill.paymentStatus!.isNotEmpty)
            ? bill.paymentStatus!
            : 'UNPAID';

    return Container(
      decoration: BoxDecoration(
        color: primeryColor.withOpacity(0.05), // Light yellowish background
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: primeryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Text(
              "Billing Summary",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                fontFamily: FontFamily.jost,
                color: blackColor,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildInfoRow(
            "Net Weight (KG):",
            "${netWeightKG.toStringAsFixed(2)} KG",
          ),
          _buildInfoRow(
            "Net Weight (QTL):",
            "${netWeightQTL.toStringAsFixed(4)} QTL",
          ),
          _buildInfoRow(
            "Actual Rate:",
            "${actualRate.toStringAsFixed(2)} ₹/QTL",
          ),
          _buildInfoRow("Total Payable:", "₹ ${netPayable.toStringAsFixed(2)}"),
          if (advance > 0.01)
            _buildInfoRow(
              "Advance Amount:",
              "₹ ${advance.toStringAsFixed(2)}",
              textColor: redColor,
            ),
          if (settled > 0.01)
            _buildInfoRow(
              "Settled Amount:",
              "₹ ${settled.toStringAsFixed(2)}",
              textColor: primeryColor,
            ),
          _buildInfoRow(
            "Final Balance:",
            "₹ ${balance.toStringAsFixed(2)}",
            bgColor: primeryColor,
            textColor: whiteColor,
            isBold: true,
          ),
          const Divider(height: 1),
          _buildInfoRow(
            "Payment Status:",
            paymentStatus.toUpperCase(),
            textColor: paymentStatus.toLowerCase() == 'paid'
                ? Colors.green
                : Colors.blue,
            isBold: true,
          ),
          if (bill.payment != null) ...[
            _buildInfoRow(
              "Paid Date:",
              bill.payment!.paidDate != null
                  ? DateFormat('dd MMM yyyy, hh:mm a')
                      .format(DateTime.parse(bill.payment!.paidDate!))
                  : "N/A",
            ),
            if (bill.payment!.reference != null &&
                bill.payment!.reference!.isNotEmpty)
              _buildInfoRow(
                "Reference No:",
                bill.payment!.reference!,
              ),
          ] else if (bill.status == 'DRAFT') ...[
            _buildInfoRow(
              "Paid Date:",
              "Pending",
            ),
            _buildInfoRow(
              "Reference No:",
              "Pending",
            ),
          ],
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showAdditionalDocumentDialog(
    BuildContext context,
    BillingController controller,
    String billId,
  ) async {
    final TextEditingController remarkController = TextEditingController();
    final List<File> selectedFiles = [];

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              title: Text(
                "Add Remarks / Documents",
                style: TextStyle(
                  fontFamily: FontFamily.jost,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: blackColor,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDialogLabel("Remark (Optional)"),
                    TextField(
                      controller: remarkController,
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontFamily: FontFamily.jost,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter any remarks here...",
                        hintStyle: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: FontFamily.jost,
                          color: greyColor.withOpacity(0.6),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 12.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6.r),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6.r),
                          borderSide: BorderSide(color: primeryColor),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _buildDialogLabel("Upload Document(s) (Optional)"),
                    GestureDetector(
                      onTap: () async {
                        try {
                          final files =
                              await ImagePickerService.pickMultipleFiles(
                                  context);
                          if (files != null && files.isNotEmpty) {
                            setDialogState(() {
                              selectedFiles.addAll(files);
                            });
                          }
                        } catch (e) {
                          debugPrint('Error picking files: $e');
                        }
                      },
                      child: DottedBorder(
                        color: primeryColor,
                        strokeWidth: 1,
                        dashPattern: const [5, 5],
                        borderType: BorderType.RRect,
                        radius: Radius.circular(8.r),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 20.h),
                          color: primeryColor.withOpacity(0.02),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                color: primeryColor,
                                size: 36.sp,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                "Upload Remark File(s)",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                  color: blackColor.withOpacity(0.7),
                                  fontFamily: FontFamily.jost,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                "Supports JPG, PNG, PDF",
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: greyColor,
                                  fontFamily: FontFamily.jost,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (selectedFiles.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      Container(
                        constraints: BoxConstraints(maxHeight: 120.h),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: selectedFiles.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 6.h),
                          itemBuilder: (context, index) {
                            final file = selectedFiles[index];
                            final name =
                                file.path.split('/').last.split('\\').last;
                            return Row(
                              children: [
                                Icon(Icons.insert_drive_file_outlined,
                                    color: primeryColor, size: 18.sp),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontFamily: FontFamily.jost,
                                      color: blackColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedFiles.removeAt(index);
                                    });
                                  },
                                  icon: Icon(Icons.cancel_outlined,
                                      color: Colors.red, size: 18.sp),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'remark': '',
                      'remarkFiles': <File>[],
                    });
                  },
                  child: Text(
                    "Skip",
                    style: TextStyle(
                      color: greyColor,
                      fontSize: 14.sp,
                      fontFamily: FontFamily.jost,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'remark': remarkController.text.trim(),
                      'remarkFiles': selectedFiles,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primeryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    "Submit",
                    style: TextStyle(
                      color: whiteColor,
                      fontSize: 14.sp,
                      fontFamily: FontFamily.jost,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFinalizeButton(
    BuildContext context,
    BillingController controller,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: controller.isLoading
            ? null
            : () async {
                final nav = Navigator.of(context);
                final botNav = Provider.of<BottomNavBarController>(
                  context,
                  listen: false,
                );

                // Show additional document popup before confirming
                final additionalData = await _showAdditionalDocumentDialog(
                  context,
                  controller,
                  widget.billId,
                );

                if (additionalData == null) return; // Vendor cancelled dialog
                if (!context.mounted) return;

                final String remark = additionalData['remark'] ?? '';
                final List<File> remarkFiles =
                    List<File>.from(additionalData['remarkFiles'] ?? []);

                // 1. Confirm Bill
                final success = await controller.confirmDraftBill(
                  context: context,
                  billId: widget.billId,
                  remark: remark,
                  remarkFiles: remarkFiles,
                );

                if (!context.mounted) return;

                if (success) {
                  // 2. Show Return Bags Dialog
                  await _showReturnBagsDialog(
                    context,
                    controller,
                    widget.billId,
                  );

                  if (!context.mounted) return;

                  // 3. Show Success Dialog with Options
                  await _showSuccessDialog(
                    context,
                    controller,
                    widget.billId,
                  );

                  // 4. Navigate away after dialog is closed
                  controller.reset(); // Clear all billing data
                  botNav.updateFormView(FormView.selection);
                  nav.pop();
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: controller.isLoading ? whiteColor : primeryColor,
          side: controller.isLoading
              ? BorderSide(color: primeryColor)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: controller.isLoading
            ? const CircularProgressIndicator()
            : Text(
                "Finalize",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: whiteColor,
                  fontFamily: FontFamily.jost,
                ),
              ),
      ),
    );
  }

  Widget _buildReturnBagsOption(
    BuildContext context,
    BillingController controller,
    BillModel bill,
  ) {
    if (bill.status == 'FINALIZED' || bill.status == 'PAID') {
      return SizedBox(
        width: double.infinity,
        height: 50.h,
        child: OutlinedButton.icon(
          onPressed: () => _showReturnBagsDialog(context, controller, bill.id!),
          icon: Icon(Icons.keyboard_return, color: primeryColor),
          label: Text(
            "Return Bags to Farmer",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: primeryColor,
              fontFamily: FontFamily.jost,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: primeryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _showReturnBagsDialog(
    BuildContext context,
    BillingController controller,
    String billId,
  ) async {
    final TextEditingController countController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer<BillingController>(
          builder: (context, controller, child) {
            return AlertDialog(
              title: const Text(
                "Return Bags to Farmer",
                style: TextStyle(fontFamily: FontFamily.jost),
              ),
              content: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: controller.isReturnBagsLoading ? 0.3 : 1.0,
                    child: AbsorbPointer(
                      absorbing: controller.isReturnBagsLoading,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDialogLabel("Select Bag Type"),
                            Container(
                              height: 48.h,
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              decoration: BoxDecoration(
                                color: whiteColor,
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.4),
                                  width: 0.5,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<GoniType>(
                                  value: (controller.returnGoniType != null &&
                                          controller.goniTypes
                                              .where((g) => g.isTracked == true)
                                              .contains(
                                                controller.returnGoniType,
                                              ))
                                      ? controller.returnGoniType
                                      : null,
                                  isExpanded: true,
                                  hint: Text(
                                    'Select Bag Type',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontFamily: FontFamily.jost,
                                    ),
                                  ),
                                  items: controller.goniTypes
                                      .where(
                                        (g) =>
                                            g.isTracked == true &&
                                            g.isActive == true,
                                      )
                                      .map(
                                        (goni) => DropdownMenuItem(
                                          value: goni,
                                          child: Text(
                                            "${goni.name ?? 'Unknown'} (${goni.weightPerBag} kg)",
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontFamily: FontFamily.jost,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      controller.selectReturnGoniType(value);
                                    }
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            _buildDialogLabel("Number of Bags"),
                            _buildDialogTextField(
                              controller: countController,
                              hint: "0",
                              keyboardType: TextInputType.number,
                            ),
                            SizedBox(height: 16.h),
                            _buildDialogLabel("Notes (Optional)"),
                            _buildDialogTextField(
                              controller: notesController,
                              hint: "Optional notes",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (controller.isReturnBagsLoading)
                    CircularProgressIndicator(color: primeryColor),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: controller.isReturnBagsLoading
                      ? null
                      : () => Navigator.pop(context),
                  child: Text("Skip", style: TextStyle(color: greyColor)),
                ),
                ElevatedButton(
                  onPressed: controller.isReturnBagsLoading
                      ? null
                      : () async {
                          final count = int.tryParse(countController.text) ?? 0;
                          if (count > 0 && controller.returnGoniType != null) {
                            controller.setReturnBagCount(count);
                            controller.setReturnNotes(notesController.text);
                            final success = await controller.returnBagsToFarmer(
                              context: context,
                            );
                            if (success && context.mounted) {
                              Navigator.pop(context);
                              ToastMessage.show(
                                context,
                                message: "Bags returned to farmer successfully",
                                isError: false,
                              );
                            }
                          } else if (count == 0) {
                            Navigator.pop(context);
                          } else {
                            ToastMessage.show(
                              context,
                              message: "Please enter a valid count",
                              isError: true,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primeryColor,
                  ),
                  child: controller.isReturnBagsLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: CircularProgressIndicator(
                            color: whiteColor,
                            strokeWidth: 2,
                          ),
                        )
                      : Text("Submit", style: TextStyle(color: whiteColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: greyColor,
          fontFamily: FontFamily.jost,
        ),
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r)),
      ),
    );
  }

  Future<void> _showSuccessDialog(
    BuildContext context,
    BillingController controller,
    String billId,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isGenerating = false;

        return StatefulBuilder(
          builder: (context, setState) {
            final bill = controller.selectedBillDetails;
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              elevation: 10,
              backgroundColor: Colors.white,
              insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success Animation/Icon
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 60.sp,
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Title
                    Text(
                      "Bill Finalized!",
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: FontFamily.jost,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "Your bill has been successfully saved.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: greyColor,
                        fontFamily: FontFamily.jost,
                      ),
                    ),
                    SizedBox(height: 30.h),

                    if (isGenerating)
                      Column(
                        children: [
                          const CircularProgressIndicator(),
                          SizedBox(height: 16.h),
                          Text(
                            "Generating PDF...",
                            style: TextStyle(
                              fontFamily: FontFamily.jost,
                              color: greyColor,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      // Share on WhatsApp Button
                      _buildActionCard(
                        icon: FontAwesomeIcons.whatsapp,
                        color: const Color(0xFF25D366), // WhatsApp Green
                        title: "Share on WhatsApp",
                        subtitle: "Send PDF directly via WhatsApp",
                        onTap: () async {
                          setState(() => isGenerating = true);
                          await _generateAndSharePdf(context, controller);
                          if (context.mounted) {
                            setState(() => isGenerating = false);
                          }
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Download PDF Button
                      _buildActionCard(
                        icon: Icons.download_rounded,
                        color: primeryColor,
                        title: "Download PDF",
                        subtitle: "Save to your device",
                        onTap: () async {
                          setState(() => isGenerating = true);
                          await _generateAndDownloadPdf(context, controller);
                          if (context.mounted) {
                            setState(() => isGenerating = false);
                          }
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Print Bill Button
                      _buildActionCard(
                        icon: Icons.print_rounded,
                        color: Colors.blueGrey,
                        title: "Print Bill",
                        subtitle: "Choose A4 or 58mm thermal",
                        onTap: () async {
                          setState(() => isGenerating = true);
                          await _printPdf(context, controller);
                          if (context.mounted) {
                            setState(() => isGenerating = false);
                          }
                        },
                      ),
                      SizedBox(height: 16.h),
                      // Advance Payment Button
                      _buildActionCard(
                        icon: Icons.bolt,
                        color: Colors.amber[800]!,
                        title: "Advance Payment",
                        subtitle: "Record an advance payment for this farmer",
                        onTap: () {
                          if (bill != null) {
                            _showInstantAdvanceDialog(
                                context, controller, bill);
                          } else {
                            ToastMessage.show(context,
                                message: "Bill details not available",
                                isError: true);
                          }
                        },
                      ),
                    ],

                    SizedBox(height: 24.h),

                    // Done Button
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                      ),
                      child: Text(
                        "Done",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: greyColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: color, // Solid color for icon background
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24.sp),
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
                      fontWeight: FontWeight.bold,
                      fontFamily: FontFamily.jost,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontFamily: FontFamily.jost,
                      color: greyColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16.sp, color: greyColor),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndSharePdf(
    BuildContext context,
    BillingController controller,
  ) async {
    try {
      final bill = controller.selectedBillDetails;
      if (bill == null) return;

      final pdfData = await PdfInvoiceService.generateInvoice(
        bill,
        deductions: controller.previewDeductions,
      );

      // Filename format: [FarmerName]_[BillNo].pdf
      final farmerName = (bill.farmer?.name ?? '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'[^\w]+'), '');
      final sanitizedBillNo = (bill.billNo ?? 'DRAFT').replaceAll(
        RegExp(r'[^\w\s]+'),
        '_',
      );

      final fileName =
          "${farmerName.isNotEmpty ? '${farmerName}_' : ''}$sanitizedBillNo.pdf";

      // Save to temporary directory for sharing
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/$fileName').create();
      await file.writeAsBytes(pdfData);

      if (Platform.isAndroid) {
        // Try direct WhatsApp sharing via native channel
        final farmerPhoneRaw =
            bill.farmer?.phone?.replaceAll(RegExp(r'[^\d]+'), '') ?? '';
        // Ensure 91 prefix for 10-digit Indian numbers
        final formattedPhone =
            farmerPhoneRaw.length == 10 ? "91$farmerPhoneRaw" : farmerPhoneRaw;
        final message = "Hello ${bill.farmer?.name ?? 'Customer'},\n\n"
            "Here is your Goods Received Note (GRN) for the Soya purchase.\n\n"
            "Bill No: ${bill.billNo ?? 'N/A'}\n"
            "Net Payable: ₹${(bill.netPayable ?? 0).toStringAsFixed(2)}\n\n"
            "Thank you for your business!";

        try {
          if (farmerPhoneRaw.isEmpty) {
            throw Exception("Farmer phone number is missing");
          }

          // V11: Unified native sharing for both direct redirection and PDF attachment
          await platform.invokeMethod('shareToWhatsApp', {
            'filePath': file.path,
            'phoneNumber': formattedPhone,
            'message': message,
          });
        } catch (e) {
          debugPrint("WhatsApp V11 native sharing error: $e");

          // Extreme Fallback: Just open the chat via wa.me if native fails entirely
          final webUrl = Uri.parse(
            "https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}",
          );
          if (await canLaunchUrl(webUrl)) {
            await launchUrl(webUrl, mode: LaunchMode.externalApplication);
          }

          if (context.mounted) {
            await Share.shareXFiles(
              [XFile(file.path)],
              text: 'Here is the bill for ${bill.farmer?.name ?? 'Customer'}.',
            );
          }
        }
      } else {
        if (context.mounted) {
          await Share.shareXFiles([
            XFile(file.path),
          ], text: 'Here is the bill for ${bill.farmer?.name ?? 'Customer'}.');
        }
      }
    } catch (e) {
      debugPrint("Error sharing PDF: $e");
      if (context.mounted) {
        ToastMessage.show(
          context,
          message: "Failed to share PDF",
          isError: true,
        );
      }
    }
  }

  Future<void> _printPdf(
    BuildContext context,
    BillingController controller,
  ) async {
    try {
      final bill = controller.selectedBillDetails;
      if (bill == null) return;

      final printFormat = await _showPrintFormatSheet(context);
      if (printFormat == null) return;

      final pdfData = await PdfInvoiceService.generateInvoice(
        bill,
        format: printFormat,
        deductions: controller.previewDeductions,
      );
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
        name:
            'Bill_${bill.billNo ?? 'N/A'}_${printFormat == BillPrintFormat.thermal58 ? '58mm' : 'A4'}',
      );
    } catch (e) {
      debugPrint("Error printing PDF: $e");
      if (context.mounted) {
        ToastMessage.show(
          context,
          message: "Failed to print PDF",
          isError: true,
        );
      }
    }
  }

  Future<BillPrintFormat?> _showPrintFormatSheet(BuildContext context) {
    return showModalBottomSheet<BillPrintFormat>(
      context: context,
      backgroundColor: whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(18.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Print Format",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: FontFamily.jost,
                    color: blackColor,
                  ),
                ),
                SizedBox(height: 12.h),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text("A4 Farmer Purchase Receipt"),
                  subtitle: const Text("Full-size PDF layout"),
                  onTap: () => Navigator.pop(context, BillPrintFormat.a4),
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text("58mm Thermal Receipt"),
                  subtitle: const Text("Compact bill printer layout"),
                  onTap: () =>
                      Navigator.pop(context, BillPrintFormat.thermal58),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateAndDownloadPdf(
    BuildContext context,
    BillingController controller,
  ) async {
    try {
      final bill = controller.selectedBillDetails;
      if (bill == null) return;

      final pdfData = await PdfInvoiceService.generateInvoice(
        bill,
        deductions: controller.previewDeductions,
      );
      // Filename format: [FarmerName]_[BillNo].pdf
      final farmerName = (bill.farmer?.name ?? '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'[^\w]+'), '');
      final sanitizedBillNo = (bill.billNo ?? 'DRAFT').replaceAll(
        RegExp(r'[^\w\s]+'),
        '_',
      );

      final fileName =
          "${farmerName.isNotEmpty ? '${farmerName}_' : ''}$sanitizedBillNo.pdf";

      final file = await PdfInvoiceService.savePdfFile(fileName, pdfData);

      if (context.mounted) {
        ToastMessage.show(
          context,
          message: "PDF Downloaded: ${file.path}",
          isError: false,
        );
        await OpenFile.open(file.path);
      }
    } catch (e) {
      debugPrint("Error downloading PDF: $e");
      if (context.mounted) {
        ToastMessage.show(
          context,
          message: "Failed to download PDF",
          isError: true,
        );
      }
    }
  }

  Widget _buildDeductionCard(BillDeduction deduction) {
    final payload = deduction.payload;
    final isQualityAnalysis = deduction.label == "Moisture" ||
        deduction.label == "Moisture Deduction" ||
        (payload != null && payload.containsKey('actualInputs'));

    if (deduction.variableDetails != null &&
        deduction.variableDetails!.isNotEmpty) {
      return _buildVariableDeductionTable(deduction);
    }
    if (isQualityAnalysis) {
      return _buildQualityAnalysisSummaryTable(deduction);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                deduction.label ?? 'Unknown Deduction',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: FontFamily.jost,
                ),
              ),
              Text(
                "- ₹${deduction.value?.toStringAsFixed(2) ?? '0.00'}",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: redColor,
                  fontFamily: FontFamily.jost,
                ),
              ),
            ],
          ),
          if (deduction.payload != null && deduction.payload!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
            SizedBox(height: 8.h),
            ...deduction.payload!.entries.map((e) {
              final key = e.key
                  .replaceAll('_', ' ')
                  .split(' ')
                  .map(
                    (str) => str.isNotEmpty
                        ? '${str[0].toUpperCase()}${str.substring(1)}'
                        : '',
                  )
                  .join(' ');
              return Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      key,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: greyColor,
                        fontFamily: FontFamily.jost,
                      ),
                    ),
                    Text(
                      "${e.value}",
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: blackColor,
                        fontFamily: FontFamily.jost,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildQualityAnalysisSummaryTable(BillDeduction deduction) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Container(
          //   padding: EdgeInsets.all(12.w),
          //   decoration: BoxDecoration(
          //     color: greyColor.withOpacity(0.05),
          //     borderRadius: BorderRadius.only(
          //       topLeft: Radius.circular(12.r),
          //       topRight: Radius.circular(12.r),
          //     ),
          //   ),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       Text("Quality Analysis Details",
          //           style: TextStyle(
          //               fontSize: 15.sp,
          //               fontWeight: FontWeight.bold,
          //               fontFamily: FontFamily.jost)),
          //       Text("- ₹${deduction.value?.toStringAsFixed(2) ?? '0.00'}",
          //           style: TextStyle(
          //               fontSize: 15.sp,
          //               fontWeight: FontWeight.bold,
          //               color: redColor,
          //               fontFamily: FontFamily.jost)),
          //     ],
          //   ),
          // ),
          Padding(
            padding: EdgeInsets.all(10.w),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  children: [
                    _tableHeaderCell("Analysis"),
                    _tableHeaderCell("Allowed"),
                    _tableHeaderCell("Actual"),
                    _tableHeaderCell("Deduct"),
                  ],
                ),
                // Dynamic Rows based on Payload
                ...(deduction.customInputs?.keys ??
                        deduction.actualInputs?.keys ??
                        [])
                    .map((code) {
                  return _qualitySummaryRow(
                    _getDisplayLabel(code),
                    _getNestedVal(deduction, 'actualInputs', code),
                    _getNestedVal(deduction, 'customInputs', code),
                    _getNestedVal(deduction, 'deductedInputs', code),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayLabel(String code) {
    if (code == 'mati') return 'FM';
    if (code == 'dagi') return 'Damage';
    if (code == 'moisture') return 'Moisture';
    return code[0].toUpperCase() + code.substring(1);
  }

  Widget _tableCell(
    String text, {
    bool isBold = false,
    Color? color,
    TextAlign textAlign = TextAlign.center,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? blackColor,
          fontFamily: FontFamily.jost,
        ),
      ),
    );
  }

  Widget _tableHeaderCell(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text(
        text,
        textAlign: text == "Analysis" ? TextAlign.start : TextAlign.center,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: greyColor,
          fontFamily: FontFamily.jost,
        ),
      ),
    );
  }

  TableRow _qualitySummaryRow(
    String label,
    String allowed,
    String actual,
    String deduction,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Text(
            label,
            style: TextStyle(fontSize: 12.sp, fontFamily: FontFamily.jost),
          ),
        ),
        _tableCell(allowed),
        _tableCell(actual, isBold: true),
        _tableCell(deduction, color: redColor),
      ],
    );
  }

  String _getNestedVal(
    BillDeduction d,
    String group,
    String key, {
    String fallback = "0",
  }) {
    // 1. Check top-level model fields (most updated)
    if (group == 'actualInputs' && d.actualInputs != null) {
      return d.actualInputs![key]?.toString() ?? fallback;
    }
    if (group == 'customInputs' && d.customInputs != null) {
      // For Actual column, if custom input is missing (equal to allowed),
      // return the actual input (threshold) to match UI expectation
      return d.customInputs![key]?.toString() ??
          d.actualInputs?[key]?.toString() ??
          fallback;
    }
    if (group == 'deductedInputs' && d.deductedInputs != null) {
      return d.deductedInputs![key]?.toString() ?? fallback;
    }
    if (group == 'deductedAmounts' && d.deductedAmounts != null) {
      return d.deductedAmounts![key]?.toString() ?? fallback;
    }

    // 2. Check inside payload map (API variation)
    final payload = d.payload;
    if (payload != null && payload[group] != null) {
      return payload[group][key]?.toString() ?? fallback;
    }

    // 3. Fallback for specific keys
    if (group == 'actualInputs' && d.defaultInputs != null) {
      return d.defaultInputs![key]?.toString() ?? fallback;
    }

    return fallback;
  }

  Widget _buildVariableDeductionTable(BillDeduction deduction) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Container(
          //   padding: EdgeInsets.all(12.w),
          //   decoration: BoxDecoration(
          //     color: greyColor.withOpacity(0.05),
          //     borderRadius: BorderRadius.only(
          //       topLeft: Radius.circular(12.r),
          //       topRight: Radius.circular(12.r),
          //     ),
          //   ),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       Text(deduction.label ?? "Deduction Details",
          //           style: TextStyle(
          //               fontSize: 15.sp,
          //               fontWeight: FontWeight.bold,
          //               fontFamily: FontFamily.jost)),
          //       Text(
          //           "- ₹${(deduction.deductionAmount ?? deduction.value ?? 0).toStringAsFixed(2)}",
          //           style: TextStyle(
          //               fontSize: 15.sp,
          //               fontWeight: FontWeight.bold,
          //               color: redColor,
          //               fontFamily: FontFamily.jost)),
          //     ],
          //   ),
          // ),
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              children: [
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: primeryColor.withOpacity(0.05),
                      ),
                      children: [
                        _tableHeaderCell("Parameter"),
                        _tableHeaderCell("Allowed"),
                        _tableHeaderCell("Actual"),
                        _tableHeaderCell("Deduct"),
                      ],
                    ),
                    ...deduction.variableDetails!.map((v) {
                      return TableRow(
                        children: [
                          _tableCell(
                            v.label ?? v.code ?? "",
                            textAlign: TextAlign.start,
                          ),
                          _tableCell(
                            "${v.actual ?? 0}",
                          ), //here actual is allowed
                          _tableCell(
                            "${v.custom ?? 0}", //custom is (actual/entered by user)
                            isBold: true,
                            color: (v.actual ?? 0) > (v.custom ?? 0)
                                ? redColor
                                : blackColor,
                          ),
                          _tableCell(
                            "${v.deducted ?? 0}",
                            color: (v.deducted ?? 0) > 0 ? redColor : greyColor,
                          ),
                        ],
                      );
                    }),
                    // Total Row
                    TableRow(
                      decoration: BoxDecoration(
                        color: primeryColor.withOpacity(0.05),
                      ),
                      children: [
                        _tableCell(
                          "Total",
                          textAlign: TextAlign.start,
                          isBold: true,
                        ),
                        const SizedBox(),
                        const SizedBox(),
                        _tableCell(
                          deduction.variableDetails!
                              .fold<double>(
                                0.0,
                                (sum, v) => sum + (v.deducted ?? 0),
                              )
                              .toStringAsFixed(2),
                          isBold: true,
                          color: deduction.variableDetails!.fold<double>(
                                    0.0,
                                    (sum, v) => sum + (v.deducted ?? 0),
                                  ) >
                                  0
                              ? redColor
                              : greyColor,
                        ),
                      ],
                    ),
                  ],
                ),
                // no need to show this
                // if (deduction.deductionPercent != null &&
                //     deduction.deductionPercent! > 0) ...[
                //   SizedBox(height: 12.h),
                //   Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       Text("Total Lab Deduction Weight:",
                //           style: TextStyle(
                //               fontSize: 13.sp,
                //               color: greyColor,
                //               fontFamily: FontFamily.jost)),
                //       Text("- ${deduction.deductionWeight ?? 0} QTL",
                //           style: TextStyle(
                //               fontSize: 13.sp,
                //               fontWeight: FontWeight.bold,
                //               color: redColor,
                //               fontFamily: FontFamily.jost)),
                //     ],
                //   ),
                // ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancesCard(
    BuildContext context,
    BillingController controller,
    BillModel bill,
  ) {
    final outstandingAdvance = controller.farmerAdvanceBalance;
    final farmerName =
        bill.farmer?.name ?? controller.selectedFarmer?.name ?? 'N/A';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF388E3C), // Dark green
            Color(0xFF1B5E20), // Extra dark green
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20.w,
            bottom: -20.h,
            child: Container(
              width: 130.w,
              height: 130.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            left: -40.w,
            top: -40.h,
            child: Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.w),
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
                          "OUTSTANDING ADVANCE",
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 1.2,
                            fontFamily: FontFamily.jost,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          "₹ ${outstandingAdvance.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: FontFamily.jost,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 26.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "FARMER NAME",
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: Colors.white.withOpacity(0.6),
                              letterSpacing: 1.0,
                              fontFamily: FontFamily.jost,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            farmerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: FontFamily.jost,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "WALLET STATUS",
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: Colors.white.withOpacity(0.6),
                            letterSpacing: 1.0,
                            fontFamily: FontFamily.jost,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: outstandingAdvance > 0
                                ? Colors.amber.withOpacity(0.2)
                                : Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4.r),
                            border: Border.all(
                              color: outstandingAdvance > 0
                                  ? Colors.amber.withOpacity(0.4)
                                  : Colors.white.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            outstandingAdvance > 0 ? "OUTSTANDING" : "CLEAR",
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: outstandingAdvance > 0
                                  ? Colors.amber[200]
                                  : Colors.white,
                              fontFamily: FontFamily.jost,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInstantAdvanceDialog(
    BuildContext context,
    BillingController controller,
    BillModel bill,
  ) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController remarksController = TextEditingController();
    String selectedReason = 'VEHICLE_RENT';
    final formKey = GlobalKey<FormState>();

    final List<Map<String, String>> reasons = [
      {'value': 'VEHICLE_RENT', 'label': 'Vehicle Rent'},
      {'value': 'LABOUR_CHARGES', 'label': 'Labour Charges'},
      {'value': 'DIESEL_EXPENSE', 'label': 'Diesel'},
      {'value': 'EMERGENCY_EXPENSE', 'label': 'Emergency Expense'},
      {'value': 'OTHER', 'label': 'Other'},
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Consumer<BillingController>(
              builder: (context, controller, child) {
                return AlertDialog(
                  backgroundColor: whiteColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  title: Row(
                    children: [
                      Icon(Icons.bolt, color: Colors.amber[800], size: 24.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Advance Payment',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: FontFamily.jost,
                            color: blackColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: SizedBox(
                        width: double.maxFinite,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Farmer name info
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 8.h),
                              margin: EdgeInsets.only(bottom: 12.h),
                              decoration: BoxDecoration(
                                color: lightGreenColor,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                    color: appColor.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.person,
                                      color: appColor, size: 16.sp),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      bill.farmer?.name ??
                                          controller.selectedFarmer?.name ??
                                          'Farmer',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: FontFamily.jost,
                                        color: blackColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Amount (₹)',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: FontFamily.jost,
                                color: blackColor,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            TextFormField(
                              controller: amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 12.h,
                                ),
                                hintText: 'Enter instant advance amount',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide(
                                    color: primeryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an amount';
                                }
                                final amt = double.tryParse(value);
                                if (amt == null || amt <= 0) {
                                  return 'Please enter a valid positive number';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Reason for Advance',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: FontFamily.jost,
                                color: blackColor,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            DropdownButtonFormField<String>(
                              initialValue: selectedReason,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 12.h,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              items: reasons.map((r) {
                                return DropdownMenuItem<String>(
                                  value: r['value'],
                                  child: Text(
                                    r['label']!,
                                    style: TextStyle(
                                      fontFamily: FontFamily.jost,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    selectedReason = val;
                                  });
                                }
                              },
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Remarks (Optional)',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: FontFamily.jost,
                                color: blackColor,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            TextFormField(
                              controller: remarksController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 12.h,
                                ),
                                hintText: 'Enter optional remarks',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide(
                                    color: primeryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: controller.isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: FontFamily.jost,
                          fontWeight: FontWeight.bold,
                          color: greyColor,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: controller.isLoading
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                final amount =
                                    double.parse(amountController.text);
                                final remarks = remarksController.text;

                                // Call controller method
                                final success =
                                    await controller.recordInstantAdvance(
                                  context: context,
                                  farmerId: bill.farmerId ??
                                      controller.selectedFarmer?.id ??
                                      '',
                                  amount: amount,
                                  reason: selectedReason,
                                  remarks: remarks,
                                  billId: bill.id,
                                );

                                if (success && context.mounted) {
                                  Navigator.pop(context); // Close dialog
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primeryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                      child: controller.isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Save',
                              style: TextStyle(
                                fontFamily: FontFamily.jost,
                                fontWeight: FontWeight.bold,
                                color: whiteColor,
                              ),
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
