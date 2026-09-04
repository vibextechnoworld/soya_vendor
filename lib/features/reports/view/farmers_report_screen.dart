import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soya_app/core/constants/api_constants.dart';
import 'package:soya_app/core/widgets/header_widget.dart';
import 'package:soya_app/core/widgets/name_initials_avatar.dart';
import 'package:soya_app/core/widgets/tost_message.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';

import 'package:provider/provider.dart';
import 'package:soya_app/features/home/controller/farmer_kyc_controller.dart';
import 'package:soya_app/features/home/model/farmer_bank_model.dart';
import 'package:soya_app/features/home/model/farmer_document_model.dart';
import 'package:soya_app/features/home/model/farmer_land_model.dart';
import 'package:soya_app/features/home/model/farmer_model.dart';
import 'package:soya_app/features/reports/view/widgets/pagination_widget.dart';
import 'package:soya_app/features/reports/view/widgets/farmer_bag_summary_dialog.dart';
import 'package:soya_app/core/widgets/empty_state_widget.dart';
import 'package:soya_app/routes/app_routes.dart';
import 'package:soya_app/features/home/controller/billing_controller.dart';
import 'package:soya_app/features/bottom_navigation_bar/controller/bottom_navbar_controller.dart';
import 'package:soya_app/features/reports/view/widgets/report_generation_date.dart';
import 'package:soya_app/util/string_utils.dart';

class FarmersReportScreen extends StatefulWidget {
  const FarmersReportScreen({super.key});

  @override
  State<FarmersReportScreen> createState() => _FarmersReportScreenState();
}

class _FarmersReportScreenState extends State<FarmersReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FarmerKycController>().listFarmers();
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
            Consumer<FarmerKycController>(
              builder: (context, controller, child) {
                if (controller.searchResults.isEmpty) {
                  return const SizedBox.shrink();
                }

                // Calculate showing range with capping
                final total = controller.totalItems;
                final itemsCount = controller.searchResults.length;
                final start =
                    total == 0 ? 0 : ((controller.currentPage - 1) * 10) + 1;
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
              child: Consumer<FarmerKycController>(
                builder: (context, controller, child) {
                  final filteredFarmers = controller.searchResults;

                  if (filteredFarmers.isEmpty && !controller.isLoading) {
                    return _buildEmptyState();
                  }

                  return Column(
                    children: [
                      if (controller.isLoading)
                        LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(appColor),
                        ),
                      if (filteredFarmers.isNotEmpty)
                        Expanded(child: _buildReportTable(filteredFarmers))
                      else if (controller.isLoading)
                        const Expanded(
                            child: Center(child: CircularProgressIndicator()))
                      else
                        const SizedBox.shrink(),
                      if (filteredFarmers.isNotEmpty)
                        PaginationWidget(
                          currentPage: controller.currentPage,
                          totalPages: controller.totalPages,
                          onPageChanged: (page) => controller.listFarmers(
                              page: page, search: controller.searchQuery),
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
                "Farmers Report",
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
    return Column(
      children: [
        Container(
          margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
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
            onChanged: (value) =>
                context.read<FarmerKycController>().onSearchChanged(value),
            decoration: InputDecoration(
              hintText: "Search by name or phone...",
              hintStyle: TextStyle(color: greyColor, fontSize: 14.sp),
              border: InputBorder.none,
              icon: Icon(Icons.search, color: appColor, size: 20.sp),
            ),
          ),
        ),
        _buildFilterOptions(),
      ],
    );
  }

  Widget _buildFilterOptions() {
    return Consumer<FarmerKycController>(
      builder: (context, controller, child) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              Icon(Icons.filter_list, color: appColor, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                "Filters:",
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: FontFamily.jost,
                  color: blackColor.withOpacity(0.7),
                ),
              ),
              SizedBox(width: 12.w),
              _buildFilterChip(
                label: "My Farmers",
                isSelected: controller.isMyFarmersOnly,
                onTap: () =>
                    controller.toggleMyFarmers(!controller.isMyFarmersOnly),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? appColor : whiteColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? appColor : appColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: appColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Padding(
                padding: EdgeInsets.only(right: 6.w),
                child: Icon(Icons.check, color: whiteColor, size: 14.sp),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? whiteColor : blackColor.withOpacity(0.8),
                fontFamily: FontFamily.jost,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSummary(
      {required int total, required int start, required int end}) {
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
              "Showing $start-$end of $total farmers",
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
      icon: Icons.people_outline,
      title: "No Matching Farmers Found",
      description:
          "We couldn't find any farmers matching your search criteria. Try a different name or phone number.",
    );
  }

  Widget _buildReportTable(List<FarmerData> farmers) {
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
              dataRowMaxHeight: 60.h,
              headingRowColor:
                  WidgetStateProperty.all(appColor.withOpacity(0.1)),
              border: TableBorder(
                horizontalInside:
                    BorderSide(color: lightGreenColor, width: 1.h),
              ),
              columns: [
                _buildColumn("Profile"),
                _buildColumn("Farmer Name"),
                _buildColumn("Phone No"),
                _buildColumn("Aadhaar"),
                _buildColumn("Total Lands"),
                _buildColumn("Total Land (acres)"),
                _buildColumn("Quantity Sold"),
                _buildColumn("KYC Status"),
                _buildColumn("Actions"),
              ],
              rows: farmers.map((farmer) {
                final name = titleCase(farmer.name ?? "N/A");
                final phone = farmer.phone ?? "N/A";
                final aadhaar = farmer.aadhaarNo ?? "N/A";

                return DataRow(
                  cells: [
                    DataCell(NameInitialsAvatar(
                      name: name,
                      profileUrl: farmer.profileUrl,
                      radius: 14.r,
                      fontSize: 12.sp,
                    )),
                    DataCell(_buildNameCell(name)),
                    DataCell(Text(phone, style: _cellStyle())),
                    DataCell(Text(aadhaar, style: _cellStyle())),
                    DataCell(Text('${farmer.totalLands ?? 0}', style: _cellStyle())),
                    DataCell(Text('${farmer.totalLandArea ?? 0}', style: _cellStyle())),
                    DataCell(Text('${farmer.quantitySold ?? 0}', style: _cellStyle())),
                    DataCell(_buildStatusBadge(
                        "Verified")), // Mock status for now as API model might not have it directly
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.receipt_long_outlined,
                                color: primeryColor, size: 20.sp),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.billingReport,
                                arguments: name,
                              );
                            },
                            tooltip: "View Bills",
                          ),
                          IconButton(
                            icon: Icon(Icons.inventory_2_outlined,
                                color: Colors.orange, size: 20.sp),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => FarmerBagSummaryDialog(
                                  farmerId: farmer.id ?? "",
                                  farmerName:
                                      farmer.name == null ? "Farmer" : titleCase(farmer.name),
                                ),
                              );
                            },
                            tooltip: "Bag Summary",
                          ),
                          IconButton(
                            icon: Icon(Icons.bolt,
                                color: Colors.amber[800], size: 20.sp),
                            onPressed: () {
                              _showInstantAdvanceDialog(context, farmer);
                            },
                            tooltip: "Advance Payment",
                          ),
                          IconButton(
                            icon: Icon(Icons.remove_red_eye,
                                color: appColor, size: 20.sp),
                            onPressed: () =>
                                _showFarmerDetails(context, farmer),
                            tooltip: "View Detail",
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10.sp,
          color: Colors.green,
          fontWeight: FontWeight.bold,
          fontFamily: FontFamily.jost,
        ),
      ),
    );
  }

  TextStyle _cellStyle({bool isBold = false, Color? color}) => TextStyle(
        fontSize: 13.sp,
        color: color ?? blackColor,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        fontFamily: FontFamily.jost,
      );

  void _showFarmerDetails(BuildContext context, FarmerData farmer) {
    if (farmer.id != null && farmer.id!.isNotEmpty) {
      final kyc = context.read<FarmerKycController>();
      final hasDocs = (farmer.documents != null && farmer.documents!.isNotEmpty);
      if (!hasDocs) kyc.fetchFarmerDetails(farmer.id!);
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.80,
        decoration: BoxDecoration(
          color: lightGreenColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        ),
        child: Column(
          children: [
            // Handle Bar
            Container(
              margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
              width: 50.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: greyColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
              child: Row(
                children: [
                  NameInitialsAvatar(
                    name: farmer.name ?? "",
                    profileUrl: farmer.profileUrl,
                    radius: 35.r,
                    fontSize: 28.sp,
                    fontFamily: FontFamily.georgia,
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleCase(farmer.name),
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: FontFamily.georgia,
                            color: blackColor,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: appColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            "FARMER PROFILE",
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: appColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Details List
            Expanded(
              child: Consumer<FarmerKycController>(
                builder: (context, controller, child) {
                  return ListView(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                    children: [
                      _buildDetailCard(
                        title: "Identity Details",
                        icon: Icons.person_outline,
                        items: [
                          {
                            "label": "Aadhaar No",
                            "value": farmer.aadhaarNo ?? "N/A"
                          },
                          {"label": "PAN No", "value": farmer.panNo ?? "N/A"},
                        ],
                      ),
                      SizedBox(height: 16.h),
                      _buildDetailCard(
                        title: "Location Details",
                        icon: Icons.location_on_outlined,
                        items: [
                          {
                            "label": "Village",
                            "value": farmer.villageAdd ?? "N/A"
                          },
                          {
                            "label": "Gut Number",
                            "value": farmer.gutNumber ?? "N/A"
                          },
                          {"label": "Taluka", "value": farmer.taluka ?? "N/A"},
                          {
                            "label": "District",
                            "value": farmer.district ?? "N/A"
                          },
                        ],
                      ),
                      SizedBox(height: 16.h),
                      _buildDetailCard(
                        title: "Contact Details",
                        icon: Icons.contact_mail_outlined,
                        items: [
                          {"label": "Phone", "value": farmer.phone ?? "N/A"},
                          {"label": "Email", "value": farmer.email ?? "N/A"},
                        ],
                      ),
                      SizedBox(height: 16.h),
                      _buildDetailCard(
                        title: "Registration Info",
                        icon: Icons.assignment_ind_outlined,
                        items: [
                          {
                            "label": "Vendor Name",
                            "value": farmer.vendorName ?? "N/A"
                          },
                          {
                            "label": "KYC Documents",
                            "value": (farmer.totalKycDocuments ?? 0).toString()
                          },
                          {
                            "label": "Total Lands",
                            "value": (farmer.totalLands ?? 0).toString()
                          },
                        ],
                      ),
                      SizedBox(height: 16.h),
                      _buildKycDocumentsCard(context, controller, farmer),
                      SizedBox(height: 16.h),
                      _buildDetailCard(
                        title: "System Info",
                        icon: Icons.info_outline,
                        items: [
                          {
                            "label": "Created At",
                            "value": _formatDateTime(farmer.createdAt)
                          },
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            // Action Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.pushNamed(
                    context,
                    AppRoutes.billingReport,
                    arguments: farmer.name,
                  );                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColor,
                  foregroundColor: whiteColor,
                  minimumSize: Size(double.infinity, 50.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      "VIEW FARMER BILLS",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: FontFamily.jost,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  showDialog(
                    context: context,
                    builder: (context) => FarmerBagSummaryDialog(
                      farmerId: farmer.id ?? "",
                      farmerName: titleCaseOr(farmer.name, "Farmer"),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: whiteColor,
                  minimumSize: Size(double.infinity, 50.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      "BAG SUMMARY",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: FontFamily.jost,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  _showInstantAdvanceDialog(context, farmer);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[800],
                  foregroundColor: whiteColor,
                  minimumSize: Size(double.infinity, 50.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      "ADVANCE PAYMENT",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: FontFamily.jost,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.pop(context); // Close report screen
                  
                  // Set active farmer in KYC controller
                  final kycController = Provider.of<FarmerKycController>(context, listen: false);
                  kycController.setSelectedFarmer(farmer);

                  // Switch bottom navbar index to Form tab & select KYC view
                  final navBarController = Provider.of<BottomNavBarController>(context, listen: false);
                  navBarController.updateFormView(FormView.farmerKYC);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primeryColor,
                  foregroundColor: whiteColor,
                  minimumSize: Size(double.infinity, 50.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_note, size: 22.sp),
                    SizedBox(width: 8.w),
                    Text(
                      "UPDATE KYC / LAND DETAILS",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: FontFamily.jost,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required List<Map<String, String>> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: blackColor.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
            child: Row(
              children: [
                Icon(icon, size: 20.sp, color: appColor),
                SizedBox(width: 10.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: blackColor.withOpacity(0.8),
                    fontFamily: FontFamily.jost,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: items.map((item) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100.w,
                        child: Text(
                          item["label"]!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: greyColor,
                            fontFamily: FontFamily.jost,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item["value"]!,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: blackColor,
                            fontFamily: FontFamily.jost,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKycDocumentsCard(
      BuildContext context, FarmerKycController controller, FarmerData farmer) {
    final FarmerData source = controller.fetchedFarmerDetail ?? farmer;

    final List<_DocEntry> entries = <_DocEntry>[];

    final List<String> landUrls = <String>[];
    final List<DocumentData> kycDocs =
        source.documents ?? controller.fetchedDocuments ?? [];
    for (final doc in kycDocs) {
      final List<String> urlList = (doc.documentUrls?.isNotEmpty ?? false)
          ? doc.documentUrls!
          : (doc.imageUrl != null && doc.imageUrl!.isNotEmpty
              ? [doc.imageUrl!]
              : []);
      if (urlList.isEmpty) continue;
      final String type = doc.type ?? "Document";
      if (type == 'LAND_712' || type == 'LAND') {
        landUrls.addAll(urlList);
      } else {
        entries.add(_DocEntry(
          type: type,
          label: _docTypeLabel(type) ?? type,
          urls: urlList,
        ));
      }
    }

    final List<LandData> lands = source.lands ?? controller.fetchedLands ?? [];
    for (final land in lands) {
      final List<String> urls = (land.documentUrls?.isNotEmpty ?? false)
          ? land.documentUrls!
          : (land.documentUrl != null && land.documentUrl!.isNotEmpty
              ? [land.documentUrl!]
              : []);
      landUrls.addAll(urls);
    }

    if (landUrls.isNotEmpty) {
      entries.insert(0, _DocEntry(
        type: "LAND",
        label: "Land Details",
        urls: landUrls.toSet().toList(),
      ));
    }

    final List<BankData> banks = source.banks ?? controller.fetchedBank ?? [];
    for (final bank in banks) {
      final List<String> urls = (bank.passbookImages?.isNotEmpty ?? false)
          ? bank.passbookImages!
          : (bank.passbookImage != null && bank.passbookImage!.isNotEmpty
              ? [bank.passbookImage!]
              : []);
      if (urls.isEmpty) continue;
      entries.add(_DocEntry(
        type: "PASSBOOK",
        label: "Bank Passbook",
        urls: urls,
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: blackColor.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
            child: Row(
              children: [
                Icon(Icons.folder_open_outlined, size: 20.sp, color: appColor),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    "KYC Documents",
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: blackColor.withOpacity(0.8),
                      fontFamily: FontFamily.jost,
                    ),
                  ),
                ),
                if (entries.isEmpty)
                  SizedBox(
                    width: 18.sp,
                    height: 18.sp,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: appColor,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (entries.isEmpty)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                "No documents uploaded yet",
                style: TextStyle(
                  fontSize: 13.sp,
                  color: greyColor,
                  fontFamily: FontFamily.jost,
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: entries.map((entry) {
                  final bool allImages =
                      entry.urls.every((u) => _isImageDoc(u));
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 14.sp,
                              color: appColor,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                entry.label,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: blackColor,
                                  fontFamily: FontFamily.jost,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        SizedBox(
                          height: 76.h,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: entry.urls.length,
                            separatorBuilder: (_, __) => SizedBox(width: 8.w),
                            itemBuilder: (context, index) {
                              final url = entry.urls[index];
                              final fullUrl = _buildDocViewUrl(url);
                              if (allImages) {
                                return GestureDetector(
                                  onTap: () =>
                                      _showDocThumbnailViewer(context, entry,
                                          index),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: Container(
                                      width: 76.w,
                                      height: 76.h,
                                      color: greyColor.withOpacity(0.15),
                                      child: Image.network(
                                        fullUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stack) {
                                          return Center(
                                            child: Icon(
                                              Icons.broken_image_outlined,
                                              color: greyColor,
                                            ),
                                          );
                                        },
                                        loadingBuilder:
                                            (context, child, progress) {
                                          if (progress == null) return child;
                                          return Center(
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: appColor,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return GestureDetector(
                                onTap: () =>
                                    _viewUrls(context, [url]),
                                child: Container(
                                  width: 76.w,
                                  height: 76.h,
                                  decoration: BoxDecoration(
                                    color: appColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isPdfDoc(url)
                                            ? Icons.picture_as_pdf_outlined
                                            : Icons.file_copy_outlined,
                                        color: appColor,
                                        size: 24.sp,
                                      ),
                                      SizedBox(height: 4.h),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 4.w),
                                        child: Text(
                                          _fileName(url),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 8.sp,
                                            color: blackColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  String? _docTypeLabel(String? type) {
    switch (type) {
      case 'AADHAAR':
        return 'Aadhaar Card';
      case 'PAN':
        return 'PAN Card';
      case 'DRIVING_LICENSE':
        return 'Driving License';
      case 'LAND_712':
        return 'Land 712';
      case 'LAND':
        return 'Land';
      case 'PASSBOOK':
        return 'Bank Passbook';
      default:
        return type;
    }
  }

  String _buildDocViewUrl(String url) {
    if (url.startsWith('http')) return url;
    final path = url.startsWith('/') ? url : '/$url';
    return '${ApiConstants.imageBaseUrl}$path';
  }

  bool _isImageDoc(String url) {
    final path = url.split('?').first;
    final ext =
        path.contains('.') ? path.split('.').last.toLowerCase() : '';
    return ['jpg', 'jpeg', 'png', 'bmp', 'gif', 'webp'].contains(ext);
  }

  bool _isPdfDoc(String url) {
    final path = url.split('?').first;
    return path.toLowerCase().endsWith('.pdf');
  }

  String _fileName(String url) {
    final cleaned = url.split('?').first;
    final segments = cleaned.split('/');
    final name = segments.isNotEmpty ? segments.last : cleaned;
    return name.isEmpty ? "document" : name;
  }

  Future<void> _viewUrls(BuildContext context, List<String> urlList) async {
    if (urlList.length == 1) {
      final url = urlList.first;
      if (_isImageDoc(url)) {
        _showDocFullImage(context, _buildDocViewUrl(url));
      } else {
        await _openNetworkDocument(context, url);
      }
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: whiteColor,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final url in urlList)
              ListTile(
                leading: Icon(
                  _isImageDoc(url)
                      ? Icons.image_outlined
                      : Icons.picture_as_pdf_outlined,
                  color: appColor,
                ),
                title: Text(
                  _fileName(url),
                  style: const TextStyle(fontFamily: FontFamily.jost),
                ),
                onTap: () => Navigator.pop(context, url),
              ),
          ],
        ),
      ),
    );

    if (selected != null && context.mounted) {
      if (_isImageDoc(selected)) {
        _showDocFullImage(context, _buildDocViewUrl(selected));
      } else {
        await _openNetworkDocument(context, selected);
      }
    }
  }

  void _showDocThumbnailViewer(
      BuildContext context, _DocEntry entry, int initialIndex) {
    final List<String> imageUrls = [
      for (final u in entry.urls)
        if (_isImageDoc(u)) _buildDocViewUrl(u)
    ];
    if (imageUrls.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: imageUrls.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Center(
                  child: Image.network(
                    imageUrls[index],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.error_outline,
                            color: Colors.white, size: 40),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child:
                            CircularProgressIndicator(color: Colors.white),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 24.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDocFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Stack(
            children: [
              Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.error_outline,
                          color: Colors.white, size: 40),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 24.sp),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openNetworkDocument(BuildContext context, String url) async {
    try {
      final fullUrl = _buildDocViewUrl(url);
      final res = await http
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 60));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
        if (context.mounted) {
          ToastMessage.show(context,
              message: 'Unable to download document', isError: true);
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final ext = _isPdfDoc(url) ? '.pdf' : '.jpg';
      final file = File(
          '${dir.path}/doc_${DateTime.now().millisecondsSinceEpoch}$ext');
      await file.writeAsBytes(res.bodyBytes);
      if (!context.mounted) return;
      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done && context.mounted) {
        ToastMessage.show(context,
            message: 'No app found to open this file', isError: true);
      }
    } catch (e) {
      debugPrint('Error opening document: $e');
      if (context.mounted) {
        ToastMessage.show(context,
            message: 'Unable to open this file', isError: true);
      }
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();

      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];

      final day = dateTime.day.toString().padLeft(2, '0');
      final month = months[dateTime.month - 1];
      final year = dateTime.year;

      int hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';

      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;

      return '$day $month $year, $hour:$minute $period';
    } catch (e) {
      return dateStr;
    }
  }

  void _showInstantAdvanceDialog(BuildContext context, FarmerData farmer) {
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
              builder: (context, billingController, child) {
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
                                      farmer.name == null
                                          ? 'Farmer'
                                          : titleCase(farmer.name),
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
                            SizedBox(height: 12.h),

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
                                hintText: 'Enter advance amount',
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
                              value: selectedReason,
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
                      onPressed: () => Navigator.pop(context),
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
                      onPressed: billingController.isLoading
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                final amount =
                                    double.parse(amountController.text);
                                final remarks = remarksController.text;

                                // Call controller method
                                final success = await billingController
                                    .recordInstantAdvance(
                                  context: context,
                                  farmerId: farmer.id ?? '',
                                  amount: amount,
                                  reason: selectedReason,
                                  remarks: remarks,
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
                          vertical: 10.h,
                        ),
                      ),
                      child: billingController.isLoading
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
                              'Submit',
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

class _DocEntry {
  final String type;
  final String label;
  final List<String> urls;

  _DocEntry({
    required this.type,
    required this.label,
    required this.urls,
  });
}
