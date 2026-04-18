// import 'dart:convert';
// import 'dart:io';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:vrs_erp/models/brand.dart';
// import 'package:vrs_erp/models/catalog.dart';
// import 'package:vrs_erp/models/category.dart';
// import 'package:vrs_erp/models/item.dart';
// import 'package:vrs_erp/models/keyName.dart';
// import 'package:vrs_erp/models/registerModel.dart';
// import 'package:vrs_erp/models/shade.dart';
// import 'package:vrs_erp/models/size.dart';
// import 'package:vrs_erp/models/stockReportModel.dart';
// import 'package:vrs_erp/models/style.dart';
// import 'package:vrs_erp/register/registerFilteration.dart';
// import 'package:vrs_erp/screens/drawer_screen.dart';
// import 'package:vrs_erp/services/app_services.dart';
// import 'package:vrs_erp/viewOrder/Pdf_viewer_screen.dart';
// import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_barcode2.dart';
// import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_screen.dart';
// import '../constants/app_constants.dart';
// import '../models/consignee.dart';

// class PackingPage extends StatefulWidget {
//   @override
//   _PackingPageState createState() => _PackingPageState();
// }

// class _PackingPageState extends State<PackingPage> {
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
//   int pageNo = 1;
//   int pageSize = 20;
//   bool hasMoreData = true;
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     fromDate = DateTime.now();
//     toDate = DateTime.now();
//     fromDateController.text = DateFormat('yyyy-MM-dd').format(fromDate!);
//     toDateController.text = DateFormat('yyyy-MM-dd').format(toDate!);
//     _loadDropdownData();
//     fetchOrders(isLoadMore: false);

//     // Add scroll listener for infinite scroll
//     _scrollController.addListener(() {
//       if (_scrollController.position.pixels >=
//               _scrollController.position.maxScrollExtent - 200 &&
//           !isLoading &&
//           hasMoreData) {
//         fetchOrders(isLoadMore: true);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     fromDateController.dispose();
//     toDateController.dispose();
//     super.dispose();
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

//   Future<void> fetchOrders({required bool isLoadMore}) async {
//     if (!isLoadMore) {
//       setState(() {
//         pageNo = 1;
//         registerOrderList.clear();
//         hasMoreData = true;
//       });
//     }

//     if (!hasMoreData || isLoading) return;

//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final orders = await ApiService.fetchPackingRegister(
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
//         userName: null,
//         lastSavedOrderId: null,
//         pageNo: pageNo,
//         pageSize: pageSize,
//       );

//       setState(() {
//         if (isLoadMore) {
//           registerOrderList.addAll(orders);
//         } else {
//           registerOrderList = orders;
//         }
//         hasMoreData = orders.length == pageSize;
//         pageNo++;
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

//   Widget buildOrderItem(RegisterOrder registerOrder) {
//     checkedOrders.putIfAbsent(registerOrder.orderNo, () => false);

//     const Color deliveryIconColor = Colors.blue;
//     const Color deliveryTextColor = Colors.blue;
//     const Color deliveryBorderColor = Color.fromRGBO(144, 202, 249, 1);

//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: const Border.fromBorderSide(
//           BorderSide(color: Color.fromRGBO(227, 242, 253, 1), width: 1),
//         ),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: SizedBox(
//                     height: 24,
//                     child: Tooltip(
//                       message: registerOrder.itemName,
//                       triggerMode: TooltipTriggerMode.tap,
//                       showDuration: const Duration(seconds: 2),
//                       waitDuration: Duration.zero,
//                       decoration: BoxDecoration(
//                         color: Colors.black.withOpacity(0.9),
//                         borderRadius: BorderRadius.zero,
//                       ),
//                       textStyle: GoogleFonts.poppins(
//                         fontSize: 14,
//                         color: Colors.white,
//                       ),
//                       child: Text(
//                         registerOrder.itemName,
//                         overflow: TextOverflow.ellipsis,
//                         maxLines: 1,
//                         style: GoogleFonts.lora(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                           color: const Color.fromRGBO(21, 101, 192, 1),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 PopupMenuButton<String>(
//                   icon: const Icon(Icons.more_vert, color: Colors.blue),
//                   onSelected: (value) async {
//                     switch (value) {
//                       case 'whatsapp':
//                         showDialog(
//                           context: context,
//                           builder: (context) {
//                             final TextEditingController controller =
//                                 TextEditingController(
//                                   text: registerOrder.whatsAppMobileNo ?? '',
//                                 );
//                             return AlertDialog(
//                               title: const Text('Enter WhatsApp Number'),
//                               content: TextField(
//                                 controller: controller,
//                                 keyboardType: TextInputType.number,
//                                 maxLength: 10,
//                                 decoration: const InputDecoration(
//                                   hintText: 'Enter 10-digit number',
//                                   counterText: '',
//                                 ),
//                               ),
//                               actions: [
//                                 TextButton(
//                                   onPressed: () => Navigator.pop(context),
//                                   child: const Text('Cancel'),
//                                 ),
//                                 ElevatedButton(
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: AppColors.primaryColor,
//                                     foregroundColor: Colors.white,
//                                   ),
//                                   onPressed: () async {
//                                     String number = controller.text.trim();
//                                     if (number.length != 10 ||
//                                         !RegExp(
//                                           r'^[0-9]{10}$',
//                                         ).hasMatch(number)) {
//                                       ScaffoldMessenger.of(
//                                         context,
//                                       ).showSnackBar(
//                                         const SnackBar(
//                                           content: Text(
//                                             'Please enter a valid 10-digit number',
//                                           ),
//                                         ),
//                                       );
//                                       return;
//                                     }

//                                     Navigator.pop(context);
//                                     String docId = registerOrder.orderId;

//                                     try {
//                                       final dio = Dio();
//                                       final response = await dio.post(
//                                         // '${AppConstants.Pdf_url}/api/values5',
//                                         '${AppConstants.Pdf_url}',
//                                         data: {
//                                           "doc_id": docId,
//                                           "rptName": 'Packing',
//                                           "dbName": UserSession.dbName,
//                                           "dbUser": UserSession.dbUser,
//                                           "dbPassword": UserSession.dbPassword,
//                                           "dbServer":
//                                               UserSession.dbSourceForRpt,
//                                           "rptPath": UserSession.rptPath,
//                                         },
//                                         options: Options(
//                                           responseType: ResponseType.bytes,
//                                         ),
//                                       );

//                                       bool sent = await _sendWhatsAppFile2(
//                                         fileBytes: response.data,
//                                         mobileNo: number,
//                                         fileType: 'pdf',
//                                         caption: 'Order PDF',
//                                       );

//                                       ScaffoldMessenger.of(
//                                         context,
//                                       ).showSnackBar(
//                                         SnackBar(
//                                           content: Text(
//                                             sent
//                                                 ? 'Sent on WhatsApp'
//                                                 : 'Failed to send',
//                                           ),
//                                         ),
//                                       );
//                                     } catch (e) {
//                                       print('Error: $e');
//                                       ScaffoldMessenger.of(
//                                         context,
//                                       ).showSnackBar(
//                                         const SnackBar(
//                                           content: Text(
//                                             'Failed to download or send',
//                                           ),
//                                         ),
//                                       );
//                                     }
//                                   },
//                                   child: const Text('Send'),
//                                 ),
//                               ],
//                             );
//                           },
//                         );
//                         break;

//                       case 'download':
//                         try {
//                           if (Platform.isAndroid) {
//                             var status = await Permission.storage.status;
//                             if (!status.isGranted) {
//                               status = await Permission.storage.request();
//                               if (!status.isGranted) {
//                                 if (mounted) {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(
//                                       content: Text(
//                                         'Storage permission denied',
//                                       ),
//                                     ),
//                                   );
//                                 }
//                                 debugPrint('Storage permission denied');
//                                 break;
//                               }
//                             }
//                           }

//                           showDialog(
//                             context: context,
//                             barrierDismissible: false,
//                             builder:
//                                 (context) => AlertDialog(
//                                   content: Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       const CircularProgressIndicator(
//                                         color: Colors.blue,
//                                       ),
//                                       const SizedBox(width: 16),
//                                       const Text('Downloading...'),
//                                     ],
//                                   ),
//                                 ),
//                           );

//                           final dio = Dio();
//                           final response = await dio.post(
//                             // '${AppConstants.Pdf_url}/api/values/order5',
//                             '${AppConstants.Pdf_url}',
//                             data: {
//                               "doc_id": registerOrder.orderId,
//                               "rptName": 'Packing',
//                               "dbName": UserSession.dbName,
//                               "dbUser": UserSession.dbUser,
//                               "dbPassword": UserSession.dbPassword,
//                               "dbServer": UserSession.dbSourceForRpt,
//                               "rptPath": UserSession.rptPath,
//                             },
//                             options: Options(responseType: ResponseType.bytes),
//                           );

//                           debugPrint(
//                             'API response status: ${response.statusCode}',
//                           );

//                           if (response.statusCode == 200) {
//                             Directory? directory;
//                             String filePath;
//                             if (Platform.isAndroid) {
//                               directory = Directory(
//                                 '/storage/emulated/0/Download',
//                               );
//                               if (!await directory.exists()) {
//                                 await directory.create(recursive: true);
//                               }
//                               filePath =
//                                   '${directory.path}/Order_${registerOrder.orderId}.pdf';
//                             } else if (Platform.isIOS) {
//                               directory =
//                                   await getApplicationDocumentsDirectory();
//                               filePath =
//                                   '${directory.path}/Order_${registerOrder.orderId}.pdf';
//                             } else {
//                               throw Exception('Unsupported platform');
//                             }

//                             final file = File(filePath);
//                             await file.writeAsBytes(response.data, flush: true);
//                             debugPrint(
//                               'PDF downloaded to: $filePath, exists: ${await file.exists()}',
//                             );

//                             if (mounted) {
//                               Navigator.of(context, rootNavigator: true).pop();
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(
//                                   content: Text('PDF downloaded to $filePath'),
//                                   action: SnackBarAction(
//                                     label: 'Open',
//                                     textColor: Colors.blue,
//                                     onPressed: () async {
//                                       final result = await OpenFile.open(
//                                         filePath,
//                                       );
//                                       debugPrint(
//                                         'OpenFile result: ${result.type}, message: ${result.message}',
//                                       );
//                                       if (result.type != ResultType.done &&
//                                           mounted) {
//                                         ScaffoldMessenger.of(
//                                           context,
//                                         ).showSnackBar(
//                                           SnackBar(
//                                             content: Text(
//                                               'Failed to open PDF: ${result.message}',
//                                             ),
//                                           ),
//                                         );
//                                       }
//                                     },
//                                   ),
//                                 ),
//                               );
//                             }
//                           } else {
//                             if (mounted) {
//                               Navigator.of(context, rootNavigator: true).pop();
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(
//                                   content: Text(
//                                     'Failed to load PDF: ${response.statusCode}',
//                                   ),
//                                 ),
//                               );
//                             }
//                             debugPrint(
//                               'Failed to load PDF: ${response.statusCode}',
//                             );
//                           }
//                         } catch (e) {
//                           debugPrint('Download error: $e');
//                           if (mounted) {
//                             Navigator.of(context, rootNavigator: true).pop();
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(content: Text('Download failed: $e')),
//                             );
//                           }
//                         }
//                         break;

//                       case 'view':
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder:
//                                 (context) => PdfViewerScreen(
//                                   rptName: 'Packing',
//                                   orderNo: registerOrder.orderId,
//                                   whatsappNo: registerOrder.whatsAppMobileNo,
//                                   partyName: registerOrder.partyName,
//                                   orderDate: registerOrder.orderDate,
//                                 ),
//                           ),
//                         );
//                         break;
//                       case 'editBarcode':
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder:
//                                 (context) => EditOrderBarcode2(
//                                   docId: registerOrder.orderId,
//                                 ),
//                           ),
//                         );
//                         break;
//                       case 'edit2':
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder:
//                                 (context) => EditOrderScreen(
//                                   docId: registerOrder.orderId,
//                                 ),
//                           ),
//                         );
//                         break;
//                     }
//                   },
//                   itemBuilder:
//                       (BuildContext context) => [
//                         const PopupMenuItem<String>(
//                           value: 'whatsapp',
//                           child: Row(
//                             children: [
//                               FaIcon(
//                                 FontAwesomeIcons.whatsapp,
//                                 size: 20,
//                                 color: Colors.blue,
//                               ),
//                               SizedBox(width: 8),
//                               Text('WhatsApp', style: TextStyle(fontSize: 14)),
//                             ],
//                           ),
//                         ),
//                         const PopupMenuItem<String>(
//                           value: 'download',
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.download,
//                                 color: Colors.blue,
//                                 size: 20,
//                               ),
//                               SizedBox(width: 8),
//                               Text('Download', style: TextStyle(fontSize: 14)),
//                             ],
//                           ),
//                         ),
//                         const PopupMenuItem<String>(
//                           value: 'view',
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.visibility,
//                                 color: Colors.blue,
//                                 size: 20,
//                               ),
//                               SizedBox(width: 8),
//                               Text('View', style: TextStyle(fontSize: 14)),
//                             ],
//                           ),
//                         ),
//                         const PopupMenuItem<String>(
//                           value: 'editBarcode',
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.edit,
//                                 color: Colors.blue,
//                                 size: 20,
//                               ),
//                               SizedBox(width: 8),
//                               Text('Edit Barcode', style: TextStyle(fontSize: 14)),
//                             ],
//                           ),
//                         ),
//                         const PopupMenuItem<String>(
//                           value: 'edit2',
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.edit,
//                                 color: Colors.blue,
//                                 size: 20,
//                               ),
//                               SizedBox(width: 8),
//                               Text('Edit', style: TextStyle(fontSize: 14)),
//                             ],
//                           ),
//                         ),
//                       ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Flexible(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8.0,
//                       vertical: 4.0,
//                     ),
//                     decoration: BoxDecoration(
//                       color: const Color.fromRGBO(227, 242, 253, 1),
//                       borderRadius: BorderRadius.circular(4),
//                       border: const Border.fromBorderSide(
//                         BorderSide(
//                           color: Color.fromRGBO(144, 202, 249, 1),
//                           width: 1,
//                         ),
//                       ),
//                     ),
//                     constraints: const BoxConstraints(minWidth: 60),
//                     child: _buildScaledRow(
//                       icon: Icons.receipt_long,
//                       text: registerOrder.orderNo,
//                       iconColor: Colors.blue,
//                       textColor: const Color.fromRGBO(21, 101, 192, 1),
//                     ),
//                   ),
//                 ),
//                 Flexible(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8.0,
//                       vertical: 4.0,
//                     ),
//                     decoration: BoxDecoration(
//                       color: const Color.fromRGBO(227, 242, 253, 1),
//                       borderRadius: BorderRadius.circular(4),
//                       border: const Border.fromBorderSide(
//                         BorderSide(
//                           color: Color.fromRGBO(144, 202, 249, 1),
//                           width: 1,
//                         ),
//                       ),
//                     ),
//                     constraints: const BoxConstraints(minWidth: 60),
//                     child: _buildScaledText(
//                       text: registerOrder.city,
//                       textColor: const Color.fromRGBO(21, 101, 192, 1),
//                     ),
//                   ),
//                 ),
//                 Flexible(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8.0,
//                       vertical: 4.0,
//                     ),
//                     decoration: BoxDecoration(
//                       color: deliveryTextColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(4),
//                       border: Border.fromBorderSide(
//                         BorderSide(color: deliveryBorderColor, width: 1),
//                       ),
//                     ),
//                     constraints: const BoxConstraints(minWidth: 80),
//                     child: _buildScaledRow(
//                       icon: Icons.local_shipping,
//                       text: registerOrder.deliveryType,
//                       iconColor: deliveryIconColor,
//                       textColor: deliveryTextColor,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Table(
//               columnWidths: const {
//                 0: FlexColumnWidth(2),
//                 1: FlexColumnWidth(3),
//               },
//               border: TableBorder(
//                 horizontalInside: const BorderSide(
//                   color: Color.fromRGBO(227, 242, 253, 1),
//                   width: 1,
//                 ),
//                 verticalInside: const BorderSide(
//                   color: Color.fromRGBO(227, 242, 253, 1),
//                   width: 1,
//                 ),
//               ),
//               children: [
//                 TableRow(
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                         vertical: 6,
//                         horizontal: 8,
//                       ),
//                       child: Text(
//                         'Date:',
//                         style: GoogleFonts.poppins(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                         vertical: 6,
//                         horizontal: 8,
//                       ),
//                       child: Text(
//                         '${registerOrder.orderDate}',
//                         style: GoogleFonts.poppins(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: const Color.fromRGBO(21, 101, 192, 1),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 TableRow(
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                         vertical: 6,
//                         horizontal: 8,
//                       ),
//                       child: Text(
//                         'Quantity:',
//                         style: GoogleFonts.poppins(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                         vertical: 6,
//                         horizontal: 8,
//                       ),
//                       child: Text(
//                         '${registerOrder.quantity}',
//                         style: GoogleFonts.poppins(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: const Color.fromRGBO(21, 101, 192, 1),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 TableRow(
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                         vertical: 6,
//                         horizontal: 8,
//                       ),
//                       child: Text(
//                         'Amount:',
//                         style: GoogleFonts.poppins(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                         vertical: 6,
//                         horizontal: 8,
//                       ),
//                       child: Text(
//                         '₹${registerOrder.amount.toStringAsFixed(2)}',
//                         style: GoogleFonts.poppins(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: const Color.fromRGBO(21, 101, 192, 1),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 if (registerOrder.salesPersonName.isNotEmpty)
//                   TableRow(
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.symmetric(
//                           vertical: 6,
//                           horizontal: 8,
//                         ),
//                         child: Text(
//                           'Salesperson:',
//                           style: GoogleFonts.poppins(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.grey.shade600,
//                           ),
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(
//                           vertical: 6,
//                           horizontal: 8,
//                         ),
//                         child: Text(
//                           registerOrder.salesPersonName,
//                           style: GoogleFonts.poppins(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: const Color.fromRGBO(21, 101, 192, 1),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildScaledRow({
//     required IconData icon,
//     required String text,
//     required Color iconColor,
//     required Color textColor,
//   }) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(icon, size: 16, color: iconColor),
//         const SizedBox(width: 6),
//         Flexible(child: _buildScaledText(text: text, textColor: textColor)),
//       ],
//     );
//   }

//   Widget _buildScaledText({required String text, required Color textColor}) {
//     return FittedBox(
//       fit: BoxFit.scaleDown,
//       child: Text(
//         text,
//         style: GoogleFonts.lora(
//           fontSize: 14,
//           fontWeight: FontWeight.w600,
//           color: textColor,
//         ),
//         maxLines: 1,
//         overflow: TextOverflow.ellipsis,
//       ),
//     );
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
//         labelStyle: const TextStyle(color: Colors.blue),
//         floatingLabelStyle: const TextStyle(
//           color: Color.fromRGBO(21, 101, 192, 1),
//         ),
//         hintStyle: const TextStyle(color: Colors.blue),
//         suffixIcon: IconButton(
//           icon: const Icon(Icons.calendar_today, color: Colors.blue),
//           onPressed: () => _selectDate(context, controller, date),
//         ),
//         border: const OutlineInputBorder(
//           borderRadius: BorderRadius.all(Radius.circular(4)),
//           borderSide: BorderSide(color: Color.fromRGBO(144, 202, 249, 1)),
//         ),
//         focusedBorder: const OutlineInputBorder(
//           borderRadius: BorderRadius.all(Radius.circular(4)),
//           borderSide: BorderSide(color: Color.fromRGBO(21, 101, 192, 1)),
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
//         title: const Text(
//           'Packing Register',
//           style: TextStyle(color: Colors.white),
//         ),
//         backgroundColor: AppColors.primaryColor,
//         elevation: 1,
//         leading: Builder(
//           builder:
//               (context) => IconButton(
//                 icon: const Icon(Icons.menu, color: Colors.white),
//                 onPressed: () => Scaffold.of(context).openDrawer(),
//               ),
//         ),
//         // bottom: PreferredSize(
//         //   preferredSize: const Size.fromHeight(20.0),
//         //   child: Column(
//         //     children: [
//         //       const Divider(color: Color.fromRGBO(144, 202, 249, 1)),
//         //       Row(
//         //         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         //         children: [
//         //           Text(
//         //             'Total: ₹${_calculateTotalAmount().toStringAsFixed(2)}',
//         //             style: GoogleFonts.roboto(color: Colors.white),
//         //           ),
//         //           const VerticalDivider(color: Color.fromRGBO(144, 202, 249, 1)),
//         //           Text(
//         //             'Total Orders: ${registerOrderList.length}',
//         //             style: GoogleFonts.roboto(color: Colors.white),
//         //           ),
//         //           const VerticalDivider(
//         //             color: Color.fromRGBO(144, 202, 249, 1),
//         //             thickness: 2,
//         //           ),
//         //           Text(
//         //             'Total Qty: ${_calculateTotalQuantity()}',
//         //             style: GoogleFonts.roboto(color: Colors.white),
//         //           ),
//         //         ],
//         //       ),
//         //     ],
//         //   ),
//         // ),
//       ),
//       body:
//           isLoading && registerOrderList.isEmpty
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
//                         borderRadius: BorderRadius.circular(4),
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
//                 controller: _scrollController,
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
//                     const Divider(color: Color.fromRGBO(144, 202, 249, 1)),
//                     ...registerOrderList.map(
//                       (order) => Column(
//                         children: [
//                           buildOrderItem(order),
//                           const Divider(
//                             color: Color.fromRGBO(144, 202, 249, 1),
//                           ),
//                         ],
//                       ),
//                     ),
//                     if (isLoading && registerOrderList.isNotEmpty)
//                       const Center(
//                         child: Padding(
//                           padding: EdgeInsets.all(10),
//                           child: CircularProgressIndicator(),
//                         ),
//                       ),
//                     if (!hasMoreData && registerOrderList.isNotEmpty)
//                       const Center(
//                         child: Padding(
//                           padding: EdgeInsets.all(10),
//                           child: Text('No more orders to load'),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//       floatingActionButton: Padding(
//         padding: const EdgeInsets.only(bottom: 50),
//         child: FloatingActionButton(
//           backgroundColor: AppColors.primaryColor,
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
//                         });
//                         fetchOrders(isLoadMore: false);
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
//       fetchOrders(isLoadMore: false);
//     }
//   }
// }


import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vrs_erp/models/brand.dart';
import 'package:vrs_erp/models/catalog.dart';
import 'package:vrs_erp/models/category.dart';
import 'package:vrs_erp/models/item.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/models/registerModel.dart';
import 'package:vrs_erp/models/shade.dart';
import 'package:vrs_erp/models/size.dart';
import 'package:vrs_erp/models/stockReportModel.dart';
import 'package:vrs_erp/models/style.dart';
import 'package:vrs_erp/register/registerFilteration.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/viewOrder/Pdf_viewer_screen.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_barcode2.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_screen.dart';
import '../constants/app_constants.dart';
import '../models/consignee.dart';

class PackingPage extends StatefulWidget {
  @override
  _PackingPageState createState() => _PackingPageState();
}

class _PackingPageState extends State<PackingPage>
    with SingleTickerProviderStateMixin {
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
  int pageNo = 1;
  int pageSize = 20;
  bool hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  int activeFilterCount = 0;

  final ScrollController _dateRangeScrollController = ScrollController();
  bool _showCustomDatePicker = false;
  String selectedRange = 'Today';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> dateRanges = [
    'Custom',
    'Today',
    'Yesterday',
    'This Week',
    'Previous Week',
    'This Month',
    'Previous Month',
    'This Quarter',
    'Previous Quarter',
    'This Year',
    'Previous Year',
  ];

  @override
  void initState() {
    super.initState();
    fromDate = DateTime.now();
    toDate = DateTime.now();
    fromDateController.text = DateFormat('yyyy-MM-dd').format(fromDate!);
    toDateController.text = DateFormat('yyyy-MM-dd').format(toDate!);
    _loadDropdownData();
    fetchOrders(isLoadMore: false);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMoreData) {
        fetchOrders(isLoadMore: true);
      }
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dateRangeScrollController.dispose();
    _animationController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    super.dispose();
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

  Future<void> fetchOrders({required bool isLoadMore}) async {
    if (!isLoadMore) {
      setState(() {
        pageNo = 1;
        registerOrderList.clear();
        hasMoreData = true;
      });
    }

    if (!hasMoreData || isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final orders = await ApiService.fetchPackingRegister(
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
        userName: null,
        lastSavedOrderId: null,
        pageNo: pageNo,
        pageSize: pageSize,
      );

      setState(() {
        if (isLoadMore) {
          registerOrderList.addAll(orders);
        } else {
          registerOrderList = orders;
        }
        hasMoreData = orders.length == pageSize;
        pageNo++;
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

  void _updateDateRange(String range) {
    final now = DateTime.now();
    setState(() {
      selectedRange = range;
      _showCustomDatePicker = (range == 'Custom');

      switch (range) {
        case 'Today':
          fromDate = DateTime(now.year, now.month, now.day);
          toDate = DateTime(now.year, now.month, now.day);
          fromDateController.text = DateFormat('yyyy-MM-dd').format(fromDate!);
          toDateController.text = DateFormat('yyyy-MM-dd').format(toDate!);
          break;
        case 'Yesterday':
          final yesterday = now.subtract(const Duration(days: 1));
          fromDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
          toDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
          fromDateController.text = DateFormat('yyyy-MM-dd').format(fromDate!);
          toDateController.text = DateFormat('yyyy-MM-dd').format(toDate!);
          break;
        case 'This Week':
          final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
          fromDate = DateTime(
            firstDayOfWeek.year,
            firstDayOfWeek.month,
            firstDayOfWeek.day,
          );
          toDate = DateTime(now.year, now.month, now.day);
          fromDateController.text = DateFormat('yyyy-MM-dd').format(fromDate!);
          toDateController.text = DateFormat('yyyy-MM-dd').format(toDate!);
          break;
        case 'Previous Week':
          final firstDayOfLastWeek = now.subtract(
            Duration(days: now.weekday + 6),
          );
          fromDate = DateTime(
            firstDayOfLastWeek.year,
            firstDayOfLastWeek.month,
            firstDayOfLastWeek.day,
          );
          toDate = DateTime(
            firstDayOfLastWeek.year,
            firstDayOfLastWeek.month,
            firstDayOfLastWeek.day + 6,
          );
          fromDateController.text = DateFormat('yyyy-MM-dd').format(fromDate!);
          toDateController.text = DateFormat('yyyy-MM-dd').format(toDate!);
          break;
        case 'This Month':
          fromDate = DateTime(now.year, now.month, 1);
          toDate = DateTime(now.year, now.month + 1, 0);
          fromDateController.text = DateFormat('yyyy-MM-dd').format(fromDate!);
          toDateController.text = DateFormat('yyyy-MM-dd').format(toDate!);
          break;
        case 'Previous Month':
          fromDate = DateTime(now.year, now.month - 1, 1);
          toDate = DateTime(now.year, now.month, 0);
          fromDateController.text = DateFormat('yyyy-MM-dd').format(fromDate!);
          toDateController.text = DateFormat('yyyy-MM-dd').format(toDate!);
          break;
        case 'This Quarter':
          final quarter = (now.month - 1) ~/ 3;
          fromDate = DateTime(now.year, quarter * 3 + 1, 1);
          toDate = DateTime(now.year, quarter * 3 + 4, 0);
          fromDateController.text = DateFormat('yyyy-MM-dd').format(fromDate!);
          toDateController.text = DateFormat('yyyy-MM-dd').format(toDate!);
          break;
        case 'Previous Quarter':
          final quarter = (now.month - 1) ~/ 3;
          final prevQuarter = quarter == 0 ? 3 : quarter - 1;
          final prevQuarterYear = quarter == 0 ? now.year - 1 : now.year;
          fromDate = DateTime(prevQuarterYear, prevQuarter * 3 + 1, 1);
          toDate = DateTime(prevQuarterYear, prevQuarter * 3 + 4, 0);
          fromDateController.text = DateFormat('yyyy-MM-dd').format(fromDate!);
          toDateController.text = DateFormat('yyyy-MM-dd').format(toDate!);
          break;
        case 'This Year':
          fromDate = DateTime(now.year, 1, 1);
          toDate = DateTime(now.year, 12, 31);
          fromDateController.text = DateFormat('yyyy-MM-dd').format(fromDate!);
          toDateController.text = DateFormat('yyyy-MM-dd').format(toDate!);
          break;
        case 'Previous Year':
          fromDate = DateTime(now.year - 1, 1, 1);
          toDate = DateTime(now.year - 1, 12, 31);
          fromDateController.text = DateFormat('yyyy-MM-dd').format(fromDate!);
          toDateController.text = DateFormat('yyyy-MM-dd').format(toDate!);
          break;
        case 'Custom':
          break;
      }
    });
    fetchOrders(isLoadMore: false);
  }

  void _changeCustomDate(bool isFromDate, int days) {
    setState(() {
      if (isFromDate) {
        if (fromDate != null) {
          fromDate = fromDate!.add(Duration(days: days));
          fromDateController.text = DateFormat('yyyy-MM-dd').format(fromDate!);
        }
      } else {
        if (toDate != null) {
          toDate = toDate!.add(Duration(days: days));
          toDateController.text = DateFormat('yyyy-MM-dd').format(toDate!);
        }
      }
      selectedRange = 'Custom';
      _showCustomDatePicker = true;
    });
    fetchOrders(isLoadMore: false);
  }

  Future<void> _selectDateForCustom(bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isFromDate ? (fromDate ?? DateTime.now()) : (toDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
          fromDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          toDate = picked;
          toDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
        selectedRange = 'Custom';
        _showCustomDatePicker = true;
      });
      fetchOrders(isLoadMore: false);
    }
  }

  Widget _buildCustomDatePickerField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required bool isFromDate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.chevron_left,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                  onPressed: () => _changeCustomDate(isFromDate, -1),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      date != null
                          ? '${date.day}/${date.month}/${date.year}'
                          : 'Select Date',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.chevron_right,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                  onPressed: () => _changeCustomDate(isFromDate, 1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openFilterPage() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => RegisterFilterPage(
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
                setState(() {
                  this.selectedLedger = selectedLedger;
                  this.selectedSalesperson = selectedSalesperson;
                  this.fromDate = fromDate;
                  this.toDate = toDate;
                  this.deliveryFromDate = deliveryFromDate;
                  this.deliveryToDate = deliveryToDate;
                  this.selectedOrderStatus = selectedOrderStatus;

                  activeFilterCount = 0;
                  if (selectedLedger != null) activeFilterCount++;
                  if (selectedSalesperson != null) activeFilterCount++;
                  if (selectedOrderStatus != null &&
                      selectedOrderStatus != 'All')
                    activeFilterCount++;
                  if (fromDate != null) activeFilterCount++;
                  if (toDate != null) activeFilterCount++;
                  if (deliveryFromDate != null) activeFilterCount++;
                  if (deliveryToDate != null) activeFilterCount++;
                });
                fetchOrders(isLoadMore: false);
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
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          );
        },
      ),
    );
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

  void _showWhatsAppDialog(RegisterOrder registerOrder) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController controller = TextEditingController(
          text: registerOrder.whatsAppMobileNo ?? '',
        );
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Text(
                'WhatsApp',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter WhatsApp Number',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: InputDecoration(
                  hintText: 'Enter 10-digit number',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryColor),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                String number = controller.text.trim();
                if (number.length != 10 ||
                    !RegExp(r'^[0-9]{10}$').hasMatch(number)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid 10-digit number'),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                await _sendWhatsApp(registerOrder, number);
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendWhatsApp(RegisterOrder registerOrder, String number) async {
    try {
      final dio = Dio();
      final response = await dio.post(
        '${AppConstants.Pdf_url}',
        data: {
          "doc_id": registerOrder.orderId,
          "rptName": "Packing",
          "dbName": UserSession.dbName,
          "dbUser": UserSession.dbUser,
          "dbPassword": UserSession.dbPassword,
          "dbServer": UserSession.dbSourceForRpt,
          "rptPath": UserSession.rptPath,
        },
        options: Options(responseType: ResponseType.bytes),
      );

      bool sent = await _sendWhatsAppFile2(
        fileBytes: response.data,
        mobileNo: number,
        fileType: 'pdf',
        caption: 'Packing Slip',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sent ? 'Sent on WhatsApp' : 'Failed to send'),
          backgroundColor: sent ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to download or send'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadOrder(RegisterOrder registerOrder) async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Storage permission denied')),
              );
            }
            return;
          }
        }
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Downloading...',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
            ),
      );

      final dio = Dio();
      final response = await dio.post(
        '${AppConstants.Pdf_url}',
        data: {
          "doc_id": registerOrder.orderId,
          "rptName": "Packing",
          "dbName": UserSession.dbName,
          "dbUser": UserSession.dbUser,
          "dbPassword": UserSession.dbPassword,
          "dbServer": UserSession.dbSourceForRpt,
          "rptPath": UserSession.rptPath,
        },
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final fileName = 'Packing_${registerOrder.orderId}.pdf';

        if (kIsWeb) {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF downloaded as $fileName'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          Directory? directory;
          String filePath;

          if (Platform.isAndroid) {
            directory = Directory('/storage/emulated/0/Download');
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
            filePath = '${directory.path}/$fileName';
          } else if (Platform.isIOS) {
            directory = await getApplicationDocumentsDirectory();
            filePath = '${directory.path}/$fileName';
          } else {
            throw Exception('Unsupported platform');
          }

          final file = File(filePath);
          await file.writeAsBytes(response.data, flush: true);

          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF downloaded'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'Open',
                  textColor: Colors.white,
                  onPressed: () async {
                    final result = await OpenFile.open(filePath);
                    if (result.type != ResultType.done && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
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
              content: Text('Failed to load PDF: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleMenuSelection(
    String value,
    RegisterOrder registerOrder,
  ) async {
    switch (value) {
      case 'whatsapp':
        _showWhatsAppDialog(registerOrder);
        break;

      case 'download':
        await _downloadOrder(registerOrder);
        break;

      case 'view':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PdfViewerScreen(
                  rptName: 'Packing',
                  orderNo: registerOrder.orderId,
                  whatsappNo: registerOrder.whatsAppMobileNo,
                  partyName: registerOrder.partyName,
                  orderDate: registerOrder.orderDate,
                ),
          ),
        );
        break;

      case 'editBarcode':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditOrderBarcode2(docId: registerOrder.orderId),
          ),
        );
        break;

      case 'edit2':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditOrderScreen(docId: registerOrder.orderId),
          ),
        );
        if (result == true) {
          fetchOrders(isLoadMore: false);
        }
        break;
    }
  }

  Widget buildOrderItem(RegisterOrder registerOrder) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryColor.withOpacity(0.6),
                        AppColors.primaryColor.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  top: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.inventory,
                                  color: AppColors.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      registerOrder.itemName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            registerOrder.orderNo,
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.green[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            border: Border.all(
                                              color: Colors.blue.withOpacity(
                                                0.2,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.local_shipping,
                                                color: Colors.blue,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                registerOrder.deliveryType,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ],
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
                        PopupMenuButton<String>(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.more_vert,
                              color: AppColors.primaryColor,
                              size: 18,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          onSelected: (value) =>
                              _handleMenuSelection(value, registerOrder),
                          itemBuilder:
                              (BuildContext context) => [
                                PopupMenuItem<String>(
                                  value: 'whatsapp',
                                  child: Row(
                                    children: [
                                      FaIcon(
                                        FontAwesomeIcons.whatsapp,
                                        size: 20,
                                        color: AppColors.primaryColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'WhatsApp',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'download',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.download,
                                        color: AppColors.primaryColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Download',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.visibility,
                                        color: AppColors.primaryColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'View',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'editBarcode',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.qr_code_scanner,
                                        color: AppColors.primaryColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Edit Barcode',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (registerOrder.deliveryType == 'Draft')
                                  PopupMenuItem<String>(
                                    value: 'edit2',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit,
                                          color: AppColors.primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Update Order',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              label: 'Date',
                              value: registerOrder.orderDate,
                              icon: Icons.calendar_today,
                            ),
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          Expanded(
                            child: _buildDetailItem(
                              label: 'Quantity',
                              value: '${registerOrder.quantity}',
                              icon: Icons.inventory,
                            ),
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          Expanded(
                            child: _buildDetailItem(
                              label: 'Amount',
                              value:
                                  '₹${registerOrder.amount.toStringAsFixed(0)}',
                              icon: Icons.currency_rupee,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (registerOrder.salesPersonName.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 14, color: Colors.purple),
                            const SizedBox(width: 6),
                            Text(
                              'Salesperson: ',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              registerOrder.salesPersonName,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading packing orders...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory,
              size: 50,
              color: AppColors.primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Packing Orders Found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or date range',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: DrawerScreen(),
      appBar: AppBar(
        title: Text(
          'Packing Register',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.filter_list, color: Colors.white, size: 22),
                  if (activeFilterCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$activeFilterCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: _openFilterPage,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.maroon.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(0),
              ),
              border: const Border(
                top: BorderSide(color: Colors.white, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  label: 'Total Amount',
                  value: '₹${_calculateTotalAmount().toStringAsFixed(0)}',
                  icon: Icons.currency_rupee,
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatItem(
                  label: 'Packing Orders',
                  value: '${registerOrderList.length}',
                  icon: Icons.receipt_long,
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatItem(
                  label: 'Quantity',
                  value: '${_calculateTotalQuantity()}',
                  icon: Icons.inventory,
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child:
            isLoading && registerOrderList.isEmpty
                ? _buildLoadingIndicator()
                : FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: () => fetchOrders(isLoadMore: false),
                    color: AppColors.primaryColor,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDateRangeSelector(),
                          const SizedBox(height: 20),
                          if (registerOrderList.isEmpty)
                            _buildEmptyState()
                          else
                            ...registerOrderList.map(
                              (order) => Column(
                                children: [
                                  buildOrderItem(order),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          if (isLoading && registerOrderList.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          if (!hasMoreData && registerOrderList.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: Text('No more orders to load'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 50,
          child: ListView.builder(
            controller: _dateRangeScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: dateRanges.length,
            itemBuilder: (context, index) {
              final range = dateRanges[index];
              final isSelected = selectedRange == range;

              return GestureDetector(
                onTap: () => _updateDateRange(range),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryColor
                          : Colors.grey.shade300,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      range,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (_showCustomDatePicker)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildCustomDatePickerField(
                    label: 'From',
                    date: fromDate,
                    onTap: () => _selectDateForCustom(true),
                    isFromDate: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCustomDatePickerField(
                    label: 'To',
                    date: toDate,
                    onTap: () => _selectDateForCustom(false),
                    isFromDate: false,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
