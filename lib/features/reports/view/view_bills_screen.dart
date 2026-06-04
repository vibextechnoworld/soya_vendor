import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soya_app/core/widgets/header_widget.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';

class ViewBillsScreen extends StatelessWidget {
  const ViewBillsScreen({super.key});

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
                        DataColumn(label: Text('')),
                        DataColumn(label: Text('Farmer Name')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Quality Check')),
                        DataColumn(label: Text('Gross Weight (kg)')),
                        DataColumn(label: Text('Tare Weight (kg)')),
                        DataColumn(label: Text('Net Weight (kg)')),
                        DataColumn(label: Text('Number of Bags')),
                        DataColumn(label: Text('Rate per Quintal (₹)')),
                        DataColumn(label: Text('Total Amount (₹)')),
                      ],
                      rows: List.generate(
                        10,
                        (index) => DataRow(
                          cells: [
                            DataCell(Icon(Icons.circle,
                                color: _getStatusColor(index), size: 12.sp)),
                            DataCell(Text('Nikhil Valmik Bare',
                                style: _cellStyle())),
                            DataCell(Text('25-09-26', style: _cellStyle())),
                            DataCell(Text('30 kg', style: _cellStyle())),
                            DataCell(Text('30 kg', style: _cellStyle())),
                            DataCell(Text('30 kg', style: _cellStyle())),
                            DataCell(Text('30 kg', style: _cellStyle())),
                            DataCell(Text('02', style: _cellStyle())),
                            DataCell(Text('Rs4000/-', style: _cellStyle())),
                            DataCell(Text('Rs10,000/-', style: _cellStyle())),
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

  Color _getStatusColor(int index) {
    if (index % 3 == 0) return const Color(0xFF00C853);
    if (index % 3 == 1) return const Color(0xFF2962FF);
    return const Color(0xFFD50000);
  }

  TextStyle _cellStyle() => TextStyle(
        fontSize: 12.sp,
        color: blackColor,
        fontFamily: FontFamily.jost,
      );
}
