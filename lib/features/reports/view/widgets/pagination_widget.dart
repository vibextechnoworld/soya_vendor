import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: whiteColor,
        border: Border(top: BorderSide(color: lightGreenColor, width: 1.h)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPageButton(
            label: "Back",
            icon: Icons.arrow_back_ios,
            isEnabled: currentPage > 1,
            onTap: () => onPageChanged(currentPage - 1),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: appColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              "Page $currentPage of $totalPages",
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                fontFamily: FontFamily.jost,
                color: appColor,
              ),
            ),
          ),
          _buildPageButton(
            label: "Next",
            icon: Icons.arrow_forward_ios,
            isEnabled: currentPage < totalPages,
            onTap: () => onPageChanged(currentPage + 1),
            isForward: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({
    required String label,
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
    bool isForward = false,
  }) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border.all(
            color: isEnabled ? appColor : greyColor.withOpacity(0.3),
            width: 1.h,
          ),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isForward) ...[
              Icon(icon, size: 12.sp, color: isEnabled ? appColor : greyColor),
              SizedBox(width: 8.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: isEnabled ? appColor : greyColor,
                fontWeight: FontWeight.w500,
                fontFamily: FontFamily.jost,
              ),
            ),
            if (isForward) ...[
              SizedBox(width: 8.w),
              Icon(icon, size: 12.sp, color: isEnabled ? appColor : greyColor),
            ],
          ],
        ),
      ),
    );
  }
}
