import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:soya_app/core/widgets/header_widget.dart';
import 'package:soya_app/core/widgets/name_initials_avatar.dart';
import 'package:soya_app/features/home/controller/billing_controller.dart';
import 'package:soya_app/features/home/model/bill_model.dart';
import 'package:soya_app/routes/app_routes.dart';
import 'package:soya_app/features/reports/view/widgets/pagination_widget.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';
import 'package:intl/intl.dart';
import 'package:soya_app/core/services/pdf_invoice_service.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:soya_app/core/widgets/tost_message.dart';
import 'package:soya_app/core/widgets/empty_state_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class BillingReportScreen extends StatefulWidget {
  const BillingReportScreen({super.key});

  @override
  State<BillingReportScreen> createState() => _BillingReportScreenState();
}

class _BillingReportScreenState extends State<BillingReportScreen> {
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<BillingController>();
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is Map<String, dynamic>) {
        if (args.containsKey('ignoreVendorId')) {
          controller.setBillFilters(ignoreVendorId: args['ignoreVendorId']);
        }
        if (args.containsKey('search')) {
          controller.onBillSearchChanged(args['search']);
        }
      } else if (args is String && args.isNotEmpty) {
        controller.onBillSearchChanged(args);
      } else {
        controller.fetchBills();
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
            _buildCustomAppBar(context),
            _buildSearchBar(),
            Consumer<BillingController>(
              builder: (context, controller, child) {
                if (controller.bills.isEmpty) return const SizedBox.shrink();

                // Calculate showing range with capping
                final total = controller.totalItems;
                final itemsCount = controller.bills.length;
                final start =
                    total == 0 ? 0 : ((controller.currentPage - 1) * 10) + 1;
                final end = (start + itemsCount - 1).clamp(0, total);
                final displayStart = start.clamp(0, total);

                return Column(
                  children: [
                    _buildStatHeader(
                      averageRate: controller.averageRate,
                      total: total,
                      totalAmount: controller.totalAmount,
                    ),
                    _buildResultsSummary(
                      total: total,
                      start: displayStart,
                      end: end,
                    ),
                  ],
                );
              },
            ),
            Expanded(
              child: Consumer<BillingController>(
                builder: (context, controller, child) {
                  final filteredBills = controller.bills;

                  if (filteredBills.isEmpty && !controller.isLoading) {
                    return _buildEmptyState();
                  }

                  return Column(
                    children: [
                      if (controller.isLoading)
                        LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(appColor),
                        ),
                      if (filteredBills.isNotEmpty)
                        Expanded(child: _buildReportTable(filteredBills))
                      else if (controller.isLoading)
                        const Expanded(
                            child: Center(child: CircularProgressIndicator()))
                      else
                        const SizedBox.shrink(),
                      if (filteredBills.isNotEmpty)
                        PaginationWidget(
                          currentPage: controller.currentPage,
                          totalPages: controller.totalPages,
                          onPageChanged: (page) => controller.fetchBills(
                              page: page, search: controller.billSearchQuery),
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
          Text(
            "Billing Report",
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              fontFamily: FontFamily.georgia,
              color: blackColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Container(
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
                focusNode: _searchFocusNode,
                onChanged: (value) => context
                    .read<BillingController>()
                    .onBillSearchChanged(value),
                key: const Key("billing_search_field"),
                decoration: InputDecoration(
                  hintText: "Search by farmer name...",
                  hintStyle: TextStyle(color: greyColor, fontSize: 14.sp),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: appColor, size: 20.sp),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Consumer<BillingController>(
            builder: (context, controller, child) {
              bool hasActiveFilters = controller.billStartDate != null ||
                  controller.billEndDate != null ||
                  controller.selectedBillStatuses.isNotEmpty;

              return GestureDetector(
                onTap: () => _showFilterBottomSheet(context),
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
                  child: Stack(
                    children: [
                      Icon(Icons.filter_list, color: appColor, size: 24.sp),
                      if (hasActiveFilters)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BillFilterBottomSheet(),
    );
  }

  Widget _buildStatHeader({
    required num averageRate,
    required int total,
    required num totalAmount,
  }) {
    if (averageRate <= 0 && total <= 0 && totalAmount <= 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        children: [
          _buildStatCard(
            "Total Amount",
            "₹${totalAmount.toStringAsFixed(2)}",
            Icons.currency_rupee,
            Colors.green.withOpacity(0.1),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Avg Rate",
                  "₹${averageRate.toStringAsFixed(2)}",
                  Icons.trending_up,
                  appColor.withOpacity(0.1),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  "Total Bills",
                  "$total",
                  Icons.receipt_long,
                  Colors.orange.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color bgColor) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: appColor, size: 16.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                    fontFamily: FontFamily.jost,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: blackColor,
                    fontFamily: FontFamily.jost,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
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
              "Showing $start-$end of $total bills",
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

  Future<void> _handlePdfAction(String billId, String action) async {
    final controller = context.read<BillingController>();

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12.w),
            const Text("Preparing PDF..."),
          ],
        ),
        backgroundColor: appColor,
        duration: const Duration(seconds: 10),
      ),
    );

    try {
      // 1. Fetch full bill details to ensure all data is present
      await controller.fetchBillDetails(billId);
      final bill = controller.selectedBillDetails;

      if (bill == null) {
        throw Exception("Failed to fetch bill details");
      }

      // 2. Generate PDF bytes
      final pdfBytes = await PdfInvoiceService.generateInvoice(bill);

      // 3. Clear loading
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // 4. Perform action
      switch (action) {
        case 'download':
          final file = await PdfInvoiceService.savePdfFile(
              "Bill_${bill.billNo?.replaceAll('/', '_') ?? bill.id}.pdf",
              pdfBytes);
          if (mounted) {
            ToastMessage.show(context,
                message: "PDF Saved to Downloads", isError: false);
            OpenFile.open(file.path);
          }
          break;
        case 'print':
          await Printing.layoutPdf(
              onLayout: (format) async => pdfBytes,
              name: "Bill_${bill.billNo ?? bill.id}");
          break;
        case 'whatsapp':
          const platform = MethodChannel('com.soya_app.share/whatsapp');
          final fileName =
              "Bill_${bill.billNo?.replaceAll('/', '_') ?? bill.id}.pdf";
          final file = await PdfInvoiceService.savePdfFile(fileName, pdfBytes);

          final farmerPhoneRaw =
              bill.farmer?.phone?.replaceAll(RegExp(r'[^\d]+'), '') ?? '';
          final formattedPhone = farmerPhoneRaw.length == 10
              ? "91$farmerPhoneRaw"
              : farmerPhoneRaw;
          final message = "Hello ${bill.farmer?.name ?? 'Customer'},\n\n"
              "Here is your Goods Received Note (GRN) for the Soya purchase.\n\n"
              "Bill No: ${bill.billNo ?? 'N/A'}\n"
              "Net Payable: ₹${(bill.netPayable ?? 0).toStringAsFixed(2)}\n\n"
              "Thank you for your business!";

          if (Platform.isAndroid) {
            try {
              if (farmerPhoneRaw.isEmpty) {
                throw Exception("Farmer phone number is missing");
              }
              await platform.invokeMethod('shareToWhatsApp', {
                'filePath': file.path,
                'phoneNumber': formattedPhone,
                'message': message
              });
            } catch (e) {
              debugPrint("WhatsApp sharing error: $e");
              final webUrl = Uri.parse(
                  "https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}");
              if (await canLaunchUrl(webUrl)) {
                await launchUrl(webUrl, mode: LaunchMode.externalApplication);
              }
              if (mounted) {
                await Share.shareXFiles([XFile(file.path)],
                    text:
                        'Here is the bill for ${bill.farmer?.name ?? 'Customer'}.');
              }
            }
          } else {
            if (mounted) {
              await Share.shareXFiles([XFile(file.path)],
                  text:
                      'Here is the bill for ${bill.farmer?.name ?? 'Customer'}.');
            }
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ToastMessage.show(context, message: "Error: $e", isError: true);
      }
    }
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.receipt_long_outlined,
      title: "No Matching Bills Found",
      description:
          "Try adjusting your filters or search query to find the bills you're looking for.",
    );
  }

  Widget _buildReportTable(List<BillModel> bills) {
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
              columnSpacing: 24.w,
              headingRowHeight: 60.h,
              dataRowMinHeight: 60.h,
              dataRowMaxHeight: 85.h,
              headingRowColor:
                  WidgetStateProperty.all(appColor.withOpacity(0.1)),
              border: TableBorder(
                horizontalInside:
                    BorderSide(color: lightGreenColor, width: 1.h),
              ),
              columns: [
                _buildColumn("Profile"),
                _buildColumn("Farmer Name"),
                _buildColumn("Date"),
                _buildColumn("Net Weight"),
                _buildColumn("Total Amount"),
                _buildColumn("Bill Status"),
                _buildColumn("Payment Status"),
                _buildColumn("Location"),
                _buildColumn("Actions"),
              ],
              rows: bills.map((bill) {
                final farmerName = bill.farmer?.name ?? "N/A";
                final rawDate = bill.billDate ?? "N/A";
                final date =
                    rawDate.contains('T') ? rawDate.split('T')[0] : rawDate;

                // Use new specific fields if available, otherwise fallback to calculations
                final quantityValue = bill.primaryQuantity ??
                    bill.items?.fold<double>(
                        0,
                        (sum, item) =>
                            sum + (item.quantity?.toDouble() ?? 0)) ??
                    0.0;
                final unit = bill.primaryUnit ??
                    (bill.items?.isNotEmpty == true
                        ? bill.items!.first.unit
                        : "KG");
                final netWeightStr =
                    "${quantityValue.toStringAsFixed(2)} $unit";

                final amount = bill.netPayable ?? bill.totalAmount ?? 0;
                final status = bill.status ?? "Pending";

                return DataRow(
                  cells: [
                    DataCell(NameInitialsAvatar(
                      name: bill.farmer?.name ?? "N/A",
                      profileUrl: bill.farmer?.profileUrl,
                      radius: 14.r,
                      fontSize: 12.sp,
                    )),
                    DataCell(_buildNameCell(farmerName)),
                    DataCell(Text(date, style: _cellStyle())),
                    DataCell(Text(netWeightStr, style: _cellStyle())),
                    DataCell(Text("₹$amount",
                        style: _cellStyle(color: primeryColor, isBold: true))),
                    DataCell(_buildStatusBadge(status)),
                    DataCell(_buildPaymentStatusBadge(bill)),
                    DataCell(
                      SizedBox(
                        width: 150.w,
                        child: Text(
                          bill.billLocation ?? "N/A",
                          style: _cellStyle(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    DataCell(
                      PopupMenuButton<String>(
                        icon: Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: appColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.more_vert,
                              color: appColor, size: 18.sp),
                        ),
                        onOpened: () {
                          // Ensure search field is unfocused when menu opens
                          if (_searchFocusNode.hasFocus) {
                            _searchFocusNode.unfocus();
                          }
                        },
                        onSelected: (value) {
                          if (value == 'view') {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.billSummary,
                              arguments: bill.id,
                            );
                          } else {
                            _handlePdfAction(bill.id!, value);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.remove_red_eye,
                                    size: 18.sp, color: appColor),
                                SizedBox(width: 8.w),
                                Text("View Details",
                                    style: TextStyle(fontSize: 13.sp)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'download',
                            child: Row(
                              children: [
                                Icon(Icons.download,
                                    size: 18.sp, color: Colors.blue),
                                SizedBox(width: 8.w),
                                Text("Download PDF",
                                    style: TextStyle(fontSize: 13.sp)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'print',
                            child: Row(
                              children: [
                                Icon(Icons.print,
                                    size: 18.sp, color: greyColor),
                                SizedBox(width: 8.w),
                                Text("Print PDF",
                                    style: TextStyle(fontSize: 13.sp)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'whatsapp',
                            child: Row(
                              children: [
                                Icon(Icons.share,
                                    size: 18.sp, color: Colors.green),
                                SizedBox(width: 8.w),
                                Text("Share on WhatsApp",
                                    style: TextStyle(fontSize: 13.sp)),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildNameCell(String name) {
    return Text(name, style: _cellStyle(isBold: true));
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

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    Color bg = Colors.orange.withOpacity(0.1);

    String lowerStatus = status.toLowerCase();

    if (lowerStatus == 'completed' ||
        lowerStatus == 'finalized' ||
        lowerStatus.contains('paid')) {
      color = Colors.green;
      bg = Colors.green.withOpacity(0.1);
    } else if (lowerStatus.contains('reject') ||
        lowerStatus.contains('cancel')) {
      color = Colors.red;
      bg = Colors.red.withOpacity(0.1);
    } else if (lowerStatus == 'draft') {
      color = Colors.blueGrey;
      bg = Colors.blueGrey.withOpacity(0.1);
    } else if (lowerStatus == 'pending') {
      color = Colors.orange;
      bg = Colors.orange.withOpacity(0.1);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.bold,
          fontFamily: FontFamily.jost,
        ),
      ),
    );
  }

  Widget _buildPaymentStatusBadge(BillModel bill) {
    final status = bill.paymentStatus ?? 'PENDING';
    Color color;
    switch (status.toUpperCase()) {
      case 'PAID':
        color = Colors.green;
        break;
      case 'PENDING':
        color = Colors.orange;
        break;
      case 'HOLD':
        color = Colors.red;
        break;
      case 'PROCESSING':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }
    final bg = color.withOpacity(0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.bold,
              fontFamily: FontFamily.jost,
            ),
          ),
        ),
        if (status.toUpperCase() == 'HOLD')
          _HoldReasonWidget(billId: bill.id ?? ""),
      ],
    );
  }

  TextStyle _cellStyle({bool isBold = false, Color? color}) => TextStyle(
        fontSize: 13.sp,
        color: color ?? blackColor,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        fontFamily: FontFamily.jost,
      );
}

class BillFilterBottomSheet extends StatefulWidget {
  const BillFilterBottomSheet({super.key});

  @override
  State<BillFilterBottomSheet> createState() => _BillFilterBottomSheetState();
}

class _BillFilterBottomSheetState extends State<BillFilterBottomSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> _statuses = [
    'DRAFT',
    'PENDING',
    'COMPLETED',
    'CANCELLED',
    'FINALIZED',
    'PAID'
  ];
  List<String> _selectedStatuses = [];

  @override
  void initState() {
    super.initState();
    final controller = context.read<BillingController>();
    _startDate = controller.billStartDate;
    _endDate = controller.billEndDate;
    _selectedStatuses = List.from(controller.selectedBillStatuses);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Filter Bills",
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: FontFamily.georgia,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Text("Date Range", style: _sectionHeaderStyle()),
          SizedBox(height: 12.h),
          _buildDateRangePicker(),
          SizedBox(height: 24.h),
          Text("Status", style: _sectionHeaderStyle()),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _statuses.map((status) {
              final isSelected = _selectedStatuses.contains(status);
              return FilterChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedStatuses.add(status);
                    } else {
                      _selectedStatuses.remove(status);
                    }
                  });
                },
                selectedColor: appColor.withOpacity(0.2),
                checkmarkColor: appColor,
                labelStyle: TextStyle(
                  color: isSelected ? appColor : blackColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 32.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.read<BillingController>().clearBillFilters();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    side: BorderSide(color: appColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text("Clear All", style: TextStyle(color: appColor)),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<BillingController>().setBillFilters(
                          startDate: _startDate,
                          endDate: _endDate,
                          statuses: _selectedStatuses,
                        );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColor,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text("Apply Filters",
                      style: TextStyle(color: whiteColor)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _sectionHeaderStyle() => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: blackColor,
        fontFamily: FontFamily.jost,
      );

  Widget _buildDateRangePicker() {
    String dateRangeText = "Select Date Range";
    if (_startDate != null && _endDate != null) {
      dateRangeText =
          "${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM').format(_endDate!)}";
    }

    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDateRange: _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: appColor,
                  onPrimary: whiteColor,
                  onSurface: blackColor,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _startDate = picked.start;
            _endDate = picked.end;
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border.all(color: greyColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20.sp, color: appColor),
            SizedBox(width: 12.w),
            Text(
              dateRangeText,
              style: TextStyle(
                fontSize: 14.sp,
                color: _startDate != null ? blackColor : greyColor,
                fontFamily: FontFamily.jost,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldReasonWidget extends StatelessWidget {
  final String billId;

  const _HoldReasonWidget({required this.billId});

  @override
  Widget build(BuildContext context) {
    if (billId.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<dynamic>>(
      future: context.read<BillingController>().fetchPaymentActivities(billId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: SizedBox(
              width: 10.w,
              height: 10.w,
              child: const CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.red,
              ),
            ),
          );
        }
        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final activities = snapshot.data!;
        
        // Find the latest activity with status HOLD that has remarks
        final holdActivities = activities.where(
          (a) => a['newStatus']?.toString().toUpperCase() == 'HOLD' && a['remarks'] != null && a['remarks'].toString().isNotEmpty,
        ).toList();
        
        final activityToShow = holdActivities.isNotEmpty 
            ? holdActivities.first 
            : activities.firstWhere(
                (a) => a['remarks'] != null && a['remarks'].toString().isNotEmpty,
                orElse: () => null,
              );

        if (activityToShow != null && activityToShow['remarks'] != null && activityToShow['remarks'].toString().isNotEmpty) {
          return Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: SizedBox(
              width: 150.w,
              child: Text(
                'Reason: ${activityToShow['remarks']}',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
                  fontFamily: FontFamily.jost,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
