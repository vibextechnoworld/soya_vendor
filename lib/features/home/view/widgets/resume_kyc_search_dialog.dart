import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:soya_app/features/home/controller/farmer_kyc_controller.dart';
import 'package:soya_app/routes/app_routes.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';

class ResumeKycSearchDialog extends StatefulWidget {
  const ResumeKycSearchDialog({super.key});

  @override
  State<ResumeKycSearchDialog> createState() => _ResumeKycSearchDialogState();
}

class _ResumeKycSearchDialogState extends State<ResumeKycSearchDialog> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FarmerKycController>().searchFarmers('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        padding: EdgeInsets.all(20.w),
        constraints: BoxConstraints(maxHeight: 500.h),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resume Farmer KYC',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: FontFamily.jost,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _searchController,
              onChanged: (val) {
                context
                    .read<FarmerKycController>()
                    .onSuggestionSearchChanged(val);
              },
              decoration: InputDecoration(
                hintText: 'Search by Name/Phone/Aadhaar',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: Consumer<FarmerKycController>(
                builder: (context, controller, child) {
                  if (controller.isSearching) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final results = controller.searchResults;
                  if (results.isEmpty) {
                    return Center(
                      child: Text(
                        'No pending KYC farmers found',
                        style: TextStyle(
                            color: greyColor, fontFamily: FontFamily.jost),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final farmer = results[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primeryColor.withOpacity(0.1),
                          child: Icon(Icons.person, color: primeryColor),
                        ),
                        title: Text(
                          farmer.name ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: FontFamily.jost,
                          ),
                        ),
                        subtitle: Text(
                          'Phone: ${farmer.phone ?? "N/A"}',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        onTap: () {
                          controller.setSelectedFarmer(farmer);
                          Navigator.pop(context);
                          Navigator.pushNamed(context, AppRoutes.farmerKyc);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
