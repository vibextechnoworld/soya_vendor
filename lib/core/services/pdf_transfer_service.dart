import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:soya_app/features/home/model/vendor_transfer_list_model.dart';

class PdfTransferService {
  static Future<Uint8List> generateDispatchPdf(
      VendorTransferData transfer) async {
    final ttf = await PdfGoogleFonts.jostRegular();
    final ttfBold = await PdfGoogleFonts.jostBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: ttf,
        bold: ttfBold,
      ),
    );

    final dateStr = DateFormat('dd/MM/yyyy hh:mm a').format(
        transfer.createdAt != null
            ? DateTime.parse(transfer.createdAt!).toLocal()
            : DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey500, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    "Tulja Bhavani Soya Pvt Ltd (TBS)",
                    style: pw.TextStyle(
                        font: ttfBold, fontSize: 16, color: PdfColors.green900),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    "STOCK DISPATCH RECEIPT",
                    style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 14,
                        decoration: pw.TextDecoration.underline),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Info Section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Transfer No: ${transfer.transferNo ?? 'N/A'}",
                            style: pw.TextStyle(font: ttfBold, fontSize: 10)),
                        pw.Text("Dispatch Date/Time: $dateStr",
                            style: pw.TextStyle(font: ttf, fontSize: 9)),
                        pw.Text(
                            "Vehicle No: ${transfer.vehicalNumber ?? 'N/A'}",
                            style: pw.TextStyle(font: ttf, fontSize: 9)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("Operator: ${transfer.vendor?.name ?? 'N/A'}",
                            style: pw.TextStyle(font: ttf, fontSize: 9)),
                        pw.Text("Phone: ${transfer.vendor?.phone ?? 'N/A'}",
                            style: pw.TextStyle(font: ttf, fontSize: 9)),
                      ],
                    )
                  ],
                ),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 10),

                // Route Details
                pw.Text("ROUTE DETAILS",
                    style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 11,
                        color: PdfColors.green700)),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Source:",
                              style: pw.TextStyle(font: ttfBold, fontSize: 9)),
                          pw.Text(
                              transfer.sourceLocation?.name ??
                                  transfer.vendor?.name ??
                                  'N/A',
                              style: pw.TextStyle(font: ttf, fontSize: 9)),
                          pw.Text(
                              "Code: ${transfer.sourceLocation?.code ?? 'N/A'}",
                              style: pw.TextStyle(font: ttf, fontSize: 8)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Destination:",
                              style: pw.TextStyle(font: ttfBold, fontSize: 9)),
                          pw.Text(transfer.destinationLocation?.name ?? transfer.toVendor?.name ?? 'N/A',
                              style: pw.TextStyle(font: ttf, fontSize: 9)),
                          pw.Text(
                              transfer.destinationLocation != null
                                  ? "Code: ${transfer.destinationLocation!.code}"
                                  : (transfer.toVendor != null ? "Phone: ${transfer.toVendor!.phone ?? 'N/A'}" : "Code: N/A"),
                              style: pw.TextStyle(font: ttf, fontSize: 8)),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),

                // GPS Proof
                pw.Text("GPS DISPATCH PROOF",
                    style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 11,
                        color: PdfColors.green700)),
                pw.SizedBox(height: 5),
                pw.Text(
                    "Coordinates: ${transfer.dispatchLatitude ?? 0.0}, ${transfer.dispatchLongitude ?? 0.0}",
                    style: pw.TextStyle(font: ttf, fontSize: 9)),
                pw.Text(
                    "Dispatch Location: ${transfer.dispatchLocationText ?? 'N/A'}",
                    style: pw.TextStyle(font: ttf, fontSize: 9)),
                pw.SizedBox(height: 15),

                // Stock Details
                pw.Text("STOCK & QUANTITY DETAILS",
                    style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 11,
                        color: PdfColors.green700)),
                pw.SizedBox(height: 5),
                pw.Table(
                  border:
                      pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text("Particulars",
                                style:
                                    pw.TextStyle(font: ttfBold, fontSize: 9))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text("Quantity",
                                style: pw.TextStyle(font: ttfBold, fontSize: 9),
                                textAlign: pw.TextAlign.right)),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text("Total Dispatched Weight",
                                style: pw.TextStyle(font: ttf, fontSize: 9))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                                "${transfer.weight ?? 0.0} ${transfer.unit ?? 'QTL'}",
                                style: pw.TextStyle(font: ttfBold, fontSize: 9),
                                textAlign: pw.TextAlign.right)),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text("Total Bag Count",
                                style: pw.TextStyle(font: ttf, fontSize: 9))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text("${transfer.bagCount ?? 0} Bags",
                                style: pw.TextStyle(font: ttf, fontSize: 9),
                                textAlign: pw.TextAlign.right)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),

                // Bag Breakdown
                pw.Text("BAG TYPE BREAKDOWN",
                    style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 11,
                        color: PdfColors.green700)),
                pw.SizedBox(height: 5),
                if (transfer.items != null && transfer.items!.isNotEmpty)
                  pw.Column(
                    children: transfer.items!.map((item) {
                      final isKaltani = item.goniType?.name
                              ?.toLowerCase()
                              .contains('kaltani') ==
                          true;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                                "${item.goniType?.name ?? 'Unknown'} (${item.goniType?.weightPerBag} Kg) ${isKaltani ? '[Affects Inventory]' : '[Reference Only]'}",
                                style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 8,
                                    color: isKaltani
                                        ? PdfColors.black
                                        : PdfColors.grey700)),
                            pw.Text("${item.bagCount} Bags",
                                style:
                                    pw.TextStyle(font: ttfBold, fontSize: 8)),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                else
                  pw.Text("No bag breakdown available",
                      style: pw.TextStyle(font: ttf, fontSize: 8)),

                pw.SizedBox(height: 15),

                // Thappis
                if (transfer.thappis != null &&
                    transfer.thappis!.isNotEmpty) ...[
                  pw.Text("THAPPI (STACK) DETAILS",
                      style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 11,
                          color: PdfColors.green700)),
                  pw.SizedBox(height: 5),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: transfer.thappis!.map((thappi) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                                "Thappi Code: ${thappi.code} | Weight: ${thappi.weightQtl} QTL | Moisture: ${thappi.moisture}% | FM: ${thappi.fm}%",
                                style: pw.TextStyle(
                                    font: pw.Font.courierBold(), fontSize: 8)),
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(left: 10),
                              child: pw.Text(
                                  "Bags: ${thappi.bagBreakdown.map((e) => "${e.bagCount}x ${e.name ?? 'Bags'}").join(", ")}",
                                  style: pw.TextStyle(
                                      font: ttf,
                                      fontSize: 8,
                                      color: PdfColors.grey700)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                pw.Spacer(),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 20),
                        pw.Container(
                            width: 80, height: 1, color: PdfColors.black),
                        pw.Text("Operator Signature",
                            style: pw.TextStyle(font: ttf, fontSize: 8)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 20),
                        pw.Container(
                            width: 80, height: 1, color: PdfColors.black),
                        pw.Text("Driver Signature",
                            style: pw.TextStyle(font: ttf, fontSize: 8)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateReceivePdf(
      VendorTransferData transfer) async {
    final ttf = await PdfGoogleFonts.jostRegular();
    final ttfBold = await PdfGoogleFonts.jostBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: ttf,
        bold: ttfBold,
      ),
    );

    final dateStr = DateFormat('dd/MM/yyyy hh:mm a').format(
        transfer.completedAt != null
            ? DateTime.parse(transfer.completedAt!).toLocal()
            : DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey500, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    "Tulja Bhavani Soya Pvt Ltd (TBS)",
                    style: pw.TextStyle(
                        font: ttfBold, fontSize: 16, color: PdfColors.green900),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    "STOCK RECEIPT VERIFICATION",
                    style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 14,
                        decoration: pw.TextDecoration.underline),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Info Section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Transfer No: ${transfer.transferNo ?? 'N/A'}",
                            style: pw.TextStyle(font: ttfBold, fontSize: 10)),
                        pw.Text("Receive Date/Time: $dateStr",
                            style: pw.TextStyle(font: ttf, fontSize: 9)),
                        pw.Text(
                            "Vehicle No: ${transfer.vehicalNumber ?? 'N/A'}",
                            style: pw.TextStyle(font: ttf, fontSize: 9)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("Status: ${transfer.status ?? 'N/A'}",
                            style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 10,
                                color: transfer.status == 'RECEIVED'
                                    ? PdfColors.green900
                                    : PdfColors.red900)),
                        pw.Text(
                            "Source: ${transfer.sourceLocation?.name ?? transfer.vendor?.name ?? 'N/A'}",
                            style: pw.TextStyle(font: ttf, fontSize: 8)),
                        pw.Text(
                            "Destination: ${transfer.destinationLocation?.name ?? transfer.toVendor?.name ?? 'N/A'}",
                            style: pw.TextStyle(font: ttf, fontSize: 8)),
                      ],
                    )
                  ],
                ),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 10),

                // GPS Proof
                pw.Text("GPS RECEIVE VERIFICATION",
                    style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 11,
                        color: PdfColors.green700)),
                pw.SizedBox(height: 5),
                pw.Text(
                    "Receive Coordinates: ${transfer.receiveLatitude ?? 0.0}, ${transfer.receiveLongitude ?? 0.0}",
                    style: pw.TextStyle(font: ttf, fontSize: 9)),
                pw.Text(
                    "Receive Location: ${transfer.receiveLocationText ?? 'N/A'}",
                    style: pw.TextStyle(font: ttf, fontSize: 9)),
                pw.SizedBox(height: 15),

                // Stock Verification Table
                pw.Text("QUANTITY COMPARISON & SHORTAGE",
                    style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 11,
                        color: PdfColors.green700)),
                pw.SizedBox(height: 5),
                pw.Table(
                  border:
                      pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text("Parameter",
                                style:
                                    pw.TextStyle(font: ttfBold, fontSize: 9))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text("Dispatched",
                                style: pw.TextStyle(font: ttfBold, fontSize: 9),
                                textAlign: pw.TextAlign.right)),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text("Received",
                                style: pw.TextStyle(font: ttfBold, fontSize: 9),
                                textAlign: pw.TextAlign.right)),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text("Shortage",
                                style: pw.TextStyle(font: ttfBold, fontSize: 9),
                                textAlign: pw.TextAlign.right)),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text("Soyabean Weight",
                                style: pw.TextStyle(font: ttf, fontSize: 9))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                                "${transfer.weight ?? 0.0} ${transfer.unit ?? 'QTL'}",
                                style: pw.TextStyle(font: ttf, fontSize: 9),
                                textAlign: pw.TextAlign.right)),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                                "${transfer.receivedWeight ?? 0.0} ${transfer.receivedUnit ?? transfer.unit ?? 'QTL'}",
                                style: pw.TextStyle(font: ttf, fontSize: 9),
                                textAlign: pw.TextAlign.right)),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            "${transfer.weightDifference ?? 0.0} QTL",
                            style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 9,
                                color: (transfer.weightDifference ?? 0) > 0
                                    ? PdfColors.red900
                                    : PdfColors.black),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text("Kaltani Bags",
                                style: pw.TextStyle(font: ttf, fontSize: 9))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text("${transfer.bagCount ?? 0} Bags",
                                style: pw.TextStyle(font: ttf, fontSize: 9),
                                textAlign: pw.TextAlign.right)),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                                "${transfer.receivedBagCount ?? 0} Bags",
                                style: pw.TextStyle(font: ttf, fontSize: 9),
                                textAlign: pw.TextAlign.right)),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            "${transfer.bagDifference ?? 0} Bags",
                            style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 9,
                                color: (transfer.bagDifference ?? 0) > 0
                                    ? PdfColors.red900
                                    : PdfColors.black),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                if (transfer.status == 'DISCREPANCY') ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.red100,
                      border:
                          pw.Border.all(color: PdfColors.red900, width: 0.5),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      "DISCREPANCY ALERT: A mismatch has been identified between the dispatched quantities and received quantities. Weight shortage is ${transfer.weightDifference} QTL and bag loss is ${transfer.bagDifference} Kaltani bags.",
                      style: pw.TextStyle(
                          font: ttfBold, fontSize: 8, color: PdfColors.red900),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                ],

                pw.Spacer(),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 25),
                        pw.Container(
                            width: 80, height: 1, color: PdfColors.black),
                        pw.Text("Receiver Signature",
                            style: pw.TextStyle(font: ttf, fontSize: 8)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 25),
                        pw.Container(
                            width: 80, height: 1, color: PdfColors.black),
                        pw.Text("Driver Signature",
                            style: pw.TextStyle(font: ttf, fontSize: 8)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
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

    final file = File("${output.path}/$fileName");
    await file.writeAsBytes(byteList);
    return file;
  }
}
