import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/dashboard/customerOrderDetailsPage.dart';
import 'package:vrs_erp/dashboard/orderStatus.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsPage extends StatefulWidget {
  final List<Map<String, dynamic>> orderDetails;
  final DateTime fromDate;
  final DateTime toDate;
  final String orderType;

  const OrderDetailsPage({
    super.key,
    required this.orderDetails,
    required this.fromDate,
    required this.toDate,
    required this.orderType,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Future<void> _launchWhatsApp(String phoneNumber) async {
    final whatsappUrl = "https://wa.me/$phoneNumber";
    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp')),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final phoneUrl = "tel:$phoneNumber";
    if (await canLaunch(phoneUrl)) {
      await launch(phoneUrl);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not make a call')));
    }
  }

  void _showContactOptions(BuildContext context, String phoneNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent, // Make background transparent for rounded bottom
      isScrollControlled: true,
      builder:
          (context) => SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(0),
                  bottom: Radius.circular(0),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const FaIcon(
                            FontAwesomeIcons.whatsapp,
                            color: Colors.green,
                          ),
                          title: const Text('Message on WhatsApp'),
                          onTap: () {
                            Navigator.pop(context);
                            _launchWhatsApp(phoneNumber);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.call, color: Colors.blue),
                          title: const Text('Call'),
                          onTap: () {
                            Navigator.pop(context);
                            _makePhoneCall(phoneNumber);
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalOrders = widget.orderDetails.fold(
      0,
      (sum, item) => sum + (item['totalorder'] as int),
    );
    int totalQuantity = widget.orderDetails.fold(
      0,
      (sum, item) => sum + (item['totalqty'] as int),
    );
    int totalAmount = widget.orderDetails.fold(
      0,
      (sum, item) => sum + (item['totalamt'] as int),
    );

    return Scaffold(
      backgroundColor: Colors.white,
 appBar: AppBar(
  title: const Text(
    'Order Details',
    style: TextStyle(color: Colors.white),
  ),
  backgroundColor: AppColors.primaryColor,
  elevation: 1,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
    onPressed: () => Navigator.pop(context),
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
      tooltip: 'Order Status',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OrderStatus()),
        );
      },
    ),
    PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      offset: const Offset(0, 40), // Positions the menu below the three-dot icon
      onSelected: (String value) {
        switch (value) {
          case 'download':
            _handleDownload();
            break;
          case 'whatsapp':
            _handleWhatsAppShare();
            break;
          case 'view':
            _handleView();
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'download',
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 0.0,
            ),
            leading: Icon(
              Icons.download,
              size: 20,
              color: Colors.blue,
            ),
            title: Text('Download'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'whatsapp',
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 0.0,
            ),
            leading: FaIcon(
              FontAwesomeIcons.whatsapp,
              size: 20,
              color: Colors.green,
            ),
            title: Text('WhatsApp'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'view',
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 0.0,
            ),
            leading: FaIcon(
              FontAwesomeIcons.eye,
              size: 18,
              color: Colors.blue,
            ),
            title: Text('View'),
          ),
        ),
      ],
    ),
  ],
),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Orders',
                      totalOrders.toString(),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Qty',
                      totalQuantity.toString(),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Amount',
                      '₹${totalAmount.toString()}',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              ...widget.orderDetails.map((order) {
                return Column(
                  children: [
                    _buildCustomerOrderCard(context, order),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Future<pw.Document> _generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Company name centered
            pw.Center(
              child: pw.Text(
                UserSession.coBrName ?? 'VRS Software',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 10),

            // Print date right-aligned
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Print Date: ${DateTime.now().toString().substring(0, 19)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Table
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(3),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Customer Name',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Total Order',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Total Qty',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Total Amt',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                // Data Rows
                ...widget.orderDetails.map((order) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(order['customernamewithcity'] ?? ''),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(order['totalorder'].toString()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(order['totalqty'].toString()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(order['totalamt'].toString()),
                      ),
                    ],
                  );
                }).toList(),

                // Total Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Total',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        widget.orderDetails
                            .fold<int>(
                              0,
                              (sum, item) => sum + (item['totalorder'] as int),
                            )
                            .toString(),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        widget.orderDetails
                            .fold<int>(
                              0,
                              (sum, item) => sum + (item['totalqty'] as int),
                            )
                            .toString(),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        widget.orderDetails
                            .fold<int>(
                              0,
                              (sum, item) => sum + (item['totalamt'] as int),
                            )
                            .toString(),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  Future<String> _savePDF(pw.Document pdf) async {
    String filePath = '';

    try {
      // Request storage permissions for Android
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          // For Android 13+, try manageExternalStorage if needed
          status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permission denied')),
            );
            return '';
          }
        }
      }

      // Determine the Downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        // On Android, use the Downloads directory
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          // Fallback to getExternalStorageDirectory if Downloads folder doesn't exist
          downloadsDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        // On iOS, use the Documents directory (Downloads folder is restricted)
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir != null) {
        final file = File(
          '${downloadsDir.path}/SalesOrder_TotalOrderSummary_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        await file.writeAsBytes(await pdf.save());
        filePath = file.path;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to access Downloads directory')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving PDF: $e')));
    }

    return filePath;
  }

  void _handleDownload() async {
    try {
      final pdf = await _generatePDF();
      final filePath = await _savePDF(pdf);
      if (filePath.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Platform.isAndroid
                  ? 'PDF downloaded to Downloads folder: $filePath'
                  : 'PDF saved to Documents: $filePath',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error downloading PDF: $e')));
    }
  }

  void _handleView() async {
    try {
      final pdf = await _generatePDF();
      final bytes = await pdf.save();

      // Create a temporary file (optional, some PDF viewers can work with bytes directly)
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_preview.pdf');
      await tempFile.writeAsBytes(bytes);

      final result = await OpenFile.open(tempFile.path);

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening PDF: ${result.message}')),
        );
      }

      // Optionally delete the temp file after viewing (or let the system handle it)
      // tempFile.delete();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error viewing PDF: $e')));
    }
  }

  void _handleWhatsAppShare() {
    // Implement WhatsApp share functionality (as before)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('WhatsApp share functionality will be implemented here'),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    IconData iconData;
    switch (title) {
      case 'Total Orders':
        iconData = Icons.receipt_long;
        break;
      case 'Total Qty':
        iconData = Icons.format_list_numbered;
        break;
      case 'Total Amount':
        iconData = Icons.currency_rupee;
        break;
      default:
        iconData = Icons.info;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color.fromARGB(255, 182, 181, 181)!),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, size: 20, color: Colors.blue[700]),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.blue[900],
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerOrderCard(
    BuildContext context,
    Map<String, dynamic> order,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CustomerOrderDetailsPage(
                  custKey: order['cust_key'] ?? '',
                  customerName: order['customernamewithcity'] ?? '',
                  fromDate: widget.fromDate,
                  toDate: widget.toDate,
                  orderType: widget.orderType,
                ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Name and City
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  order['customernamewithcity'] ?? '',
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Table
              Table(
                border: TableBorder.all(color: Colors.grey.withOpacity(0.3)),
                columnWidths: const {
                  0: FlexColumnWidth(),
                  1: FlexColumnWidth(),
                  2: FlexColumnWidth(),
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 226, 240, 245),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Text(
                          'TOTAL ORDER',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Text(
                          'TOTAL QTY',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Text(
                          'TOTAL AMOUNT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text(
                          order['totalorder'].toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text(
                          order['totalqty'].toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text(
                          '₹${order['totalamt'].toString()}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (order['whatsappmobileno'] != null &&
                  order['whatsappmobileno'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: GestureDetector(
                    onTap:
                        () => _showContactOptions(
                          context,
                          order['whatsappmobileno'].toString(),
                        ),
                    child: Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.whatsapp,
                          size: 12,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order['whatsappmobileno'].toString(),
                          overflow: TextOverflow.visible,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
