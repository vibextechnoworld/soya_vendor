import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:soya_app/features/home/controller/stock_controller.dart';
import 'package:soya_app/features/home/model/farmer_bag_return_due_model.dart';
import 'package:soya_app/core/widgets/tost_message.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';

class FarmerBagSummaryDialog extends StatefulWidget {
  final String farmerId;
  final String farmerName;

  const FarmerBagSummaryDialog({
    super.key,
    required this.farmerId,
    required this.farmerName,
  });

  @override
  State<FarmerBagSummaryDialog> createState() => _FarmerBagSummaryDialogState();
}

class _FarmerBagSummaryDialogState extends State<FarmerBagSummaryDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockController>().fetchFarmerBagReturnDue(widget.farmerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        decoration: BoxDecoration(
          color: lightGreenColor,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: blackColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: Consumer<StockController>(
                builder: (context, controller, child) {
                  if (controller.isLoading) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.h),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  final data = controller.farmerBagReturnDue;

                  if (data == null) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.h),
                      child: Center(
                        child: Text(
                          controller.errorMessage ?? 'No data available',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: greyColor,
                            fontFamily: FontFamily.jost,
                          ),
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBagTypeBadge(data.goniTypeName ?? "N/A"),
                        SizedBox(height: 20.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                label: "Received",
                                value: "${data.receivedFromFarmer ?? 0}",
                                color: primeryColor,
                                icon: Icons.download_outlined,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildStatCard(
                                label: "Returned",
                                value: "${data.returnedToFarmer ?? 0}",
                                color: Colors.green,
                                icon: Icons.upload_outlined,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        _buildPendingCard(data.returnDue ?? 0),
                        if ((data.returnDue ?? 0) > 0) ...[
                          SizedBox(height: 12.h),
                          _buildReturnBagsButton(context, data),
                        ],
                        SizedBox(height: 24.h),
                        _buildCloseButton(context),
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

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bag Summary",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: FontFamily.georgia,
                    color: blackColor,
                  ),
                ),
                Text(
                  widget.farmerName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: greyColor,
                    fontFamily: FontFamily.jost,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: greyColor),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildBagTypeBadge(String type) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: appColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: appColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 16.sp, color: appColor),
          SizedBox(width: 8.w),
          Text(
            type,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: appColor,
              fontFamily: FontFamily.jost,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16.sp, color: color),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: FontFamily.jost,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: greyColor,
              fontFamily: FontFamily.jost,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(int count) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.pending_actions_outlined,
                size: 20.sp, color: Colors.orange),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$count Bags",
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  fontFamily: FontFamily.jost,
                ),
              ),
              Text(
                "Return Due (Pending)",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.orange.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                  fontFamily: FontFamily.jost,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.pop(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: greyColor.withOpacity(0.1),
        foregroundColor: greyColor,
        minimumSize: Size(double.infinity, 50.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        elevation: 0,
      ),
      child: Text(
        "CLOSE",
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          fontFamily: FontFamily.jost,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildReturnBagsButton(
      BuildContext context, FarmerBagReturnDueData data) {
    return ElevatedButton(
      onPressed: () => _showReturnBagsDialog(context, data),
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
          Icon(Icons.assignment_return_outlined, size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            "RETURN BAGS",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              fontFamily: FontFamily.jost,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  void _showReturnBagsDialog(
      BuildContext context, FarmerBagReturnDueData data) {
    final countController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text("Return Bags",
            style: TextStyle(
                fontFamily: FontFamily.georgia, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Farmer: ${widget.farmerName}",
                  style: TextStyle(
                      fontSize: 14.sp,
                      color: greyColor,
                      fontFamily: FontFamily.jost)),
              Text("Bag Type: ${data.goniTypeName}",
                  style: TextStyle(
                      fontSize: 14.sp,
                      color: greyColor,
                      fontFamily: FontFamily.jost)),
              Text("Due: ${data.returnDue} Bags",
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontFamily: FontFamily.jost)),
              SizedBox(height: 16.h),
              TextFormField(
                controller: countController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Bag Count",
                  hintText: "Enter number of bags",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter bag count";
                  }
                  final count = int.tryParse(value);
                  if (count == null || count <= 0) {
                    return "Please enter a valid count";
                  }
                  if (count > (data.returnDue ?? 0)) {
                    return "Cannot return more than due";
                  }
                  return null;
                },
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: "Notes (Optional)",
                  hintText: "Enter notes (optional)",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: TextStyle(color: greyColor)),
          ),
          Consumer<StockController>(
            builder: (context, controller, _) {
              return ElevatedButton(
                onPressed: controller.isLoading
                    ? null
                    : () async {
                        if (formKey.currentState?.validate() ?? false) {
                          final success = await controller.returnBagsToFarmer(
                              context: context,
                              farmerId: widget.farmerId,
                              goniTypeId: data.goniTypeId ?? "",
                              bagCount: int.parse(countController.text),
                               notes: notesController.text.trim());

                          if (success) {
                            if (context.mounted) {
                              Navigator.pop(context); // Close input dialog
                              ToastMessage.show(context,
                                  message: "Bags returned to farmer successfully",
                                  isError: false);
                              controller
                                  .fetchFarmerBagReturnDue(widget.farmerId);
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primeryColor,
                  foregroundColor: whiteColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                  minimumSize: Size(100.w, 40.h),
                ),
                child: controller.isLoading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
                        ),
                      )
                    : const Text("CONFIRM"),
              );
            },
          ),
        ],
      ),
    );
  }
}
