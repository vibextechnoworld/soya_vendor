import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:soya_app/features/home/model/bill_model.dart';

class PdfInvoiceService {
  static Future<Uint8List> generateInvoice(BillModel bill) async {
    final ttf = await PdfGoogleFonts.jostRegular();
    final ttfBold = await PdfGoogleFonts.jostBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: ttf,
        bold: ttfBold,
      ),
    );

    final dateStr = bill.billDate != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(bill.billDate!))
        : DateFormat('dd/MM/yyyy').format(DateTime.now());

    final timeStr = DateFormat('hh:mm:ss a').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // --- HEADER SECTION ---
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  alignment: pw.Alignment.center,
                  child: pw.Column(
                    children: [
                      pw.Text(
                        "Tulja Bhavani Soya Pvt Ltd (TBS)",
                        style: pw.TextStyle(font: ttfBold, fontSize: 11),
                      ),
                      pw.Text(
                        "Goods Received Note-Cum-Kisan Payment Voucher",
                        style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 10,
                            decoration: pw.TextDecoration.underline),
                      ),
                    ],
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Printed by X888307 on $dateStr $timeStr",
                          style: pw.TextStyle(font: ttf, fontSize: 7)),
                    ],
                  ),
                ),
                pw.Divider(thickness: 0.5, color: PdfColors.black),

                // --- PURCHASE INFO GRID ---
                _buildInfoGrid(ttf, ttfBold, bill, dateStr),

                pw.Divider(thickness: 0.5, color: PdfColors.black),

                // --- MAIN DATA GRID (Weights & Quality) ---
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left: Weight Data
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                              right: pw.BorderSide(
                                  color: PdfColors.black, width: 0.5)),
                        ),
                        child: _buildWeightTable(ttf, ttfBold, bill),
                      ),
                    ),
                    // Right: Quality Parameters
                    pw.Expanded(
                      flex: 1,
                      child: _buildQualityTable(ttf, ttfBold, bill),
                    ),
                  ],
                ),

                pw.Divider(thickness: 0.5, color: PdfColors.black),

                // --- BANK DETAILS ---
                _buildBankDetailsSection(ttf, ttfBold, bill),

                pw.Divider(thickness: 0.5, color: PdfColors.black),

                // --- SIGNATURES TOP ---
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 10, horizontal: 10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSignBox(ttf, "Farmer"),
                      _buildSignBox(ttf, "Lab Chemist"),
                      _buildSignBox(ttf, "Checked By"),
                    ],
                  ),
                ),

                pw.Divider(thickness: 0.5, color: PdfColors.black),

                // --- DECLARATION ---
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Declaration :",
                          style: pw.TextStyle(font: ttfBold, fontSize: 8)),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                                "Sub: Supply of  SOYA SEED(Govt. MSP:4300Rs/Qtl)",
                                style: pw.TextStyle(font: ttf, fontSize: 8)),
                          ),
                          pw.SizedBox(width: 5),
                          pw.Text("Vide above GRN to ADMLVP, Latur.",
                              style: pw.TextStyle(font: ttf, fontSize: 8)),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            flex: 2,
                            child: pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(
                                      text: "I ",
                                      style: pw.TextStyle(
                                          font: ttfBold, fontSize: 8)),
                                  pw.TextSpan(
                                      text: bill.farmer?.name ??
                                          '________________',
                                      style: pw.TextStyle(
                                          font: ttfBold, fontSize: 8)),
                                  pw.TextSpan(
                                      text: " S/O VINAYAK",
                                      style:
                                          pw.TextStyle(font: ttf, fontSize: 8)),
                                ],
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                                "R/Pan ${bill.farmer?.villageAdd ?? '________'}",
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(font: ttf, fontSize: 8)),
                          ),
                        ],
                      ),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                                "Talluka  ${bill.farmer?.taluka ?? '________'}",
                                style: pw.TextStyle(font: ttf, fontSize: 8)),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                                "District   ${bill.farmer?.district ?? '________'}",
                                style: pw.TextStyle(font: ttf, fontSize: 8)),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                                "PAN  ${bill.farmer?.panNo ?? '________'}",
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(font: ttf, fontSize: 8)),
                          ),
                        ],
                      ),
                      pw.Text(
                          "Confirm that afore said goods supplied by me has been produced by me.",
                          style: pw.TextStyle(font: ttf, fontSize: 8)),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                                "I Received Rs. ___________ ${(bill.netPayable ?? 0).toStringAsFixed(2)} (Rupees)  in words",
                                style: pw.TextStyle(font: ttf, fontSize: 8)),
                          ),
                        ],
                      ),
                      pw.Text(
                          "${_numberToWords(bill.netPayable?.toInt() ?? 0)} Only",
                          style: pw.TextStyle(font: ttfBold, fontSize: 8)),
                      pw.Text(
                          "from TBS by Cheque/Cash/Bank Transfer in full settlement of the payment for the commodity supplied as above.",
                          style: pw.TextStyle(font: ttf, fontSize: 7)),
                    ],
                  ),
                ),

                pw.Divider(thickness: 0.5, color: PdfColors.black),

                // --- SIGNATURES BOTTOM ---
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSignLabel(ttf, "F/O Asst."),
                      _buildSignLabel(ttf, "Godown Sup."),
                      _buildSignLabel(ttf, "Scroll Sup."),
                      _buildSignLabel(ttf, "Cashier"),
                      _buildSignLabel(ttf, "Farmer"),
                    ],
                  ),
                ),

                // --- MINI DETAILS GRID ---
                _buildMiniDetails(ttf, ttfBold, bill, dateStr),

                // pw.Divider(thickness: 0.5, color: PdfColors.black),

                // // --- BANK DETAILS SECTION ---
                // _buildBankDetailsSection(ttf, ttfBold),

                // pw.Divider(thickness: 0.5, color: PdfColors.black),

                // --- GUNNY INFO ---
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        children: [
                          _buildSmallInput(ttf, "Gunny Card"),
                          _buildSmallInput(ttf, "If yes Card No."),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        children: [
                          _buildSmallInput(ttf, "Gunny Replace"),
                          pw.Spacer(),
                          pw.Text("Godown Supervisor",
                              style: pw.TextStyle(font: ttf, fontSize: 7)),
                          pw.SizedBox(width: 20),
                          pw.Text("Gunny Godown Asst.",
                              style: pw.TextStyle(font: ttf, fontSize: 7)),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- FOOTER TABLE ---
                _buildFooterTable(ttf, ttfBold, bill, dateStr),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildInfoGrid(
      pw.Font ttf, pw.Font ttfBold, BillModel bill, String date) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              children: [
                _buildRow(ttf, ttfBold, "KP No :", bill.billNo ?? 'N/A'),
                _buildRow(ttf, ttfBold, "Kisan Id :",
                    bill.farmer?.aadhaarNo ?? 'N/A'),
                _buildRow(
                    ttf, ttfBold, "Mobile No. :", bill.farmer?.phone ?? 'N/A'),
                _buildRow(
                    ttf, ttfBold, "Place :", bill.farmer?.villageAdd ?? 'N/A'),
                _buildRow(ttf, ttfBold, "Commodity :",
                    "SOYA SEED(Govt. MSP:4300Rs/Qtl)"),
                _buildRow(ttf, ttfBold, "GRN No :",
                    bill.id?.substring(0, 5) ?? 'N/A'),
                _buildRow(ttf, ttfBold, "Purchase Type :",
                    "00 - Direct Farmer Purchase"),
                _buildRow(
                    ttf,
                    ttfBold,
                    "Kisan Bank Details :",
                    bill.farmer?.banks?.isNotEmpty == true
                        ? "${bill.farmer?.banks?.first.bankName}, ${bill.farmer?.banks?.first.ifsc}"
                        : "N/A"),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              children: [
                _buildRow(ttf, ttfBold, "Purchase Point :", "RP Renapur"),
                _buildRow(ttf, ttfBold, "Date :", date),
                _buildRow(ttf, ttfBold, "Name :",
                    (bill.farmer?.name ?? 'N/A').toUpperCase()),
                _buildRow(
                    ttf, ttfBold, "Veh. No :", bill.vehicleNumber ?? 'N/A'),
                _buildRow(
                    ttf, ttfBold, "Veh. Type :", bill.vehicleType ?? 'N/A'),
                _buildRow(ttf, ttfBold, "Driver Name :",
                    (bill.driverName ?? 'N/A').toUpperCase()),
                _buildRow(ttf, ttfBold, "Place Desc :", "Not Available"),
                _buildRow(ttf, ttfBold, "Warehouse Issue No :", ""),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildRow(
      pw.Font ttf, pw.Font ttfBold, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.SizedBox(
              width: 80,
              child:
                  pw.Text(label, style: pw.TextStyle(font: ttf, fontSize: 8))),
          pw.Expanded(
              child: pw.Text(value,
                  style: pw.TextStyle(font: ttfBold, fontSize: 8))),
        ],
      ),
    );
  }

  static pw.Widget _buildWeightTable(
      pw.Font ttf, pw.Font ttfBold, BillModel bill) {
    final style = pw.TextStyle(font: ttf, fontSize: 8);
    final styleBold = pw.TextStyle(font: ttfBold, fontSize: 8);

    final grossQty = bill.primaryQuantity ?? 0;
    final rate = bill.ratePerUnit ?? 0;
    final grossAmount = bill.grossAmount ?? (grossQty * rate);

    // Sum up quality deductions
    final qualityDeductions =
        bill.deductions?.fold<num>(0, (sum, d) => sum + (d.value ?? 0)) ?? 0;
    final goniDeductionAmount = bill.goniDeductionAmount ?? 0;
    final netPayable = bill.netPayable ??
        (grossAmount - qualityDeductions - goniDeductionAmount);

    return pw.Table(
      border: const pw.TableBorder(
          bottom: pw.BorderSide(color: PdfColors.black, width: .5)),
      children: [
        _buildTableCellRow(
            "Gross Qty (QTL):", grossQty.toStringAsFixed(2), style,
            textAlign: pw.TextAlign.right),
        _buildTableCellRow("Purchase Rate:", rate.toStringAsFixed(2), style,
            textAlign: pw.TextAlign.right),
        _buildTableCellRow(
            "Gross Amount:", grossAmount.toStringAsFixed(2), styleBold,
            textAlign: pw.TextAlign.right),
        if (qualityDeductions > 0)
          _buildTableCellRow(
              "Quality Deduct:", qualityDeductions.toStringAsFixed(2), style,
              textAlign: pw.TextAlign.right),
        if (goniDeductionAmount > 0)
          _buildTableCellRow(
              "Goni Deduct:", goniDeductionAmount.toStringAsFixed(2), style,
              textAlign: pw.TextAlign.right),
        _buildTableCellRow(
            "Net Payable:", netPayable.toStringAsFixed(2), styleBold,
            textAlign: pw.TextAlign.right),
      ],
    );
  }

  static pw.TableRow _buildTableCellRow(
      String label, String value, pw.TextStyle style,
      {pw.TextAlign textAlign = pw.TextAlign.left}) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(3),
          child: pw.Text(label, style: style),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(3),
          decoration: const pw.BoxDecoration(
              border: pw.Border(
                  left: pw.BorderSide(color: PdfColors.black, width: 0.5))),
          child: pw.Text(value, style: style, textAlign: textAlign),
        ),
      ],
    );
  }

  static String _getDisplayLabel(String code) {
    switch (code.toLowerCase()) {
      case 'moisture':
        return 'Moisture %';
      case 'fm':
      case 'mati':
        return 'Foreign Material %';
      case 'damage':
      case 'dagi':
        return 'Damaged Seeds %';
      case 'green':
      case 'green_seeds':
        return 'Green Seeds %';
      case 'oil':
        return 'Oil Content %';
      default:
        // Capitalize and replace underscores
        return code
            .split('_')
            .map((word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                : '')
            .join(' ');
    }
  }

  static pw.Widget _buildQualityTable(
      pw.Font ttf, pw.Font ttfBold, BillModel bill) {
    final style = pw.TextStyle(font: ttf, fontSize: 8);
    final styleBold = pw.TextStyle(font: ttfBold, fontSize: 8);

    List<pw.TableRow> rows = [];

    // Header row for quality
    rows.add(pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(2),
          child: pw.Text("Parameter", style: styleBold),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(2),
          decoration: const pw.BoxDecoration(
              border: pw.Border(
                  left: pw.BorderSide(color: PdfColors.black, width: 0.5))),
          child: pw.Text("Actual",
              style: styleBold, textAlign: pw.TextAlign.center),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(2),
          decoration: const pw.BoxDecoration(
              border: pw.Border(
                  left: pw.BorderSide(color: PdfColors.black, width: 0.5))),
          child: pw.Text("Deduct",
              style: styleBold, textAlign: pw.TextAlign.center),
        ),
      ],
    ));

    // Find all unique quality codes across deductions
    Set<String> allCodes = {};
    if (bill.deductions != null) {
      for (var d in bill.deductions!) {
        if (d.customInputs != null) allCodes.addAll(d.customInputs!.keys);
        if (d.actualInputs != null) allCodes.addAll(d.actualInputs!.keys);
        if (d.deductedInputs != null) allCodes.addAll(d.deductedInputs!.keys);
      }
    }

    if (allCodes.isEmpty) {
      // Fallback if no specific quality data but still want consistent look
      rows.add(pw.TableRow(children: [
        pw.Padding(
            padding: const pw.EdgeInsets.all(2),
            child: pw.Text("No Quality Data", style: style)),
        pw.Container(
            decoration: const pw.BoxDecoration(
                border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.black, width: 0.5))),
            child: pw.Text("-", style: style, textAlign: pw.TextAlign.center)),
        pw.Container(
            decoration: const pw.BoxDecoration(
                border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.black, width: 0.5))),
            child: pw.Text("-", style: style, textAlign: pw.TextAlign.center)),
      ]));
    } else {
      for (var code in allCodes) {
        num actual = 0;
        num deductValue = 0;

        if (bill.deductions != null) {
          for (var d in bill.deductions!) {
            if (d.customInputs != null && d.customInputs![code] != null) {
              actual = num.tryParse(d.customInputs![code].toString()) ?? 0;
            }
            if (d.deductedInputs != null && d.deductedInputs![code] != null) {
              deductValue +=
                  num.tryParse(d.deductedInputs![code].toString()) ?? 0;
            }
          }
        }

        rows.add(pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Text(_getDisplayLabel(code), style: style),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(2),
              decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      left: pw.BorderSide(color: PdfColors.black, width: 0.5))),
              child: pw.Text(actual.toStringAsFixed(2),
                  style: style, textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(2),
              decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      left: pw.BorderSide(color: PdfColors.black, width: 0.5))),
              child: pw.Text(deductValue.toStringAsFixed(2),
                  style: style, textAlign: pw.TextAlign.center),
            ),
          ],
        ));
      }
    }

    return pw.Table(
      border: const pw.TableBorder(
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.5)),
      children: rows,
    );
  }

  static pw.Widget _buildSignBox(pw.Font ttf, String label) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 20),
        pw.Container(width: 60, height: 1, color: PdfColors.black),
        pw.Text(label, style: pw.TextStyle(font: ttf, fontSize: 8)),
      ],
    );
  }

  static pw.Widget _buildSignLabel(pw.Font ttf, String label) {
    return pw.Text(label, style: pw.TextStyle(font: ttf, fontSize: 8));
  }

  static pw.Widget _buildMiniDetails(
      pw.Font ttf, pw.Font ttfBold, BillModel bill, String date) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text("KP No : ${bill.billNo ?? 'N/A'}",
                style: pw.TextStyle(font: ttf, fontSize: 7)),
          ),
          pw.Expanded(
            child: pw.Text("Bag Details",
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: ttf, fontSize: 7)),
          ),
          pw.Expanded(
            child: pw.Text("Date : $date",
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(font: ttf, fontSize: 7)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSmallInput(pw.Font ttf, String label) {
    return pw.Row(
      children: [
        pw.Text("$label ", style: pw.TextStyle(font: ttf, fontSize: 7)),
        pw.Container(
          width: 40,
          height: 12,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 0.5),
          ),
        ),
        pw.SizedBox(width: 5),
      ],
    );
  }

  static pw.Widget _buildFooterTable(
      pw.Font ttf, pw.Font ttfBold, BillModel bill, String date) {
    final style = pw.TextStyle(font: ttf, fontSize: 7);
    final styleBold = pw.TextStyle(font: ttfBold, fontSize: 7);
    return pw.Column(
      children: [
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          children: [
            pw.TableRow(
              children: [
                pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text("Bag Type", style: style)),
                pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text("F.O", style: style)),
                pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text("C.O", style: style)),
                pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text("Total", style: styleBold)),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text("Pp Bags", style: style)),
                pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text("${bill.bagCount ?? 0}", style: style)),
                pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text("0", style: style)),
                pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text("${bill.bagCount ?? 0}", style: styleBold)),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 0.5, color: PdfColors.black),
        // Final bottom section
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("KP NO : ${bill.billNo ?? 'N/A'}", style: style),
                    pw.Text("KP Date: $date", style: style),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("( Lab - 100% Sample )", style: style),
                    pw.Text("Purchase Point: RP Renapur", style: style),
                    pw.Row(
                      children: [
                        pw.Text("No of Bags :", style: style),
                        pw.SizedBox(width: 10),
                        pw.Text("0 Gunny", style: style),
                        pw.SizedBox(width: 10),
                        pw.Text("${bill.bagCount ?? 0} PP", style: style),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _numberToWords(int number) {
    if (number == 0) return "Zero";
    var words = "";
    if (number >= 100000) {
      words += "${_numberToWords(number ~/ 100000)} Lakh ";
      number %= 100000;
    }
    if (number >= 1000) {
      words += "${_numberToWords(number ~/ 1000)} Thousand ";
      number %= 1000;
    }
    if (number >= 100) {
      words += "${_numberToWords(number ~/ 100)} Hundred ";
      number %= 100;
    }
    if (number > 0) {
      if (words != "") words += "and ";
      var unitsMap = [
        "Zero",
        "One",
        "Two",
        "Three",
        "Four",
        "Five",
        "Six",
        "Seven",
        "Eight",
        "Nine",
        "Ten",
        "Eleven",
        "Twelve",
        "Thirteen",
        "Fourteen",
        "Fifteen",
        "Sixteen",
        "Seventeen",
        "Eighteen",
        "Nineteen"
      ];
      var tensMap = [
        "Zero",
        "Ten",
        "Twenty",
        "Thirty",
        "Forty",
        "Fifty",
        "Sixty",
        "Seventy",
        "Eighty",
        "Ninety"
      ];

      if (number < 20) {
        words += unitsMap[number];
      } else {
        words += tensMap[number ~/ 10];
        if ((number % 10) > 0) words += "-${unitsMap[number % 10]}";
      }
    }
    return words;
  }

  static Future<File> savePdfFile(String fileName, Uint8List byteList) async {
    Directory? output;
    if (Platform.isAndroid) {
      // Use the public Download directory
      output = Directory('/storage/emulated/0/Download/SoyaApp');
    } else {
      // Fallback for iOS/other (documents directory)
      output = await getApplicationDocumentsDirectory();
    }

    if (!await output.exists()) {
      await output.create(recursive: true);
    }

    final file = File("${output.path}/$fileName");
    await file.writeAsBytes(byteList);
    return file;
  }

  static pw.Widget _buildBankDetailsSection(
      pw.Font ttf, pw.Font ttfBold, BillModel bill) {
    final bank = (bill.farmer?.banks != null && bill.farmer!.banks!.isNotEmpty)
        ? bill.farmer!.banks!.first
        : null;

    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("Transaction Type: e-Fund Transfer",
              style: pw.TextStyle(font: ttfBold, fontSize: 8)),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildBankPdfRow(
                        ttf, ttfBold, "A/c No.", bank?.accountNo ?? "N/A"),
                    _buildBankPdfRow(
                        ttf, ttfBold, "Bank Name", bank?.bankName ?? "N/A"),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildBankPdfRow(
                        ttf, ttfBold, "IFS Code", bank?.ifsc ?? "N/A"),
                    _buildBankPdfRow(ttf, ttfBold, "Beneficiary",
                        bank?.holderName ?? bill.farmer?.name ?? "N/A"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBankPdfRow(
      pw.Font ttf, pw.Font ttfBold, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.SizedBox(
              width: 80,
              child:
                  pw.Text(label, style: pw.TextStyle(font: ttf, fontSize: 8))),
          pw.Text(": ", style: pw.TextStyle(font: ttf, fontSize: 8)),
          pw.Expanded(
              child: pw.Text(value,
                  style: pw.TextStyle(font: ttfBold, fontSize: 8))),
        ],
      ),
    );
  }
}
