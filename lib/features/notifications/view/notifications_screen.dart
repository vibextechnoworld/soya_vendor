import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:soya_app/core/controller/shimmer_controller.dart';
import 'package:soya_app/core/widgets/shimmer_box.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shimmer = context.watch<ShimmerController>();

    return Scaffold(
      backgroundColor: lightGreenColor,
      appBar: _buildAppBar(context),
      body: shimmer.isLoading
          ? _buildShimmer(context)
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Today'),
                  _buildNotificationItem(
                    context,
                    'New request on your item',
                    'A user wants to take your office chair.',
                    '10 min ago',
                    'assets/profile1.png',
                    false,
                  ),
                  _buildNotificationItem(
                    context,
                    'New request on your item',
                    'A user wants to take your office chair.',
                    '10:30 AM',
                    'assets/profile1.png',
                    true,
                  ),
                  _buildSectionHeader('This Week'),
                  _buildNotificationItem(
                    context,
                    'New request on your item',
                    'A user wants to take your office chair.',
                    'Mon, 5:00 PM',
                    'assets/profile1.png',
                    false,
                  ),
                  _buildNotificationItem(
                    context,
                    'New request on your item',
                    'A user wants to take your office chair.',
                    'Tue, 11:00 AM',
                    'assets/profile1.png',
                    true,
                  ),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: primeryColor,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios, color: whiteColor),
      ),
      centerTitle: true,
      title: Text(
        'Notifications',
        style: TextStyle(
          color: whiteColor,
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          fontFamily: FontFamily.openSans,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: greyColorOpacity2),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          fontFamily: FontFamily.openSans,
          color: blackColor,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    String title,
    String subtitle,
    String time,
    String imagePath,
    bool isRead,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFFE8F1FF) : whiteColor,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: greyColor.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30.r,
            backgroundImage: AssetImage(imagePath),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: FontFamily.openSans,
                          color: blackColor,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80.w,
                      child: Text(
                        time,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: greyColor,
                          fontFamily: FontFamily.openSans,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: greyColor,
                    fontFamily: FontFamily.openSans,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerSection('Today'),
          _buildShimmerItem(),
          _buildShimmerItem(),
          _buildShimmerSection('This Week'),
          _buildShimmerItem(),
          _buildShimmerItem(),
        ],
      ),
    );
  }

  Widget _buildShimmerSection(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 8.h),
      child: Row(
        children: [
          ShimmerBox(height: 18.h, width: 80.w),
        ],
      ),
    );
  }

  Widget _buildShimmerItem() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: greyColor.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(height: 60.r, width: 60.r, radius: 30.r),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(height: 14.h, width: 140.w),
                    ShimmerBox(height: 10.h, width: 60.w),
                  ],
                ),
                SizedBox(height: 8.h),
                ShimmerBox(height: 12.h, width: double.infinity),
                SizedBox(height: 4.h),
                ShimmerBox(height: 12.h, width: 150.w),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
