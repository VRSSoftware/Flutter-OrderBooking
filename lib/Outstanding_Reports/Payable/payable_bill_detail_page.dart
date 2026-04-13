// payable_bill_detail_page.dart
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class PayableBillDetailPage extends StatelessWidget {
  final Map<String, dynamic> bill;
  final String ledgerName;

  const PayableBillDetailPage({
    super.key,
    required this.bill,
    required this.ledgerName,
  });

  String _formatDate(String dateTimeStr) {
    try {
      DateTime dateTime = DateTime.parse(dateTimeStr);
      return "${dateTime.day} ${_getMonthAbbreviation(dateTime.month)} ${dateTime.year}";
    } catch (e) {
      return dateTimeStr;
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  int _calculateDueDays() {
    try {
      DateTime dueDt = DateTime.parse(bill['DueDt'] ?? '');
      DateTime docDt = DateTime.parse(bill['Doc_Dt'] ?? '');
      DateTime currentDate = DateTime.now();
      DateTime invalidDate = DateTime(1900, 1, 1);

      if (dueDt.isAfter(invalidDate)) {
        if (currentDate.isAfter(docDt)) {
          return dueDt.difference(docDt).inDays;
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  int _calculateOverdueDays() {
    try {
      DateTime dueDt = DateTime.parse(bill['DueDt'] ?? '');
      DateTime docDt = DateTime.parse(bill['Doc_Dt'] ?? '');
      DateTime currentDate = DateTime.now();
      DateTime invalidDate = DateTime(1900, 1, 1);

      if (dueDt.isAfter(invalidDate)) {
        if (dueDt.isAfter(docDt)) {
          int overdueDays = currentDate.difference(dueDt).inDays;
          return overdueDays > 0 ? overdueDays : 0;
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _generateAndSharePDF() async {
    final pdf = await _generatePDFDocument();
    await Printing.sharePdf(
      bytes: pdf,
      filename: '${bill['Doc_No'] ?? 'bill'}.pdf',
    );
  }

  Future<void> _downloadAndOpenPDF() async {
    try {
      final pdf = await _generatePDFDocument();
      final fileName = '${bill['Doc_No'] ?? 'bill'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // Get the documents directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Could not access storage');
      }
      
      // Create downloads folder if it doesn't exist
      final downloadsDir = Directory('${directory.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      
      // Save the PDF file
      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(pdf);
      
      // Open the file
      final result = await OpenFile.open(file.path);
      
      if (result.type != ResultType.done) {
        throw Exception('Could not open file');
      }
    } catch (e) {
      // Fallback to share if download fails
      await _generateAndSharePDF();
    }
  }

  Future<Uint8List> _generatePDFDocument() async {
    final pdf = pw.Document();
    final dueDays = _calculateDueDays();
    final overdueDays = _calculateOverdueDays();
    final billAmount = (bill['BillAmt'] ?? 0).toDouble();
    final pendingAmount = (bill['BalAmt'] ?? 0).toDouble();
    final partyName = bill['Led_Name'] ?? ledgerName;
    final docNo = bill['Doc_No'] ?? '';
    final vchrType = bill['Vchr_Type'] ?? 'Bill';
    final mobile = bill['Mobile1'] ?? '';
    final address = bill['OAddr'] ?? '';
    final gstNo = bill['GSTNo'] ?? '';

    // Calculate Subtotal and Net Amount
    final subtotal = billAmount;
    final netAmount = subtotal;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (context) => [
          // Header
          pw.Container(
            padding: pw.EdgeInsets.only(bottom: 20),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey400, width: 2),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Row 1: PURCHASE INVOICE and Voucher Type
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'PURCHASE INVOICE',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange,
                      ),
                    ),
                    pw.Container(
                      padding: pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange,
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Text(
                        vchrType,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 8),
                
                // Divider
                pw.Divider(
                  height: 1,
                  thickness: 1,
                  color: PdfColors.grey400,
                ),
                
                pw.SizedBox(height: 12),
                
                // Row 2: Party Name and Document Number
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      partyName,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '[$docNo]',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 16),
                
                // Vendor Details
                if (mobile.isNotEmpty)
                  pw.Text(
                    'Phone: $mobile',
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey600,
                    ),
                  ),
                if (address.isNotEmpty)
                  pw.Text(
                    'Address: $address',
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey600,
                    ),
                  ),
                if (gstNo.isNotEmpty)
                  pw.Text(
                    'GST No: $gstNo',
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey600,
                    ),
                  ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 20),
          
          // Bill Details Table
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                // Table Header
                pw.Container(
                  padding: pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(8),
                      topRight: pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          'Particulars',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          'Details',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Table Rows
                _buildPDFTableRow('Invoice Date', _formatDate(bill['Cross_Dt'] ?? bill['Doc_Dt'] ?? '')),
                _buildPDFTableDivider(),
                _buildPDFTableRow('Reference No', bill['RefNo'] ?? '—'),
                _buildPDFTableDivider(),
                _buildPDFTableRow('Document No', docNo),
                _buildPDFTableDivider(),
                _buildPDFTableRow('Voucher Type', vchrType),
                _buildPDFTableDivider(),
                _buildPDFTableRow('Due Date', _formatDate(bill['DueDt'] ?? '')),
                _buildPDFTableDivider(),
                _buildPDFTableRow('Due Days', '$dueDays days'),
                _buildPDFTableDivider(),
                _buildPDFTableRow('Overdue Days', '$overdueDays days',
                    valueColor: overdueDays > 0 ? PdfColors.red : PdfColors.black),
              ],
            ),
          ),
          
          pw.SizedBox(height: 20),
          
          // Amount Summary
          pw.Container(
            padding: pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('₹ ${subtotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Net Amount', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.orange)),
                    pw.Text('₹ ${netAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.orange)),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Pending Amount', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('₹ ${pendingAmount.toStringAsFixed(2)}', style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: overdueDays > 0 ? PdfColors.red : PdfColors.orange,
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    
    return await pdf.save();
  }

  pw.Widget _buildPDFTableRow(
    String label,
    String value, {
    PdfColor? valueColor,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 11)),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.normal,
                color: valueColor,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFTableDivider() {
    return pw.Divider(height: 1, thickness: 0.5, color: PdfColors.grey200);
  }

  @override
  Widget build(BuildContext context) {
    final dueDays = _calculateDueDays();
    final overdueDays = _calculateOverdueDays();
    final billAmount = (bill['BillAmt'] ?? 0).toDouble();
    final pendingAmount = (bill['BalAmt'] ?? 0).toDouble();
    final partyName = bill['Led_Name'] ?? ledgerName;
    final mobile = bill['Mobile1'] ?? '';
    final address = bill['OAddr'] ?? '';
    final gstNo = bill['GSTNo'] ?? '';

    // Calculate Subtotal and Net Amount
    final subtotal = billAmount;
    final netAmount = subtotal;

    final docNo = bill['Doc_No'] ?? '';
    final vchrType = bill['Vchr_Type'] ?? 'Bill';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "$docNo [$vchrType]",
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () => _downloadAndOpenPDF(),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _generateAndSharePDF(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(height: 1, color: Colors.white.withOpacity(0.3)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Bill Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "PURCHASE INVOICE",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        vchrType,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // White Divider
                                Container(
                                  height: 1,
                                  color: Colors.white.withOpacity(0.3),
                                ),

                                const SizedBox(height: 12),

                                // Party Name and Document Number in same row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      partyName,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "[$docNo]",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Vendor Details below
                                if (mobile.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 14,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          mobile,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (address.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            address,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (gstNo.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.account_balance,
                                          size: 14,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "GST: $gstNo",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Dotted Line
                          Container(
                            height: 1,
                            child: CustomPaint(painter: DottedLinePainter()),
                          ),

                          // Bill Details
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildBillRow(
                                  "Invoice Date",
                                  _formatDate(
                                    bill['Cross_Dt'] ?? bill['Doc_Dt'] ?? '',
                                  ),
                                ),
                                _buildDottedDivider(),
                                _buildBillRow(
                                  "Reference No",
                                  bill['RefNo'] ?? '—',
                                ),
                                _buildDottedDivider(),
                                _buildBillRow("Document No", docNo),
                                _buildDottedDivider(),
                                _buildBillRow("Voucher Type", vchrType),
                                _buildDottedDivider(),
                                _buildBillRow(
                                  "Due Date",
                                  _formatDate(bill['DueDt'] ?? ''),
                                ),
                                _buildDottedDivider(),
                                _buildBillRow("Due Days", "$dueDays days"),
                                _buildDottedDivider(),
                                _buildBillRow(
                                  "Overdue Days",
                                  "$overdueDays days",
                                  valueColor:
                                      overdueDays > 0 ? AppColors.red : null,
                                ),
                              ],
                            ),
                          ),

                          // Dotted Line
                          Container(
                            height: 1,
                            child: CustomPaint(painter: DottedLinePainter()),
                          ),

                          // Amount Section - Only Subtotal and Net Amount
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildAmountRow(
                                  "Subtotal",
                                  subtotal,
                                  isBold: true,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: _buildAmountRow(
                                    "Net Amount",
                                    netAmount,
                                    isBold: true,
                                    isTotal: true,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Pending Amount",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                      Text(
                                        "₹ ${pendingAmount.toStringAsFixed(2)}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              overdueDays > 0
                                                  ? AppColors.red
                                                  : AppColors.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Dotted Line
                          Container(
                            height: 1,
                            child: CustomPaint(painter: DottedLinePainter()),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Status Card
                    if (overdueDays > 0)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "This bill is overdue by $overdueDays days. Please process payment immediately.",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isTotal = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: color ?? Colors.grey.shade700,
          ),
        ),
        Text(
          "₹ ${amount.toStringAsFixed(2)}",
          style: GoogleFonts.poppins(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? Colors.grey.shade900,
          ),
        ),
      ],
    );
  }

  Widget _buildDottedDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: CustomPaint(painter: DottedLinePainter()),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.shade300
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    const dashWidth = 5;
    const dashSpace = 5;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}