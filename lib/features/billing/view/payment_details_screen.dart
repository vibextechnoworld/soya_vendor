import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soya_app/core/widgets/header_widget.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';

class PaymentDetailsScreen extends StatelessWidget {
  const PaymentDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreenColor,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: Container(
                    margin: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: whiteColor,
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DataTable(
                      columnSpacing: 20.w,
                      headingRowColor: WidgetStateProperty.all(whiteColor),
                      dataRowColor: WidgetStateProperty.all(whiteColor),
                      columns: const [
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Payment Mode')),
                        DataColumn(label: Text('Beneficiary Name')),
                        DataColumn(label: Text('Requested Amount')),
                        DataColumn(label: Text('Final Amount')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Requested on')),
                        DataColumn(label: Text('View Detail')),
                      ],
                      rows: List.generate(
                        10,
                        (index) => DataRow(
                          cells: [
                            DataCell(_buildStatusIcon(index)),
                            DataCell(Text(_getPaymentMode(index),
                                style: _cellStyle())),
                            DataCell(
                                Text('Sangita sharma', style: _cellStyle())),
                            DataCell(Text('Rs 10,000/-', style: _cellStyle())),
                            DataCell(Text('Rs 10,000/-', style: _cellStyle())),
                            DataCell(_buildStatusBadge(index)),
                            DataCell(Text('25-09-26', style: _cellStyle())),
                            DataCell(Icon(Icons.remove_red_eye,
                                color: const Color(0xFF1976D2), size: 20.sp)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(int index) {
    if (index % 4 == 2 || index % 4 == 3) {
      // Info icon for pending/fail
      return Icon(Icons.info_outline, color: Colors.red, size: 20.sp);
    }
    if (index % 4 == 1 && index == 5) {
      // Just some variation
      return Icon(Icons.check, color: Colors.blue, size: 20.sp);
    }
    return Icon(Icons.check_circle_outline,
        color: const Color(0xFF00C853), size: 20.sp);
  }

  String _getPaymentMode(int index) {
    if (index % 3 == 0) return 'UPI';
    if (index % 3 == 1) return 'Cash';
    return 'Net Banking';
  }

  Widget _buildStatusBadge(int index) {
    String text = 'Fully Paid';
    Color color = const Color(0xFF00C853);
    Color bg = const Color(0xFFE8F5E9);

    if (index % 4 == 2) {
      text = 'Not Paid';
      color = Colors.red;
      bg = const Color(0xFFFFEBEE);
    } else if (index % 4 == 3) {
      // Pending
      text = 'pending';
      color = Colors.blue;
      bg = const Color(0xFFE3F2FD);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  TextStyle _cellStyle() => TextStyle(
        fontSize: 12.sp,
        color: blackColor,
        fontFamily: FontFamily.jost,
      );
}
