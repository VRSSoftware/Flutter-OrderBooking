// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:dio/dio.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'package:marquee/marquee.dart';
// import 'package:http/http.dart' as http; // Added for HTTP requests
// import 'package:permission_handler/permission_handler.dart';
// import 'dart:convert'; // Added for base64 encoding

// import 'package:vrs_erp/constants/app_constants.dart';
// import 'package:vrs_erp/models/keyName.dart';
// import 'package:vrs_erp/models/registerModel.dart';
// import 'package:vrs_erp/register/registerFilteration.dart';
// import 'package:vrs_erp/screens/drawer_screen.dart';
// import 'package:vrs_erp/services/app_services.dart';
// import 'package:vrs_erp/viewOrder/Pdf_viewer_screen.dart';

// class RegisterPage extends StatefulWidget {
//   @override
//   _RegisterPageState createState() => _RegisterPageState();
// }

// class _RegisterPageState extends State<RegisterPage> {
//   bool isLoading = false;
//   List<RegisterOrder> registerOrderList = [];
//   DateTime? fromDate;
//   DateTime? toDate;
//   final TextEditingController fromDateController = TextEditingController();
//   final TextEditingController toDateController = TextEditingController();
//   KeyName? selectedLedger;
//   KeyName? selectedSalesperson;
//   List<KeyName> ledgerList = [];
//   List<KeyName> salespersonList = [];
//   bool isLoadingLedgers = true;
//   bool isLoadingSalesperson = true;
//   Map<String, bool> checkedOrders = {};
//   String? selectedOrderStatus;
//   DateTime? deliveryFromDate;
//   DateTime? deliveryToDate;

//   @override
//   void initState() {
//     super.initState();
//     fromDate = DateTime.now().subtract(Duration(days: 30));
//     toDate = DateTime.now();
//     fromDateController.text = DateFormat('yyyy-MM-dd').format(fromDate!);
//     toDateController.text = DateFormat('yyyy-MM-dd').format(toDate!);
//     _loadDropdownData();
//     fetchOrders();
//   }

//   Future<void> _loadDropdownData() async {
//     setState(() {
//       isLoadingLedgers = true;
//       isLoadingSalesperson = true;
//     });

//     try {
//       final fetchedLedgersResponse = await ApiService.fetchLedgers(
//         ledCat: 'w',
//         coBrId: UserSession.coBrId ?? '',
//       );
//       final fetchedSalespersonResponse = await ApiService.fetchLedgers(
//         ledCat: 's',
//         coBrId: UserSession.coBrId ?? '',
//       );

//       setState(() {
//         ledgerList = List<KeyName>.from(fetchedLedgersResponse['result'] ?? []);
//         salespersonList = List<KeyName>.from(
//           fetchedSalespersonResponse['result'] ?? [],
//         );
//         isLoadingLedgers = false;
//         isLoadingSalesperson = false;
//       });
//     } catch (e) {
//       setState(() {
//         isLoadingLedgers = false;
//         isLoadingSalesperson = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching dropdown data: $e')),
//       );
//     }
//   }

//   Future<void> fetchOrders() async {
//     setState(() {
//       isLoading = true;
//     });
//     try {
//       final orders = await ApiService.fetchOrderRegister(
//         fromDate: fromDateController.text,
//         toDate: toDateController.text,
//         custKey:
//             UserSession.userType == "C"
//                 ? UserSession.userLedKey
//                 : selectedLedger?.key,
//         coBrId: UserSession.coBrId ?? '',
//         salesPerson:
//             UserSession.userType == "S"
//                 ? UserSession.userLedKey
//                 : selectedSalesperson?.key,
//         status: selectedOrderStatus,
//         dlvFromDate:
//             deliveryFromDate == null ? null : deliveryFromDate.toString(),
//         dlvToDate: deliveryToDate == null ? null : deliveryToDate.toString(),
//         // userName: UserSession.userType == 'Admin'? '''',
//         userName: null,
//         lastSavedOrderId: null,
//       );
//       setState(() {
//         registerOrderList = orders;
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error fetching orders: $e')));
//     }
//   }

//   double _calculateTotalAmount() {
//     return registerOrderList.fold(
//       0.0,
//       (sum, registerOrder) => sum + registerOrder.amount,
//     );
//   }

//   int _calculateTotalQuantity() {
//     return registerOrderList.fold(
//       0,
//       (sum, registerOrder) => sum + registerOrder.quantity,
//     );
//   }

//   void _submitRegisterOrders() {
//     // Handle register submission logic
//   }
//   Future<bool> _sendWhatsAppFile2({
//     required List<int> fileBytes,
//     required String mobileNo,
//     required String fileType,
//     String? caption,
//   }) async {
//     try {
//       String fileBase64 = base64Encode(fileBytes);

//       final response = await http.post(
//         Uri.parse("http://node4.wabapi.com/v4/postfile.php"),
//         body: {
//           'data': fileBase64,
//           'filename': fileType == 'image' ? 'catalog.jpg' : 'catalog.pdf',
//           'key': AppConstants.whatsappKey,
//           'number': '91$mobileNo',
//           'caption': caption ?? 'Please find the file attached.',
//         },
//       );

//       if (response.statusCode == 200) {
//         return true;
//       } else {
//         return false;
//       }
//     } catch (e) {
//       print('Error sending file: $e');
//       return false;
//     }
//   }

// Widget buildOrderItem(RegisterOrder registerOrder) {
//   // Initialize checkbox state for this order if not already set
//   checkedOrders.putIfAbsent(registerOrder.orderNo, () => false);

//   // Determine colors based on DeliveryType
//   Color deliveryIconColor;
//   Color deliveryTextColor;
//   Color deliveryBorderColor;
//   String deliveryType = registerOrder.deliveryType ?? 'N/A';
//   switch (deliveryType) {
//     case 'Approved':
//       deliveryIconColor = Colors.teal;
//       deliveryTextColor = Colors.teal;
//       deliveryBorderColor = Colors.teal;
//       break;
//     case 'Partially Delivered':
//       deliveryIconColor = Colors.orange;
//       deliveryTextColor = Colors.orange;
//       deliveryBorderColor = Colors.orange;
//       break;
//     case 'Delivered':
//       deliveryIconColor = Colors.blue;
//       deliveryTextColor = Colors.blue;
//       deliveryBorderColor = Colors.blue;
//       break;
//     case 'Completed':
//       deliveryIconColor = Colors.green;
//       deliveryTextColor = Colors.green;
//       deliveryBorderColor = Colors.green;
//       break;
//     case 'Partially Completed':
//       deliveryIconColor = Colors.greenAccent;
//       deliveryTextColor = Colors.greenAccent;
//       deliveryBorderColor = Colors.greenAccent;
//       break;
//     default:
//       deliveryIconColor = Colors.grey;
//       deliveryTextColor = Colors.grey;
//       deliveryBorderColor = Colors.grey;
//   }

//   return Container(
//     margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//     width: double.infinity,
//     decoration: BoxDecoration(
//       color: Colors.white, // White background
//       border: Border.all(color: Colors.blueGrey.shade100, width: 1), // Subtle border
//       borderRadius: BorderRadius.circular(0), // Rounded corners

//     ),
//     child: Padding(
//       padding: const EdgeInsets.all(12.0), // Reduced padding for compactness
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // First Row: Item Name and Popup Menu
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: SizedBox(
//                   height: 24,
//                   child: Marquee(
//                     text: registerOrder.itemName,
//                     style: GoogleFonts.poppins(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.primaryColor, // Vibrant color for item name
//                     ),
//                     scrollAxis: Axis.horizontal,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     blankSpace: 20.0,
//                     velocity: 50.0,
//                     pauseAfterRound: const Duration(seconds: 1),
//                     startPadding: 10.0,
//                     accelerationDuration: const Duration(seconds: 1),
//                     accelerationCurve: Curves.linear,
//                     decelerationDuration: const Duration(milliseconds: 500),
//                     decelerationCurve: Curves.easeOut,
//                   ),
//                 ),
//               ),
//               PopupMenuButton<String>(
//                 icon: const Icon(Icons.more_vert, color: Colors.black54),
//                 onSelected: (value) async {
//                   switch (value) {
//                     case 'whatsapp':
//                       showDialog(
//                         context: context,
//                         builder: (context) {
//                           final TextEditingController controller =
//                               TextEditingController(
//                             text: registerOrder.whatsAppMobileNo ?? '',
//                           );
//                           return AlertDialog(
//                             title: const Text('Enter WhatsApp Number'),
//                             content: TextField(
//                               controller: controller,
//                               keyboardType: TextInputType.number,
//                               maxLength: 10,
//                               decoration: const InputDecoration(
//                                 hintText: 'Enter 10-digit number',
//                                 counterText: '',
//                               ),
//                             ),
//                             actions: [
//                               TextButton(
//                                 onPressed: () => Navigator.pop(context),
//                                 child: const Text('Cancel'),
//                               ),
//                               ElevatedButton(
//                                 onPressed: () async {
//                                   String number = controller.text.trim();
//                                   if (number.length != 10 ||
//                                       !RegExp(r'^[0-9]{10}$').hasMatch(number)) {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       const SnackBar(
//                                         content: Text(
//                                           'Please enter a valid 10-digit number',
//                                         ),
//                                       ),
//                                     );
//                                     return;
//                                   }

//                                   Navigator.pop(context); // Close dialog
//                                   String docId = registerOrder.orderId;

//                                   try {
//                                     final dio = Dio();
//                                     final response = await dio.post(
//                                       '${AppConstants.Pdf_url}/api/values/order',
//                                       data: {"doc_id": docId},
//                                       options: Options(
//                                         responseType: ResponseType.bytes,
//                                       ),
//                                     );

//                                     bool sent = await _sendWhatsAppFile2(
//                                       fileBytes: response.data,
//                                       mobileNo: number,
//                                       fileType: 'pdf',
//                                       caption: 'Order PDF',
//                                     );

//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       SnackBar(
//                                         content: Text(
//                                           sent
//                                               ? 'Sent on WhatsApp'
//                                               : 'Failed to send',
//                                         ),
//                                       ),
//                                     );
//                                   } catch (e) {
//                                     print('Error: $e');
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       const SnackBar(
//                                         content: Text('Failed to download or send'),
//                                       ),
//                                     );
//                                   }
//                                 },
//                                 child: const Text('Send'),
//                               ),
//                             ],
//                           );
//                         },
//                       );
//                       break;

//                     case 'download':
//                       try {
//                         // Request storage permission for Android
//                         if (Platform.isAndroid) {
//                           var status = await Permission.storage.status;
//                           if (!status.isGranted) {
//                             status = await Permission.storage.request();
//                             if (!status.isGranted) {
//                               if (mounted) {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content: Text('Storage permission denied'),
//                                   ),
//                                 );
//                               }
//                               debugPrint('Storage permission denied');
//                               break;
//                             }
//                           }
//                         }

//                         // Show loading dialog
//                         showDialog(
//                           context: context,
//                           barrierDismissible: false,
//                           builder: (context) => const AlertDialog(
//                             content: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 CircularProgressIndicator(),
//                                 SizedBox(width: 16),
//                                 Text('Downloading...'),
//                               ],
//                             ),
//                           ),
//                         );

//                         // Make API request
//                         final dio = Dio();
//                         final response = await dio.post(
//                           '${AppConstants.Pdf_url}/api/values/order',
//                           data: {"doc_id": registerOrder.orderId},
//                           options: Options(responseType: ResponseType.bytes),
//                         );

//                         debugPrint('API response status: ${response.statusCode}');

//                         if (response.statusCode == 200) {
//                           // Get Downloads directory
//                           Directory? directory;
//                           String filePath;
//                           if (Platform.isAndroid) {
//                             directory = Directory('/storage/emulated/0/Download');
//                             if (!await directory.exists()) {
//                               await directory.create(recursive: true);
//                             }
//                             filePath =
//                                 '${directory.path}/Order_${registerOrder.orderId}.pdf';
//                           } else if (Platform.isIOS) {
//                             directory = await getApplicationDocumentsDirectory();
//                             filePath =
//                                 '${directory.path}/Order_${registerOrder.orderId}.pdf';
//                           } else {
//                             throw Exception('Unsupported platform');
//                           }

//                           // Write file
//                           final file = File(filePath);
//                           await file.writeAsBytes(response.data, flush: true);
//                           debugPrint(
//                             'PDF downloaded to: $filePath, exists: ${await file.exists()}',
//                           );

//                           // Close loading dialog
//                           if (mounted) {
//                             Navigator.of(context, rootNavigator: true).pop();
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text('PDF downloaded to $filePath'),
//                                 action: SnackBarAction(
//                                   label: 'Open',
//                                   onPressed: () async {
//                                     final result = await OpenFile.open(filePath);
//                                     debugPrint(
//                                       'OpenFile result: ${result.type}, message: ${result.message}',
//                                     );
//                                     if (result.type != ResultType.done && mounted) {
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         SnackBar(
//                                           content: Text(
//                                             'Failed to open PDF: ${result.message}',
//                                           ),
//                                         ),
//                                       );
//                                     }
//                                   },
//                                 ),
//                               ),
//                             );
//                           }
//                         } else {
//                           if (mounted) {
//                             Navigator.of(context, rootNavigator: true).pop();
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text(
//                                   'Failed to load PDF: ${response.statusCode}',
//                                 ),
//                               ),
//                             );
//                           }
//                           debugPrint('Failed to load PDF: ${response.statusCode}');
//                         }
//                       } catch (e) {
//                         debugPrint('Download error: $e');
//                         if (mounted) {
//                           Navigator.of(context, rootNavigator: true).pop();
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(content: Text('Download failed: $e')),
//                           );
//                         }
//                       }
//                       break;

//                     case 'view':
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => PdfViewerScreen(
//                             orderNo: registerOrder.orderId,
//                             whatsappNo: registerOrder.whatsAppMobileNo,
//                           ),
//                         ),
//                       );
//                       break;
//                   }
//                 },
//                 itemBuilder: (BuildContext context) => [
//                   PopupMenuItem<String>(
//                     value: 'whatsapp',
//                     child: Row(
//                       children: [
//                         const FaIcon(
//                           FontAwesomeIcons.whatsapp,
//                           size: 20,
//                           color: Colors.green,
//                         ),
//                         const SizedBox(width: 8),
//                         Text(
//                           'WhatsApp',
//                           style: GoogleFonts.poppins(fontSize: 14),
//                         ),
//                       ],
//                     ),
//                   ),
//                   PopupMenuItem<String>(
//                     value: 'download',
//                     child: Row(
//                       children: [
//                         const Icon(
//                           Icons.download,
//                           color: Colors.blue,
//                           size: 20,
//                         ),
//                         const SizedBox(width: 8),
//                         Text(
//                           'Download',
//                           style: GoogleFonts.poppins(fontSize: 14),
//                         ),
//                       ],
//                     ),
//                   ),
//                   PopupMenuItem<String>(
//                     value: 'view',
//                     child: Row(
//                       children: [
//                         const Icon(
//                           Icons.visibility,
//                           color: Colors.purple,
//                           size: 20,
//                         ),
//                         const SizedBox(width: 8),
//                         Text(
//                           'View',
//                           style: GoogleFonts.poppins(fontSize: 14),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           // Second Row: Order Number, City, and Delivery Type
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//                 decoration: BoxDecoration(
//                   color: AppColors.primaryColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: AppColors.primaryColor.withOpacity(0.5), width: 1), // Lighter border
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(
//                       Icons.receipt_long,
//                       size: 16,
//                       color: AppColors.primaryColor,
//                     ),
//                     const SizedBox(width: 6),
//                     Text(
//                       registerOrder.orderNo,
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.primaryColor,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//                 decoration: BoxDecoration(
//                   color: Colors.amber.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1), // Lighter border
//                 ),
//                 child: Text(
//                   registerOrder.city,
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.amber,
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//                 decoration: BoxDecoration(
//                   color: deliveryTextColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: deliveryBorderColor.withOpacity(0.5), width: 1), // Lighter border
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.local_shipping,
//                       size: 16,
//                       color: deliveryIconColor,
//                     ),
//                     const SizedBox(width: 6),
//                     Text(
//                       registerOrder.deliveryType,
//                       style: GoogleFonts.poppins(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: deliveryTextColor,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           // Table for Additional Details
//           Table(
//             columnWidths: const {
//               0: FlexColumnWidth(2),
//               1: FlexColumnWidth(3),
//             },
//             border: TableBorder(
//               horizontalInside: BorderSide(
//                 color: Colors.grey.shade200,
//                 width: 1,
//               ),
//               verticalInside: BorderSide(
//                 color: Colors.grey.shade200,
//                 width: 1,
//               ),
//             ),
//             children: [
//               TableRow(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
//                     child: Text(
//                       'Date:',
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
//                     child: Text(
//                       '${registerOrder.orderDate} ${registerOrder.createdTime}',
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.blue,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               TableRow(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
//                     child: Text(
//                       'Quantity:',
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
//                     child: Text(
//                       '${registerOrder.quantity}',
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.purple,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               TableRow(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
//                     child: Text(
//                       'Amount:',
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
//                     child: Text(
//                       '₹${registerOrder.amount.toStringAsFixed(2)}',
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.deepOrange,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               if (registerOrder.salesPersonName.isNotEmpty)
//                 TableRow(
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
//                       child: Text(
//                         'Salesperson:',
//                         style: GoogleFonts.poppins(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
//                       child: Text(
//                         registerOrder.salesPersonName,
//                         style: GoogleFonts.poppins(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black87,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//             ],
//           ),
//         ],
//       ),
//     ),
//   );
// }

//   Future<void> _selectDate(
//     BuildContext context,
//     TextEditingController controller,
//     DateTime? initialDate,
//   ) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: initialDate ?? DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) {
//       setState(() {
//         if (controller == fromDateController) {
//           fromDate = picked;
//           controller.text = DateFormat('yyyy-MM-dd').format(picked);
//         } else if (controller == toDateController) {
//           toDate = picked;
//           controller.text = DateFormat('yyyy-MM-dd').format(picked);
//         }
//       });
//       fetchOrders();
//     }
//   }

//   Widget _buildDateInput(
//     TextEditingController controller,
//     String label,
//     DateTime? date,
//   ) {
//     return TextField(
//       controller: controller,
//       readOnly: true,
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: const TextStyle(color: Color(0xFF87898A)),
//         floatingLabelStyle: TextStyle(color: AppColors.primaryColor),
//         hintStyle: const TextStyle(color: Color(0xFF87898A)),
//         suffixIcon: IconButton(
//           icon: Icon(Icons.calendar_today, color: AppColors.primaryColor),
//           onPressed: () => _selectDate(context, controller, date),
//         ),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: AppColors.secondaryColor),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: AppColors.primaryColor),
//         ),
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 12,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       drawer: DrawerScreen(),
//       appBar: AppBar(
//         title: Text('Order Register', style: TextStyle(color: AppColors.white)),
//         backgroundColor: AppColors.primaryColor,
//         elevation: 1,
//         leading: Builder(
//           builder:
//               (context) => IconButton(
//                 icon: Icon(Icons.menu, color: AppColors.white),
//                 onPressed: () => Scaffold.of(context).openDrawer(),
//               ),
//         ),

//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(20.0),
//           child: Column(
//             children: [
//               const Divider(),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   Text(
//                     'Total: ₹${_calculateTotalAmount().toStringAsFixed(2)}',
//                     style: GoogleFonts.roboto(color: Colors.white),
//                   ),
//                   const VerticalDivider(color: Colors.white),
//                   Text(
//                     'Total Orders: ${registerOrderList.length}',
//                     style: GoogleFonts.roboto(color: Colors.white),
//                   ),
//                   const VerticalDivider(color: Colors.white, thickness: 2),
//                   Text(
//                     'Total Qty: ${_calculateTotalQuantity()}',
//                     style: GoogleFonts.roboto(color: Colors.white),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//       body:
//           isLoading
//               ? Stack(
//                 children: [
//                   Container(color: Colors.black.withOpacity(0.2)),
//                   Center(
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(0),
//                         boxShadow: const [
//                           BoxShadow(
//                             color: Colors.black12,
//                             blurRadius: 8,
//                             offset: Offset(0, 3),
//                           ),
//                         ],
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const Text(
//                             'Loading...',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.black,
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(strokeWidth: 2.5),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               )
//               : SingleChildScrollView(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(height: 10),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _buildDateInput(
//                             fromDateController,
//                             'From Date',
//                             fromDate,
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: _buildDateInput(
//                             toDateController,
//                             'To Date',
//                             toDate,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     const Divider(),
//                     ...registerOrderList.map(
//                       (order) => Column(
//                         children: [buildOrderItem(order), const Divider()],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//       floatingActionButton: Padding(
//         padding: const EdgeInsets.only(bottom: 50),
//         child: FloatingActionButton(
//           backgroundColor: Colors.blue,
//           onPressed: () async {
//             await Navigator.push(
//               context,
//               PageRouteBuilder(
//                 pageBuilder:
//                     (
//                       context,
//                       animation,
//                       secondaryAnimation,
//                     ) => RegisterFilterPage(
//                       ledgerList: ledgerList,
//                       salespersonList: salespersonList,
//                       onApplyFilters: ({
//                         KeyName? selectedLedger,
//                         KeyName? selectedSalesperson,
//                         DateTime? fromDate,
//                         DateTime? toDate,
//                         DateTime? deliveryFromDate,
//                         DateTime? deliveryToDate,
//                         String? selectedOrderStatus,
//                         String? selectedDateRange,
//                       }) {
//                         debugPrint(
//                           'Selected Ledger: ${selectedLedger?.name ?? 'None'}',
//                         );
//                         debugPrint(
//                           'Selected Salesperson: ${selectedSalesperson?.name ?? 'None'}',
//                         );
//                         debugPrint(
//                           'From Date: ${fromDate != null ? DateFormat('dd-MM-yyyy').format(fromDate) : 'Not selected'}',
//                         );
//                         debugPrint(
//                           'To Date: ${toDate != null ? DateFormat('dd-MM-yyyy').format(toDate) : 'Not selected'}',
//                         );
//                         debugPrint(
//                           'Delivery From Date: ${deliveryFromDate != null ? DateFormat('dd-MM-yyyy').format(deliveryFromDate) : 'Not selected'}',
//                         );
//                         debugPrint(
//                           'Delivery To Date: ${deliveryToDate != null ? DateFormat('dd-MM-yyyy').format(deliveryToDate) : 'Not selected'}',
//                         );
//                         debugPrint(
//                           'Order Status: ${selectedOrderStatus ?? 'Not selected'}',
//                         );
//                         debugPrint(
//                           'Date Range: ${selectedDateRange ?? 'Not selected'}',
//                         );
//                         setState(() {
//                           this.selectedLedger = selectedLedger;
//                           this.selectedSalesperson = selectedSalesperson;
//                           this.fromDate = fromDate;
//                           this.toDate = toDate;
//                           this.deliveryFromDate = deliveryFromDate;
//                           this.deliveryToDate = deliveryToDate;
//                           this.selectedOrderStatus = selectedOrderStatus;
//                           //this.selectedDateRange = selectedDateRange;
//                         });
//                         fetchOrders();
//                       },
//                     ),
//                 settings: RouteSettings(
//                   arguments: {
//                     'ledgerList': ledgerList,
//                     'salespersonList': salespersonList,
//                     'selectedLedger': selectedLedger,
//                     'selectedSalesperson': selectedSalesperson,
//                     'fromDate': fromDate,
//                     'toDate': toDate,
//                     'deliveryFromDate': deliveryFromDate,
//                     'deliveryToDate': deliveryToDate,
//                     'selectedOrderStatus': selectedOrderStatus,
//                     //'selectedDateRange': selectedDateRange,
//                   },
//                 ),
//                 transitionDuration: const Duration(milliseconds: 500),
//                 transitionsBuilder: (
//                   context,
//                   animation,
//                   secondaryAnimation,
//                   child,
//                 ) {
//                   return ScaleTransition(
//                     scale: animation,
//                     alignment: Alignment.bottomRight,
//                     child: FadeTransition(opacity: animation, child: child),
//                   );
//                 },
//               ),
//             );
//           },

//           tooltip: 'Filter Orders',
//           child: const Icon(Icons.filter_list, color: Colors.white),
//         ),
//       ),
//     );
//   }
// }

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:marquee/marquee.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/models/registerModel.dart';
import 'package:vrs_erp/register/registerFilteration.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/viewOrder/Pdf_viewer_screen.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_barcode2.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_screen.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_screen_barcode.dart';
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/foundation.dart' show kIsWeb; // Detect Web
import 'package:flutter/material.dart';

// Web-specific (ignore in mobile)
import 'dart:html' as html; // For browser downloads

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool isLoading = false;
  List<RegisterOrder> registerOrderList = [];
  DateTime? fromDate;
  DateTime? toDate;
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  KeyName? selectedLedger;
  KeyName? selectedSalesperson;
  List<KeyName> ledgerList = [];
  List<KeyName> salespersonList = [];
  bool isLoadingLedgers = true;
  bool isLoadingSalesperson = true;
  Map<String, bool> checkedOrders = {};
  String? selectedOrderStatus;
  DateTime? deliveryFromDate;
  DateTime? deliveryToDate;

  @override
  void initState() {
    super.initState();
    fromDate = DateTime.now();
    toDate = DateTime.now();
    fromDateController.text = DateFormat('yyyy-MM-dd').format(fromDate!);
    toDateController.text = DateFormat('yyyy-MM-dd').format(toDate!);
    _loadDropdownData();
    fetchOrders();
  }

  Future<void> _loadDropdownData() async {
    setState(() {
      isLoadingLedgers = true;
      isLoadingSalesperson = true;
    });

    try {
      final fetchedLedgersResponse = await ApiService.fetchLedgers(
        ledCat: 'w',
        coBrId: UserSession.coBrId ?? '',
      );
      final fetchedSalespersonResponse = await ApiService.fetchLedgers(
        ledCat: 's',
        coBrId: UserSession.coBrId ?? '',
      );

      setState(() {
        ledgerList = List<KeyName>.from(fetchedLedgersResponse['result'] ?? []);
        salespersonList = List<KeyName>.from(
          fetchedSalespersonResponse['result'] ?? [],
        );
        isLoadingLedgers = false;
        isLoadingSalesperson = false;
      });
    } catch (e) {
      setState(() {
        isLoadingLedgers = false;
        isLoadingSalesperson = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching dropdown data: $e')),
      );
    }
  }

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true;
    });
    try {
      final orders = await ApiService.fetchOrderRegister(
        fromDate: fromDateController.text,
        toDate: toDateController.text,
        custKey:
            UserSession.userType == "C"
                ? UserSession.userLedKey
                : selectedLedger?.key,
        coBrId: UserSession.coBrId ?? '',
        salesPerson:
            UserSession.userType == "S"
                ? UserSession.userLedKey
                : selectedSalesperson?.key,
        status: selectedOrderStatus,
        dlvFromDate:
            deliveryFromDate == null ? null : deliveryFromDate.toString(),
        dlvToDate: deliveryToDate == null ? null : deliveryToDate.toString(),
        // userName: UserSession.userType == 'Admin'? '''',
        userName: null,
        lastSavedOrderId: null,
      );
      setState(() {
        registerOrderList = orders;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching orders: $e')));
    }
  }

  double _calculateTotalAmount() {
    return registerOrderList.fold(
      0.0,
      (sum, registerOrder) => sum + registerOrder.amount,
    );
  }

  int _calculateTotalQuantity() {
    return registerOrderList.fold(
      0,
      (sum, registerOrder) => sum + registerOrder.quantity,
    );
  }

  void _submitRegisterOrders() {
    // Handle register submission logic
  }

  Future<bool> _sendWhatsAppFile2({
    required List<int> fileBytes,
    required String mobileNo,
    required String fileType,
    String? caption,
  }) async {
    try {
      String fileBase64 = base64Encode(fileBytes);

      final response = await http.post(
        Uri.parse("http://node4.wabapi.com/v4/postfile.php"),
        body: {
          'data': fileBase64,
          'filename': fileType == 'image' ? 'catalog.jpg' : 'catalog.pdf',
          'key': AppConstants.whatsappKey,
          'number': '91$mobileNo',
          'caption': caption ?? 'Please find the file attached.',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error sending file: $e');
      return false;
    }
  }

  Widget buildOrderItem(RegisterOrder registerOrder) {
    // Initialize checkbox state for this order if not already set
    checkedOrders.putIfAbsent(registerOrder.orderNo, () => false);

    // Use fixed blue shades for delivery status to ensure non-nullable colors
    const Color deliveryIconColor = Colors.blue; // Base blue
    const Color deliveryTextColor = Colors.blue; // Base blue
    const Color deliveryBorderColor = Color.fromRGBO(
      144,
      202,
      249,
      1,
    ); // Blue[200]

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white, // White background for contrast
        border: const Border.fromBorderSide(
          BorderSide(
            color: Color.fromRGBO(227, 242, 253, 1), // Blue[50]
            width: 1,
          ),
        ),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First Row: Item Name and Popup Menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 24,
                    child: Tooltip(
                      message: registerOrder.itemName,
                      triggerMode: TooltipTriggerMode.tap, // show on tap
                      showDuration: const Duration(seconds: 2),
                      waitDuration: Duration.zero, // no delay
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.9),
                        borderRadius: BorderRadius.zero, // removes curve
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        registerOrder.itemName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.lora(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromRGBO(21, 101, 192, 1),
                        ),
                      ),
                    ),
                  ),
                ),

                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.blue),
                  onSelected: (value) async {
                    switch (value) {
                      case 'whatsapp':
                        showDialog(
                          context: context,
                          builder: (context) {
                            final TextEditingController controller =
                                TextEditingController(
                                  text: registerOrder.whatsAppMobileNo ?? '',
                                );
                            return AlertDialog(
                              title: const Text('Enter WhatsApp Number'),
                              content: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                maxLength: 10,
                                decoration: const InputDecoration(
                                  hintText: 'Enter 10-digit number',
                                  counterText: '',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppColors.primaryColor, // Blue[700]
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    String number = controller.text.trim();
                                    if (number.length != 10 ||
                                        !RegExp(
                                          r'^[0-9]{10}$',
                                        ).hasMatch(number)) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please enter a valid 10-digit number',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    Navigator.pop(context);
                                    String docId = registerOrder.orderId;

                                    try {
                                      final dio = Dio();
                                      final response = await dio.post(
                                        '${AppConstants.Pdf_url}/api/values/order2',
                                        data: {"doc_id": docId},
                                        options: Options(
                                          responseType: ResponseType.bytes,
                                        ),
                                      );

                                      bool sent = await _sendWhatsAppFile2(
                                        fileBytes: response.data,
                                        mobileNo: number,
                                        fileType: 'pdf',
                                        caption: 'Order PDF',
                                      );

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            sent
                                                ? 'Sent on WhatsApp'
                                                : 'Failed to send',
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      print('Error: $e');
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Failed to download or send',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Send'),
                                ),
                              ],
                            );
                          },
                        );
                        break;

                      case 'download':
                        try {
                          /* ======================= PERMISSIONS ======================= */
                          if (!kIsWeb && Platform.isAndroid) {
                            var status = await Permission.storage.status;
                            if (!status.isGranted) {
                              status = await Permission.storage.request();
                              if (!status.isGranted) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Storage permission denied',
                                      ),
                                    ),
                                  );
                                }
                                debugPrint('Storage permission denied');
                                break;
                              }
                            }
                          }

                          /* ======================= SHOW LOADING ======================= */
                          if (mounted) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder:
                                  (context) => AlertDialog(
                                    content: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        CircularProgressIndicator(
                                          color: Colors.blue,
                                        ),
                                        SizedBox(width: 16),
                                        Text('Downloading...'),
                                      ],
                                    ),
                                  ),
                            );
                          }

                          /* ======================= FETCH PDF ======================= */
                          final dio = Dio();
                          final response = await dio.post(
                            '${AppConstants.Pdf_url}/api/values/order2',
                            data: {"doc_id": registerOrder.orderId},
                            options: Options(responseType: ResponseType.bytes),
                          );

                          debugPrint(
                            'API response status: ${response.statusCode}',
                          );

                          if (response.statusCode == 200) {
                            final fileName =
                                'Order_${registerOrder.orderId}.pdf';

                            /* ======================= WEB ======================= */
                            if (kIsWeb) {
                              final blob = html.Blob([
                                response.data,
                              ], 'application/pdf');
                              final url = html.Url.createObjectUrlFromBlob(
                                blob,
                              );

                              final anchor =
                                  html.AnchorElement(href: url)
                                    ..setAttribute('download', fileName)
                                    ..click();

                              html.Url.revokeObjectUrl(url);

                              if (mounted) {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'PDF downloaded as $fileName',
                                    ),
                                  ),
                                );
                              }
                            }
                            /* ======================= MOBILE ======================= */
                            else {
                              Directory? directory;
                              String filePath;

                              if (Platform.isAndroid) {
                                directory = Directory(
                                  '/storage/emulated/0/Download',
                                );
                                if (!await directory.exists()) {
                                  await directory.create(recursive: true);
                                }
                                filePath = '${directory.path}/$fileName';
                              } else if (Platform.isIOS) {
                                directory =
                                    await getApplicationDocumentsDirectory();
                                filePath = '${directory.path}/$fileName';
                              } else {
                                throw Exception('Unsupported platform');
                              }

                              final file = File(filePath);
                              await file.writeAsBytes(
                                response.data,
                                flush: true,
                              );

                              debugPrint(
                                'PDF downloaded to: $filePath, exists: ${await file.exists()}',
                              );

                              if (mounted) {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'PDF downloaded to $filePath',
                                    ),
                                    action: SnackBarAction(
                                      label: 'Open',
                                      textColor: Colors.blue,
                                      onPressed: () async {
                                        final result = await OpenFile.open(
                                          filePath,
                                        );
                                        debugPrint(
                                          'OpenFile result: ${result.type}, message: ${result.message}',
                                        );
                                        if (result.type != ResultType.done &&
                                            mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to open PDF: ${result.message}',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }
                            }
                          } else {
                            if (mounted) {
                              Navigator.of(context, rootNavigator: true).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to load PDF: ${response.statusCode}',
                                  ),
                                ),
                              );
                            }
                            debugPrint(
                              'Failed to load PDF: ${response.statusCode}',
                            );
                          }
                        } catch (e) {
                          debugPrint('Download error: $e');
                          if (mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Download failed: $e')),
                            );
                          }
                        }
                        break;

                      case 'view':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PdfViewerScreen(
                                  rptName: 'SalesOrder',
                                  orderNo: registerOrder.orderId,
                                  whatsappNo: registerOrder.whatsAppMobileNo,
                                  partyName:
                                      registerOrder
                                          .partyName, // Use partyLedKey from RegisterOrder
                                  orderDate: registerOrder.orderDate,
                                ),
                          ),
                        );
                        break;
                      case 'editBarcode':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => EditOrderBarcode2(
                                  docId: registerOrder.orderId,
                                ),
                            // builder: (context) => EditOrderScreen(docId: registerOrder.orderId),
                          ),
                        );
                        break;
                      case 'edit2':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            // builder: (context) => EditOrderScreenBarcode(docId: registerOrder.orderId),
                            builder:
                                (context) => EditOrderScreen(
                                  docId: registerOrder.orderId,
                                ),
                          ),
                        );
                        break;
                    }
                  },
                  itemBuilder:
                      (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'whatsapp',
                          child: Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.whatsapp,
                                size: 20,
                                color: Colors.blue, // Non-nullable
                              ),
                              SizedBox(width: 8),
                              Text('WhatsApp', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'download',
                          child: Row(
                            children: [
                              Icon(
                                Icons.download,
                                color: Colors.blue, // Non-nullable
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text('Download', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(
                                Icons.visibility,
                                color: Colors.blue, // Non-nullable
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text('View', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'editBarcode',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit,
                                color: Colors.blue, // Non-nullable
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Edit Barcode',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'edit2',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit,
                                color: Colors.blue, // Non-nullable
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text('Edit ', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Second Row: Order Number, City, and Delivery Type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Order Number Container
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(227, 242, 253, 1),
                      borderRadius: BorderRadius.circular(4),
                      border: const Border.fromBorderSide(
                        BorderSide(
                          color: Color.fromRGBO(144, 202, 249, 1),
                          width: 1,
                        ),
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 60,
                    ), // Minimum width
                    child: _buildScaledRow(
                      icon: Icons.receipt_long,
                      text: registerOrder.orderNo,
                      iconColor: Colors.blue,
                      textColor: const Color.fromRGBO(21, 101, 192, 1),
                    ),
                  ),
                ),

                // City Container
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(227, 242, 253, 1),
                      borderRadius: BorderRadius.circular(4),
                      border: const Border.fromBorderSide(
                        BorderSide(
                          color: Color.fromRGBO(144, 202, 249, 1),
                          width: 1,
                        ),
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 60,
                    ), // Minimum width
                    child: _buildScaledText(
                      text: registerOrder.city,
                      textColor: const Color.fromRGBO(21, 101, 192, 1),
                    ),
                  ),
                ),

                // Delivery Type Container
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: deliveryTextColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.fromBorderSide(
                        BorderSide(color: deliveryBorderColor, width: 1),
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 80,
                    ), // Wider minimum
                    child: _buildScaledRow(
                      icon: Icons.local_shipping,
                      text: registerOrder.deliveryType,
                      iconColor: deliveryIconColor,
                      textColor: deliveryTextColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            // Table for Additional Details
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
              },
              border: TableBorder(
                horizontalInside: const BorderSide(
                  color: Color.fromRGBO(227, 242, 253, 1), // Blue[50]
                  width: 1,
                ),
                verticalInside: const BorderSide(
                  color: Color.fromRGBO(227, 242, 253, 1), // Blue[50]
                  width: 1,
                ),
              ),
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: Text(
                        'Date:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: Text(
                        '${registerOrder.orderDate} ',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromRGBO(
                            21,
                            101,
                            192,
                            1,
                          ), // Blue[900]
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: Text(
                        'Quantity:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: Text(
                        '${registerOrder.quantity}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromRGBO(
                            21,
                            101,
                            192,
                            1,
                          ), // Blue[900]
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: Text(
                        'Amount:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: Text(
                        '₹${registerOrder.amount.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromRGBO(
                            21,
                            101,
                            192,
                            1,
                          ), // Blue[900]
                        ),
                      ),
                    ),
                  ],
                ),
                if (registerOrder.salesPersonName.isNotEmpty)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        child: Text(
                          'Salesperson:',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        child: Text(
                          registerOrder.salesPersonName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color.fromRGBO(
                              21,
                              101,
                              192,
                              1,
                            ), // Blue[900]
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScaledRow({
    required IconData icon,
    required String text,
    required Color iconColor,
    required Color textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Flexible(child: _buildScaledText(text: text, textColor: textColor)),
      ],
    );
  }

  // Helper method for auto-scaling text
  Widget _buildScaledText({required String text, required Color textColor}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: GoogleFonts.lora(
          fontSize: 14, // Base size
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDateInput(
    TextEditingController controller,
    String label,
    DateTime? date,
  ) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blue),
        floatingLabelStyle: const TextStyle(
          color: Color.fromRGBO(21, 101, 192, 1),
        ), // Blue[900]
        hintStyle: const TextStyle(color: Colors.blue),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today, color: Colors.blue),
          onPressed: () => _selectDate(context, controller, date),
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(
            color: Color.fromRGBO(144, 202, 249, 1),
          ), // Blue[200]
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(
            color: Color.fromRGBO(21, 101, 192, 1),
          ), // Blue[900]
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: DrawerScreen(),
      appBar: AppBar(
        title: const Text(
          'Order Register',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor, // Blue[700]
        elevation: 1,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Column(
            children: [
              const Divider(
                color: Color.fromRGBO(144, 202, 249, 1),
              ), // Blue[200]
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'Total: ₹${_calculateTotalAmount().toStringAsFixed(2)}',
                    style: GoogleFonts.roboto(color: Colors.white),
                  ),
                  const VerticalDivider(
                    color: Color.fromRGBO(144, 202, 249, 1),
                  ), // Blue[200]
                  Text(
                    'Total Orders: ${registerOrderList.length}',
                    style: GoogleFonts.roboto(color: Colors.white),
                  ),
                  const VerticalDivider(
                    color: Color.fromRGBO(144, 202, 249, 1), // Blue[200]
                    thickness: 2,
                  ),
                  Text(
                    'Total Qty: ${_calculateTotalQuantity()}',
                    style: GoogleFonts.roboto(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body:
          isLoading
              ? Stack(
                children: [
                  Container(color: Colors.black.withOpacity(0.2)),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        // boxShadow: const [
                        //   BoxShadow(
                        //     color: Colors.black12,
                        //     blurRadius: 8,
                        //     offset: Offset(0, 3),
                        //   ),
                        // ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateInput(
                            fromDateController,
                            'From Date',
                            fromDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDateInput(
                            toDateController,
                            'To Date',
                            toDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(
                      color: Color.fromRGBO(144, 202, 249, 1),
                    ), // Blue[200]
                    ...registerOrderList.map(
                      (order) => Column(
                        children: [
                          buildOrderItem(order),
                          const Divider(
                            color: Color.fromRGBO(
                              144,
                              202,
                              249,
                              1,
                            ), // Blue[200]
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: FloatingActionButton(
          backgroundColor: AppColors.primaryColor, // Blue[700]
          onPressed: () async {
            await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (
                      context,
                      animation,
                      secondaryAnimation,
                    ) => RegisterFilterPage(
                      ledgerList: ledgerList,
                      salespersonList: salespersonList,
                      onApplyFilters: ({
                        KeyName? selectedLedger,
                        KeyName? selectedSalesperson,
                        DateTime? fromDate,
                        DateTime? toDate,
                        DateTime? deliveryFromDate,
                        DateTime? deliveryToDate,
                        String? selectedOrderStatus,
                        String? selectedDateRange,
                      }) {
                        debugPrint(
                          'Selected Ledger: ${selectedLedger?.name ?? 'None'}',
                        );
                        debugPrint(
                          'Selected Salesperson: ${selectedSalesperson?.name ?? 'None'}',
                        );
                        debugPrint(
                          'From Date: ${fromDate != null ? DateFormat('dd-MM-yyyy').format(fromDate) : 'Not selected'}',
                        );
                        debugPrint(
                          'To Date: ${toDate != null ? DateFormat('dd-MM-yyyy').format(toDate) : 'Not selected'}',
                        );
                        debugPrint(
                          'Delivery From Date: ${deliveryFromDate != null ? DateFormat('dd-MM-yyyy').format(deliveryFromDate) : 'Not selected'}',
                        );
                        debugPrint(
                          'Delivery To Date: ${deliveryToDate != null ? DateFormat('dd-MM-yyyy').format(deliveryToDate) : 'Not selected'}',
                        );
                        debugPrint(
                          'Order Status: ${selectedOrderStatus ?? 'Not selected'}',
                        );
                        debugPrint(
                          'Date Range: ${selectedDateRange ?? 'Not selected'}',
                        );
                        setState(() {
                          this.selectedLedger = selectedLedger;
                          this.selectedSalesperson = selectedSalesperson;
                          this.fromDate = fromDate;
                          this.toDate = toDate;
                          this.deliveryFromDate = deliveryFromDate;
                          this.deliveryToDate = deliveryToDate;
                          this.selectedOrderStatus = selectedOrderStatus;
                        });
                        fetchOrders();
                      },
                    ),
                settings: RouteSettings(
                  arguments: {
                    'ledgerList': ledgerList,
                    'salespersonList': salespersonList,
                    'selectedLedger': selectedLedger,
                    'selectedSalesperson': selectedSalesperson,
                    'fromDate': fromDate,
                    'toDate': toDate,
                    'deliveryFromDate': deliveryFromDate,
                    'deliveryToDate': deliveryToDate,
                    'selectedOrderStatus': selectedOrderStatus,
                  },
                ),
                transitionDuration: const Duration(milliseconds: 500),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return ScaleTransition(
                    scale: animation,
                    alignment: Alignment.bottomRight,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
              ),
            );
          },
          tooltip: 'Filter Orders',
          child: const Icon(Icons.filter_list, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
    DateTime? initialDate,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (controller == fromDateController) {
          fromDate = picked;
          controller.text = DateFormat('yyyy-MM-dd').format(picked);
        } else if (controller == toDateController) {
          toDate = picked;
          controller.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
      fetchOrders();
    }
  }
}
