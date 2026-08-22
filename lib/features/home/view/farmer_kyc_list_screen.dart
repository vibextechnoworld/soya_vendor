import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:soya_app/core/widgets/header_widget.dart';
import 'package:soya_app/features/home/controller/farmer_kyc_controller.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';
import 'package:soya_app/util/string_utils.dart';

class FarmerKycListScreen extends StatefulWidget {
  const FarmerKycListScreen({super.key});

  @override
  State<FarmerKycListScreen> createState() => _FarmerKycListScreenState();
}

class _FarmerKycListScreenState extends State<FarmerKycListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FarmerKycController>().fetchNonKycFarmers();
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
              child: Consumer<FarmerKycController>(
                builder: (context, controller, child) {
                  return Column(
                    children: [
                      SizedBox(height: 10.h),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: Icon(Icons.arrow_back_ios,
                                  color: blackColor, size: 24.sp),
                            ),
                          ),
                          Text(
                            'Action Required',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: FontFamily.georgia,
                              color: blackColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      _buildSearchBar(context),
                      Expanded(
                        child: _buildListBody(controller),
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

  Widget _buildListBody(FarmerKycController controller) {
    if (controller.isLoadingNonKycFarmers) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 3),
      );
    }

    final farmers = controller.nonKycFarmers
        .where((f) =>
            f.kycStatus == 'PENDING_VERIFICATION' || f.kycStatus == 'REJECTED')
        .toList();

    if (farmers.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 60.sp),
              SizedBox(height: 16.h),
              Text(
                "All KYC completed",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontFamily: FontFamily.jost,
                  fontWeight: FontWeight.bold,
                  color: blackColor,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "You have no pending or rejected KYC actions remaining.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: FontFamily.jost,
                  color: greyColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      itemCount: farmers.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final farmer = farmers[index];
        final isRejected = farmer.kycStatus == 'REJECTED';

        return InkWell(
          onTap: () {
            Navigator.pop(context, farmer);
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isRejected
                    ? Colors.red.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        titleCaseOr(farmer.name, 'Unknown Farmer'),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontFamily: FontFamily.jost,
                          fontWeight: FontWeight.bold,
                          color: blackColor,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isRejected
                            ? Colors.red.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        isRejected ? 'Rejected' : 'Pending',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color:
                              isRejected ? Colors.red : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'Aadhaar: ${farmer.aadhaarNo ?? 'N/A'} | Phone: ${farmer.phone ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontFamily: FontFamily.jost,
                    color: greyColor,
                  ),
                ),
                if (farmer.villageAdd != null &&
                    farmer.villageAdd!.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Location: ${farmer.villageAdd}, ${farmer.taluka ?? ''}, ${farmer.district ?? ''}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontFamily: FontFamily.jost,
                      color: greyColor,
                    ),
                  ),
                ],
                if (isRejected &&
                    farmer.kycRejectionReason != null &&
                    farmer.kycRejectionReason!.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.red.withOpacity(0.1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontFamily: FontFamily.jost,
                                color: Colors.red.shade800,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Rejection Reason: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: farmer.kycRejectionReason),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
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
                context.read<FarmerKycController>().onNonKycSearchChanged(value),
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
                isSelected: controller.isNonKycMyFarmersOnly,
                onTap: () =>
                    controller.toggleNonKycMyFarmers(!controller.isNonKycMyFarmersOnly),
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
}
