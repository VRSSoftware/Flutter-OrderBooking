// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'package:marquee/marquee.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:vrs_erp/constants/app_constants.dart';
// import 'package:vrs_erp/dashboard/data.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// // import 'dart:html' as html;
// import 'dart:typed_data';

// class CustomerOrderDetailsPage extends StatefulWidget {
//   final String custKey;
//   final String customerName;
//   final DateTime fromDate;
//   final DateTime toDate;
//   final String orderType;

//   const CustomerOrderDetailsPage({
//     super.key,
//     required this.custKey,
//     required this.customerName,
//     required this.fromDate,
//     required this.toDate,
//     required this.orderType,
//   });

//   @override
//   State<CustomerOrderDetailsPage> createState() =>
//       _CustomerOrderDetailsPageState();
// }

// class _CustomerOrderDetailsPageState extends State<CustomerOrderDetailsPage> {
//   List<Map<String, dynamic>> orderDetails = [];
//   bool isLoading = true;
//   int totalOrders = 0;
//   int totalQuantity = 0;
//   int totalAmount = 0;
//   bool _appBarViewChecked = false;
//   Map<String, bool> _orderViewChecked = {};

//   @override
//   void initState() {
//     super.initState();
//     _fetchOrderDetails();
//   }

//   Future<void> _fetchOrderDetails() async {
//     try {
//       final response = await http.post(
//         Uri.parse('${AppConstants.BASE_URL}/report/getReportsDetail'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           "FromDate": DateFormat('yyyy-MM-dd').format(widget.fromDate),
//           "ToDate": DateFormat('yyyy-MM-dd').format(widget.toDate),
//           "CoBr_Id": UserSession.coBrId,
//           "CustKey": widget.custKey,
//           "SalesPerson":
//               UserSession.userType == 'S'
//                   ? UserSession.userLedKey
//                   : FilterData.selectedSalespersons!.isNotEmpty
//                   ? FilterData.selectedSalespersons!.map((b) => b.key).join(',')
//                   : null,
//           "State":
//               FilterData.selectedStates!.isNotEmpty
//                   ? FilterData.selectedStates!.map((b) => b.key).join(',')
//                   : null,
//           "City":
//               FilterData.selectedCities!.isNotEmpty
//                   ? FilterData.selectedCities!.map((b) => b.key).join(',')
//                   : null,
//           "orderType": widget.orderType,
//           "Detail": 2,
//         }),
//       );
//       print(
//         "HHHHHHHHHHCustomer wise-order detailResponse body:${response.body}",
//       );
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data is List) {
//           setState(() {
//             orderDetails = List<Map<String, dynamic>>.from(data);
//             totalOrders = orderDetails.length;
//             totalQuantity = orderDetails.fold(
//               0,
//               (sum, item) =>
//                   sum + (int.tryParse(item['TotalQty'].toString()) ?? 0),
//             );
//             totalAmount = orderDetails.fold(
//               0,
//               (sum, item) =>
//                   sum + (int.tryParse(item['TotalAmt'].toString()) ?? 0),
//             );
//             isLoading = false;
//           });
//         } else {
//           throw Exception('Unexpected response format');
//         }
//       } else {
//         throw Exception('Failed to load order details: ${response.statusCode}');
//       }
//     } catch (e) {
//       setState(() => isLoading = false);
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Error: $e')));
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: Text(
//           'Customer Wise - Order Details',
//           style: GoogleFonts.poppins(
//             color: Colors.white,
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         backgroundColor: AppColors.primaryColor,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           PopupMenuButton<String>(
//             icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
//             offset: const Offset(
//               0,
//               40,
//             ), // Adjusts the menu to appear below the icon
//             onSelected: (String value) {
//               switch (value) {
//                 case 'download':
//                   _handleDownloadAll();
//                   break;
//                 case 'whatsapp':
//                   _handleWhatsAppShareAll();
//                   break;
//                 case 'viewAll':
//                   _handleViewAll();
//                   break;
//                 case 'withImage':
//                   break;
//               }
//             },
//             itemBuilder:
//                 (BuildContext context) => <PopupMenuEntry<String>>[
//                   PopupMenuItem<String>(
//                     value: 'download',
//                     child: ListTile(
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 12.0,
//                         vertical: 0.0,
//                       ),
//                       leading: Icon(
//                         Icons.download,
//                         size: 18,
//                         color: AppColors.primaryColor,
//                       ),
//                       title: Text(
//                         'Download All',
//                         style: GoogleFonts.poppins(fontSize: 12),
//                       ),
//                     ),
//                   ),
//                   PopupMenuItem<String>(
//                     value: 'whatsapp',
//                     child: ListTile(
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 12.0,
//                         vertical: 0.0,
//                       ),
//                       leading: Icon(
//                         Icons.share,
//                         size: 18,
//                         color: AppColors.primaryColor,
//                       ),
//                       title: Text(
//                         'Share All',
//                         style: GoogleFonts.poppins(fontSize: 12),
//                       ),
//                     ),
//                   ),
//                   PopupMenuItem<String>(
//                     value: 'viewAll',
//                     child: ListTile(
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 12.0,
//                         vertical: 0.0,
//                       ),
//                       leading: Icon(
//                         Icons.visibility,
//                         size: 18,
//                         color: AppColors.primaryColor,
//                       ),
//                       title: Text(
//                         'View All',
//                         style: GoogleFonts.poppins(fontSize: 12),
//                       ),
//                     ),
//                   ),
//                   PopupMenuItem<String>(
//                     value: 'withImage',
//                     child: StatefulBuilder(
//                       builder: (BuildContext context, StateSetter setState) {
//                         return Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12.0,
//                             vertical: 6.0,
//                           ),
//                           child: Row(
//                             children: [
//                               Checkbox(
//                                 value: _appBarViewChecked,
//                                 onChanged: (bool? newValue) {
//                                   setState(() {
//                                     _appBarViewChecked = newValue ?? false;
//                                   });
//                                   this.setState(() {
//                                     _appBarViewChecked = newValue ?? false;
//                                   });
//                                 },
//                                 activeColor: AppColors.primaryColor,
//                                 materialTapTargetSize:
//                                     MaterialTapTargetSize.shrinkWrap,
//                                 visualDensity: const VisualDensity(
//                                   horizontal: -4,
//                                   vertical: -4,
//                                 ),
//                               ),
//                               const SizedBox(width: 6),
//                               Text(
//                                 'With Image',
//                                 style: GoogleFonts.poppins(fontSize: 12),
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//           ),
//         ],
//       ),
//       body:
//           isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: _buildSummaryCard(
//                               'Total Orders',
//                               totalOrders.toString(),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: _buildSummaryCard(
//                               'Total Qty',
//                               totalQuantity.toString(),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: _buildSummaryCard(
//                               'Total Amount',
//                               '₹${totalAmount.toString()}',
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 16),
//                       Row(
//                         children: [
//                           Icon(Icons.person, color: AppColors.primaryColor, size: 18),
//                           const SizedBox(width: 6),
//                           Flexible(
//                             child: Text(
//                               widget.customerName,
//                               style: GoogleFonts.poppins(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w600,
//                                 color: AppColors.primaryColor.shade900
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 16),
//                       ...orderDetails
//                           .map((order) => _buildOrderCard(order))
//                           .toList(),
//                     ],
//                   ),
//                 ),
//               ),
//     );
//   }

//   Future<List<Map<String, dynamic>>> _fetchFullCustomerReport() async {
//     try {
//       final requestBody = {
//         "FromDate": DateFormat('yyyy-MM-dd').format(widget.fromDate),
//         "ToDate": DateFormat('yyyy-MM-dd').format(widget.toDate),
//         "CustKey": widget.custKey,
//         "CoBr_Id": UserSession.coBrId,
//         "orderType": widget.orderType,
//         "All": false, // Get full report
//       };

//       print("Request Body: ${jsonEncode(requestBody)}");

//       final response = await http.post(
//         Uri.parse('${AppConstants.BASE_URL}/report/customer-wise1'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(requestBody),
//       );

//       print("Response Status: ${response.statusCode}");
//       print("Response Body: ${response.body}");

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body) as List;
//         return data.cast<Map<String, dynamic>>();
//       } else {
//         throw Exception('Failed to load report: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error fetching full customer report: $e');
//       return [];
//     }
//   }

//   Future<String> _savePDF(pw.Document pdf, String fileNamePrefix) async {
//     String filePath = '';

//     try {
//       // Request storage permissions
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

//       // Determine the downloads directory
//       Directory? downloadsDir;
//       if (Platform.isAndroid) {
//         downloadsDir = Directory('/storage/emulated/0/Download');
//         if (!await downloadsDir.exists()) {
//           downloadsDir = await getExternalStorageDirectory();
//         }
//       } else if (Platform.isIOS) {
//         downloadsDir = await getApplicationDocumentsDirectory();
//       }

//       if (downloadsDir != null) {
//         final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
//         final file = File('${downloadsDir.path}/$fileNamePrefix$timestamp.pdf');
//         await file.writeAsBytes(await pdf.save());
//         filePath = file.path;
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Unable to access Downloads directory')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error saving PDF: $e')));
//     }

//     return filePath;
//   }

//   void _downloadPdfOnWeb({required List<int> bytes, required String fileName}) {
//     // final blob = html.Blob([bytes], 'application/pdf');
//     // final url = html.Url.createObjectUrlFromBlob(blob);

//     // final anchor =
//     //     html.AnchorElement(href: url)
//     //       ..setAttribute('download', fileName)
//     //       ..click();

//     // html.Url.revokeObjectUrl(url);
//   }

//   Future<void> _handleDownloadAll() async {
//     try {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Generating full report...')),
//       );

//       final detailedData = await _fetchFullCustomerReport();

//       if (detailedData.isEmpty) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text('No data available')));
//         return;
//       }

//       final pdf = await _generateFullCustomerPDF(detailedData);

//       final timestamp =
//           '${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}'
//           '_${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}';

//       final fileName = 'CustomerOrderReport_$timestamp.pdf';

//       /* ==================== WEB ==================== */
//       if (kIsWeb) {
//         final Uint8List pdfBytes = await pdf.save();

//         _downloadPdfOnWeb(
//           bytes: pdfBytes.toList(), // ✅ convert to List<int>
//           fileName: fileName,
//         );

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('PDF downloaded successfully')),
//         );
//       }
//       /* ==================== MOBILE ==================== */
//       else {
//         final filePath = await _savePDF(pdf, 'CustomerOrderReport_');

//         if (filePath.isNotEmpty) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('PDF saved to: $filePath'),
//               action: SnackBarAction(
//                 label: 'Open',
//                 onPressed: () => OpenFile.open(filePath),
//               ),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: $e')));
//     }
//   }

//   void _handleOrderDownload(Map<String, dynamic> order) async {
//     try {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Generating order: ${order['OrderNo']}...')),
//       );

//       final detailedData = await _fetchCustomerWiseReport(
//         order['OrderId'] ?? 0,
//       );
//       if (detailedData.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No data available for this order')),
//         );
//         return;
//       }

//       final pdf = await _generatePDF(order, detailedData);
//       final filePath = await _savePDF(pdf, 'Order_${order['OrderNo']}_');

//       if (filePath.isNotEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('PDF saved to: $filePath'),
//             action: SnackBarAction(
//               label: 'Open',
//               onPressed: () => OpenFile.open(filePath),
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: $e')));
//     }
//   }

//   void _handleWhatsAppShareAll() async {
//     try {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Generating and sharing full report...')),
//       );

//       final detailedData = await _fetchFullCustomerReport();
//       if (detailedData.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No data available to share')),
//         );
//         return;
//       }

//       final pdf = await _generateFullCustomerPDF(detailedData);
//       final directory = await getTemporaryDirectory();
//       final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
//       final filePath = '${directory.path}/CustomerOrderReport_$timestamp.pdf';
//       final file = File(filePath);
//       await file.writeAsBytes(await pdf.save());

//       // Share the PDF using the native share dialog
//       await Share.shareFiles(
//         [filePath],
//         text: 'Customer Order Report',
//         subject: 'Customer Order Report',
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error sharing report: $e')));
//     }
//   }

//   void _handleViewAll() async {
//     try {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Generating report...')));

//       final detailedData = await _fetchFullCustomerReport();

//       if (detailedData.isEmpty) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text('No data available')));
//         return;
//       }

//       // Generate and open PDF for the entire report
//       await _generateAndOpenFullPdf(detailedData);
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: $e')));
//     }
//   }

//   Future<void> _generateAndOpenFullPdf(
//     List<Map<String, dynamic>> detailedData,
//   ) async {
//     final pdf = await _generateFullCustomerPDF(detailedData);
//     final directory = await getApplicationDocumentsDirectory();
//     final filePath =
//         '${directory.path}/customer_${widget.customerName}_orders.pdf';
//     final file = File(filePath);
//     await file.writeAsBytes(await pdf.save());
//     await OpenFile.open(file.path);
//   }

//   Future<pw.Document> _generateFullCustomerPDF(
//     List<Map<String, dynamic>> detailedData,
//   ) async {
//     final pdf = pw.Document();
//     final fromDate = DateFormat('dd-MM-yyyy').format(widget.fromDate);
//     final toDate = DateFormat('dd-MM-yyyy').format(widget.toDate);

//     // Group data by ItemName + OrderNo + Color
//     Map<String, List<Map<String, dynamic>>> groupedData = {};
//     for (var item in detailedData) {
//       String key = '${item['ItemName']}_${item['OrderNo']}_${item['Color']}';
//       groupedData.putIfAbsent(key, () => []).add(item);
//     }

//     // Function to get image URL
//     String _getImageUrl(Map<String, dynamic> item) {
//       if (UserSession.onlineImage == '0') {
//         final imagePath = item['Style_Image'] ?? '';
//         final imageName = imagePath.split('/').last.split('?').first;
//         if (imageName.isEmpty) {
//           return '';
//         }
//         return '${AppConstants.BASE_URL}/images/$imageName';
//       } else if (UserSession.onlineImage == '1') {
//         return item['Style_Image'] ?? '';
//       }
//       return '';
//     }

//     // Function to load image for PDF
//     Future<pw.ImageProvider?> _loadImage(String imageUrl) async {
//       if (imageUrl.isEmpty) return null;
//       try {
//         final response = await http.get(Uri.parse(imageUrl));
//         if (response.statusCode == 200) {
//           return pw.MemoryImage(response.bodyBytes);
//         }
//       } catch (e) {
//         print('Error loading image $imageUrl: $e');
//       }
//       return null;
//     }

//     // Precompute images for each group if checkbox is checked
//     Map<String, pw.ImageProvider?> imageCache = {};
//     if (_appBarViewChecked) {
//       for (var key in groupedData.keys) {
//         final item = groupedData[key]![0];
//         final imageUrl = _getImageUrl(item);
//         imageCache[key] = await _loadImage(imageUrl);
//       }
//     }

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         margin: const pw.EdgeInsets.all(10),
//         build: (context) {
//           List<pw.Widget> widgets = [];
//           int serial = 1;
//           num totalOrder = 0;
//           num totalDelv = 0;
//           num totalSettle = 0;
//           num totalPend = 0;

//           // Define column widths dynamically based on _appBarViewChecked
//           final columnWidths =
//               _appBarViewChecked
//                   ? {
//                     0: const pw.FixedColumnWidth(30), // No
//                     1: const pw.FixedColumnWidth(60), // Image
//                     2: const pw.FixedColumnWidth(80), // ItemName
//                     3: const pw.FixedColumnWidth(80), // Order No.
//                     4: const pw.FixedColumnWidth(60), // Color
//                     5: const pw.FixedColumnWidth(40), // Size
//                     6: const pw.FixedColumnWidth(40), // Ord.
//                     7: const pw.FixedColumnWidth(40), // Delv.
//                     8: const pw.FixedColumnWidth(40), // Settle
//                     9: const pw.FixedColumnWidth(40), // Pend.
//                   }
//                   : {
//                     0: const pw.FixedColumnWidth(30), // No
//                     1: const pw.FixedColumnWidth(
//                       100,
//                     ), // ItemName (increased width)
//                     2: const pw.FixedColumnWidth(
//                       100,
//                     ), // Order No. (increased width)
//                     3: const pw.FixedColumnWidth(80), // Color (increased width)
//                     4: const pw.FixedColumnWidth(40), // Size
//                     5: const pw.FixedColumnWidth(40), // Ord.
//                     6: const pw.FixedColumnWidth(40), // Delv.
//                     7: const pw.FixedColumnWidth(40), // Settle
//                     8: const pw.FixedColumnWidth(40), // Pend.
//                   };

//           // Add table header
//           widgets.add(
//             pw.Container(
//               color: PdfColors.grey200,
//               child: pw.Table(
//                 border: pw.TableBorder.all(width: 0.5),
//                 columnWidths: columnWidths,
//                 children: [
//                   pw.TableRow(
//                     children: [
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(4),
//                         child: pw.Text(
//                           'No',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                       if (_appBarViewChecked)
//                         pw.Padding(
//                           padding: const pw.EdgeInsets.all(4),
//                           child: pw.Text(
//                             'Image',
//                             style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                           ),
//                         ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(4),
//                         child: pw.Text(
//                           'ItemName',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(4),
//                         child: pw.Text(
//                           'Order No.',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(4),
//                         child: pw.Text(
//                           'Color',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(4),
//                         child: pw.Text(
//                           'Size',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(4),
//                         child: pw.Text(
//                           'Ord.',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(4),
//                         child: pw.Text(
//                           'Delv.',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(4),
//                         child: pw.Text(
//                           'Settle',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(4),
//                         child: pw.Text(
//                           'Pend.',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           );

//           // Generate data rows
//           for (var key in groupedData.keys) {
//             final groupItems = groupedData[key]!;
//             final item = groupItems[0];
//             num entryOrder = 0, entryDelv = 0, entrySettle = 0, entryPend = 0;

//             // Create image cell
//             pw.Widget imageCell =
//                 _appBarViewChecked
//                     ? (imageCache[key] != null
//                         ? pw.Image(imageCache[key]!, fit: pw.BoxFit.contain)
//                         : pw.Text(
//                           'Image Not Available',
//                           style: pw.TextStyle(
//                             fontSize: 10,
//                             color: PdfColors.grey,
//                           ),
//                           textAlign: pw.TextAlign.center,
//                         ))
//                     : pw.Text(
//                       '',
//                       style: const pw.TextStyle(fontSize: 10),
//                       textAlign: pw.TextAlign.center,
//                     );

//             // Create itemName cell
//             pw.Widget itemNameCell = pw.Text(
//               item['ItemName']?.toString() ?? 'N/A',
//               style: const pw.TextStyle(fontSize: 10),
//               textAlign: pw.TextAlign.center,
//             );

//             // Create subtable for size-related data
//             final subTableRows =
//                 groupItems.map((row) {
//                   entryOrder += (row['OrderQty'] ?? 0) as num;
//                   entryDelv += (row['DelvQty'] ?? 0) as num;
//                   entrySettle += (row['SettleQty'] ?? 0) as num;
//                   entryPend += (row['PendingQty'] ?? 0) as num;
//                   return pw.TableRow(
//                     children: [
//                       pw.Container(
//                         padding: const pw.EdgeInsets.all(4),
//                         alignment: pw.Alignment.center,
//                         child: pw.Text(row['Size']?.toString() ?? ''),
//                       ),
//                       pw.Container(
//                         padding: const pw.EdgeInsets.all(4),
//                         alignment: pw.Alignment.center,
//                         child: pw.Text((row['OrderQty'] ?? 0).toString()),
//                       ),
//                       pw.Container(
//                         padding: const pw.EdgeInsets.all(4),
//                         alignment: pw.Alignment.center,
//                         child: pw.Text((row['DelvQty'] ?? 0).toString()),
//                       ),
//                       pw.Container(
//                         padding: const pw.EdgeInsets.all(4),
//                         alignment: pw.Alignment.center,
//                         child: pw.Text((row['SettleQty'] ?? 0).toString()),
//                       ),
//                       pw.Container(
//                         padding: const pw.EdgeInsets.all(4),
//                         alignment: pw.Alignment.center,
//                         child: pw.Text((row['PendingQty'] ?? 0).toString()),
//                       ),
//                     ],
//                   );
//                 }).toList();

//             // Calculate maxCellHeight based on content
//             final numRows = groupItems.length;
//             final baseRowHeight = 18.0;
//             final imageHeight = _appBarViewChecked ? 40.0 : baseRowHeight;
//             final subtableHeight = numRows * baseRowHeight;
//             final maxCellHeight =
//                 (subtableHeight > imageHeight ? subtableHeight : imageHeight);
//             final rowHeight = maxCellHeight / numRows;

//             // Define row column widths
//             final rowColumnWidths =
//                 _appBarViewChecked
//                     ? {
//                       0: const pw.FixedColumnWidth(30), // No
//                       1: const pw.FixedColumnWidth(60), // Image
//                       2: const pw.FixedColumnWidth(80), // ItemName
//                       3: const pw.FixedColumnWidth(80), // Order No.
//                       4: const pw.FixedColumnWidth(60), // Color
//                       5: const pw.FixedColumnWidth(200), // Subtable
//                     }
//                     : {
//                       0: const pw.FixedColumnWidth(30), // No
//                       1: const pw.FixedColumnWidth(100), // ItemName
//                       2: const pw.FixedColumnWidth(100), // Order No.
//                       3: const pw.FixedColumnWidth(80), // Color
//                       4: const pw.FixedColumnWidth(200), // Subtable
//                     };

//             widgets.add(
//               pw.Table(
//                 border: pw.TableBorder.all(width: 0.5),
//                 columnWidths: rowColumnWidths,
//                 children: [
//                   pw.TableRow(
//                     children: [
//                       pw.Container(
//                         height: maxCellHeight,
//                         padding: const pw.EdgeInsets.all(4),
//                         alignment: pw.Alignment.center,
//                         child: pw.Text('$serial'),
//                       ),
//                       if (_appBarViewChecked)
//                         pw.Container(
//                           height: maxCellHeight,
//                           padding: const pw.EdgeInsets.all(4),
//                           alignment: pw.Alignment.center,
//                           child: imageCell,
//                         ),
//                       pw.Container(
//                         height: maxCellHeight,
//                         padding: const pw.EdgeInsets.all(4),
//                         alignment: pw.Alignment.center,
//                         child: itemNameCell,
//                       ),
//                       pw.Container(
//                         height: maxCellHeight,
//                         padding: const pw.EdgeInsets.all(4),
//                         alignment: pw.Alignment.center,
//                         child: pw.Text(
//                           "${item['OrderNo'] ?? ''}\n(${item['OrderDate'] ?? ''})",
//                         ),
//                       ),
//                       pw.Container(
//                         height: maxCellHeight,
//                         padding: const pw.EdgeInsets.all(4),
//                         alignment: pw.Alignment.center,
//                         child: pw.Text(item['Color']?.toString() ?? ''),
//                       ),
//                       pw.Table(
//                         border: pw.TableBorder.all(width: 0.5),
//                         columnWidths: {
//                           0: const pw.FixedColumnWidth(40),
//                           1: const pw.FixedColumnWidth(40),
//                           2: const pw.FixedColumnWidth(40),
//                           3: const pw.FixedColumnWidth(40),
//                           4: const pw.FixedColumnWidth(40),
//                         },
//                         children:
//                             subTableRows
//                                 .map(
//                                   (row) => pw.TableRow(
//                                     children:
//                                         row.children
//                                             .map(
//                                               (cell) => pw.Container(
//                                                 height: rowHeight,
//                                                 child: cell,
//                                               ),
//                                             )
//                                             .toList(),
//                                   ),
//                                 )
//                                 .toList(),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             );

//             // Update totals
//             totalOrder += entryOrder;
//             totalDelv += entryDelv;
//             totalSettle += entrySettle;
//             totalPend += entryPend;
//             serial++;
//           }

//           // Total Summary Row
//           widgets.add(
//             pw.Table(
//               border: pw.TableBorder.all(width: 0.5),
//               columnWidths:
//                   _appBarViewChecked
//                       ? {
//                         0: const pw.FixedColumnWidth(315), // Merged column
//                         1: const pw.FixedColumnWidth(40), // Ord
//                         2: const pw.FixedColumnWidth(40), // Delv
//                         3: const pw.FixedColumnWidth(40), // Settle
//                         4: const pw.FixedColumnWidth(40), // Pend
//                       }
//                       : {
//                         0: const pw.FixedColumnWidth(350), // Merged column
//                         1: const pw.FixedColumnWidth(40), // Ord
//                         2: const pw.FixedColumnWidth(40), // Delv
//                         3: const pw.FixedColumnWidth(40), // Settle
//                         4: const pw.FixedColumnWidth(40), // Pend
//                       },
//               children: [
//                 pw.TableRow(
//                   decoration: const pw.BoxDecoration(color: PdfColors.grey300),
//                   children: [
//                     pw.Container(
//                       padding: const pw.EdgeInsets.all(4),
//                       alignment: pw.Alignment.centerLeft,
//                       child: pw.Text(
//                         'Total',
//                         style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                       ),
//                     ),
//                     pw.Container(
//                       padding: const pw.EdgeInsets.all(4),
//                       alignment: pw.Alignment.center,
//                       child: pw.Text(
//                         '$totalOrder',
//                         style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                       ),
//                     ),
//                     pw.Container(
//                       padding: const pw.EdgeInsets.all(4),
//                       alignment: pw.Alignment.center,
//                       child: pw.Text(
//                         '$totalDelv',
//                         style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                       ),
//                     ),
//                     pw.Container(
//                       padding: const pw.EdgeInsets.all(4),
//                       alignment: pw.Alignment.center,
//                       child: pw.Text(
//                         '$totalSettle',
//                         style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                       ),
//                     ),
//                     pw.Container(
//                       padding: const pw.EdgeInsets.all(4),
//                       alignment: pw.Alignment.center,
//                       child: pw.Text(
//                         '$totalPend',
//                         style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           );

//           // Blue Header
//           widgets.insert(
//             0,
//             pw.Container(
//               color: PdfColors.blue,
//               padding: const pw.EdgeInsets.all(10),
//               child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Row(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Expanded(
//                         child: pw.Column(
//                           crossAxisAlignment: pw.CrossAxisAlignment.center,
//                           children: [
//                             pw.Text(
//                               'Order Register - Party Wise',
//                               style: pw.TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: pw.FontWeight.bold,
//                                 color: PdfColors.white,
//                               ),
//                             ),
//                             pw.Text(
//                               UserSession.coBrName ?? 'VRS Software Pvt Ltd',
//                               style: pw.TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: pw.FontWeight.bold,
//                                 color: PdfColors.white,
//                               ),
//                             ),
//                             pw.Text(
//                               '1234567890',
//                               style: pw.TextStyle(
//                                 fontSize: 12,
//                                 color: PdfColors.white,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       pw.Text(
//                         'Print Date: ${DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now())}',
//                         style: pw.TextStyle(
//                           fontSize: 10,
//                           color: PdfColors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                   pw.SizedBox(height: 5),
//                   pw.Text(
//                     'Date: $fromDate to $toDate',
//                     style: pw.TextStyle(fontSize: 12, color: PdfColors.white),
//                   ),
//                 ],
//               ),
//             ),
//           );

//           // Party Name
//           widgets.insert(1, pw.SizedBox(height: 10));
//           widgets.insert(
//             2,
//             pw.Text(
//               widget.customerName.toUpperCase(),
//               style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
//             ),
//           );
//           widgets.insert(3, pw.SizedBox(height: 10));

//           return widgets;
//         },
//       ),
//     );

//     return pdf;
//   }

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

//   Widget _buildOrderCard(Map<String, dynamic> order) {
//     String formattedDateTime = '';
//     try {
//       final date = DateFormat('yyyy-MM-dd').parse(order['OrderDate']);
//       formattedDateTime = DateFormat('dd/MM/yyyy HH:mm').format(date);
//     } catch (e) {
//       formattedDateTime =
//           '${order['OrderDate']} ${order['Created_Time'] ?? 'N/A'}';
//     }

//     String formattedDeliveryDate = '';
//     try {
//       final date = DateFormat('yyyy-MM-dd').parse(order['DlvDate']);
//       formattedDeliveryDate = DateFormat('dd/MM/yyyy').format(date);
//     } catch (e) {
//       formattedDeliveryDate = order['DlvDate'] ?? 'N/A';
//     }

//     Widget _buildTextWithMarquee(String text, TextStyle style) {
//       final maxWidth = MediaQuery.of(context).size.width / 5;
//       const int lengthThreshold = 12;
//       if (text.length > lengthThreshold) {
//         return SizedBox(
//           width: maxWidth,
//           height: 18.0,
//           child: Marquee(
//             text: text,
//             style: style,
//             scrollAxis: Axis.horizontal,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             blankSpace: 16.0,
//             velocity: 50.0,
//             pauseAfterRound: const Duration(seconds: 1),
//             startPadding: 8.0,
//             accelerationDuration: const Duration(seconds: 1),
//             accelerationCurve: Curves.linear,
//             decelerationDuration: const Duration(milliseconds: 500),
//             decelerationCurve: Curves.linear,
//           ),
//         );
//       }
//       return Text(text, style: style, overflow: TextOverflow.ellipsis);
//     }

//     Color deliveryColor;
//     String deliveryType = order['DeliveryType']?.toString() ?? 'N/A';
//     switch (deliveryType) {
//       case 'Approved':
//         deliveryColor = AppColors.primaryColor!;
//         break;
//       case 'Partially Delivered':
//         deliveryColor = AppColors.primaryColor.shade400!;
//         break;
//       case 'Delivered':
//         deliveryColor = AppColors.primaryColor.shade900!;
//         break;
//       case 'Completed':
//         deliveryColor = AppColors.primaryColor.shade600!;
//         break;
//       case 'Partially Completed':
//         deliveryColor = AppColors.primaryColor.shade300!;
//         break;
//       default:
//         deliveryColor = Colors.grey[600]!;
//     }

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: const Color.fromARGB(255, 196, 195, 195)),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(10.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // FIRST ROW
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.receipt_long,
//                         size: 16,
//                         color: AppColors.primaryColor,
//                       ),
//                       const SizedBox(width: 4),
//                       Expanded(
//                         child: _buildTextWithMarquee(
//                           '${order['OrderNo'] ?? 'N/A'}',
//                           GoogleFonts.poppins(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             color: AppColors.primaryColor,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 6),
//                 Expanded(
//                   child: Row(
//                     children: [
//                       Icon(Icons.category, size: 16, color: AppColors.primaryColor),
//                       const SizedBox(width: 4),
//                       Expanded(
//                         child: _buildTextWithMarquee(
//                           '${order['Order_Type'] ?? 'N/A'}',
//                           GoogleFonts.poppins(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             color: AppColors.primaryColor,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 6),
//                 Expanded(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 6.0,
//                       vertical: 3.0,
//                     ),
//                     decoration: BoxDecoration(
//                       color: AppColors.primaryColor.shade100,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           Icons.local_shipping,
//                           size: 16,
//                           color: deliveryColor,
//                         ),
//                         const SizedBox(width: 4),
//                         Expanded(
//                           child: _buildTextWithMarquee(
//                             deliveryType,
//                             GoogleFonts.poppins(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                               color: deliveryColor,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 8),

//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: Row(
//                     children: [
//                       Text(
//                         'Qty: ',
//                         style: GoogleFonts.poppins(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w500,
//                           color: AppColors.primaryColor,
//                         ),
//                       ),
//                       Expanded(
//                         child: _buildTextWithMarquee(
//                           '${order['TotalQty'] ?? '0'}',
//                           GoogleFonts.poppins(
//                             fontSize: 11,
//                             fontWeight: FontWeight.w500,
//                             color: AppColors.primaryColor,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 6),
//                 Expanded(
//                   child: Row(
//                     children: [
//                       Text(
//                         'Amt: ₹',
//                         style: GoogleFonts.poppins(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w500,
//                           color: AppColors.primaryColor,
//                         ),
//                       ),
//                       Expanded(
//                         child: _buildTextWithMarquee(
//                           '${order['TotalAmt'] ?? '0.00'}',
//                           GoogleFonts.poppins(
//                             fontSize: 11,
//                             fontWeight: FontWeight.w500,
//                             color: AppColors.primaryColor,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 6),
//                 Expanded(
//                   child:
//                       (order['WhatsAppMobileNo'] != null &&
//                               order['WhatsAppMobileNo']
//                                   .toString()
//                                   .trim()
//                                   .isNotEmpty)
//                           ? GestureDetector(
//                             onTap:
//                                 () => _showContactOptions(
//                                   context,
//                                   order['WhatsAppMobileNo'].toString(),
//                                 ),
//                             child: Row(
//                               children: [
//                                 const FaIcon(
//                                   FontAwesomeIcons.whatsapp,
//                                   size: 12,
//                                   color: Colors.green,
//                                 ),
//                                 const SizedBox(width: 3),
//                                 Expanded(
//                                   child: _buildTextWithMarquee(
//                                     order['WhatsAppMobileNo'].toString(),
//                                     GoogleFonts.poppins(
//                                       fontSize: 11,
//                                       fontWeight: FontWeight.w500,
//                                       color: Colors.green,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           )
//                           : Row(
//                             children: [
//                               const FaIcon(
//                                 FontAwesomeIcons.whatsapp,
//                                 size: 12,
//                                 color: Colors.green,
//                               ),
//                               const SizedBox(width: 3),
//                               Expanded(
//                                 child: _buildTextWithMarquee(
//                                   'xxxxx xxxxx',
//                                   GoogleFonts.poppins(
//                                     fontSize: 11,
//                                     color: Colors.green,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 8),

//             // FOURTH ROW - Ordered + Delivery Date + Popup Menu
//             Row(
//               children: [
//                 RichText(
//                   text: TextSpan(
//                     children: [
//                       TextSpan(
//                         text: 'Ordered: ',
//                         style: GoogleFonts.poppins(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.grey[800],
//                         ),
//                       ),
//                       TextSpan(
//                         text: formattedDateTime,
//                         style: GoogleFonts.poppins(
//                           fontSize: 11,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.grey[800],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 18),
//                 RichText(
//                   text: TextSpan(
//                     children: [
//                       TextSpan(
//                         text: 'Delivery: ',
//                         style: GoogleFonts.poppins(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.grey[800],
//                         ),
//                       ),
//                       TextSpan(
//                         text: formattedDeliveryDate,
//                         style: GoogleFonts.poppins(
//                           fontSize: 11,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.grey[800],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 6),
//                 _OrderPopupMenu(
//                   order: order,
//                   viewChecked: _orderViewChecked[order['OrderNo']] ?? false,
//                   onViewCheckedChanged: (value) {
//                     setState(() {
//                       _orderViewChecked[order['OrderNo']] = value;
//                     });
//                   },
//                   onDownload: () => _handleOrderDownload(order),
//                   onWhatsApp: () => _handleOrderWhatsAppShare(order),
//                   onView: () => _handleOrderView(order),
//                   orderType: widget.orderType, // Pass orderType from widget
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _handleOrderWhatsAppShare(Map<String, dynamic> order) async {
//     try {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Generating and sharing order: ${order['OrderNo']}...'),
//         ),
//       );

//       final detailedData = await _fetchCustomerWiseReport(
//         order['OrderId'] ?? 0,
//       );
//       if (detailedData.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No data available for this order')),
//         );
//         return;
//       }

//       final pdf = await _generatePDF(order, detailedData);
//       final directory = await getTemporaryDirectory();
//       final filePath = '${directory.path}/Order_${order['OrderNo']}.pdf';
//       final file = File(filePath);
//       await file.writeAsBytes(await pdf.save());

//       // Share the PDF using the native share dialog
//       await Share.shareFiles(
//         [filePath],
//         text: 'Order ${order['OrderNo']} Report',
//         subject: 'Order ${order['OrderNo']} Report',
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error sharing order: $e')));
//     }
//   }

//   Future<List<Map<String, dynamic>>> _fetchCustomerWiseReport(int docId) async {
//     try {
//       final requestBody = {
//         "CoBr_Id": UserSession.coBrId,
//         "orderType": widget.orderType,
//         "DocId": docId,
//         "All": true,
//       };

//       print("📤 Request Body:\n${jsonEncode(requestBody)}");

//       final response = await http.post(
//         Uri.parse('${AppConstants.BASE_URL}/report/customer-wise'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(requestBody),
//       );

//       print("📥 Response Body:\n${response.body}");

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body) as List;
//         return data.cast<Map<String, dynamic>>();
//       } else {
//         throw Exception('Failed to load report: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error fetching report: $e');
//       return [];
//     }
//   }

//   Future<pw.Document> _generatePDF(
//     Map<String, dynamic> orderData,
//     List<Map<String, dynamic>> detailedData,
//   ) async {
//     final pdf = pw.Document();
//     final bool withImage = _orderViewChecked[orderData['OrderNo']] ?? false;
//     final fromDate = DateFormat('dd-MM-yyyy').format(
//       DateFormat('yyyy-MM-dd').parse(
//         detailedData.isNotEmpty ? detailedData[0]['FromDate'] : '2025-07-17',
//       ),
//     );
//     final toDate = DateFormat('dd-MM-yyyy').format(
//       DateFormat('yyyy-MM-dd').parse(
//         detailedData.isNotEmpty ? detailedData[0]['ToDate'] : '2025-07-17',
//       ),
//     );

//     // Group data by ItemName + OrderNo + Color
//     Map<String, List<Map<String, dynamic>>> groupedData = {};
//     for (var item in detailedData) {
//       String key = '${item['ItemName']}_${item['OrderNo']}_${item['Color']}';
//       groupedData.putIfAbsent(key, () => []).add(item);
//     }

//     // Function to get image URL
//     String _getImageUrl(Map<String, dynamic> item) {
//       if (UserSession.onlineImage == '0') {
//         final imagePath = item['Style_Image'] ?? '';
//         final imageName = imagePath.split('/').last.split('?').first;
//         if (imageName.isEmpty) {
//           return '';
//         }
//         return '${AppConstants.BASE_URL}/images/$imageName';
//       } else if (UserSession.onlineImage == '1') {
//         return item['Style_Image'] ?? '';
//       }
//       return '';
//     }

//     // Function to load image for PDF
//     Future<pw.ImageProvider?> _loadImage(String imageUrl) async {
//       if (imageUrl.isEmpty) return null;
//       try {
//         final response = await http.get(Uri.parse(imageUrl));
//         if (response.statusCode == 200) {
//           return pw.MemoryImage(response.bodyBytes);
//         }
//       } catch (e) {
//         print('Error loading image $imageUrl: $e');
//       }
//       return null;
//     }

//     // Precompute images for each group if checkbox is checked
//     Map<String, pw.ImageProvider?> imageCache = {};
//     if (withImage) {
//       for (var key in groupedData.keys) {
//         final item = groupedData[key]![0];
//         final imageUrl = _getImageUrl(item);
//         imageCache[key] = await _loadImage(imageUrl);
//       }
//     }

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         margin: const pw.EdgeInsets.all(10),
//         build: (context) {
//           List<pw.Widget> widgets = [];
//           int serial = 1;
//           num totalOrder = 0;
//           num totalDelv = 0;
//           num totalSettle = 0;
//           num totalPend = 0;

//           // Define column widths dynamically based on withImage
//           final columnWidths =
//               withImage
//                   ? {
//                     0: const pw.FixedColumnWidth(30), // No
//                     1: const pw.FixedColumnWidth(60), // Image
//                     2: const pw.FixedColumnWidth(80), // ItemName
//                     3: const pw.FixedColumnWidth(80), // Order No.
//                     4: const pw.FixedColumnWidth(60), // Color
//                     5: const pw.FixedColumnWidth(40), // Size
//                     6: const pw.FixedColumnWidth(40), // Ord.
//                     7: const pw.FixedColumnWidth(40), // Delv.
//                     8: const pw.FixedColumnWidth(40), // Settle
//                     9: const pw.FixedColumnWidth(40), // Pend.
//                   }
//                   : {
//                     0: const pw.FixedColumnWidth(30), // No
//                     1: const pw.FixedColumnWidth(100), // ItemName
//                     2: const pw.FixedColumnWidth(100), // Order No.
//                     3: const pw.FixedColumnWidth(80), // Color
//                     4: const pw.FixedColumnWidth(40), // Size
//                     5: const pw.FixedColumnWidth(40), // Ord.
//                     6: const pw.FixedColumnWidth(40), // Delv.
//                     7: const pw.FixedColumnWidth(40), // Settle
//                     8: const pw.FixedColumnWidth(40), // Pend.
//                   };

//           // Add table header
//           widgets.add(
//             pw.Container(
//               color: PdfColors.grey200,
//               child: pw.Table(
//                 border: pw.TableBorder.all(width: 0.5),
//                 columnWidths: columnWidths,
//                 children: [
//                   pw.TableRow(
//                     children: [
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(4),
//                         child: pw.Text(
//                           'No',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                       if (withImage)
//                         pw.Padding(
//                           padding: const pw.EdgeInsets.all(4),
//                           child: pw.Text(
//                             'Image',
//                             style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                           ),
//                         ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(4),
//                         child: pw.Text(
//                           'ItemName',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(4),
//                         child: pw.Text(
//                           'Order No.',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(4),
//                         child: pw.Text(
//                           'Color',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(4),
//                         child: pw.Text(
//                           'Size',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(4),
//                         child: pw.Text(
//                           'Ord.',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(4),
//                         child: pw.Text(
//                           'Delv.',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(4),
//                         child: pw.Text(
//                           'Settle',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(4),
//                         child: pw.Text(
//                           'Pend.',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           );

//           // Generate data rows
//           for (var key in groupedData.keys) {
//             final groupItems = groupedData[key]!;
//             final item = groupItems[0];
//             num entryOrder = 0, entryDelv = 0, entrySettle = 0, entryPend = 0;

//             // Create image cell
//             pw.Widget imageCell =
//                 withImage
//                     ? (imageCache[key] != null
//                         ? pw.Image(imageCache[key]!, fit: pw.BoxFit.contain)
//                         : pw.Text(
//                           'Image Not Available',
//                           style: pw.TextStyle(
//                             fontSize: 10,
//                             color: PdfColors.grey,
//                           ),
//                           textAlign: pw.TextAlign.center,
//                         ))
//                     : pw.Text(
//                       '',
//                       style: const pw.TextStyle(fontSize: 10),
//                       textAlign: pw.TextAlign.center,
//                     );

//             // Create itemName cell
//             pw.Widget itemNameCell = pw.Text(
//               item['ItemName']?.toString() ?? 'N/A',
//               style: const pw.TextStyle(fontSize: 10),
//               textAlign: pw.TextAlign.center,
//             );

//             // Create subtable for size-related data
//             final subTableRows =
//                 groupItems.map((row) {
//                   entryOrder += (row['OrderQty'] ?? 0) as num;
//                   entryDelv += (row['DelvQty'] ?? 0) as num;
//                   entrySettle += (row['SettleQty'] ?? 0) as num;
//                   entryPend += (row['PendingQty'] ?? 0) as num;
//                   return pw.TableRow(
//                     children: [
//                       pw.Container(
//                         padding: const pw.EdgeInsets.all(4),
//                         alignment: pw.Alignment.center,
//                         child: pw.Text(row['Size']?.toString() ?? ''),
//                       ),
//                       pw.Container(
//                         padding: const pw.EdgeInsets.all(4),
//                         alignment: pw.Alignment.center,
//                         child: pw.Text((row['OrderQty'] ?? 0).toString()),
//                       ),
//                       pw.Container(
//                         padding: const pw.EdgeInsets.all(4),
//                         alignment: pw.Alignment.center,
//                         child: pw.Text((row['DelvQty'] ?? 0).toString()),
//                       ),
//                       pw.Container(
//                         padding: const pw.EdgeInsets.all(4),
//                         alignment: pw.Alignment.center,
//                         child: pw.Text((row['SettleQty'] ?? 0).toString()),
//                       ),
//                       pw.Container(
//                         padding: const pw.EdgeInsets.all(4),
//                         alignment: pw.Alignment.center,
//                         child: pw.Text((row['PendingQty'] ?? 0).toString()),
//                       ),
//                     ],
//                   );
//                 }).toList();

//             // Calculate maxCellHeight based on content
//             final numRows = groupItems.length;
//             final baseRowHeight = 18.0;
//             final imageHeight = withImage ? 40.0 : baseRowHeight;
//             final subtableHeight = numRows * baseRowHeight;
//             final maxCellHeight =
//                 (subtableHeight > imageHeight ? subtableHeight : imageHeight);
//             final rowHeight = maxCellHeight / numRows;

//             // Define row column widths
//             final rowColumnWidths =
//                 withImage
//                     ? {
//                       0: const pw.FixedColumnWidth(30), // No
//                       1: const pw.FixedColumnWidth(60), // Image
//                       2: const pw.FixedColumnWidth(80), // ItemName
//                       3: const pw.FixedColumnWidth(80), // Order No.
//                       4: const pw.FixedColumnWidth(60), // Color
//                       5: const pw.FixedColumnWidth(200), // Subtable
//                     }
//                     : {
//                       0: const pw.FixedColumnWidth(30), // No
//                       1: const pw.FixedColumnWidth(100), // ItemName
//                       2: const pw.FixedColumnWidth(100), // Order No.
//                       3: const pw.FixedColumnWidth(80), // Color
//                       4: const pw.FixedColumnWidth(200), // Subtable
//                     };

//             widgets.add(
//               pw.Table(
//                 border: pw.TableBorder.all(width: 0.5),
//                 columnWidths: rowColumnWidths,
//                 children: [
//                   pw.TableRow(
//                     children: [
//                       pw.Container(
//                         height: maxCellHeight,
//                         padding: const pw.EdgeInsets.all(4),
//                         alignment: pw.Alignment.center,
//                         child: pw.Text('$serial'),
//                       ),
//                       if (withImage)
//                         pw.Container(
//                           height: maxCellHeight,
//                           padding: const pw.EdgeInsets.all(4),
//                           alignment: pw.Alignment.center,
//                           child: imageCell,
//                         ),
//                       pw.Container(
//                         height: maxCellHeight,
//                         padding: const pw.EdgeInsets.all(4),
//                         alignment: pw.Alignment.center,
//                         child: itemNameCell,
//                       ),
//                       pw.Container(
//                         height: maxCellHeight,
//                         padding: const pw.EdgeInsets.all(4),
//                         alignment: pw.Alignment.center,
//                         child: pw.Text(
//                           "${item['OrderNo'] ?? ''}\n(${item['OrderDate'] ?? ''})",
//                         ),
//                       ),
//                       pw.Container(
//                         height: maxCellHeight,
//                         padding: const pw.EdgeInsets.all(4),
//                         alignment: pw.Alignment.center,
//                         child: pw.Text(item['Color']?.toString() ?? ''),
//                       ),
//                       pw.Table(
//                         border: pw.TableBorder.all(width: 0.5),
//                         columnWidths: {
//                           0: const pw.FixedColumnWidth(40),
//                           1: const pw.FixedColumnWidth(40),
//                           2: const pw.FixedColumnWidth(40),
//                           3: const pw.FixedColumnWidth(40),
//                           4: const pw.FixedColumnWidth(40),
//                         },
//                         children:
//                             subTableRows
//                                 .map(
//                                   (row) => pw.TableRow(
//                                     children:
//                                         row.children
//                                             .map(
//                                               (cell) => pw.Container(
//                                                 height: rowHeight,
//                                                 child: cell,
//                                               ),
//                                             )
//                                             .toList(),
//                                   ),
//                                 )
//                                 .toList(),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             );

//             // Update totals
//             totalOrder += entryOrder;
//             totalDelv += entryDelv;
//             totalSettle += entrySettle;
//             totalPend += entryPend;
//             serial++;
//           }

//           // Total Summary Row
//           widgets.add(
//             pw.Table(
//               border: pw.TableBorder.all(width: 0.5),
//               columnWidths:
//                   withImage
//                       ? {
//                         0: const pw.FixedColumnWidth(350), // Merged column
//                         1: const pw.FixedColumnWidth(40), // Ord
//                         2: const pw.FixedColumnWidth(40), // Delv
//                         3: const pw.FixedColumnWidth(40), // Settle
//                         4: const pw.FixedColumnWidth(40), // Pend
//                       }
//                       : {
//                         0: const pw.FixedColumnWidth(390), // Merged column
//                         1: const pw.FixedColumnWidth(40), // Ord
//                         2: const pw.FixedColumnWidth(40), // Delv
//                         3: const pw.FixedColumnWidth(40), // Settle
//                         4: const pw.FixedColumnWidth(40), // Pend
//                       },
//               children: [
//                 pw.TableRow(
//                   decoration: const pw.BoxDecoration(color: PdfColors.grey300),
//                   children: [
//                     pw.Container(
//                       padding: const pw.EdgeInsets.all(4),
//                       alignment: pw.Alignment.centerLeft,
//                       child: pw.Text(
//                         'Total',
//                         style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                       ),
//                     ),
//                     pw.Container(
//                       padding: const pw.EdgeInsets.all(4),
//                       alignment: pw.Alignment.center,
//                       child: pw.Text(
//                         '$totalOrder',
//                         style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                       ),
//                     ),
//                     pw.Container(
//                       padding: const pw.EdgeInsets.all(4),
//                       alignment: pw.Alignment.center,
//                       child: pw.Text(
//                         '$totalDelv',
//                         style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                       ),
//                     ),
//                     pw.Container(
//                       padding: const pw.EdgeInsets.all(4),
//                       alignment: pw.Alignment.center,
//                       child: pw.Text(
//                         '$totalSettle',
//                         style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                       ),
//                     ),
//                     pw.Container(
//                       padding: const pw.EdgeInsets.all(4),
//                       alignment: pw.Alignment.center,
//                       child: pw.Text(
//                         '$totalPend',
//                         style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           );

//           // Blue Header
//           widgets.insert(
//             0,
//             pw.Container(
//               color: PdfColors.blue,
//               padding: const pw.EdgeInsets.all(10),
//               child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Row(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Expanded(
//                         child: pw.Column(
//                           crossAxisAlignment: pw.CrossAxisAlignment.center,
//                           children: [
//                             pw.Text(
//                               'Order Register - Party Wise',
//                               style: pw.TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: pw.FontWeight.bold,
//                                 color: PdfColors.white,
//                               ),
//                             ),
//                             pw.Text(
//                               UserSession.coBrName ?? 'VRS Software Pvt Ltd',
//                               style: pw.TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: pw.FontWeight.bold,
//                                 color: PdfColors.white,
//                               ),
//                             ),
//                             pw.Text(
//                               '1234567890',
//                               style: pw.TextStyle(
//                                 fontSize: 12,
//                                 color: PdfColors.white,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       pw.Text(
//                         'Print Date: ${DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now())}',
//                         style: pw.TextStyle(
//                           fontSize: 10,
//                           color: PdfColors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                   pw.SizedBox(height: 5),
//                   pw.Text(
//                     'Date: $fromDate to $toDate',
//                     style: pw.TextStyle(fontSize: 12, color: PdfColors.white),
//                   ),
//                 ],
//               ),
//             ),
//           );

//           // Party Name
//           widgets.insert(1, pw.SizedBox(height: 10));
//           widgets.insert(
//             2,
//             pw.Text(
//               (detailedData.isNotEmpty
//                           ? detailedData[0]['Party'] ??
//                               orderData['CustomerName']
//                           : orderData['CustomerName'])
//                       ?.toString()
//                       .toUpperCase() ??
//                   '',
//               style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
//             ),
//           );
//           widgets.insert(3, pw.SizedBox(height: 10));

//           return widgets;
//         },
//       ),
//     );

//     return pdf;
//   }

//   void _handleOrderView(Map<String, dynamic> order) {
//     final withImage = _orderViewChecked[order['OrderNo']] ?? false;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           'Viewing order ${order['OrderNo']} ${withImage ? 'with image' : ''}',
//         ),
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
//                 color: AppColors.primaryColor.shade900,
//               ),
//               textAlign: TextAlign.center,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _OrderPopupMenu extends StatelessWidget {
//   final Map<String, dynamic> order;
//   final bool viewChecked;
//   final ValueChanged<bool> onViewCheckedChanged;
//   final VoidCallback onDownload;
//   final VoidCallback onWhatsApp;
//   final VoidCallback onView;
//   final String orderType;

//   const _OrderPopupMenu({
//     required this.order,
//     required this.viewChecked,
//     required this.onViewCheckedChanged,
//     required this.onDownload,
//     required this.onWhatsApp,
//     required this.onView,
//     required this.orderType,
//   });

//   Future<void> _generateAndOpenPdf(BuildContext context) async {
//     try {
//       // Access the parent state to call methods
//       final parentState =
//           context.findAncestorStateOfType<_CustomerOrderDetailsPageState>();
//       if (parentState == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Error: Unable to access parent state')),
//         );
//         return;
//       }

//       // Fetch detailed data using the parent state's method
//       final detailedData = await parentState._fetchCustomerWiseReport(
//         order['OrderId'] ?? 0,
//       );

//       if (detailedData.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No data available for this order')),
//         );
//         return;
//       }

//       // Generate PDF using the parent state's method
//       final pdf = await parentState._generatePDF(order, detailedData);
//       final directory = await getApplicationDocumentsDirectory();
//       final file = File('${directory.path}/order_${order['OrderNo']}.pdf');
//       await file.writeAsBytes(await pdf.save());

//       // Open the PDF
//       await OpenFile.open(file.path);
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopupMenuButton<String>(
//       icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
//       onSelected: (String value) async {
//         switch (value) {
//           case 'download':
//             onDownload();
//             break;
//           case 'whatsapp':
//             onWhatsApp();
//             break;
//           case 'view':
//             await _generateAndOpenPdf(context); // Use the updated method
//             break;
//           case 'withImage':
//             break;
//         }
//       },
//       itemBuilder:
//           (BuildContext context) => <PopupMenuEntry<String>>[
//             PopupMenuItem<String>(
//               value: 'download',
//               child: ListTile(
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 12.0,
//                   vertical: 0.0,
//                 ),
//                 leading: Icon(
//                   Icons.download,
//                   size: 18,
//                   color: AppColors.primaryColor,
//                 ),
//                 title: Text(
//                   'Download',
//                   style: GoogleFonts.poppins(fontSize: 12),
//                 ),
//               ),
//             ),
//             PopupMenuItem<String>(
//               value: 'whatsapp',
//               child: ListTile(
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 12.0,
//                   vertical: 0.0,
//                 ),
//                 leading: Icon(Icons.share, size: 18, color: AppColors.primaryColor),
//                 title: Text('Share', style: GoogleFonts.poppins(fontSize: 12)),
//               ),
//             ),
//             PopupMenuItem<String>(
//               value: 'view',
//               child: ListTile(
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 12.0,
//                   vertical: 0.0,
//                 ),
//                 leading: Icon(
//                   Icons.visibility,
//                   size: 18,
//                   color: AppColors.primaryColor,
//                 ),
//                 title: Text('View', style: GoogleFonts.poppins(fontSize: 12)),
//               ),
//             ),
//             PopupMenuItem<String>(
//               value: 'withImage',
//               child: StatefulBuilder(
//                 builder: (BuildContext context, StateSetter setState) {
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12.0,
//                       vertical: 6.0,
//                     ),
//                     child: Row(
//                       children: [
//                         Checkbox(
//                           value: viewChecked,
//                           onChanged: (bool? newValue) {
//                             setState(() {
//                               onViewCheckedChanged(newValue ?? false);
//                             });
//                           },
//                           activeColor: AppColors.primaryColor,
//                           materialTapTargetSize:
//                               MaterialTapTargetSize.shrinkWrap,
//                           visualDensity: const VisualDensity(
//                             horizontal: -4,
//                             vertical: -4,
//                           ),
//                         ),
//                         const SizedBox(width: 6),
//                         Text(
//                           'With Image',
//                           style: GoogleFonts.poppins(fontSize: 12),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//     );
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:marquee/marquee.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/dashboard/data.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// import 'dart:html' as html;
import 'dart:typed_data';

import 'package:vrs_erp/viewOrder/Pdf_viewer_screen.dart';

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

class CustomerOrderDetailsPage extends StatefulWidget {
  final String custKey;
  final String customerName;
  final DateTime fromDate;
  final DateTime toDate;
  final String orderType;

  const CustomerOrderDetailsPage({
    super.key,
    required this.custKey,
    required this.customerName,
    required this.fromDate,
    required this.toDate,
    required this.orderType,
  });

  @override
  State<CustomerOrderDetailsPage> createState() =>
      _CustomerOrderDetailsPageState();
}

class _CustomerOrderDetailsPageState extends State<CustomerOrderDetailsPage> {
  List<Map<String, dynamic>> orderDetails = [];
  bool isLoading = true;
  int totalOrders = 0;
  int totalQuantity = 0;
  int totalAmount = 0;
  bool _appBarViewChecked = false;
  Map<String, bool> _orderViewChecked = {};

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }
  

  Future<void> _fetchOrderDetails() async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/report/getReportsDetail'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "FromDate": DateFormat('yyyy-MM-dd').format(widget.fromDate),
          "ToDate": DateFormat('yyyy-MM-dd').format(widget.toDate),
          "CoBr_Id": UserSession.coBrId,
          "CustKey": widget.custKey,
          "SalesPerson":
              UserSession.userType == 'S'
                  ? UserSession.userLedKey
                  : FilterData.selectedSalespersons!.isNotEmpty
                  ? FilterData.selectedSalespersons!.map((b) => b.key).join(',')
                  : null,
          "State":
              FilterData.selectedStates!.isNotEmpty
                  ? FilterData.selectedStates!.map((b) => b.key).join(',')
                  : null,
          "City":
              FilterData.selectedCities!.isNotEmpty
                  ? FilterData.selectedCities!.map((b) => b.key).join(',')
                  : null,
          "orderType": widget.orderType,
          "Detail": 2,
        }),
      );
      print(
        "HHHHHHHHHHCustomer wise-order detailResponse body:${response.body}",
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            orderDetails = List<Map<String, dynamic>>.from(data);
            totalOrders = orderDetails.length;
            totalQuantity = orderDetails.fold(
              0,
              (sum, item) =>
                  sum + (int.tryParse(item['TotalQty'].toString()) ?? 0),
            );
            totalAmount = orderDetails.fold(
              0,
              (sum, item) =>
                  sum + (int.tryParse(item['TotalAmt'].toString()) ?? 0),
            );
            isLoading = false;
          });
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to load order details: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Customer Wise - Order Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        toolbarHeight: 44,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (String value) {
                switch (value) {
                  case 'download':
                    _handleDownloadAll();
                    break;
                  case 'whatsapp':
                    _handleWhatsAppShareAll();
                    break;
                  case 'viewAll':
                    _handleViewAll();
                    break;
                  case 'withImage':
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
                              size: 16,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Download All',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
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
                              size: 16,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Share All',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'viewAll',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.visibility,
                              size: 16,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'View All',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'withImage',
                      child: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return Row(
                            children: [
                              Checkbox(
                                value: _appBarViewChecked,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    _appBarViewChecked = newValue ?? false;
                                  });
                                  this.setState(() {
                                    _appBarViewChecked = newValue ?? false;
                                  });
                                },
                                activeColor: AppColors.primaryColor,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: const VisualDensity(
                                  horizontal: -4,
                                  vertical: -4,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'With Image',
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
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
                    _buildBottomSummaryItem(
                      label: 'Total Orders',
                      value: totalOrders.toString(),
                      icon: Icons.receipt_long,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildBottomSummaryItem(
                      label: 'Total Qty',
                      value: totalQuantity.toString(),
                      icon: Icons.shopping_bag,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildBottomSummaryItem(
                      label: 'Total Amt',
                      value: '₹$totalAmount',
                      icon: Icons.currency_rupee,
                    ),
                  ],
                ),
                
              ),
            ],
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Customer Info Card
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColor.withOpacity(0.08),
                          Colors.white,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.business_center,
                            size: 22,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CUSTOMER',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.customerName,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryColor.shade900,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Orders List
                  Expanded(
                    child:
                        orderDetails.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              itemCount: orderDetails.length,
                              itemBuilder: (context, index) {
                                final order = orderDetails[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildEnhancedOrderCard(order),
                                );
                              },
                            ),
                  ),

                ],
              ),
    );
  }

Widget _buildBottomSummaryItem({
  required String label,
  required String value,
  required IconData icon,
}) {
  return Expanded(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: Colors.white),
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

Widget _buildEnhancedOrderCard(Map<String, dynamic> order) {
  String formattedDateTime = '';
  try {
    final date = DateFormat('yyyy-MM-dd').parse(order['OrderDate']);
    formattedDateTime = DateFormat('dd/MM/yyyy HH:mm').format(date);
  } catch (e) {
    formattedDateTime =
        '${order['OrderDate']} ${order['Created_Time'] ?? 'N/A'}';
  }

  String formattedDeliveryDate = '';
  try {
    final date = DateFormat('yyyy-MM-dd').parse(order['DlvDate']);
    formattedDeliveryDate = DateFormat('dd/MM/yyyy').format(date);
  } catch (e) {
    formattedDeliveryDate = order['DlvDate'] ?? 'N/A';
  }

  Widget _buildTextWithMarquee(String text, TextStyle style) {
    final maxWidth = MediaQuery.of(context).size.width / 4;
    const int lengthThreshold = 12;
    if (text.length > lengthThreshold) {
      return SizedBox(
        width: maxWidth,
        height: 20.0,
        child: Marquee(
          text: text,
          style: style,
          scrollAxis: Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          blankSpace: 16.0,
          velocity: 50.0,
          pauseAfterRound: const Duration(seconds: 1),
          startPadding: 8.0,
          accelerationDuration: const Duration(seconds: 1),
          accelerationCurve: Curves.linear,
          decelerationDuration: const Duration(milliseconds: 500),
          decelerationCurve: Curves.linear,
        ),
      );
    }
    return Text(text, style: style, overflow: TextOverflow.ellipsis);
  }

  Color deliveryColor;
  String deliveryType = order['DeliveryType']?.toString() ?? 'N/A';
  switch (deliveryType) {
    case 'Approved':
      deliveryColor = AppColors.primaryColor!;
      break;
    case 'Partially Delivered':
      deliveryColor = AppColors.primaryColor.shade400!;
      break;
    case 'Delivered':
      deliveryColor = AppColors.primaryColor.shade900!;
      break;
    case 'Completed':
      deliveryColor = AppColors.primaryColor.shade600!;
      break;
    case 'Partially Completed':
      deliveryColor = AppColors.primaryColor.shade300!;
      break;
    default:
      deliveryColor = Colors.grey[600]!;
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Left gradient border
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
            child: Column(
              children: [
                // ROW 1: Order No, Type, Status, Three Dots
                Row(
                  children: [
                    // Order No with colored background
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order['OrderNo'] ?? 'N/A',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Type with colored background
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Type:',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order['Order_Type'] ?? 'N/A',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Status with colored background
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: deliveryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: deliveryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                         
                          Text(
                            deliveryType.length > 8
                                ? '${deliveryType}'
                                : deliveryType,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: deliveryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                   const Spacer(),
                    
                    // Three dots with custom popup that doesn't close on checkbox
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.more_vert,
                          size: 18,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      onSelected: (value) {
                        // Only handle non-checkbox items
                        if (value != 'checkbox') {
                          switch (value) {
                            case 'reportView':
                              // Handle report view
                              break;
                            case 'whatsapp':
                              _showContactOptions(context, order['WhatsAppMobileNo']?.toString() ?? '');
                              break;
                            case 'download':
                              _handleOrderDownload(order);
                              break;
                            case 'view':
                              _generateAndOpenPdf(order); 
                              break;
                          }
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        // Checkbox item with custom handling (doesn't close menu)
                        PopupMenuItem<String>(
                          value: 'checkbox',
                          enabled: true,
                          child: StatefulBuilder(
                            builder: (context, setState) {
                              return Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: _orderViewChecked[order['OrderNo']] ?? false
                                          ? AppColors.primaryColor
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: _orderViewChecked[order['OrderNo']] ?? false
                                            ? AppColors.primaryColor
                                            : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                    ),
                                    child: _orderViewChecked[order['OrderNo']] ?? false
                                        ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'With Image',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          'Include images in PDF',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          onTap: () {
                            // Handle checkbox tap without closing menu
                            setState(() {
                              _orderViewChecked[order['OrderNo']] = 
                                  !(_orderViewChecked[order['OrderNo']] ?? false);
                            });
                            // Don't close the popup
                            return ;
                          },
                        ),
                        
                        const PopupMenuDivider(),
                        
                        // Report View
                        PopupMenuItem<String>(
                          value: 'reportView',
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.table_chart,
                                  color: AppColors.primaryColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Report View',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'View detailed report',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // WhatsApp
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
                                child: FaIcon(
                                  FontAwesomeIcons.whatsapp,
                                  color: Colors.green,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'WhatsApp',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Share on WhatsApp',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Download
                        PopupMenuItem<String>(
                          value: 'download',
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.download,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Download',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Save PDF to device',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // View
                        PopupMenuItem<String>(
                          value: 'view',
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.visibility,
                                  color: Colors.purple,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'View',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Open PDF viewer',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 5),

      // ROW 2: Qty, Amt, Items with colors
Container(
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: Colors.grey.shade50,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    children: [
      // Quantity
      Expanded(
        flex: 1,
        child: _buildColoredStatItem(
          label: 'Qty',
          value: '${order['TotalQty'] ?? '0'}',
          icon: Icons.shopping_bag,
          color: Colors.orange,
        ),
      ),
      Container(height: 30, width: 1, color: Colors.grey.shade300),
      
      // Amount
      Expanded(
        flex: 1,
        child: _buildColoredStatItem(
          label: 'Amt',
          value: '₹${order['TotalAmt'] ?? '0.00'}',
          icon: Icons.currency_rupee,
          color: Colors.green,
        ),
      ),
      Container(height: 30, width: 1, color: Colors.grey.shade300),
      
      // Items
      Expanded(
        flex: 1,
        child: _buildColoredStatItem(
          label: 'Items',
          value: '${order['TotalItems'] ?? '1'}',
          icon: Icons.inventory,
          color: Colors.purple,
        ),
      ),
    ],
  ),
),

                const SizedBox(height: 12),

                // ROW 3: Order Date, Delivery Date, WhatsApp with colors
                Row(
                  children: [
                    // Order Date
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: AppColors.primaryColor),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order Date',
                                    style: GoogleFonts.poppins(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    formattedDateTime,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryColor.shade900,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Delivery Date
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event, size: 12, color: Colors.green.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delivery',
                                    style: GoogleFonts.poppins(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    formattedDeliveryDate,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // WhatsApp
                    Expanded(
                      child: GestureDetector(
                        onTap: (order['WhatsAppMobileNo'] != null &&
                                order['WhatsAppMobileNo'].toString().trim().isNotEmpty)
                            ? () => _showContactOptions(
                                  context,
                                  order['WhatsAppMobileNo'].toString(),
                                )
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: (order['WhatsAppMobileNo'] != null &&
                                    order['WhatsAppMobileNo'].toString().trim().isNotEmpty)
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.whatsapp,
                                size: 12,
                                color: (order['WhatsAppMobileNo'] != null &&
                                        order['WhatsAppMobileNo'].toString().trim().isNotEmpty)
                                    ? Colors.green
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'WhatsApp',
                                      style: GoogleFonts.poppins(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      (order['WhatsAppMobileNo'] != null &&
                                              order['WhatsAppMobileNo'].toString().trim().isNotEmpty)
                                          ? order['WhatsAppMobileNo'].toString()
                                          : 'Not Available',
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: (order['WhatsAppMobileNo'] != null &&
                                                order['WhatsAppMobileNo'].toString().trim().isNotEmpty)
                                            ? Colors.green.shade700
                                            : Colors.grey.shade500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// Colored Stat Item for second row
Widget _buildColoredStatItem({
  required String label,
  required String value,
  required IconData icon,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 4),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
 
  Future<List<Map<String, dynamic>>> _fetchFullCustomerReport() async {
    try {
      final requestBody = {
        "FromDate": DateFormat('yyyy-MM-dd').format(widget.fromDate),
        "ToDate": DateFormat('yyyy-MM-dd').format(widget.toDate),
        "CustKey": widget.custKey,
        "CoBr_Id": UserSession.coBrId,
        "orderType": widget.orderType,
        "All": false, // Get full report
      };

      print("Request Body: ${jsonEncode(requestBody)}");

      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/report/customer-wise1'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load report: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching full customer report: $e');
      return [];
    }
  }

  Future<String> _savePDF(pw.Document pdf, String fileNamePrefix) async {
    String filePath = '';

    try {
      // Request storage permissions
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

      // Determine the downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir != null) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final file = File('${downloadsDir.path}/$fileNamePrefix$timestamp.pdf');
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

  void _downloadPdfOnWeb({required List<int> bytes, required String fileName}) {
    // final blob = html.Blob([bytes], 'application/pdf');
    // final url = html.Url.createObjectUrlFromBlob(blob);

    // final anchor =
    //     html.AnchorElement(href: url)
    //       ..setAttribute('download', fileName)
    //       ..click();

    // html.Url.revokeObjectUrl(url);
  }

  Future<void> _handleDownloadAll() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating full report...')),
      );

      final detailedData = await _fetchFullCustomerReport();

      if (detailedData.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No data available')));
        return;
      }

      final pdf = await _generateFullCustomerPDF(detailedData);

      final timestamp =
          '${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}'
          '_${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}';

      final fileName = 'CustomerOrderReport_$timestamp.pdf';

      /* ==================== WEB ==================== */
      if (kIsWeb) {
        final Uint8List pdfBytes = await pdf.save();

        _downloadPdfOnWeb(
          bytes: pdfBytes.toList(), // ✅ convert to List<int>
          fileName: fileName,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF downloaded successfully')),
        );
      }
      /* ==================== MOBILE ==================== */
      else {
        final filePath = await _savePDF(pdf, 'CustomerOrderReport_');

        if (filePath.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF saved to: $filePath'),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () => OpenFile.open(filePath),
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _handleOrderDownload(Map<String, dynamic> order) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generating order: ${order['OrderNo']}...')),
      );

      final detailedData = await _fetchCustomerWiseReport(
        order['OrderId'] ?? 0,
      );
      if (detailedData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data available for this order')),
        );
        return;
      }

      final pdf = await _generatePDF(order, detailedData);
      final filePath = await _savePDF(pdf, 'Order_${order['OrderNo']}_');

      if (filePath.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to: $filePath'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFile.open(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _handleWhatsAppShareAll() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating and sharing full report...')),
      );

      final detailedData = await _fetchFullCustomerReport();
      if (detailedData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data available to share')),
        );
        return;
      }

      final pdf = await _generateFullCustomerPDF(detailedData);
      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/CustomerOrderReport_$timestamp.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Share the PDF using the native share dialog
      await Share.shareFiles(
        [filePath],
        text: 'Customer Order Report',
        subject: 'Customer Order Report',
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sharing report: $e')));
    }
  }

  void _handleViewAll() async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Generating report...')));

      final detailedData = await _fetchFullCustomerReport();

      if (detailedData.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No data available')));
        return;
      }

      // Generate and open PDF for the entire report
      await _generateAndOpenFullPdf(detailedData);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _generateAndOpenFullPdf(
    List<Map<String, dynamic>> detailedData,
  ) async {
    final pdf = await _generateFullCustomerPDF(detailedData);
    final directory = await getApplicationDocumentsDirectory();
    final filePath =
        '${directory.path}/customer_${widget.customerName}_orders.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  Future<pw.Document> _generateFullCustomerPDF(
    List<Map<String, dynamic>> detailedData,
  ) async {
    final pdf = pw.Document();
    final fromDate = DateFormat('dd-MM-yyyy').format(widget.fromDate);
    final toDate = DateFormat('dd-MM-yyyy').format(widget.toDate);

    // Group data by ItemName + OrderNo + Color
    Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var item in detailedData) {
      String key = '${item['ItemName']}_${item['OrderNo']}_${item['Color']}';
      groupedData.putIfAbsent(key, () => []).add(item);
    }

    // Function to get image URL
    String _getImageUrl(Map<String, dynamic> item) {
      if (UserSession.onlineImage == '0') {
        final imagePath = item['Style_Image'] ?? '';
        final imageName = imagePath.split('/').last.split('?').first;
        if (imageName.isEmpty) {
          return '';
        }
        return '${AppConstants.BASE_URL}/images/$imageName';
      } else if (UserSession.onlineImage == '1') {
        return item['Style_Image'] ?? '';
      }
      return '';
    }

    // Function to load image for PDF
    Future<pw.ImageProvider?> _loadImage(String imageUrl) async {
      if (imageUrl.isEmpty) return null;
      try {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          return pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        print('Error loading image $imageUrl: $e');
      }
      return null;
    }

    // Precompute images for each group if checkbox is checked
    Map<String, pw.ImageProvider?> imageCache = {};
    if (_appBarViewChecked) {
      for (var key in groupedData.keys) {
        final item = groupedData[key]![0];
        final imageUrl = _getImageUrl(item);
        imageCache[key] = await _loadImage(imageUrl);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(10),
        build: (context) {
          List<pw.Widget> widgets = [];
          int serial = 1;
          num totalOrder = 0;
          num totalDelv = 0;
          num totalSettle = 0;
          num totalPend = 0;

          // Define column widths dynamically based on _appBarViewChecked
          final columnWidths =
              _appBarViewChecked
                  ? {
                    0: const pw.FixedColumnWidth(30), // No
                    1: const pw.FixedColumnWidth(60), // Image
                    2: const pw.FixedColumnWidth(80), // ItemName
                    3: const pw.FixedColumnWidth(80), // Order No.
                    4: const pw.FixedColumnWidth(60), // Color
                    5: const pw.FixedColumnWidth(40), // Size
                    6: const pw.FixedColumnWidth(40), // Ord.
                    7: const pw.FixedColumnWidth(40), // Delv.
                    8: const pw.FixedColumnWidth(40), // Settle
                    9: const pw.FixedColumnWidth(40), // Pend.
                  }
                  : {
                    0: const pw.FixedColumnWidth(30), // No
                    1: const pw.FixedColumnWidth(
                      100,
                    ), // ItemName (increased width)
                    2: const pw.FixedColumnWidth(
                      100,
                    ), // Order No. (increased width)
                    3: const pw.FixedColumnWidth(80), // Color (increased width)
                    4: const pw.FixedColumnWidth(40), // Size
                    5: const pw.FixedColumnWidth(40), // Ord.
                    6: const pw.FixedColumnWidth(40), // Delv.
                    7: const pw.FixedColumnWidth(40), // Settle
                    8: const pw.FixedColumnWidth(40), // Pend.
                  };

          // Add table header
          widgets.add(
            pw.Container(
              color: PdfColors.grey200,
              child: pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: columnWidths,
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'No',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      if (_appBarViewChecked)
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Image',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'ItemName',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Order No.',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Color',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Size',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Ord.',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Delv.',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Settle',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Pend.',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );

          // Generate data rows
          for (var key in groupedData.keys) {
            final groupItems = groupedData[key]!;
            final item = groupItems[0];
            num entryOrder = 0, entryDelv = 0, entrySettle = 0, entryPend = 0;

            // Create image cell
            pw.Widget imageCell =
                _appBarViewChecked
                    ? (imageCache[key] != null
                        ? pw.Image(imageCache[key]!, fit: pw.BoxFit.contain)
                        : pw.Text(
                          'Image Not Available',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey,
                          ),
                          textAlign: pw.TextAlign.center,
                        ))
                    : pw.Text(
                      '',
                      style: const pw.TextStyle(fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    );

            // Create itemName cell
            pw.Widget itemNameCell = pw.Text(
              item['ItemName']?.toString() ?? 'N/A',
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.center,
            );

            // Create subtable for size-related data
            final subTableRows =
                groupItems.map((row) {
                  entryOrder += (row['OrderQty'] ?? 0) as num;
                  entryDelv += (row['DelvQty'] ?? 0) as num;
                  entrySettle += (row['SettleQty'] ?? 0) as num;
                  entryPend += (row['PendingQty'] ?? 0) as num;
                  return pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.center,
                        child: pw.Text(row['Size']?.toString() ?? ''),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.center,
                        child: pw.Text((row['OrderQty'] ?? 0).toString()),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.center,
                        child: pw.Text((row['DelvQty'] ?? 0).toString()),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.center,
                        child: pw.Text((row['SettleQty'] ?? 0).toString()),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.center,
                        child: pw.Text((row['PendingQty'] ?? 0).toString()),
                      ),
                    ],
                  );
                }).toList();

            // Calculate maxCellHeight based on content
            final numRows = groupItems.length;
            final baseRowHeight = 18.0;
            final imageHeight = _appBarViewChecked ? 40.0 : baseRowHeight;
            final subtableHeight = numRows * baseRowHeight;
            final maxCellHeight =
                (subtableHeight > imageHeight ? subtableHeight : imageHeight);
            final rowHeight = maxCellHeight / numRows;

            // Define row column widths
            final rowColumnWidths =
                _appBarViewChecked
                    ? {
                      0: const pw.FixedColumnWidth(30), // No
                      1: const pw.FixedColumnWidth(60), // Image
                      2: const pw.FixedColumnWidth(80), // ItemName
                      3: const pw.FixedColumnWidth(80), // Order No.
                      4: const pw.FixedColumnWidth(60), // Color
                      5: const pw.FixedColumnWidth(200), // Subtable
                    }
                    : {
                      0: const pw.FixedColumnWidth(30), // No
                      1: const pw.FixedColumnWidth(100), // ItemName
                      2: const pw.FixedColumnWidth(100), // Order No.
                      3: const pw.FixedColumnWidth(80), // Color
                      4: const pw.FixedColumnWidth(200), // Subtable
                    };

            widgets.add(
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: rowColumnWidths,
                children: [
                  pw.TableRow(
                    children: [
                      pw.Container(
                        height: maxCellHeight,
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.center,
                        child: pw.Text('$serial'),
                      ),
                      if (_appBarViewChecked)
                        pw.Container(
                          height: maxCellHeight,
                          padding: const pw.EdgeInsets.all(4),
                          alignment: pw.Alignment.center,
                          child: imageCell,
                        ),
                      pw.Container(
                        height: maxCellHeight,
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.center,
                        child: itemNameCell,
                      ),
                      pw.Container(
                        height: maxCellHeight,
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          "${item['OrderNo'] ?? ''}\n(${item['OrderDate'] ?? ''})",
                        ),
                      ),
                      pw.Container(
                        height: maxCellHeight,
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.center,
                        child: pw.Text(item['Color']?.toString() ?? ''),
                      ),
                      pw.Table(
                        border: pw.TableBorder.all(width: 0.5),
                        columnWidths: {
                          0: const pw.FixedColumnWidth(40),
                          1: const pw.FixedColumnWidth(40),
                          2: const pw.FixedColumnWidth(40),
                          3: const pw.FixedColumnWidth(40),
                          4: const pw.FixedColumnWidth(40),
                        },
                        children:
                            subTableRows
                                .map(
                                  (row) => pw.TableRow(
                                    children:
                                        row.children
                                            .map(
                                              (cell) => pw.Container(
                                                height: rowHeight,
                                                child: cell,
                                              ),
                                            )
                                            .toList(),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ],
              ),
            );

            // Update totals
            totalOrder += entryOrder;
            totalDelv += entryDelv;
            totalSettle += entrySettle;
            totalPend += entryPend;
            serial++;
          }

          // Total Summary Row
          widgets.add(
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths:
                  _appBarViewChecked
                      ? {
                        0: const pw.FixedColumnWidth(315), // Merged column
                        1: const pw.FixedColumnWidth(40), // Ord
                        2: const pw.FixedColumnWidth(40), // Delv
                        3: const pw.FixedColumnWidth(40), // Settle
                        4: const pw.FixedColumnWidth(40), // Pend
                      }
                      : {
                        0: const pw.FixedColumnWidth(350), // Merged column
                        1: const pw.FixedColumnWidth(40), // Ord
                        2: const pw.FixedColumnWidth(40), // Delv
                        3: const pw.FixedColumnWidth(40), // Settle
                        4: const pw.FixedColumnWidth(40), // Pend
                      },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Text(
                        'Total',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        '$totalOrder',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        '$totalDelv',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        '$totalSettle',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        '$totalPend',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          // Blue Header
          widgets.insert(
            0,
            pw.Container(
              color: PdfColors.blue,
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              'Order Register - Party Wise',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.Text(
                              UserSession.coBrName ?? 'VRS Software Pvt Ltd',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.Text(
                              '1234567890',
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Text(
                        'Print Date: ${DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now())}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Date: $fromDate to $toDate',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.white),
                  ),
                ],
              ),
            ),
          );

          // Party Name
          widgets.insert(1, pw.SizedBox(height: 10));
          widgets.insert(
            2,
            pw.Text(
              widget.customerName.toUpperCase(),
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          );
          widgets.insert(3, pw.SizedBox(height: 10));

          return widgets;
        },
      ),
    );

    return pdf;
  }

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
      builder:  (context) =>SafeArea( 
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
   ), );
  }


  Future<List<Map<String, dynamic>>> _fetchCustomerWiseReport(int docId) async {
    try {
      final requestBody = {
        "CoBr_Id": UserSession.coBrId,
        "orderType": widget.orderType,
        "DocId": docId,
        "All": true,
      };

      print("📤 Request Body:\n${jsonEncode(requestBody)}");

      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/report/customer-wise'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print("📥 Response Body:\n${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load report: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching report: $e');
      return [];
    }
  }

  Future<pw.Document> _generatePDF(
    Map<String, dynamic> orderData,
    List<Map<String, dynamic>> detailedData,
  ) async {
    final pdf = pw.Document();
    final bool withImage = _orderViewChecked[orderData['OrderNo']] ?? false;
    final fromDate = DateFormat('dd-MM-yyyy').format(
      DateFormat('yyyy-MM-dd').parse(
        detailedData.isNotEmpty ? detailedData[0]['FromDate'] : '2025-07-17',
      ),
    );
    final toDate = DateFormat('dd-MM-yyyy').format(
      DateFormat('yyyy-MM-dd').parse(
        detailedData.isNotEmpty ? detailedData[0]['ToDate'] : '2025-07-17',
      ),
    );

    // Group data by ItemName + OrderNo + Color
    Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var item in detailedData) {
      String key = '${item['ItemName']}_${item['OrderNo']}_${item['Color']}';
      groupedData.putIfAbsent(key, () => []).add(item);
    }

    // Function to get image URL
    String _getImageUrl(Map<String, dynamic> item) {
      if (UserSession.onlineImage == '0') {
        final imagePath = item['Style_Image'] ?? '';
        final imageName = imagePath.split('/').last.split('?').first;
        if (imageName.isEmpty) {
          return '';
        }
        return '${AppConstants.BASE_URL}/images/$imageName';
      } else if (UserSession.onlineImage == '1') {
        return item['Style_Image'] ?? '';
      }
      return '';
    }

    // Function to load image for PDF
    Future<pw.ImageProvider?> _loadImage(String imageUrl) async {
      if (imageUrl.isEmpty) return null;
      try {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          return pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        print('Error loading image $imageUrl: $e');
      }
      return null;
    }

    // Precompute images for each group if checkbox is checked
    Map<String, pw.ImageProvider?> imageCache = {};
    if (withImage) {
      for (var key in groupedData.keys) {
        final item = groupedData[key]![0];
        final imageUrl = _getImageUrl(item);
        imageCache[key] = await _loadImage(imageUrl);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(10),
        build: (context) {
          List<pw.Widget> widgets = [];
          int serial = 1;
          num totalOrder = 0;
          num totalDelv = 0;
          num totalSettle = 0;
          num totalPend = 0;

          // Define column widths dynamically based on withImage
          final columnWidths =
              withImage
                  ? {
                    0: const pw.FixedColumnWidth(30), // No
                    1: const pw.FixedColumnWidth(60), // Image
                    2: const pw.FixedColumnWidth(80), // ItemName
                    3: const pw.FixedColumnWidth(80), // Order No.
                    4: const pw.FixedColumnWidth(60), // Color
                    5: const pw.FixedColumnWidth(40), // Size
                    6: const pw.FixedColumnWidth(40), // Ord.
                    7: const pw.FixedColumnWidth(40), // Delv.
                    8: const pw.FixedColumnWidth(40), // Settle
                    9: const pw.FixedColumnWidth(40), // Pend.
                  }
                  : {
                    0: const pw.FixedColumnWidth(30), // No
                    1: const pw.FixedColumnWidth(100), // ItemName
                    2: const pw.FixedColumnWidth(100), // Order No.
                    3: const pw.FixedColumnWidth(80), // Color
                    4: const pw.FixedColumnWidth(40), // Size
                    5: const pw.FixedColumnWidth(40), // Ord.
                    6: const pw.FixedColumnWidth(40), // Delv.
                    7: const pw.FixedColumnWidth(40), // Settle
                    8: const pw.FixedColumnWidth(40), // Pend.
                  };

          // Add table header
          widgets.add(
            pw.Container(
              color: PdfColors.grey200,
              child: pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: columnWidths,
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'No',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      if (withImage)
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Image',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'ItemName',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Order No.',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Color',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Size',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Ord.',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Delv.',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Settle',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Pend.',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );

          // Generate data rows
          for (var key in groupedData.keys) {
            final groupItems = groupedData[key]!;
            final item = groupItems[0];
            num entryOrder = 0, entryDelv = 0, entrySettle = 0, entryPend = 0;

            // Create image cell
            pw.Widget imageCell =
                withImage
                    ? (imageCache[key] != null
                        ? pw.Image(imageCache[key]!, fit: pw.BoxFit.contain)
                        : pw.Text(
                          'Image Not Available',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey,
                          ),
                          textAlign: pw.TextAlign.center,
                        ))
                    : pw.Text(
                      '',
                      style: const pw.TextStyle(fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    );

            // Create itemName cell
            pw.Widget itemNameCell = pw.Text(
              item['ItemName']?.toString() ?? 'N/A',
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.center,
            );

            // Create subtable for size-related data
            final subTableRows =
                groupItems.map((row) {
                  entryOrder += (row['OrderQty'] ?? 0) as num;
                  entryDelv += (row['DelvQty'] ?? 0) as num;
                  entrySettle += (row['SettleQty'] ?? 0) as num;
                  entryPend += (row['PendingQty'] ?? 0) as num;
                  return pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.center,
                        child: pw.Text(row['Size']?.toString() ?? ''),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.center,
                        child: pw.Text((row['OrderQty'] ?? 0).toString()),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.center,
                        child: pw.Text((row['DelvQty'] ?? 0).toString()),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.center,
                        child: pw.Text((row['SettleQty'] ?? 0).toString()),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.center,
                        child: pw.Text((row['PendingQty'] ?? 0).toString()),
                      ),
                    ],
                  );
                }).toList();

            // Calculate maxCellHeight based on content
            final numRows = groupItems.length;
            final baseRowHeight = 18.0;
            final imageHeight = withImage ? 40.0 : baseRowHeight;
            final subtableHeight = numRows * baseRowHeight;
            final maxCellHeight =
                (subtableHeight > imageHeight ? subtableHeight : imageHeight);
            final rowHeight = maxCellHeight / numRows;

            // Define row column widths
            final rowColumnWidths =
                withImage
                    ? {
                      0: const pw.FixedColumnWidth(30), // No
                      1: const pw.FixedColumnWidth(60), // Image
                      2: const pw.FixedColumnWidth(80), // ItemName
                      3: const pw.FixedColumnWidth(80), // Order No.
                      4: const pw.FixedColumnWidth(60), // Color
                      5: const pw.FixedColumnWidth(200), // Subtable
                    }
                    : {
                      0: const pw.FixedColumnWidth(30), // No
                      1: const pw.FixedColumnWidth(100), // ItemName
                      2: const pw.FixedColumnWidth(100), // Order No.
                      3: const pw.FixedColumnWidth(80), // Color
                      4: const pw.FixedColumnWidth(200), // Subtable
                    };

            widgets.add(
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: rowColumnWidths,
                children: [
                  pw.TableRow(
                    children: [
                      pw.Container(
                        height: maxCellHeight,
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.center,
                        child: pw.Text('$serial'),
                      ),
                      if (withImage)
                        pw.Container(
                          height: maxCellHeight,
                          padding: const pw.EdgeInsets.all(4),
                          alignment: pw.Alignment.center,
                          child: imageCell,
                        ),
                      pw.Container(
                        height: maxCellHeight,
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.center,
                        child: itemNameCell,
                      ),
                      pw.Container(
                        height: maxCellHeight,
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          "${item['OrderNo'] ?? ''}\n(${item['OrderDate'] ?? ''})",
                        ),
                      ),
                      pw.Container(
                        height: maxCellHeight,
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.center,
                        child: pw.Text(item['Color']?.toString() ?? ''),
                      ),
                      pw.Table(
                        border: pw.TableBorder.all(width: 0.5),
                        columnWidths: {
                          0: const pw.FixedColumnWidth(40),
                          1: const pw.FixedColumnWidth(40),
                          2: const pw.FixedColumnWidth(40),
                          3: const pw.FixedColumnWidth(40),
                          4: const pw.FixedColumnWidth(40),
                        },
                        children:
                            subTableRows
                                .map(
                                  (row) => pw.TableRow(
                                    children:
                                        row.children
                                            .map(
                                              (cell) => pw.Container(
                                                height: rowHeight,
                                                child: cell,
                                              ),
                                            )
                                            .toList(),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ],
              ),
            );

            // Update totals
            totalOrder += entryOrder;
            totalDelv += entryDelv;
            totalSettle += entrySettle;
            totalPend += entryPend;
            serial++;
          }

          // Total Summary Row
          widgets.add(
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths:
                  withImage
                      ? {
                        0: const pw.FixedColumnWidth(350), // Merged column
                        1: const pw.FixedColumnWidth(40), // Ord
                        2: const pw.FixedColumnWidth(40), // Delv
                        3: const pw.FixedColumnWidth(40), // Settle
                        4: const pw.FixedColumnWidth(40), // Pend
                      }
                      : {
                        0: const pw.FixedColumnWidth(390), // Merged column
                        1: const pw.FixedColumnWidth(40), // Ord
                        2: const pw.FixedColumnWidth(40), // Delv
                        3: const pw.FixedColumnWidth(40), // Settle
                        4: const pw.FixedColumnWidth(40), // Pend
                      },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Text(
                        'Total',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        '$totalOrder',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        '$totalDelv',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        '$totalSettle',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        '$totalPend',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          // Blue Header
          widgets.insert(
            0,
            pw.Container(
              color: PdfColors.blue,
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              'Order Register - Party Wise',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.Text(
                              UserSession.coBrName ?? 'VRS Software Pvt Ltd',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.Text(
                              '1234567890',
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Text(
                        'Print Date: ${DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now())}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Date: $fromDate to $toDate',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.white),
                  ),
                ],
              ),
            ),
          );

          // Party Name
          widgets.insert(1, pw.SizedBox(height: 10));
          widgets.insert(
            2,
            pw.Text(
              (detailedData.isNotEmpty
                          ? detailedData[0]['Party'] ??
                              orderData['CustomerName']
                          : orderData['CustomerName'])
                      ?.toString()
                      .toUpperCase() ??
                  '',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          );
          widgets.insert(3, pw.SizedBox(height: 10));

          return widgets;
        },
      ),
    );

    return pdf;
  }
Future<void> _generateAndOpenPdf(Map<String, dynamic> order) async {
  try {
    // Fetch detailed data using the parent state's method
    final detailedData = await _fetchCustomerWiseReport(
      order['OrderId'] ?? 0,
    );

    if (detailedData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available for this order')),
      );
      return;
    }

    // Generate PDF using the parent state's method
    final pdf = await _generatePDF(order, detailedData);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/order_${order['OrderNo']}.pdf');
    await file.writeAsBytes(await pdf.save());

    // Open the PDF
    await OpenFile.open(file.path);
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
  }
}
}

