import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';

String formatReportDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return "N/A";
  try {
    final parsed = DateTime.parse(dateStr);
    return DateFormat('dd/MM/yyyy').format(parsed.toLocal());
  } catch (_) {
    return dateStr;
  }
}

class ReportGenerationDate extends StatelessWidget {
  const ReportGenerationDate({super.key});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());
    return Text(
      "Report Date: $dateStr",
      style: TextStyle(
        fontSize: 12.sp,
        color: greyColor,
        fontFamily: FontFamily.jost,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
