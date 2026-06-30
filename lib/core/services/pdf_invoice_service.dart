import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:soya_app/core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soya_app/core/services/api_service.dart';
import 'package:soya_app/features/home/model/bill_model.dart';

enum BillPrintFormat { a4, thermal58 }

class PdfInvoiceService {
  static const double _mspRate = 4300;
  static const String _companyName = 'TULJA BHAVANI SOYA PRIVATE LIMITED';
  static const String _companyShortName = 'TBSPL';
  static const String _commodity = 'SOYA SEED';
  static const String _helpline = '+91 9763087275';
  static const String _vendorPhone = '+91 98XXXXXXX';

  static Future<String?> _fetchDisclaimer() async {
    try {
      final response = await ApiService.instance.get(ApiConstants.disclaimer);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          final dynamic rawData = decoded['data'];
          if (rawData is Map<String, dynamic>) {
            return rawData['text']?.toString();
          } else if (rawData is String) {
            return rawData;
          }
        } else if (decoded['text'] != null) {
          return decoded['text']?.toString();
        } else if (decoded['data'] != null && decoded['data'] is String) {
          return decoded['data']?.toString();
        }
      }
    } catch (e) {
      debugPrint('Error fetching disclaimer: $e');
    }
    return null;
  }

  static Future<Uint8List> generateInvoice(
    BillModel bill, {
    BillPrintFormat format = BillPrintFormat.a4,
    List<BillDeduction>? deductions,
  }) async {
    final disclaimer = await _fetchDisclaimer();
    if (format == BillPrintFormat.thermal58) {
      return generateThermal58Invoice(bill,
          deductions: deductions, customDisclaimer: disclaimer);
    }
    return generateA4Invoice(bill,
        deductions: deductions, customDisclaimer: disclaimer);
  }

  static Future<Uint8List> generateA4Invoice(
    BillModel bill, {
    List<BillDeduction>? deductions,
    String? customDisclaimer,
  }) async {
    final ttf = await PdfGoogleFonts.notoSansDevanagariRegular();
    final ttfBold = await PdfGoogleFonts.notoSansDevanagariBold();
    String? vName;
    String? vMobile;
    String? vLocation;
    int? stdRate;
    try {
      final prefs = await SharedPreferences.getInstance();
      vName = prefs.getString('userName');
      vMobile = prefs.getString('userPhone');
      final vVillage = prefs.getString('villageAdd') ?? '';
      final vTaluka = prefs.getString('taluka') ?? '';
      final vDistrict = prefs.getString('district') ?? '';
      vLocation =
          [vVillage, vTaluka, vDistrict].where((s) => s.isNotEmpty).join(', ');
      stdRate = prefs.getInt('standardRate');
    } catch (_) {}
    final data = _BillPrintData.fromBill(bill,
        deductions: deductions,
        vendorName: vName,
        vendorMobile: vMobile,
        vendorLocation: vLocation,
        standardRate: stdRate);
    final disclaimerText = customDisclaimer ?? await _fetchDisclaimer();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(9),
        build: (context) {
          return pw.DefaultTextStyle(
            style: pw.TextStyle(font: ttf, fontSize: 7.4),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 0.8),
              ),
              padding: const pw.EdgeInsets.fromLTRB(7, 5, 7, 4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _a4ReceiptHeader(ttf, ttfBold, data),
                  _a4Rule(),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(child: _a4FarmerBlock(ttf, ttfBold, data)),
                      pw.Container(
                          width: .6, height: 146, color: PdfColors.black),
                      pw.Expanded(child: _a4PurchaseBlock(ttf, ttfBold, data)),
                    ],
                  ),
                  _a4Rule(),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(child: _a4WeightBlock(ttf, ttfBold, data)),
                      pw.Container(
                          width: .6, height: 114, color: PdfColors.black),
                      pw.Expanded(child: _a4BagBlock(ttf, ttfBold, data)),
                      pw.Container(
                          width: .6, height: 114, color: PdfColors.black),
                      pw.Expanded(child: _a4QualityBlock(ttf, ttfBold, data)),
                    ],
                  ),
                  _a4Rule(),
                  _a4BankBlock(ttf, ttfBold, data),
                  _a4Rule(),
                  _declarationSection(
                    ttf,
                    ttfBold,
                    data,
                    customDisclaimer: disclaimerText,
                  ),
                  pw.SizedBox(height: 2),
                  _a4CutLine(ttf),
                  _a4TearOffSlip(ttf, ttfBold, data),
                  _a4Rule(),
                  _a4ReceiptFooter(ttf, ttfBold),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateThermal58Invoice(
    BillModel bill, {
    List<BillDeduction>? deductions,
    String? customDisclaimer,
  }) async {
    final ttf = await PdfGoogleFonts.notoSansDevanagariRegular();
    final ttfBold = await PdfGoogleFonts.notoSansDevanagariBold();
    String? vName;
    String? vMobile;
    String? vLocation;
    int? stdRate;
    try {
      final prefs = await SharedPreferences.getInstance();
      vName = prefs.getString('userName');
      vMobile = prefs.getString('userPhone');
      final vVillage = prefs.getString('villageAdd') ?? '';
      final vTaluka = prefs.getString('taluka') ?? '';
      final vDistrict = prefs.getString('district') ?? '';
      vLocation =
          [vVillage, vTaluka, vDistrict].where((s) => s.isNotEmpty).join(', ');
      stdRate = prefs.getInt('standardRate');
    } catch (_) {}
    final data = _BillPrintData.fromBill(bill,
        deductions: deductions,
        vendorName: vName,
        vendorMobile: vMobile,
        vendorLocation: vLocation,
        standardRate: stdRate);
    final disclaimerText = customDisclaimer ?? await _fetchDisclaimer();
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          58 * PdfPageFormat.mm,
          760 * PdfPageFormat.mm,
          marginAll: 3 * PdfPageFormat.mm,
        ),
        build: (context) {
          return pw.DefaultTextStyle(
            style: pw.TextStyle(font: ttf, fontSize: 6.4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _thermalCenter(
                    ttfBold, '${data.location} PURCHASE POINT'.toUpperCase(),
                    size: 7.4),
                pw.SizedBox(height: 1),
                _thermalCenter(ttfBold, _companyName, size: 8.2),
                _thermalCenter(ttf, 'Ph: ${_helpline.replaceAll('+91 ', '')}',
                    size: 6.5),
                _thermalLine(),
                _thermalRow(ttf, ttfBold, 'Invoice No', data.kpNo),
                _thermalRow(ttf, ttfBold, 'Date', data.date),
                _thermalRow(ttf, ttfBold, 'Purchase by', ''),
                _thermalRow(ttf, ttfBold, 'Farmer Name', data.farmerName),
                _thermalRow(ttf, ttfBold, 'Mobile No', data.mobile),
                _thermalRow(ttf, ttfBold, 'Village', data.village),
                _thermalLine(),
                _thermalAmountBlock(ttf, ttfBold, data),
                _thermalLine(),
                _thermalCenter(ttfBold, 'WEIGHT DETAILS', size: 7),
                _thermalRow(ttf, ttfBold, 'Gross Weight', '${data.grossKg} KG',
                    labelWidth: 75),
                _thermalRow(
                    ttf, ttfBold, 'Bag Deduction', '${data.bagDeductionKg} KG',
                    labelWidth: 75),
                _thermalLine(),
                _thermalRow(ttf, ttfBold, 'Net Weight', '${data.netKg} KG',
                    boldValue: true, labelWidth: 75),
                _thermalLine(),
                _thermalCenter(ttfBold, 'BAG DETAILS'),
                _thermalBagHeader(ttfBold),
                ...data.bagRows.skip(1).map(
                      (row) => _thermalBagRow(
                        ttf,
                        row[0],
                        row.length > 1 ? row[1] : '',
                      ),
                    ),
                _thermalDashText(),
                _thermalBagRow(ttfBold, 'TOTAL BAGS', data.totalBags,
                    boldValue: true),
                _thermalLine(),
                _thermalCenter(ttfBold, 'QUALITY DETAILS (QC)', size: 7),
                _thermalQualityHeader(ttfBold, detailed: true),
                ...data.qualityRows.map((row) => _thermalQualityRow(ttf, row)),
                _thermalRow(
                    ttf, ttfBold, 'Total Deduct', data.deductionTotalValue,
                    boldValue: true, labelWidth: 82),
                _thermalLine(),
                _thermalCenter(ttfBold, 'DECLARATION'),
                pw.Text(
                  (disclaimerText != null && disclaimerText.trim().isNotEmpty)
                      ? 'I, ${data.farmerName}, ${disclaimerText.trim()}'
                      : 'I confirm that the supplied crop belongs to me and payment details mentioned above are accepted by me.',
                  textAlign: pw.TextAlign.left,
                  style: pw.TextStyle(font: ttfBold, fontSize: 6),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _thermalSign(ttf, 'Farmer Sign'),
                    _thermalSign(ttf, 'Lab Chemist Sign'),
                  ],
                ),
                _thermalLine(),
                _thermalCenter(ttfBold, 'Generated / Billing Time', size: 6.2),
                _thermalCenter(ttf, data.printedOn, size: 6),
                _thermalCenter(ttfBold, 'KISAN HELPLINE : $_helpline',
                    size: 6.3),
                _thermalLine(),
                _thermalCenter(ttfBold, 'SAMRUDDHA SHETKARI CHALWAL',
                    size: 7.2),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _a4ReceiptHeader(
      pw.Font ttf, pw.Font ttfBold, _BillPrintData data) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 92,
              child: pw.Column(
                children: [
                  pw.Container(
                    width: 58,
                    height: 42,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: .8),
                    ),
                    child: pw.Text(
                      _companyShortName,
                      style: pw.TextStyle(font: ttfBold, fontSize: 18),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'TULJA BHAVANI\nSOYA PVT. LTD.',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(font: ttfBold, fontSize: 6.4),
                  ),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Text(
                    _companyName,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(font: ttfBold, fontSize: 23),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'FARMER PURCHASE RECEIPT',
                    style: pw.TextStyle(font: ttfBold, fontSize: 14),
                  ),
                  pw.Container(width: 182, height: .7, color: PdfColors.black),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                children: [
                  _a4InlineField(ttf, ttfBold, 'Invoice No.', data.kpNo,
                      labelWidth: 74),
                  _a4InlineField(ttf, ttfBold, 'Date', data.date,
                      labelWidth: 74),
                  _a4InlineField(ttf, ttfBold, 'Time', data.time,
                      labelWidth: 74),
                ],
              ),
            ),
            pw.SizedBox(width: 28),
            pw.Expanded(
              child: pw.Column(
                children: [
                  _a4InlineField(ttf, ttfBold, 'Officer Name', data.vendorName,
                      labelWidth: 102),
                  _a4InlineField(
                      ttf, ttfBold, 'Officer Mobile No.', data.vendorMobile,
                      labelWidth: 102),
                  _a4InlineField(ttf, ttfBold, 'Center Name', data.location,
                      labelWidth: 102),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _a4FarmerBlock(
      pw.Font ttf, pw.Font ttfBold, _BillPrintData data) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(6, 4, 18, 3),
      child: pw.Column(
        children: [
          _a4SectionTitle(ttfBold, 'FARMER INFORMATION'),
          pw.SizedBox(height: 8),
          _a4InlineField(ttf, ttfBold, 'Aadhaar No.', data.aadhaar),
          _a4InlineField(ttf, ttfBold, 'Farmer Name', data.farmerName),
          _a4InlineField(ttf, ttfBold, 'Farmer ID', data.farmerId),
          _a4InlineField(ttf, ttfBold, 'Mobile No.', data.mobile),
          _a4InlineField(ttf, ttfBold, 'Village', data.village),
          _a4InlineField(ttf, ttfBold, 'Taluka', data.taluka),
          _a4InlineField(ttf, ttfBold, 'District', data.district),
        ],
      ),
    );
  }

  static pw.Widget _a4PurchaseBlock(
      pw.Font ttf, pw.Font ttfBold, _BillPrintData data) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(18, 4, 6, 3),
      child: pw.Column(
        children: [
          _a4SectionTitle(ttfBold, 'PURCHASE INFORMATION'),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: .8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text("Today's Purchase Rate",
                    style: pw.TextStyle(font: ttfBold, fontSize: 8.5)),
                pw.Text('  :  ',
                    style: pw.TextStyle(font: ttfBold, fontSize: 8.5)),
                pw.Text('Rs. ${data.actualRate} / Qtl',
                    style: pw.TextStyle(font: ttfBold, fontSize: 8.5)),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          _a4InlineField(ttf, ttfBold, 'Central Sr. No.', data.grnNo,
              labelWidth: 108),
          _a4InlineField(ttf, ttfBold, 'Purchase Point Sr. No.', data.kpNo,
              labelWidth: 108),
          _a4InlineField(ttf, ttfBold, 'Commodity', _commodity,
              labelWidth: 108),
          _a4InlineField(ttf, ttfBold, 'Vehicle No.', data.vehicleNo,
              labelWidth: 108),
        ],
      ),
    );
  }

  static pw.Widget _a4WeightBlock(
      pw.Font ttf, pw.Font ttfBold, _BillPrintData data) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(6, 4, 9, 3),
      child: pw.Column(
        children: [
          _a4SectionTitle(ttfBold, 'WEIGHT SUMMARY'),
          pw.SizedBox(height: 8),
          _a4AmountRow(ttf, ttfBold, 'Gross Weight', '${data.grossKg} KG'),
          _a4AmountRow(ttf, ttfBold, 'Bag Weight (Deduction)',
              '${data.bagDeductionKg} KG'),
          _a4Dash(),
          _a4AmountRow(ttf, ttfBold, 'Net Weight', '${data.netKg} KG',
              bold: true),
          _a4Dash(),
          _a4AmountRow(
              ttf, ttfBold, 'Final Purchase Rate', 'Rs. ${data.rate} / Qtl'),
          _a4Dash(),
          _a4AmountRow(
              ttf, ttfBold, 'PAYABLE AMOUNT', 'Rs. ${data.payableAmount}',
              bold: true, fontSize: 9.3),
        ],
      ),
    );
  }

  static pw.Widget _a4BagBlock(
      pw.Font ttf, pw.Font ttfBold, _BillPrintData data) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(9, 4, 9, 3),
      child: pw.Column(
        children: [
          _a4SectionTitle(ttfBold, 'BAG DETAILS'),
          pw.SizedBox(height: 7),
          _a4TwoColumnHeader(ttfBold, 'Particulars', 'Quantity (Bags)'),
          _a4Dash(),
          ...data.bagRows.map(
            (row) => _a4AmountRow(
              ttf,
              ttfBold,
              row.first,
              row.length > 1 ? row[1] : '',
              bold: row.first.toLowerCase().contains('total'),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _a4QualityBlock(
      pw.Font ttf, pw.Font ttfBold, _BillPrintData data) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(9, 4, 6, 3),
      child: pw.Column(
        children: [
          _a4SectionTitle(ttfBold, 'QUALITY / LAB ANALYSIS'),
          pw.SizedBox(height: 7),
          _a4QualityRow(
              ttfBold, ['Parameter', 'Allowed', 'Actual', 'Deduction'],
              isHeader: true),
          _a4Dash(),
          ...data.qualityRows.map((row) => _a4QualityRow(ttf, row)),
          _a4Dash(),
          _a4AmountRow(
              ttf, ttfBold, 'Total Deduction', data.deductionTotalValue,
              bold: true),
        ],
      ),
    );
  }

  static pw.Widget _a4BankBlock(
      pw.Font ttf, pw.Font ttfBold, _BillPrintData data) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(6, 4, 6, 2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text('BANK DETAILS',
              style: pw.TextStyle(font: ttfBold, fontSize: 9)),
          pw.SizedBox(height: 3),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  children: [
                    _a4InlineField(ttf, ttfBold, 'Bank Name', data.bankName,
                        labelWidth: 88),
                    _a4InlineField(
                        ttf, ttfBold, 'Account Number', data.accountNo,
                        labelWidth: 88),
                  ],
                ),
              ),
              pw.SizedBox(width: 28),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    _a4InlineField(
                        ttf, ttfBold, 'Account Holder', data.holderName,
                        labelWidth: 100),
                    _a4InlineField(
                        ttf, ttfBold, 'IFSC Code & Branch', data.ifsc,
                        labelWidth: 100),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _a4TearOffSlip(
      pw.Font ttf, pw.Font ttfBold, _BillPrintData data) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(24, 4, 24, 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              children: [
                _a4InlineField(ttf, ttfBold, 'Farmer Name', data.farmerName,
                    labelWidth: 96),
                _a4InlineField(ttf, ttfBold, 'Vehicle No.', data.vehicleNo,
                    labelWidth: 96),
                _a4InlineField(ttf, ttfBold, 'Net Weight', '${data.netKg} KG',
                    labelWidth: 96),
                _a4InlineField(
                    ttf, ttfBold, 'Purchase Rate', 'Rs. ${data.rate} / Qtl',
                    labelWidth: 96),
                _a4InlineField(
                    ttf, ttfBold, 'Total Amount', 'Rs. ${data.payableAmount}',
                    labelWidth: 96),
              ],
            ),
          ),
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(horizontal: 20),
            width: .7,
            height: 58,
            color: PdfColors.black,
          ),
          pw.Expanded(
            child: pw.Column(
              children: [
                _a4InlineField(
                    ttf, ttfBold, 'Purchase Point Sr. No.', data.kpNo,
                    labelWidth: 120),
                _a4InlineField(ttf, ttfBold, 'Date', data.date,
                    labelWidth: 120),
                _a4InlineField(ttf, ttfBold, 'Total Bags', data.totalBags,
                    labelWidth: 120),
                _a4InlineField(
                    ttf, ttfBold, 'Kaltani Bags (50 Kg)', data.kaltaniBags,
                    labelWidth: 120),
                _a4InlineField(ttf, ttfBold, 'PP Bags (150 Gms)', data.ppBags,
                    labelWidth: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _a4ReceiptFooter(pw.Font ttf, pw.Font ttfBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: pw.Row(
        children: [
          pw.Container(
            width: 28,
            height: 28,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.4),
              shape: pw.BoxShape.circle,
            ),
            child:
                pw.Text('A', style: pw.TextStyle(font: ttfBold, fontSize: 13)),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('REGISTERED ADDRESS',
                    style: pw.TextStyle(font: ttfBold, fontSize: 8)),
                pw.Text(
                  'At Post - Bhandi Bk.\nTaluka - Murud,\nDist. - Latur,\nMaharashtra - 413512',
                  style: pw.TextStyle(font: ttfBold, fontSize: 6.6),
                ),
              ],
            ),
          ),
          pw.Container(width: .6, height: 45, color: PdfColors.black),
          pw.SizedBox(width: 26),
          pw.Container(
            width: 28,
            height: 28,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.4),
              shape: pw.BoxShape.circle,
            ),
            child:
                pw.Text('T', style: pw.TextStyle(font: ttfBold, fontSize: 13)),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('FARMER HELPLINE',
                    style: pw.TextStyle(font: ttfBold, fontSize: 8.5)),
                pw.Text(_helpline,
                    style: pw.TextStyle(font: ttfBold, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _a4InlineField(
    pw.Font ttf,
    pw.Font ttfBold,
    String label,
    String value, {
    double labelWidth = 86,
    double fontSize = 8.1,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: labelWidth,
            child: pw.Text(label,
                style: pw.TextStyle(font: ttfBold, fontSize: fontSize)),
          ),
          pw.Text(':', style: pw.TextStyle(font: ttfBold, fontSize: fontSize)),
          pw.SizedBox(width: 9),
          pw.Expanded(
            child: pw.Container(
              height: 12,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black, width: .45),
                ),
              ),
              child: value.trim().isEmpty
                  ? pw.SizedBox()
                  : pw.Text(
                      value,
                      maxLines: 1,
                      overflow: pw.TextOverflow.clip,
                      style: pw.TextStyle(font: ttfBold, fontSize: fontSize),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _a4AmountRow(
    pw.Font ttf,
    pw.Font ttfBold,
    String label,
    String value, {
    bool bold = false,
    double fontSize = 8.1,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.3),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(label,
                style: pw.TextStyle(
                    font: bold ? ttfBold : ttf, fontSize: fontSize)),
          ),
          pw.Text(':  ',
              style: pw.TextStyle(font: ttfBold, fontSize: fontSize)),
          pw.Text(value,
              style: pw.TextStyle(font: ttfBold, fontSize: fontSize)),
        ],
      ),
    );
  }

  static pw.Widget _a4TwoColumnHeader(
      pw.Font ttfBold, String left, String right) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(left, style: pw.TextStyle(font: ttfBold, fontSize: 7)),
        ),
        pw.Text(right, style: pw.TextStyle(font: ttfBold, fontSize: 7)),
      ],
    );
  }

  static pw.Widget _a4QualityRow(pw.Font font, List<String> cells,
      {bool isHeader = false}) {
    final values = List<String>.generate(
      4,
      (index) => index < cells.length ? cells[index] : '',
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.1),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 5,
            child: pw.Text(values[0],
                style:
                    pw.TextStyle(font: font, fontSize: isHeader ? 6.7 : 7.1)),
          ),
          for (final value in values.skip(1))
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                value,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: font, fontSize: isHeader ? 6.7 : 7.1),
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _a4SectionTitle(pw.Font ttfBold, String title) {
    return pw.Text(
      title,
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(font: ttfBold, fontSize: 9.2),
    );
  }

  static pw.Widget _a4Rule() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Container(height: .8, color: PdfColors.black),
    );
  }

  static pw.Widget _a4Dash() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.8),
      child: pw.Text(
        '---------------------------------------------',
        style: const pw.TextStyle(fontSize: 5.8),
      ),
    );
  }

  static pw.Widget _a4CutLine(pw.Font ttf) {
    return pw.Row(
      children: [
        pw.Text('--X', style: pw.TextStyle(font: ttf, fontSize: 10)),
        pw.Expanded(
          child: pw.Text(
            '---------------------------------------------------------------',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: ttf, fontSize: 8),
          ),
        ),
        pw.Text('X--', style: pw.TextStyle(font: ttf, fontSize: 10)),
      ],
    );
  }

  static pw.Widget _a4Header(pw.Font ttf, pw.Font ttfBold) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.8),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Text(
                  _companyName,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 23,
                    letterSpacing: .4,
                  ),
                ),
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 4),
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16, vertical: 2),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 0.8),
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                  child: pw.Text(
                    'FARMER PURCHASE RECEIPT',
                    style: pw.TextStyle(font: ttfBold, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Container(
            width: 58,
            alignment: pw.Alignment.center,
            child: pw.Column(
              children: [
                pw.Text(_companyShortName,
                    style: pw.TextStyle(font: ttfBold, fontSize: 16)),
                pw.Text('Tulja Bhavani Soya\nPrivate Limited',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(font: ttfBold, fontSize: 6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _boxedSection({
    required String title,
    required String icon,
    required pw.Font ttf,
    required pw.Font ttfBold,
    required pw.Widget child,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.6),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      padding: const pw.EdgeInsets.fromLTRB(7, 4, 7, 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Center(
            child: pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  color: PdfColors.black,
                  child: pw.Text(icon,
                      style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 5.5,
                          color: PdfColors.white)),
                ),
                pw.SizedBox(width: 4),
                pw.Text(title,
                    style: pw.TextStyle(font: ttfBold, fontSize: 8.5)),
              ],
            ),
          ),
          pw.SizedBox(height: 5),
          child,
        ],
      ),
    );
  }

  static pw.Widget _a4Field(
      pw.Font ttf, pw.Font ttfBold, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 74,
            child: pw.Text(label,
                style: pw.TextStyle(font: ttfBold, fontSize: 7.6)),
          ),
          pw.Text(':  ', style: pw.TextStyle(font: ttfBold, fontSize: 7.6)),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 1),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey600, width: .4),
                ),
              ),
              child: pw.Text(value,
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(font: ttf, fontSize: 7.6)),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _a4ValueRow(
    pw.Font ttf,
    pw.Font ttfBold,
    String label,
    String value, {
    bool highlight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.2),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(label,
                style: pw.TextStyle(
                    font: highlight ? ttfBold : ttf, fontSize: 7.8)),
          ),
          pw.Text(':  ', style: pw.TextStyle(font: ttfBold, fontSize: 7.8)),
          pw.Text(value,
              style:
                  pw.TextStyle(font: ttfBold, fontSize: highlight ? 9.2 : 7.8)),
        ],
      ),
    );
  }

  static pw.Widget _pill(pw.Font ttfBold, String text) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: .6),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Text(text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: ttfBold, fontSize: 8)),
    );
  }

  static pw.Widget _dashLine() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text('----------------------------------------',
          style: const pw.TextStyle(fontSize: 6)),
    );
  }

  static pw.Widget _miniTable(
    pw.Font ttf,
    pw.Font ttfBold, {
    String? title,
    required List<String> headers,
    required List<List<String>> rows,
    Map<int, pw.TableColumnWidth>? widths,
    double fontSize = 6.4,
  }) {
    final allRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: headers
            .map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Text(h,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: ttfBold, fontSize: fontSize)),
                ))
            .toList(),
      ),
      ...rows.map(
        (row) => pw.TableRow(
          children: row
              .map(
                (cell) => pw.Padding(
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Text(cell,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: ttf, fontSize: fontSize)),
                ),
              )
              .toList(),
        ),
      ),
    ];

    final table = pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey600, width: .35),
      columnWidths: widths,
      children: allRows,
    );

    if (title == null) return table;
    return pw.Column(
      children: [
        pw.Text(title,
            style: pw.TextStyle(font: ttfBold, fontSize: fontSize + 1)),
        pw.SizedBox(height: 2),
        table,
      ],
    );
  }

  static pw.Widget _a4BottomBagDetails(
      pw.Font ttf, pw.Font ttfBold, _BillPrintData data) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: .55),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      padding: const pw.EdgeInsets.all(3),
      child: pw.Column(
        children: [
          _miniTable(
            ttf,
            ttfBold,
            title: 'BAG DETAILS',
            headers: ['Bag Type', 'No. of Bags', 'Bag Weight / Type'],
            rows: data.returnBagRows,
            fontSize: 6,
          ),
          pw.SizedBox(height: 3),
          _a4BagReturnInfo(ttf, ttfBold, data),
        ],
      ),
    );
  }

  static pw.Widget _a4BagReturnInfo(
      pw.Font ttf, pw.Font ttfBold, _BillPrintData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(9, 4, 9, 4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: .5),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              children: [
                _a4ReturnField(ttf, ttfBold, 'Farmer Name', data.farmerName),
                _a4ReturnField(ttf, ttfBold, 'Vehicle Number', data.vehicleNo),
                _a4ReturnField(ttf, ttfBold, 'Net Weight', '${data.netKg} KG'),
                _a4ReturnField(
                    ttf, ttfBold, 'Purchase Rate', 'Rs. ${data.rate} / Qtl'),
                _a4ReturnField(
                    ttf, ttfBold, 'Total Amount', 'Rs. ${data.payableAmount}'),
              ],
            ),
          ),
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(horizontal: 12),
            width: .5,
            height: 62,
            color: PdfColors.grey600,
          ),
          pw.Expanded(
            child: pw.Column(
              children: [
                _a4ReturnField(ttf, ttfBold, 'KP No.', data.kpNo),
                _a4ReturnField(ttf, ttfBold, 'Date', data.date),
                _a4ReturnField(ttf, ttfBold, 'Total Bags', data.totalBags),
                _a4ReturnField(ttf, ttfBold, 'Kaltani Bags', data.kaltaniBags),
                _a4ReturnField(ttf, ttfBold, "PP Bag's", data.ppBags),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _a4ReturnField(
      pw.Font ttf, pw.Font ttfBold, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 86,
            child: pw.Text(label,
                style: pw.TextStyle(font: ttfBold, fontSize: 7.1)),
          ),
          pw.Text(':  ', style: pw.TextStyle(font: ttfBold, fontSize: 7.1)),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 1),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey600, width: .4),
                ),
              ),
              child: pw.Text(value,
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(font: ttf, fontSize: 7.1)),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _declarationSection(
      pw.Font ttf, pw.Font ttfBold, _BillPrintData data,
      {String? customDisclaimer}) {
    final String declarationText = (customDisclaimer != null &&
            customDisclaimer.trim().isNotEmpty)
        ? 'I, ${data.farmerName}, ${customDisclaimer.trim()}'
        : 'I, ${data.farmerName}, confirm that the supplied crop belongs to me and the payment details mentioned above are accepted by me.';

    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(6, 0, 6, 0),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            'DECLARATION',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: ttfBold, fontSize: 9.8),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            declarationText,
            style: pw.TextStyle(font: ttfBold, fontSize: 7.7),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Amount received in words: Rs. ${_numberToWords(data.payableRounded)} ONLY',
            style: pw.TextStyle(font: ttfBold, fontSize: 7.7),
          ),
          pw.SizedBox(height: 13),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _signature(ttfBold, 'Farmer Signature'),
              _signature(ttfBold, 'Lab Chemist / Godown Incharge'),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'This is a system generated document and does not require signature.',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: ttfBold, fontSize: 6.8),
          ),
        ],
      ),
    );
  }

  static pw.Widget _signature(pw.Font ttfBold, String label) {
    return pw.Column(
      children: [
        pw.Container(width: 90, height: .6, color: PdfColors.black),
        pw.SizedBox(height: 2),
        pw.Text('( $label )',
            style: pw.TextStyle(font: ttfBold, fontSize: 6.5)),
      ],
    );
  }

  static pw.Widget _footerBand(
      pw.Font ttf, pw.Font ttfBold, _BillPrintData data) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _footerBox(ttf, ttfBold, 'REGISTERED ADDRESS',
                  'Latur - Barshi Road,\nNear Palsap Pati,\nLatur - 413510'),
            ),
            pw.Expanded(
              child: _footerBox(ttf, ttfBold, 'VENDOR DETAILS',
                  'Vendor No. : ${data.vendorNo}\nVendor Phone No. : $_vendorPhone'),
            ),
            pw.Expanded(
              child: _footerBox(ttf, ttfBold, 'FARMER HELPLINE',
                  'KISAN HELPLINE\n$_helpline'),
            ),
            pw.Expanded(
              child: _footerBox(ttf, ttfBold, 'NOTE',
                  'System Generated Document\nPrinted On : ${data.printedOn}\nNo signature required.'),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: PdfColors.black,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _footerWhite(ttfBold, 'CIN : U15499MH2021PTC365061'),
              _footerWhite(ttfBold, 'GSTIN : 27AAICT6752P1ZV'),
              _footerWhite(ttfBold, 'Vendor Phone No. : $_vendorPhone'),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _footerBox(
      pw.Font ttf, pw.Font ttfBold, String title, String body) {
    return pw.Container(
      constraints: const pw.BoxConstraints(minHeight: 44),
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: .4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(font: ttfBold, fontSize: 6.6)),
          pw.SizedBox(height: 2),
          pw.Text(body, style: pw.TextStyle(font: ttf, fontSize: 6.2)),
        ],
      ),
    );
  }

  static pw.Widget _footerWhite(pw.Font ttfBold, String text) {
    return pw.Text(text,
        style:
            pw.TextStyle(font: ttfBold, fontSize: 6.4, color: PdfColors.white));
  }

  static pw.Widget _thermalCenter(pw.Font font, String text,
      {double size = 7.2}) {
    return pw.Text(
      text,
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(font: font, fontSize: size),
    );
  }

  static pw.Widget _thermalAmountBlock(
      pw.Font ttf, pw.Font ttfBold, _BillPrintData data) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: pw.Column(
        children: [
          _thermalRow(ttf, ttfBold, 'Commodity', _commodity, labelWidth: 62),
          _thermalRow(
              ttf, ttfBold, "Today's Rate", 'Rs ${data.actualRate} / Qtl',
              labelWidth: 62),
          _thermalRow(ttf, ttfBold, 'Purchase Rate', 'Rs ${data.rate} / Qtl',
              labelWidth: 62),
          pw.SizedBox(height: 3),
          _thermalRow(ttf, ttfBold, 'AMOUNT', 'Rs ${data.payableAmount}',
              boldValue: true, labelWidth: 62, fontSize: 7.8),
        ],
      ),
    );
  }

  static pw.Widget _thermalLine() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.6),
      child: pw.Text('------------------------------------',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 6)),
    );
  }

  static pw.Widget _thermalRow(
    pw.Font ttf,
    pw.Font ttfBold,
    String label,
    String value, {
    bool boldValue = false,
    double labelWidth = 58,
    double fontSize = 6.2,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: labelWidth,
          child: pw.Text(label,
              style: pw.TextStyle(font: ttfBold, fontSize: fontSize)),
        ),
        pw.Text(': ', style: pw.TextStyle(font: ttf, fontSize: fontSize)),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
                font: boldValue ? ttfBold : ttf, fontSize: fontSize),
          ),
        ),
      ],
    );
  }

  static pw.Widget _thermalBagHeader(pw.Font ttfBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 1, bottom: 1.5),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text('Bag Type',
                style: pw.TextStyle(font: ttfBold, fontSize: 6.1)),
          ),
          pw.Text('No. of Bags',
              style: pw.TextStyle(font: ttfBold, fontSize: 6.1)),
        ],
      ),
    );
  }

  static pw.Widget _thermalBagRow(
    pw.Font font,
    String label,
    String value, {
    bool boldValue = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.4),
      child: pw.Row(
        children: [
          pw.Expanded(
            child:
                pw.Text(label, style: pw.TextStyle(font: font, fontSize: 6.1)),
          ),
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: 6.1)),
        ],
      ),
    );
  }

  static pw.Widget _thermalDashText() {
    return pw.Text(
      '-----------------------------',
      textAlign: pw.TextAlign.center,
      style: const pw.TextStyle(fontSize: 5.8),
    );
  }

  static pw.Widget _thermalQualityHeader(pw.Font ttfBold,
      {bool detailed = false}) {
    return _thermalQualityCells(
      ttfBold,
      detailed
          ? const ['Parameter', 'Allowed', 'Actual', 'Deduct']
          : const ['Parameter', 'Allow', 'Actual', 'Deduct'],
      isHeader: true,
    );
  }

  static pw.Widget _thermalQualityRow(pw.Font ttf, List<String> row) {
    final cells = List<String>.generate(
      4,
      (index) => index < row.length ? row[index] : '',
    );
    return _thermalQualityCells(ttf, cells);
  }

  static pw.Widget _thermalQualityCells(
    pw.Font font,
    List<String> cells, {
    bool isHeader = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.4),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 7,
            child: pw.Text(cells[0],
                style:
                    pw.TextStyle(font: font, fontSize: isHeader ? 5.4 : 5.8)),
          ),
          for (final cell in cells.skip(1))
            pw.Expanded(
              flex: 4,
              child: pw.Text(
                cell,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: font, fontSize: isHeader ? 5.4 : 5.8),
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _thermalBox(pw.Font ttfBold, String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(2.4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: .5),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Text(text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: ttfBold, fontSize: 6.4)),
    );
  }

  static pw.Widget _thermalBottomBagDetails(
      pw.Font ttf, pw.Font ttfBold, _BillPrintData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: .5),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _miniTable(
            ttf,
            ttfBold,
            title: 'BAG DETAILS',
            headers: ['Bag Type', 'No', 'Wt'],
            rows: data.returnBagRows,
            fontSize: 5.5,
          ),
          pw.SizedBox(height: 3),
          _thermalBagReturnInfo(ttf, ttfBold, data),
        ],
      ),
    );
  }

  static pw.Widget _thermalBagReturnInfo(
      pw.Font ttf, pw.Font ttfBold, _BillPrintData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: .5),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _thermalRow(ttf, ttfBold, 'Farmer Name', data.farmerName),
          _thermalRow(ttf, ttfBold, 'Vehicle No', data.vehicleNo),
          _thermalRow(ttf, ttfBold, 'Net Weight', '${data.netKg} KG'),
          _thermalRow(ttf, ttfBold, 'Rate', 'Rs ${data.rate} / Qtl'),
          _thermalRow(ttf, ttfBold, 'Total Amount', 'Rs ${data.payableAmount}'),
          _thermalLine(),
          _thermalRow(ttf, ttfBold, 'KP No', data.kpNo),
          _thermalRow(ttf, ttfBold, 'Date', data.date),
          _thermalRow(ttf, ttfBold, 'Total Bags', data.totalBags),
          _thermalRow(ttf, ttfBold, 'Kaltani Bags', data.kaltaniBags),
          _thermalRow(ttf, ttfBold, 'PP Bags', data.ppBags),
        ],
      ),
    );
  }

  static pw.Widget _thermalSign(pw.Font ttf, String label) {
    return pw.Column(
      children: [
        pw.Container(width: 52, height: .5, color: PdfColors.black),
        pw.Text(label, style: pw.TextStyle(font: ttf, fontSize: 5)),
      ],
    );
  }

  static Future<File> savePdfFile(String fileName, Uint8List byteList) async {
    final directories = <Directory>[];

    if (Platform.isAndroid) {
      directories.add(Directory('/storage/emulated/0/Download/SoyaApp'));
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        directories.add(Directory('${externalDir.path}/SoyaApp'));
      }
    }

    directories.add(await getApplicationDocumentsDirectory());

    Object? lastError;
    for (final output in directories) {
      try {
        if (!await output.exists()) {
          await output.create(recursive: true);
        }

        final file = File('${output.path}${Platform.pathSeparator}$fileName');
        await file.writeAsBytes(byteList);
        return file;
      } catch (e) {
        lastError = e;
        debugPrint('Failed to save PDF at ${output.path}: $e');
      }
    }

    throw FileSystemException(
      'Unable to save PDF',
      fileName,
      lastError is FileSystemException ? lastError.osError : null,
    );
  }

  static String _numberToWords(int number) {
    if (number == 0) return 'ZERO';
    final words = <String>[];
    if (number >= 10000000) {
      words.add('${_numberToWords(number ~/ 10000000)} CRORE');
      number %= 10000000;
    }
    if (number >= 100000) {
      words.add('${_numberToWords(number ~/ 100000)} LAKH');
      number %= 100000;
    }
    if (number >= 1000) {
      words.add('${_numberToWords(number ~/ 1000)} THOUSAND');
      number %= 1000;
    }
    if (number >= 100) {
      words.add('${_numberToWords(number ~/ 100)} HUNDRED');
      number %= 100;
    }
    if (number > 0) {
      final units = [
        '',
        'ONE',
        'TWO',
        'THREE',
        'FOUR',
        'FIVE',
        'SIX',
        'SEVEN',
        'EIGHT',
        'NINE',
        'TEN',
        'ELEVEN',
        'TWELVE',
        'THIRTEEN',
        'FOURTEEN',
        'FIFTEEN',
        'SIXTEEN',
        'SEVENTEEN',
        'EIGHTEEN',
        'NINETEEN'
      ];
      final tens = [
        '',
        '',
        'TWENTY',
        'THIRTY',
        'FORTY',
        'FIFTY',
        'SIXTY',
        'SEVENTY',
        'EIGHTY',
        'NINETY'
      ];
      if (number < 20) {
        words.add(units[number]);
      } else {
        final text = number % 10 == 0
            ? tens[number ~/ 10]
            : '${tens[number ~/ 10]} ${units[number % 10]}';
        words.add(text);
      }
    }
    return words.join(' ');
  }
}

class _BillPrintData {
  final String rate;
  final String farmerId;
  final String farmerName;
  final String aadhaar;
  final String mobile;
  final String village;
  final String taluka;
  final String district;
  final String grnNo;
  final String kpNo;
  final String date;
  final String time;
  final String printedOn;
  final String location;
  final String vehicleNo;
  final String grossKg;
  final String bagDeductionKg;
  final String netKg;
  final String actualRate;
  final String payableAmount;
  final int payableRounded;
  final String vendorName;
  final String vendorMobile;
  final String deductionTotal;
  final String deductionTotalValue;
  final String bankName;
  final String holderName;
  final String accountNo;
  final String ifsc;
  final String vendorNo;
  final String totalBags;
  final String ppBags;
  final String kaltaniBags;
  final List<List<String>> bagRows;
  final List<List<String>> thermalBagRows;
  final List<List<String>> returnBagRows;
  final List<List<String>> qualityRows;
  final List<List<String>> thermalQualityRows;

  _BillPrintData({
    required this.rate,
    required this.farmerId,
    required this.farmerName,
    required this.aadhaar,
    required this.mobile,
    required this.village,
    required this.taluka,
    required this.district,
    required this.grnNo,
    required this.kpNo,
    required this.date,
    required this.time,
    required this.printedOn,
    required this.location,
    required this.vehicleNo,
    required this.grossKg,
    required this.bagDeductionKg,
    required this.netKg,
    required this.actualRate,
    required this.payableAmount,
    required this.payableRounded,
    required this.vendorName,
    required this.vendorMobile,
    required this.deductionTotal,
    required this.deductionTotalValue,
    required this.bankName,
    required this.holderName,
    required this.accountNo,
    required this.ifsc,
    required this.vendorNo,
    required this.totalBags,
    required this.ppBags,
    required this.kaltaniBags,
    required this.bagRows,
    required this.thermalBagRows,
    required this.returnBagRows,
    required this.qualityRows,
    required this.thermalQualityRows,
  });

  factory _BillPrintData.fromBill(
    BillModel bill, {
    List<BillDeduction>? deductions,
    String? vendorName,
    String? vendorMobile,
    String? vendorLocation,
    int? standardRate,
  }) {
    final farmer = bill.farmer;
    final bank =
        farmer?.banks?.isNotEmpty == true ? farmer!.banks!.first : null;
    final billDate = _parseDate(bill.billDate) ?? DateTime.now();
    final created = _parseDate(bill.createdAt) ?? DateTime.now();
    final calc = bill.calculationDetails;

    final netQtl = _asQtl(
      calc?.pricedQuantity ??
          calc?.netWeightForLab ??
          bill.primaryQuantity ??
          bill.items?.fold<num>(0, (sum, i) => sum + (i.quantity ?? 0)) ??
          0,
      bill.primaryUnit,
    );
    final bagDeductionQtl = calc?.bagWeight ?? bill.goniWeight ?? 0;
    final grossQtl = calc?.totalQuantityReceived != null
        ? _asQtl(calc?.totalQuantityReceived ?? 0, bill.primaryUnit)
        : netQtl + bagDeductionQtl;
    final finalRate = calc?.rateAfterLabDeductionRounded ??
        calc?.ratePerUnit ??
        bill.ratePerUnit ??
        bill.items?.firstOrNull?.rate ??
        0;
    final actualRateVal = standardRate ?? finalRate;
    final totalPayable =
        calc?.recalculatedTotal ?? bill.netPayable ?? bill.totalAmount ?? 0;
    final advance = (bill.advancedAmount != null && bill.advancedAmount! > 0)
        ? bill.advancedAmount!
        : 0;
    final payable = bill.balanceAmount ?? (totalPayable - advance);
    final billDeductions = deductions?.isNotEmpty == true
        ? deductions!
        : (bill.deductions ?? const <BillDeduction>[]);
    final deductionTotal = calc?.totalLabDeductionAmount ??
        billDeductions.fold<num>(
            0, (sum, d) => sum + (d.deductionAmount ?? d.value ?? 0));

    final bagRows = _bagRows(bill);
    final qualityRows = _qualityRows(billDeductions);
    final deductionTotalValue = qualityRows.fold<num>(
      0,
      (sum, row) => sum + (num.tryParse(row.length > 3 ? row[3] : '0') ?? 0),
    );
    final totalBags = _totalBags(bill);
    final kaltaniBags = _typedBagCount(bill, 'kaltani');
    final ppBags = totalBags - kaltaniBags;

    return _BillPrintData(
      rate: _fmt(finalRate),
      farmerId: _short(farmer?.id ?? bill.farmerId),
      farmerName: _clean(farmer?.name),
      aadhaar: _clean(farmer?.aadhaarNo),
      mobile: _clean(farmer?.phone),
      village: _clean(farmer?.villageAdd),
      taluka: _clean(farmer?.taluka),
      district: _clean(farmer?.district),
      grnNo: _clean(bill.grnNo ?? bill.id),
      kpNo: _clean(bill.billNo),
      date: DateFormat('dd/MM/yyyy').format(billDate),
      time: DateFormat('hh:mm a').format(created),
      printedOn: DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now()),
      location: vendorLocation ?? _clean(bill.billLocation),
      vehicleNo: _clean(bill.vehicleNumber),
      grossKg: _fmt(grossQtl * 100),
      bagDeductionKg: _fmt(bagDeductionQtl * 100),
      netKg: _fmt(netQtl * 100),
      actualRate: _fmt(actualRateVal),
      payableAmount: _money(payable),
      payableRounded: payable.round(),
      vendorName: vendorName ?? _clean(farmer?.vendorName),
      vendorMobile: vendorMobile ?? '',
      deductionTotal: _money(deductionTotal),
      deductionTotalValue: _fmtPrecise(deductionTotalValue),
      bankName: _clean(bank?.bankName),
      holderName: _clean(bank?.holderName ?? farmer?.name),
      accountNo: _clean(bank?.accountNo),
      ifsc: _clean(bank?.ifsc),
      vendorNo: _short(bill.vendorId),
      totalBags: '$totalBags',
      ppBags: '${ppBags < 0 ? 0 : ppBags}',
      kaltaniBags: '$kaltaniBags',
      bagRows: bagRows,
      thermalBagRows: bagRows
          .map((row) => [row.first, row.length > 1 ? row[1] : '0'])
          .toList(),
      returnBagRows: _returnBagRows(bill),
      qualityRows: qualityRows,
      thermalQualityRows: qualityRows
          .map((row) => [row.first, row.length > 2 ? row[2] : '0'])
          .toList(),
    );
  }

  static List<List<String>> _bagRows(BillModel bill) {
    final rows = <List<String>>[];
    final totalBags = _totalBags(bill);
    rows.add(['Total Bag', '$totalBags']);
    if (bill.gonis?.isNotEmpty == true) {
      for (final goni in bill.gonis!) {
        rows.add([
          _bagLabel(goni.goniType?.name, goni.goniType?.weightPerBag),
          '${goni.bagCount ?? 0}'
        ]);
      }
    } else if (bill.goniType != null) {
      rows.add([
        _bagLabel(bill.goniType?.name, bill.goniType?.weightPerBag),
        '${bill.bagCount ?? 0}'
      ]);
    } else {
      rows.add(['PP Bag (150 Gms)', '$totalBags']);
    }
    rows.add(['Kaltani - 50 Kg', '0']);
    rows.add(['Kaltani - 100 Kg', '0']);
    return rows;
  }

  static List<List<String>> _returnBagRows(BillModel bill) {
    final rows = <List<String>>[];
    if (bill.gonis?.isNotEmpty == true) {
      for (final goni in bill.gonis!) {
        rows.add([
          _clean(goni.goniType?.name),
          '${goni.bagCount ?? 0}',
          '${_fmt(goni.goniType?.weightPerBag ?? goni.weight ?? 0)} Kg'
        ]);
      }
    }
    if (rows.isEmpty) {
      rows.add([
        _bagLabel(bill.goniType?.name ?? 'PP Bag', bill.goniType?.weightPerBag),
        '${bill.bagCount ?? 0}',
        '${_fmt(bill.goniType?.weightPerBag ?? 0)} Kg'
      ]);
    }
    rows.add(['TOTAL', '${bill.bagCount ?? 0}', '']);
    return rows;
  }

  static int _totalBags(BillModel bill) {
    return bill.bagCount ??
        bill.gonis?.fold<int>(0, (sum, g) => sum + (g.bagCount ?? 0)) ??
        bill.items?.fold<int>(0, (sum, i) => sum + (i.bagCount ?? 0)) ??
        0;
  }

  static int _typedBagCount(BillModel bill, String typeText) {
    final needle = typeText.toLowerCase();
    if (bill.gonis?.isNotEmpty == true) {
      return bill.gonis!.fold<int>(0, (sum, goni) {
        final name = (goni.goniType?.name ?? '').toLowerCase();
        return name.contains(needle) ? sum + (goni.bagCount ?? 0) : sum;
      });
    }

    final name = (bill.goniType?.name ?? '').toLowerCase();
    return name.contains(needle) ? bill.bagCount ?? 0 : 0;
  }

  static List<List<String>> _qualityRows(List<BillDeduction> deductions) {
    final byCode = <String, List<num>>{};
    if (deductions.isNotEmpty) {
      for (final d in deductions) {
        if (d.variableDetails?.isNotEmpty == true) {
          for (final detail in d.variableDetails!) {
            final code = detail.code ?? detail.label ?? 'quality';
            // Existing UI uses: actual = allowed, custom = entered actual.
            byCode[code] = [
              _toNum(detail.actual),
              _toNum(detail.custom ?? detail.actual),
              _toNum(detail.deducted ?? detail.deductionValue),
            ];
          }
          continue;
        }

        final codes = <String>{
          ...?d.customInputs?.keys,
          ...?d.actualInputs?.keys,
          ...?d.defaultInputs?.keys,
          ...?d.allowedInputs?.keys,
          ...?d.deductedInputs?.keys,
          ...?d.deductedAmounts?.keys,
          ...?d.variableDeductions?.keys,
        };

        for (final code in codes) {
          // Match BillSummaryScreen._getNestedVal:
          // allowed comes from actualInputs/defaultInputs, actual comes from
          // customInputs and falls back to allowed when no custom value exists.
          final allowed = _deductionValue(d, 'actualInputs', code);
          final actual = _deductionValue(d, 'customInputs', code,
              fallback: allowed.toString());
          final deducted = _deductionValue(d, 'deductedInputs', code);
          byCode[code] = [allowed, actual, deducted];
        }
      }
    }
    if (byCode.isEmpty) {
      byCode.addAll({
        'damage': [2, 0, 0],
        'fm': [2, 0, 0],
        'moisture': [10, 0, 0],
        'green_seeds': [2, 0, 0],
      });
    }
    return byCode.entries
        .map((entry) => [
              _label(entry.key),
              _fmt(entry.value[0]),
              _fmt(entry.value[1]),
              _fmtPrecise(entry.value[2]),
            ])
        .toList();
  }

  static num _deductionValue(
    BillDeduction d,
    String group,
    String key, {
    String fallback = '0',
  }) {
    if (group == 'actualInputs' && d.actualInputs != null) {
      return _toNum(d.actualInputs![key] ?? fallback);
    }
    if (group == 'customInputs' && d.customInputs != null) {
      return _toNum(d.customInputs![key] ?? d.actualInputs?[key] ?? fallback);
    }
    if (group == 'deductedInputs' && d.deductedInputs != null) {
      return _toNum(d.deductedInputs![key] ?? fallback);
    }
    if (group == 'deductedAmounts' && d.deductedAmounts != null) {
      return _toNum(d.deductedAmounts![key] ?? fallback);
    }

    final payload = d.payload;
    if (payload != null && payload[group] is Map) {
      return _toNum((payload[group] as Map)[key] ?? fallback);
    }
    if (group == 'actualInputs' && d.defaultInputs != null) {
      return _toNum(d.defaultInputs![key] ?? fallback);
    }
    if (group == 'deductedInputs') {
      return _toNum(
          d.deductedAmounts?[key] ?? d.variableDeductions?[key] ?? fallback);
    }
    return _toNum(fallback);
  }

  static String _bagLabel(String? name, num? weight) {
    final cleanName = _clean(name);
    if (weight == null || weight == 0) return cleanName;
    return '$cleanName (${_fmt(weight)} Kg)';
  }

  static String _label(String code) {
    switch (code.toLowerCase()) {
      case 'fm':
      case 'mati':
        return 'FM (%)';
      case 'damage':
      case 'dagi':
        return 'Damage (%)';
      case 'moisture':
        return 'Moisture (%)';
      case 'green':
      case 'green_seed':
      case 'green_seeds':
        return 'Green Seed (%)';
      default:
        return code
            .replaceAll('_', ' ')
            .split(' ')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
    }
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static num _asQtl(num value, String? unit) {
    final normalized = (unit ?? '').toUpperCase();
    if (normalized == 'KG' || normalized == 'KGS') return value / 100;
    return value;
  }

  static num _toNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _clean(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? 'N/A' : text;
  }

  static String _short(String? value) {
    final text = _clean(value);
    if (text == 'N/A' || text.length <= 14) return text;
    return text.substring(0, 14).toUpperCase();
  }

  static String _fmt(num value) => value.toStringAsFixed(2);
  static String _fmtPrecise(num value) => value.toStringAsFixed(4);

  static String _money(num value) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return formatter.format(value);
  }
}
