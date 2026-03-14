// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:vrs_erp/constants/app_constants.dart';
// import 'package:vrs_erp/dashboard/customerOrderDetailsPage.dart';
// import 'package:vrs_erp/dashboard/orderStatus.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart' show kIsWeb;

// // ignore: avoid_web_libraries_in_flutter
// // import 'dart:html' as html;

// class OrderDetailsPage extends StatefulWidget {
//   final List<Map<String, dynamic>> orderDetails;
//   final DateTime fromDate;
//   final DateTime toDate;
//   final String orderType;

//   const OrderDetailsPage({
//     super.key,
//     required this.orderDetails,
//     required this.fromDate,
//     required this.toDate,
//     required this.orderType,
//   });

//   @override
//   State<OrderDetailsPage> createState() => _OrderDetailsPageState();
// }

// class _OrderDetailsPageState extends State<OrderDetailsPage> {
//   Future<void> _launchWhatsApp(String phoneNumber) async {
//     final whatsappUrl = "https://wa.me/$phoneNumber";
//     if (await canLaunch(whatsappUrl)) {
//       await launch(whatsappUrl);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Could not launch WhatsApp')),
//       );
//     }
//   }

//   Future<void> _makePhoneCall(String phoneNumber) async {
//     final phoneUrl = "tel:$phoneNumber";
//     if (await canLaunch(phoneUrl)) {
//       await launch(phoneUrl);
//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Could not make a call')));
//     }
//   }

//   void _showContactOptions(BuildContext context, String phoneNumber) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor:
//           Colors.transparent, // Make background transparent for rounded bottom
//       isScrollControlled: true,
//       builder:
//           (context) => SafeArea(
//             child: Container(
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.vertical(
//                   top: Radius.circular(0),
//                   bottom: Radius.circular(0),
//                 ),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.only(top: 16, bottom: 0),
//                     child: Column(
//                       children: [
//                         ListTile(
//                           leading: const FaIcon(
//                             FontAwesomeIcons.whatsapp,
//                             color: Colors.green,
//                           ),
//                           title: const Text('Message on WhatsApp'),
//                           onTap: () {
//                             Navigator.pop(context);
//                             _launchWhatsApp(phoneNumber);
//                           },
//                         ),
//                         ListTile(
//                           leading: const Icon(Icons.call, color: AppColors.primaryColor),
//                           title: const Text('Call'),
//                           onTap: () {
//                             Navigator.pop(context);
//                             _makePhoneCall(phoneNumber);
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                   const Divider(height: 1),
//                   Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.grey[300],
//                           foregroundColor: Colors.black87,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                         ),
//                         onPressed: () => Navigator.pop(context),
//                         child: const Text('Cancel'),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     int totalOrders = widget.orderDetails.fold(
//       0,
//       (sum, item) => sum + (item['totalorder'] as int),
//     );
//     int totalQuantity = widget.orderDetails.fold(
//       0,
//       (sum, item) => sum + (item['totalqty'] as int),
//     );
//     int totalAmount = widget.orderDetails.fold(
//       0,
//       (sum, item) => sum + (item['totalamt'] as int),
//     );

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text(
//           'Order Details',
//           style: TextStyle(color: Colors.white),
//         ),
//         backgroundColor: AppColors.primaryColor,
//         elevation: 1,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
//             tooltip: 'Order Status',
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const OrderStatus()),
//               );
//             },
//           ),
//           PopupMenuButton<String>(
//             icon: const Icon(Icons.more_vert, color: Colors.white),
//             offset: const Offset(
//               0,
//               40,
//             ), // Positions the menu below the three-dot icon
//             onSelected: (String value) {
//               switch (value) {
//                 case 'download':
//                   _handleDownload();
//                   break;
//                 case 'whatsapp':
//                   _handleWhatsAppShare();
//                   break;
//                 case 'view':
//                   _handleView();
//                   break;
//               }
//             },
//             itemBuilder:
//                 (BuildContext context) => <PopupMenuEntry<String>>[
//                   const PopupMenuItem<String>(
//                     value: 'download',
//                     child: ListTile(
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 16.0,
//                         vertical: 0.0,
//                       ),
//                       leading: Icon(
//                         Icons.download,
//                         size: 20,
//                         color: AppColors.primaryColor,
//                       ),
//                       title: Text('Download'),
//                     ),
//                   ),
//                   const PopupMenuItem<String>(
//                     value: 'whatsapp',
//                     child: ListTile(
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 16.0,
//                         vertical: 0.0,
//                       ),
//                       leading: FaIcon(
//                         FontAwesomeIcons.whatsapp,
//                         size: 20,
//                         color: Colors.green,
//                       ),
//                       title: Text('WhatsApp'),
//                     ),
//                   ),
//                   const PopupMenuItem<String>(
//                     value: 'view',
//                     child: ListTile(
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 16.0,
//                         vertical: 0.0,
//                       ),
//                       leading: FaIcon(
//                         FontAwesomeIcons.eye,
//                         size: 18,
//                         color: AppColors.primaryColor,
//                       ),
//                       title: Text('View'),
//                     ),
//                   ),
//                 ],
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildSummaryCard(
//                       'Total Orders',
//                       totalOrders.toString(),
//                     ),
//                   ),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: _buildSummaryCard(
//                       'Total Qty',
//                       totalQuantity.toString(),
//                     ),
//                   ),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: _buildSummaryCard(
//                       'Total Amount',
//                       '₹${totalAmount.toString()}',
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),
//               ...widget.orderDetails.map((order) {
//                 return Column(
//                   children: [
//                     _buildCustomerOrderCard(context, order),
//                     const SizedBox(height: 16),
//                   ],
//                 );
//               }).toList(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<pw.Document> _generatePDF() async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) {
//           return [
//             // Company name centered
//             pw.Center(
//               child: pw.Text(
//                 UserSession.coBrName ?? 'VRS Software',
//                 style: pw.TextStyle(
//                   fontSize: 16,
//                   fontWeight: pw.FontWeight.bold,
//                 ),
//               ),
//             ),

//             pw.SizedBox(height: 10),

//             // Print date right-aligned
//             pw.Row(
//               mainAxisAlignment: pw.MainAxisAlignment.end,
//               children: [
//                 pw.Text(
//                   'Print Date: ${DateTime.now().toString().substring(0, 19)}',
//                   style: const pw.TextStyle(fontSize: 12),
//                 ),
//               ],
//             ),

//             pw.SizedBox(height: 20),

//             // Table
//             pw.Table(
//               border: pw.TableBorder.all(),
//               columnWidths: {
//                 0: const pw.FlexColumnWidth(4),
//                 1: const pw.FlexColumnWidth(2),
//                 2: const pw.FlexColumnWidth(2),
//                 3: const pw.FlexColumnWidth(3),
//               },
//               children: [
//                 // Header Row
//                 pw.TableRow(
//                   decoration: const pw.BoxDecoration(color: PdfColors.grey200),
//                   children: [
//                     pw.Padding(
//                       padding: const pw.EdgeInsets.all(8),
//                       child: pw.Text(
//                         'Customer Name',
//                         style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                       ),
//                     ),
//                     pw.Padding(
//                       padding: const pw.EdgeInsets.all(8),
//                       child: pw.Text(
//                         'Total Order',
//                         style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                       ),
//                     ),
//                     pw.Padding(
//                       padding: const pw.EdgeInsets.all(8),
//                       child: pw.Text(
//                         'Total Qty',
//                         style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                       ),
//                     ),
//                     pw.Padding(
//                       padding: const pw.EdgeInsets.all(8),
//                       child: pw.Text(
//                         'Total Amt',
//                         style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                       ),
//                     ),
//                   ],
//                 ),

//                 // Data Rows
//                 ...widget.orderDetails.map((order) {
//                   return pw.TableRow(
//                     children: [
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(8),
//                         child: pw.Text(order['customernamewithcity'] ?? ''),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(8),
//                         child: pw.Text(order['totalorder'].toString()),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(8),
//                         child: pw.Text(order['totalqty'].toString()),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(8),
//                         child: pw.Text(order['totalamt'].toString()),
//                       ),
//                     ],
//                   );
//                 }).toList(),

//                 // Total Row
//                 pw.TableRow(
//                   decoration: const pw.BoxDecoration(color: PdfColors.grey200),
//                   children: [
//                     pw.Padding(
//                       padding: const pw.EdgeInsets.all(8),
//                       child: pw.Text(
//                         'Total',
//                         style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                       ),
//                     ),
//                     pw.Padding(
//                       padding: const pw.EdgeInsets.all(8),
//                       child: pw.Text(
//                         widget.orderDetails
//                             .fold<int>(
//                               0,
//                               (sum, item) => sum + (item['totalorder'] as int),
//                             )
//                             .toString(),
//                         style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                       ),
//                     ),
//                     pw.Padding(
//                       padding: const pw.EdgeInsets.all(8),
//                       child: pw.Text(
//                         widget.orderDetails
//                             .fold<int>(
//                               0,
//                               (sum, item) => sum + (item['totalqty'] as int),
//                             )
//                             .toString(),
//                         style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                       ),
//                     ),
//                     pw.Padding(
//                       padding: const pw.EdgeInsets.all(8),
//                       child: pw.Text(
//                         widget.orderDetails
//                             .fold<int>(
//                               0,
//                               (sum, item) => sum + (item['totalamt'] as int),
//                             )
//                             .toString(),
//                         style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ];
//         },
//       ),
//     );

//     return pdf;
//   }

//   Future<String> _savePDF(pw.Document pdf) async {
//     try {
//       final timestamp = DateTime.now().millisecondsSinceEpoch;
//       final fileName = 'SalesOrder_TotalOrderSummary_$timestamp.pdf';

//       /* ======================== WEB ======================== */
//       if (kIsWeb) {
//         // final Uint8List pdfBytes = await pdf.save();

//         // final blob = html.Blob([pdfBytes], 'application/pdf');
//         // final url = html.Url.createObjectUrlFromBlob(blob);

//         // final anchor =
//         //     html.AnchorElement(href: url)
//         //       ..setAttribute('download', fileName)
//         //       ..click();

//         // html.Url.revokeObjectUrl(url);

//         // Web has no real file path – return filename only
//         return fileName;
//       }

//       /* ====================== MOBILE ====================== */

//       // Request storage permissions for Android
//       if (Platform.isAndroid) {
//         var status = await Permission.storage.request();
//         if (!status.isGranted) {
//           status = await Permission.manageExternalStorage.request();
//           if (!status.isGranted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Storage permission denied')),
//             );
//             return '';
//           }
//         }
//       }

//       Directory? downloadsDir;

//       if (Platform.isAndroid) {
//         downloadsDir = Directory('/storage/emulated/0/Download');
//         if (!await downloadsDir.exists()) {
//           downloadsDir = await getExternalStorageDirectory();
//         }
//       } else if (Platform.isIOS) {
//         downloadsDir = await getApplicationDocumentsDirectory();
//       }

//       if (downloadsDir == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Unable to access Downloads directory')),
//         );
//         return '';
//       }

//       final file = File('${downloadsDir.path}/$fileName');
//       await file.writeAsBytes(await pdf.save());

//       return file.path;
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error saving PDF: $e')));
//       return '';
//     }
//   }

//   void _handleDownload() async {
//     try {
//       final pdf = await _generatePDF();
//       final filePath = await _savePDF(pdf);
//       if (filePath.isNotEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               Platform.isAndroid
//                   ? 'PDF downloaded to Downloads folder: $filePath'
//                   : 'PDF saved to Documents: $filePath',
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error downloading PDF: $e')));
//     }
//   }

//   void _handleView() async {
//     try {
//       final pdf = await _generatePDF();
//       final bytes = await pdf.save();

//       // Create a temporary file (optional, some PDF viewers can work with bytes directly)
//       final tempDir = await getTemporaryDirectory();
//       final tempFile = File('${tempDir.path}/temp_preview.pdf');
//       await tempFile.writeAsBytes(bytes);

//       final result = await OpenFile.open(tempFile.path);

//       if (result.type != ResultType.done) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error opening PDF: ${result.message}')),
//         );
//       }

//       // Optionally delete the temp file after viewing (or let the system handle it)
//       // tempFile.delete();
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error viewing PDF: $e')));
//     }
//   }

//   void _handleWhatsAppShare() {
//     // Implement WhatsApp share functionality (as before)
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('WhatsApp share functionality will be implemented here'),
//       ),
//     );
//   }

//   Widget _buildSummaryCard(String title, String value) {
//     IconData iconData;
//     switch (title) {
//       case 'Total Orders':
//         iconData = Icons.receipt_long;
//         break;
//       case 'Total Qty':
//         iconData = Icons.format_list_numbered;
//         break;
//       case 'Total Amount':
//         iconData = Icons.currency_rupee;
//         break;
//       default:
//         iconData = Icons.info;
//     }

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: const Color.fromARGB(255, 182, 181, 181)!),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(iconData, size: 20, color: AppColors.primaryColor),
//             const SizedBox(height: 6),
//             Text(
//               title,
//               style: GoogleFonts.poppins(
//                 fontSize: 10,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey[600],
//               ),
//               textAlign: TextAlign.center,
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 3),
//             Text(
//               value,
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w700,
//                 color: AppColors.primaryColor,
//               ),
//               textAlign: TextAlign.center,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCustomerOrderCard(
//     BuildContext context,
//     Map<String, dynamic> order,
//   ) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder:
//                 (context) => CustomerOrderDetailsPage(
//                   custKey: order['cust_key'] ?? '',
//                   customerName: order['customernamewithcity'] ?? '',
//                   fromDate: widget.fromDate,
//                   toDate: widget.toDate,
//                   orderType: widget.orderType,
//                 ),
//           ),
//         );
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border.all(color: Colors.grey.shade300),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Customer Name and City
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Text(
//                   order['customernamewithcity'] ?? '',
//                   overflow: TextOverflow.visible,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.primaryColor,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 12),

//               // Table
//               Table(
//                 border: TableBorder.all(color: Colors.grey.withOpacity(0.3)),
//                 columnWidths: const {
//                   0: FlexColumnWidth(),
//                   1: FlexColumnWidth(),
//                   2: FlexColumnWidth(),
//                 },
//                 children: [
//                   const TableRow(
//                     decoration: BoxDecoration(
//                       color: Color.fromARGB(255, 226, 240, 245),
//                     ),
//                     children: [
//                       Padding(
//                         padding: EdgeInsets.all(6.0),
//                         child: Text(
//                           'TOTAL ORDER',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 12,
//                           ),
//                           overflow: TextOverflow.visible,
//                         ),
//                       ),
//                       Padding(
//                         padding: EdgeInsets.all(6.0),
//                         child: Text(
//                           'TOTAL QTY',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 12,
//                           ),
//                           overflow: TextOverflow.visible,
//                         ),
//                       ),
//                       Padding(
//                         padding: EdgeInsets.all(6.0),
//                         child: Text(
//                           'TOTAL AMOUNT',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 12,
//                           ),
//                           overflow: TextOverflow.visible,
//                         ),
//                       ),
//                     ],
//                   ),
//                   TableRow(
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.all(6.0),
//                         child: Text(
//                           order['totalorder'].toString(),
//                           style: const TextStyle(fontSize: 12),
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.all(6.0),
//                         child: Text(
//                           order['totalqty'].toString(),
//                           style: const TextStyle(fontSize: 12),
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.all(6.0),
//                         child: Text(
//                           '₹${order['totalamt'].toString()}',
//                           style: const TextStyle(fontSize: 12),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),

//               if (order['whatsappmobileno'] != null &&
//                   order['whatsappmobileno'].toString().isNotEmpty)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 10),
//                   child: GestureDetector(
//                     onTap:
//                         () => _showContactOptions(
//                           context,
//                           order['whatsappmobileno'].toString(),
//                         ),
//                     child: Row(
//                       children: [
//                         const FaIcon(
//                           FontAwesomeIcons.whatsapp,
//                           size: 12,
//                           color: Colors.green,
//                         ),
//                         const SizedBox(width: 6),
//                         Text(
//                           order['whatsappmobileno'].toString(),
//                           overflow: TextOverflow.visible,
//                           style: const TextStyle(
//                             color: Colors.green,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

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
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// Add this color class at the top
class TableColors {
  static const Color headerBg = Color(0xFF2C3E50); // Dark blue-grey
  static const Color headerText = Colors.white;
  static const Color priceRowBg = Color(0xFFF8F9FA); // Very light grey
  static const Color evenRowBg = Colors.white;
  static const Color oddRowBg = Color(0xFFF8F9FA); // Alternating row colors
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color totalRowBg = Color(0xFFE8F4FD); // Light blue for totals
}

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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Contact Options',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),

                  // WhatsApp Option
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.whatsapp,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'WhatsApp',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(phoneNumber),
                    onTap: () {
                      Navigator.pop(context);
                      _launchWhatsApp(phoneNumber);
                    },
                  ),

                  // Call Option
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.call,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Call',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(phoneNumber),
                    onTap: () {
                      Navigator.pop(context);
                      _makePhoneCall(phoneNumber);
                    },
                  ),

                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
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
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16, // Reduced from 18 to 16
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        toolbarHeight:
            42, // ADD THIS LINE - reduces AppBar height from default ~56 to 44
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 18,
          ), // Reduced from 20 to 18
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.receipt_long,
                color: Colors.white,
                size: 20,
              ), // Reduced from 22 to 20
              tooltip: 'Order Status',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderStatus()),
                );
              },
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
              size: 22,
            ), // Added size
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'download',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.download,
                            size: 18,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Download'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'whatsapp',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.whatsapp,
                            size: 18,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('WhatsApp'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'view',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.eye,
                            size: 18,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('View'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70), // This remains unchanged
          child: Column(
            children: [
              // White divider line
              Container(
                height: 1,
                width: double.infinity,
                color: Colors.white.withOpacity(0.3),
              ),
              // Summary container
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                color: AppColors.primaryColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryItem(
                      label: 'Total Orders',
                      value: totalOrders.toString(),
                      icon: Icons.receipt,
                      color: Colors.amber,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildSummaryItem(
                      label: 'Total Qty',
                      value: totalQuantity.toString(),
                      icon: Icons.shopping_bag,
                      color: Colors.lightBlue,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildSummaryItem(
                      label: 'Total Amt',
                      value: '₹$totalAmount',
                      icon: Icons.currency_rupee,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child:
            widget.orderDetails.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No orders found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  itemCount: widget.orderDetails.length,
                  itemBuilder: (context, index) {
                    final order = widget.orderDetails[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildUniqueCard(order),
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.roboto(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUniqueCard(Map<String, dynamic> order) {
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TableColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with left border
            Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.primaryColor, width: 4),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Customer Icon with gradient background
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor,
                            AppColors.primaryColor.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.business_center,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Customer Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['customernamewithcity'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Customer',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stats in pill-shaped containers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPillStat(
                      'Orders',
                      order['totalorder'].toString(),
                      Icons.receipt,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPillStat(
                      'Qty',
                      order['totalqty'].toString(),
                      Icons.shopping_bag,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPillStat(
                      'Amount',
                      '₹${order['totalamt'].toString()}',
                      Icons.currency_rupee,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            // WhatsApp Section (if available)
            if (order['whatsappmobileno'] != null &&
                order['whatsappmobileno'].toString().isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.whatsapp,
                        size: 16,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WhatsApp',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            order['whatsappmobileno'].toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap:
                            () => _showContactOptions(
                              context,
                              order['whatsappmobileno'].toString(),
                            ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.green.shade400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
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
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'SalesOrder_TotalOrderSummary_$timestamp.pdf';

      /* ======================== WEB ======================== */
      if (kIsWeb) {
        // final Uint8List pdfBytes = await pdf.save();

        // final blob = html.Blob([pdfBytes], 'application/pdf');
        // final url = html.Url.createObjectUrlFromBlob(blob);

        // final anchor =
        //     html.AnchorElement(href: url)
        //       ..setAttribute('download', fileName)
        //       ..click();

        // html.Url.revokeObjectUrl(url);

        // Web has no real file path – return filename only
        return fileName;
      }

      /* ====================== MOBILE ====================== */

      // Request storage permissions for Android
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permission denied')),
            );
            return '';
          }
        }
      }

      Directory? downloadsDir;

      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to access Downloads directory')),
        );
        return '';
      }

      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving PDF: $e')));
      return '';
    }
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
            backgroundColor: AppColors.primaryColor,
            duration: const Duration(seconds: 3),
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

      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_preview.pdf');
      await tempFile.writeAsBytes(bytes);

      final result = await OpenFile.open(tempFile.path);

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening PDF: ${result.message}')),
        );
      }
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
}
