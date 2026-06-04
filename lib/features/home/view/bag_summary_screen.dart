import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:soya_app/features/home/controller/stock_controller.dart';
import 'package:soya_app/features/bottom_navigation_bar/controller/bottom_navbar_controller.dart';
import 'package:soya_app/features/home/view/widgets/bag_summary_tabs.dart';
import 'package:soya_app/core/widgets/header_widget.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';

class BagSummaryScreen extends StatefulWidget {
  const BagSummaryScreen({super.key});

  @override
  State<BagSummaryScreen> createState() => _BagSummaryScreenState();
}

class _BagSummaryScreenState extends State<BagSummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockController>().fetchVendorBagSummary();
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
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        context
                            .read<BottomNavBarController>()
                            .updateFormView(FormView.selection);
                      }
                    },
                    icon: Icon(Icons.arrow_back_ios,
                        color: blackColor, size: 24.sp),
                  ),
                  Text(
                    'Bag Summary',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: FontFamily.jost,
                      color: blackColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<StockController>(
                builder: (context, controller, child) {
                  if (controller.isLoading && controller.bagSummary == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.bagSummary == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 64.sp, color: greyColor),
                          SizedBox(height: 16.h),
                          Text(
                            'No Bag Summary Found',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: greyColor,
                              fontFamily: FontFamily.jost,
                            ),
                          ),
                          TextButton(
                            onPressed: () => controller.fetchVendorBagSummary(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  return BagSummaryContentView(controller: controller);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
