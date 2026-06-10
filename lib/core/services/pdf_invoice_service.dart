import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:soya_app/features/home/model/bill_model.dart';

enum BillPrintFormat { a4, thermal58 }

class PdfInvoiceService {
  static const double _mspRate = 4300;
  static const String _companyName = 'TULJA BHAVANI SOYA PRIVATE LIMITED';
  static const String _companyShortName = 'TBSPL';
  static const String _commodity = 'SOYA SEED';
  static const String _helpline = '+91 9763087275';
  static const String _vendorPhone = '+91 98XXXXXXX';

  static Future<Uint8List> generateInvoice(
    BillModel bill, {
    BillPrintFormat format = BillPrintFormat.a4,
    List<BillDeduction>? deductions,
  }) async {
    if (format == BillPrintFormat.thermal58) {
      return generateThermal58Invoice(bill, deductions: deductions);
    }
    return generateA4Invoice(bill, deductions: deductions);
  }

  static Future<Uint8List> generateA4Invoice(
    BillModel bill, {
    List<BillDeduction>? deductions,
  }) async {
    final ttf = await PdfGoogleFonts.jostRegular();
    final ttfBold = await PdfGoogleFonts.jostBold();
    final data = _BillPrintData.fromBill(bill, deductions: deductions);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(12),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.8),
            ),
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _a4Header(ttf, ttfBold),
                pw.SizedBox(height: 5),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: _boxedSection(
                        title: 'FARMER INFORMATION',
                        icon: 'ID',
                        ttf: ttf,
                        ttfBold: ttfBold,
                        child: pw.Column(
                          children: [
                            _a4Field(ttf, ttfBold, 'Farmer ID', data.farmerId),
                            _a4Field(
                                ttf, ttfBold, 'Farmer Name', data.farmerName),
                            _a4Field(ttf, ttfBold, 'Aadhaar No.', data.aadhaar),
                            _a4Field(ttf, ttfBold, 'Mobile No.', data.mobile),
                            _a4Field(ttf, ttfBold, 'Village', data.village),
                            _a4Field(ttf, ttfBold, 'Taluka', data.taluka),
                            _a4Field(ttf, ttfBold, 'District', data.district),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      child: _boxedSection(
                        title: 'PURCHASE INFORMATION',
                        icon: 'GRN',
                        ttf: ttf,
                        ttfBold: ttfBold,
                        child: pw.Column(
                          children: [
                            pw.Container(
                              margin: const pw.EdgeInsets.only(bottom: 5),
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(
                                    color: PdfColors.grey700, width: 0.6),
                                borderRadius: pw.BorderRadius.circular(2),
                              ),
                              child: pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text("Today's Purchase Rate",
                                      style: pw.TextStyle(
                                          font: ttfBold, fontSize: 8)),
                                  pw.Text('Rs. ${data.actualRate} / Qtl',
                                      style: pw.TextStyle(
                                          font: ttfBold, fontSize: 8)),
                                ],
                              ),
                            ),
                            _a4Field(ttf, ttfBold, 'GRN No.', data.grnNo),
                            _a4Field(ttf, ttfBold, 'KP No.', data.kpNo),
                            _a4Field(ttf, ttfBold, 'Date', data.date),
                            _a4Field(ttf, ttfBold, 'Time', data.time),
                            _a4Field(
                                ttf, ttfBold, 'Purchase Center', data.location),
                            _a4Field(ttf, ttfBold, 'Commodity',
                                '$_commodity (Gov. MSP : Rs. ${_mspRate.toStringAsFixed(0)} / Qtl)'),
                            _a4Field(
                                ttf, ttfBold, 'Vehicle No.', data.vehicleNo),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: _boxedSection(
                        title: 'WEIGHT SUMMARY',
                        icon: 'WT',
                        ttf: ttf,
                        ttfBold: ttfBold,
                        child: pw.Column(
                          children: [
                            _a4ValueRow(ttf, ttfBold, 'Gross Weight',
                                '${data.grossKg} KG'),
                            _a4ValueRow(ttf, ttfBold, 'Bag Weight (Deduction)',
                                '${data.bagDeductionKg} KG'),
                            _dashLine(),
                            _a4ValueRow(
                                ttf, ttfBold, 'Net Weight', '${data.netKg} KG',
                                highlight: true),
                            pw.SizedBox(height: 5),
                            _pill(ttfBold,
                                'Actual Purchase Rate  :  Rs. ${data.actualRate} / Qtl'),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      child: _boxedSection(
                        title: 'BILL SUMMARY',
                        icon: 'BILL',
                        ttf: ttf,
                        ttfBold: ttfBold,
                        child: pw.Column(
                          children: [
                            _miniTable(
                              ttf,
                              ttfBold,
                              headers: ['Particulars', 'Quantity (Bags)'],
                              rows: data.bagRows,
                            ),
                            pw.SizedBox(height: 5),
                            _pill(ttfBold,
                                'Payable Amount (Rs.)   ${data.payableAmount}'),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      child: _boxedSection(
                        title: 'QUALITY / LAB ANALYSIS',
                        icon: 'QC',
                        ttf: ttf,
                        ttfBold: ttfBold,
                        child: pw.Column(
                          children: [
                            _miniTable(
                              ttf,
                              ttfBold,
                              headers: [
                                'Parameter',
                                'Allowed',
                                'Actual',
                                'Deduction'
                              ],
                              rows: data.qualityRows,
                              widths: const {
                                0: pw.FlexColumnWidth(1.45),
                                1: pw.FlexColumnWidth(.85),
                                2: pw.FlexColumnWidth(.85),
                                3: pw.FlexColumnWidth(.95),
                              },
                            ),
                            _a4ValueRow(ttf, ttfBold, 'Deduction Value (Total)',
                                data.deductionTotal,
                                highlight: true),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                _boxedSection(
                  title: 'BANK DETAILS',
                  icon: 'BANK',
                  ttf: ttf,
                  ttfBold: ttfBold,
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            _a4Field(ttf, ttfBold, 'Bank Name', data.bankName),
                            _a4Field(
                                ttf, ttfBold, 'Account Number', data.accountNo),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            _a4Field(ttf, ttfBold, 'Account Holder',
                                data.holderName),
                            _a4Field(ttf, ttfBold, 'IFSC Code', data.ifsc),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),
                _declarationSection(ttf, ttfBold, data),
                pw.SizedBox(height: 4),
                _footerBand(ttf, ttfBold, data),
                pw.SizedBox(height: 3),
                _a4BottomBagDetails(ttf, ttfBold, data),
              ],
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
  }) async {
    final ttf = await PdfGoogleFonts.robotoMonoRegular();
    final ttfBold = await PdfGoogleFonts.robotoMonoBold();
    final data = _BillPrintData.fromBill(bill, deductions: deductions);
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          58 * PdfPageFormat.mm,
          430 * PdfPageFormat.mm,
          marginAll: 3 * PdfPageFormat.mm,
        ),
        build: (context) {
          return pw.DefaultTextStyle(
            style: pw.TextStyle(font: ttf, fontSize: 7.2),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _thermalCenter(ttfBold, _companyName, size: 8.5),
                _thermalCenter(ttfBold, 'FARMER PURCHASE RECEIPT', size: 8),
                _thermalLine(),
                _thermalRow(ttf, ttfBold, 'Farmer Name', data.farmerName),
                _thermalRow(ttf, ttfBold, 'Mobile No', data.mobile),
                _thermalRow(ttf, ttfBold, 'Village', data.village),
                _thermalRow(ttf, ttfBold, 'Taluka', data.taluka),
                _thermalRow(ttf, ttfBold, 'District', data.district),
                _thermalLine(),
                _thermalRow(ttf, ttfBold, 'KP No', data.kpNo),
                _thermalRow(ttf, ttfBold, 'Date', data.date),
                _thermalRow(ttf, ttfBold, 'Time', data.time),
                _thermalRow(ttf, ttfBold, 'Purchase Center', data.location),
                _thermalRow(ttf, ttfBold, 'Commodity', _commodity),
                _thermalRow(ttf, ttfBold, 'Gov MSP',
                    'Rs ${_mspRate.toStringAsFixed(0)} / Qtl'),
                pw.SizedBox(height: 2),
                _thermalBox(ttfBold,
                    "Today's Purchase Rate : Rs ${data.actualRate} / Qtl"),
                _thermalLine(),
                _thermalCenter(ttfBold, 'WEIGHT DETAILS'),
                _thermalRow(ttf, ttfBold, 'Gross Weight', '${data.grossKg} KG'),
                _thermalRow(
                    ttf, ttfBold, 'Bag Deduction', '${data.bagDeductionKg} KG'),
                _thermalLine(),
                _thermalRow(ttf, ttfBold, 'Net Weight', '${data.netKg} KG',
                    boldValue: true),
                _thermalRow(
                    ttf, ttfBold, 'Actual Rate', 'Rs ${data.actualRate} / Qtl'),
                _thermalLine(),
                _thermalCenter(ttfBold, 'QUALITY DETAILS'),
                ...data.thermalQualityRows.map(
                  (row) => _thermalRow(ttf, ttfBold, row[0], row[1]),
                ),
                _thermalLine(),
                _thermalRow(ttf, ttfBold, 'Deduction Total',
                    'Rs ${data.deductionTotal}'),
                _thermalLine(),
                _thermalCenter(ttfBold, 'BAG DETAILS'),
                ...data.thermalBagRows.map(
                  (row) => _thermalRow(ttf, ttfBold, row[0], row[1]),
                ),
                _thermalLine(),
                _thermalCenter(ttfBold, 'PAYMENT DETAILS'),
                _thermalBox(
                    ttfBold, 'Payable Amount : Rs ${data.payableAmount}'),
                _thermalLine(),
                _thermalCenter(ttfBold, 'BANK DETAILS'),
                _thermalRow(ttf, ttfBold, 'Bank Name', data.bankName),
                _thermalRow(ttf, ttfBold, 'A/C Holder', data.holderName),
                _thermalRow(ttf, ttfBold, 'A/C Number', data.accountNo),
                _thermalRow(ttf, ttfBold, 'IFSC Code', data.ifsc),
                _thermalLine(),
                _thermalCenter(ttfBold, 'DECLARATION'),
                pw.Text(
                  'I confirm that the supplied crop belongs to me and payment details mentioned above are accepted by me.',
                  textAlign: pw.TextAlign.left,
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _thermalSign(ttf, 'Farmer Signature'),
                    _thermalSign(ttf, 'Lab / Godown'),
                  ],
                ),
                _thermalLine(),
                _thermalCenter(ttfBold, 'Farmer Helpline : $_helpline'),
                _thermalCenter(ttfBold, 'Vendor No : ${data.vendorNo}'),
                _thermalLine(),
                _thermalCenter(ttf, 'System Generated Receipt'),
                _thermalCenter(ttfBold, 'Thank You! Visit Again.'),
                _thermalLine(),
                _thermalBottomBagDetails(ttf, ttfBold, data),
                _thermalLine(),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
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
                _a4ReturnField(ttf, ttfBold, 'Purchase Rate',
                    'Rs. ${data.actualRate} / Qtl'),
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
      pw.Font ttf, pw.Font ttfBold, _BillPrintData data) {
    return _boxedSection(
      title: 'DECLARATION',
      icon: 'DOC',
      ttf: ttf,
      ttfBold: ttfBold,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'I, ${data.farmerName}, confirm that the supplied crop belongs to me and the payment details mentioned above are accepted by me.',
            style: pw.TextStyle(font: ttf, fontSize: 8),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Payable Amount: Rs. ${data.payableAmount}/-  (${_numberToWords(data.payableRounded)} ONLY)',
            style: pw.TextStyle(font: ttfBold, fontSize: 8),
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              _signature(ttfBold, 'Farmer Signature'),
              pw.SizedBox(width: 45),
              _signature(ttfBold, 'Lab Chemist / Godown Incharge'),
            ],
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

  static pw.Widget _thermalLine() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Text('--------------------------------',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 7)),
    );
  }

  static pw.Widget _thermalRow(
    pw.Font ttf,
    pw.Font ttfBold,
    String label,
    String value, {
    bool boldValue = false,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 55,
          child:
              pw.Text(label, style: pw.TextStyle(font: ttfBold, fontSize: 7)),
        ),
        pw.Text(': ', style: pw.TextStyle(font: ttf, fontSize: 7)),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(font: boldValue ? ttfBold : ttf, fontSize: 7),
          ),
        ),
      ],
    );
  }

  static pw.Widget _thermalBox(pw.Font ttfBold, String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: .5),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Text(text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: ttfBold, fontSize: 7.2)),
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
          _thermalRow(ttf, ttfBold, 'Rate', 'Rs ${data.actualRate} / Qtl'),
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
        pw.Text(label, style: pw.TextStyle(font: ttf, fontSize: 5.4)),
      ],
    );
  }

  static Future<File> savePdfFile(String fileName, Uint8List byteList) async {
    Directory? output;
    if (Platform.isAndroid) {
      output = Directory('/storage/emulated/0/Download/SoyaApp');
    } else {
      output = await getApplicationDocumentsDirectory();
    }

    if (!await output.exists()) {
      await output.create(recursive: true);
    }

    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(byteList);
    return file;
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
  final String deductionTotal;
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
    required this.deductionTotal,
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
    final bagDeductionQtl =
        _asQtl(calc?.bagWeight ?? bill.goniWeight ?? 0, 'KG');
    final grossQtl = calc?.totalQuantityReceived != null
        ? _asQtl(calc?.totalQuantityReceived ?? 0, bill.primaryUnit)
        : netQtl + bagDeductionQtl;
    final rate = calc?.rateAfterLabDeductionRounded ??
        calc?.ratePerUnit ??
        bill.ratePerUnit ??
        bill.items?.firstOrNull?.rate ??
        0;
    final payable = calc?.recalculatedTotal ??
        calc?.finalPayableAmount ??
        bill.netPayable ??
        bill.totalAmount ??
        0;
    final billDeductions = deductions?.isNotEmpty == true
        ? deductions!
        : (bill.deductions ?? const <BillDeduction>[]);
    final deductionTotal = calc?.totalLabDeductionAmount ??
        billDeductions.fold<num>(
            0, (sum, d) => sum + (d.deductionAmount ?? d.value ?? 0));

    final bagRows = _bagRows(bill);
    final qualityRows = _qualityRows(billDeductions);
    final totalBags = _totalBags(bill);
    final kaltaniBags = _typedBagCount(bill, 'kaltani');
    final ppBags = totalBags - kaltaniBags;

    return _BillPrintData(
      farmerId: _short(farmer?.id ?? bill.farmerId),
      farmerName: _clean(farmer?.name),
      aadhaar: _clean(farmer?.aadhaarNo),
      mobile: _clean(farmer?.phone),
      village: _clean(farmer?.villageAdd),
      taluka: _clean(farmer?.taluka),
      district: _clean(farmer?.district),
      grnNo: _short(bill.id),
      kpNo: _clean(bill.billNo),
      date: DateFormat('dd/MM/yyyy').format(billDate),
      time: DateFormat('hh:mm a').format(created),
      printedOn: DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now()),
      location: _clean(bill.billLocation),
      vehicleNo: _clean(bill.vehicleNumber),
      grossKg: _fmt(grossQtl * 100),
      bagDeductionKg: _fmt(bagDeductionQtl * 100),
      netKg: _fmt(netQtl * 100),
      actualRate: _fmt(rate),
      payableAmount: _money(payable),
      payableRounded: payable.round(),
      deductionTotal: _money(deductionTotal),
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
              _fmt(entry.value[2]),
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

  static String _money(num value) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return formatter.format(value);
  }
}
