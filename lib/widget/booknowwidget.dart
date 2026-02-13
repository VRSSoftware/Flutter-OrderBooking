// import 'dart:convert';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:vrs_erp/constants/app_constants.dart';
// import 'package:vrs_erp/models/CatalogItem.dart';

// class CatalogBookingTable extends StatefulWidget {
//   final String itemSubGrpKey;
//   final String itemKey;
//   final String styleKey;
//   final VoidCallback onSuccess;

//   const CatalogBookingTable({
//     super.key,
//     required this.itemSubGrpKey,
//     required this.itemKey,
//     required this.styleKey,
//     required this.onSuccess,
//   });

//   @override
//   State<CatalogBookingTable> createState() => _CatalogBookingTableState();
// }

// class _CatalogBookingTableState extends State<CatalogBookingTable> {
//   List<CatalogItem> catalogItems = [];
//   List<String> sizes = [];
//   List<String> colors = [];
//   Map<String, Map<String, TextEditingController>> controllers = {};
//   String styleCode = '';
//   late Map<String, double> sizeMrpMap;
//   late Map<String, double> sizeWspMap;

//   String itemSubGrpKey = '';
//   String itemKey = '';
//   String styleKey = '';
//   String userId = UserSession.userName??'';
//   String coBrId = UserSession.coBrId??'';
//   String fcYrId = UserSession.userFcYr??'';
//   bool stockWise = true;
//   bool isLoading = true;
//   List<String> _copiedRow = [];
//   TextEditingController noteController = TextEditingController();

//   int get totalQty {
//     int total = 0;
//     for (var row in controllers.values) {
//       for (var cell in row.values) {
//         total += int.tryParse(cell.text) ?? 0;
//       }
//     }
//     return total;
//   }

//   @override
//   void initState() {
//     super.initState();
//     itemSubGrpKey = widget.itemSubGrpKey;
//     itemKey = widget.itemKey;
//     styleKey = widget.styleKey;
//     fetchCatalogData();
//   }

//   Future<void> fetchCatalogData() async {
//     final String apiUrl = '${AppConstants.BASE_URL}/catalog/GetOrderDetails';

//     final Map<String, dynamic> requestBody = {
//       "itemSubGrpKey": itemSubGrpKey,
//       "itemKey": itemKey,
//       "styleKey": styleKey,
//       "userId": userId,
//       "coBrId": coBrId,
//       "fcYrId": fcYrId,
//       "stockWise": stockWise,
//       "brandKey": null,
//       "shadeKey": null,
//       "styleSizeId": null,
//       "fromMRP": null,
//       "toMRP": null,
//     };

//     final response = await http.post(
//       Uri.parse(apiUrl),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode(requestBody),
//     );
//     //  print("${response.body}");
//     if (response.statusCode == 200) {
//       final List data = jsonDecode(response.body);
//       if (data.isNotEmpty) {
//         final items = data.map((e) => CatalogItem.fromJson(e)).toList();

//         final uniqueSizes =
//             items.map((e) => e.sizeName).toSet().toList()..sort();
//         final uniqueColors = items.map((e) => e.shadeName).toSet().toList();

//         // Initialize size-specific price maps
//         sizeMrpMap = {};
//         sizeWspMap = {};
//         for (var item in items) {
//           sizeMrpMap[item.sizeName] = item.mrp;
//           sizeWspMap[item.sizeName] = item.wsp;
//         }

//         setState(() {
//           catalogItems = items;
//           sizes = uniqueSizes;
//           colors = uniqueColors;
//           styleCode = items.first.styleCode;

//           for (var color in colors) {
//             controllers[color] = {};
//             for (var size in sizes) {
//               final match = items.firstWhere(
//                 (item) => item.shadeName == color && item.sizeName == size,
//                 orElse:
//                     () => CatalogItem(
//                       styleCode: styleCode,
//                       shadeName: color,
//                       sizeName: size,
//                       clQty: 0,
//                       mrp: sizeMrpMap[size] ?? 0,
//                       wsp: sizeWspMap[size] ?? 0,
//                     ),
//               );
//               final controller = TextEditingController();
//               controller.addListener(() => setState(() {}));
//               controllers[color]![size] = controller;
//             }
//           }
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     } else {
//       debugPrint('Failed to fetch catalog data: ${response.statusCode}');
//     }
//   }

//   void _copyQtyInAllShade() {
//     if (colors.isEmpty || sizes.isEmpty) return;

//     // Copy from first row, first column
//     final sourceColor = colors.first;
//     final sourceSize = sizes.first;
//     final valueToCopy = controllers[sourceColor]?[sourceSize]?.text ?? '';

//     for (var color in colors) {
//       for (var size in sizes) {
//         controllers[color]?[size]?.text = valueToCopy;
//       }
//     }

//     setState(() {});
//   }

//   void _copySizeQtyInAllShade() {
//     if (colors.isEmpty || sizes.isEmpty) return;

//     // Copy the first row (colors[0]) values to other rows (vertically)
//     final sourceColor = colors.first;
//     for (var size in sizes) {
//       final valueToCopy = controllers[sourceColor]?[size]?.text ?? '';
//       for (var color in colors) {
//         controllers[color]?[size]?.text = valueToCopy;
//       }
//     }

//     setState(() {});
//   }

//   Color _getColorCode(String color) {
//     switch (color.toLowerCase()) {
//       case 'red':
//         return Colors.red;
//       case 'green':
//         return Colors.green;
//       case 'blue':
//         return Colors.blue;
//       case 'yellow':
//         return Colors.yellow[800]!;
//       case 'black':
//         return Colors.black;
//       case 'white':
//         return Colors.grey;
//       default:
//         return Colors.black;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     } else if (catalogItems.isEmpty) {
//       return const Center(child: Text("Empty"));
//     }

//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 16),
//       child: LayoutBuilder(
//         builder: (context, constraints) {
//           return SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     _buildPriceTag(context),
//                     const SizedBox(width: 4),
//                     // Icon(Icons.copy_outlined) //copy size qty in all shades
//                     PopupMenuButton<String>(
//                       icon: const Icon(Icons.copy_outlined),
//                       onSelected: (value) {
//                         if (value == 'copy_qty_all_shade') {
//                           _copyQtyInAllShade();
//                         } else if (value == 'copy_size_qty_all_shade') {
//                           _copySizeQtyInAllShade();
//                         }
//                       },
//                       itemBuilder:
//                           (BuildContext context) => [
//                             const PopupMenuItem(
//                               value: 'copy_qty_all_shade',
//                               child: Text('Copy Qty in All Shade'),
//                             ),
//                             const PopupMenuItem(
//                               value: 'copy_size_qty_all_shade',
//                               child: Text('Copy Size Qty in All Shade'),
//                             ),
//                           ],
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 _buildCatalogTable(constraints.maxWidth),
//                 const SizedBox(height: 16),
//                 // Add matching width constraints to note and total qty
//                 _buildNoteField(constraints.maxWidth),
//                 const SizedBox(height: 12),
//                 _buildTotalQtyField(constraints.maxWidth),
//                 const SizedBox(height: 16),
//                 _buildActionButtons(),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildPriceTag(BuildContext context) {
//     final textScale = MediaQuery.of(context).textScaleFactor;

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       child: SizedBox(
//         height: 35 * textScale,
//         width: 120 * textScale,
//         child: CustomPaint(
//           painter: PriceTagPaint(),
//           child: Center(
//             child: Text(
//               styleCode,
//               style: TextStyle(
//                 fontSize: 20 * textScale,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCatalogTable(double maxWidth) {
//     final requiredTableWidth = 100 + (80 * sizes.length);
//     final hasHorizontalScroll = requiredTableWidth > maxWidth;

//     // Handle empty state early
//     if (sizes.isEmpty || colors.isEmpty) {
//       return Container(
//         padding: const EdgeInsets.all(16),
//         child: const Center(
//           child: Text(
//             'No items available',
//             style: TextStyle(fontSize: 16, color: Colors.grey),
//           ),
//         ),
//       );
//     }

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade500),
//       ),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: ConstrainedBox(
//           constraints: BoxConstraints(minWidth: maxWidth - 32),
//           child: Container(
//             width: requiredTableWidth.toDouble(),
//             child: Table(
//               border: TableBorder.symmetric(
//                 inside: BorderSide(color: Colors.grey.shade400, width: 1),
//               ),
//               columnWidths: _buildColumnWidths(maxWidth),
//               children: [
//                 _buildPriceRow("MRP", sizeMrpMap, FontWeight.w600),
//                 _buildPriceRow("WSP", sizeWspMap, FontWeight.w400),
//                 _buildHeaderRow(),
//                 // ...colors.map((color) => _buildQuantityRow(color)),
//                 for (var i = 0; i < colors.length; i++)
//                   _buildQuantityRow(colors[i], i),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Map<int, TableColumnWidth> _buildColumnWidths(double maxWidth) {
//     final baseWidth = maxWidth < 600 ? 80.0 : 100.0;
//     return {
//       0: FixedColumnWidth(baseWidth),
//       for (int i = 0; i < sizes.length; i++)
//         (i + 1): FixedColumnWidth(baseWidth * 0.8),
//     };
//   }

//   Widget _buildNoteField(double maxWidth) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: ConstrainedBox(
//         constraints: BoxConstraints(maxWidth: maxWidth - 32),
//         child: TextField(
//           controller: noteController,
//           decoration: InputDecoration(
//             border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
//             contentPadding: const EdgeInsets.all(16),
//             labelText: 'Note',
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTotalQtyField(double maxWidth) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: ConstrainedBox(
//         constraints: BoxConstraints(maxWidth: maxWidth - 32),
//         child: TextField(
//           readOnly: true,
//           controller: TextEditingController(text: totalQty.toString()),
//           decoration: InputDecoration(
//             border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
//             contentPadding: const EdgeInsets.all(16),
//             labelText: 'Total Qty',
//             filled: true,
//             //fillColor: Colors.grey[100],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildActionButtons() {
//     return Center(
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _buildAddButton(),
//             const SizedBox(width: 24),
//             _buildCloseButton(),
//           ],
//         ),
//       ),
//     );
//   }

//   // Keep the button widgets exactly as they were before
//   Widget _buildAddButton() {
//     return SizedBox(
//       width: 140,
//       height: 45,
//       child: ElevatedButton.icon(
//         icon: const Icon(Icons.add, color: Colors.white),
//         label: const Text(
//           'Add',
//           style: TextStyle(fontSize: 16, color: Colors.white),
//         ),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: totalQty > 0 ? AppColors.primaryColor : Colors.grey,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//         ),
//         onPressed: totalQty > 0 ? _submitOrder : null,
//       ),
//     );
//   }

//   Widget _buildCloseButton() {
//     return SizedBox(
//       width: 140,
//       height: 45,
//       child: ElevatedButton.icon(
//         icon: const Icon(Icons.close, color: AppColors.primaryColor),
//         label: const Text(
//           'Close',
//           style: TextStyle(fontSize: 16, color: AppColors.primaryColor),
//         ),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//             side: const BorderSide(color: AppColors.primaryColor, width: 2),
//           ),
//         ),
//         onPressed: () => Navigator.pop(context),
//       ),
//     );
//   }

//   TableRow _buildPriceRow(
//     String label,
//     Map<String, double> sizePriceMap,
//     FontWeight weight,
//   ) {
//     return TableRow(
//       children: [
//         TableCell(
//           verticalAlignment: TableCellVerticalAlignment.middle,
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Text(label, style: TextStyle(fontWeight: weight)),
//           ),
//         ),
//         ...sizes.map((size) {
//           final price = sizePriceMap[size] ?? 0.0;
//           return TableCell(
//             verticalAlignment: TableCellVerticalAlignment.middle,
//             child: Center(
//               child: Text(
//                 price.toStringAsFixed(0),
//                 style: TextStyle(fontWeight: weight),
//               ),
//             ),
//           );
//         }).toList(),
//       ],
//     );
//   }

//   TableRow _buildHeaderRow() {
//     return TableRow(
//       decoration: BoxDecoration(
//         color: const Color.fromARGB(255, 236, 212, 204),
//       ),
//       children: [
//         const TableCell(
//           verticalAlignment: TableCellVerticalAlignment.middle,
//           child: _TableHeaderCell(),
//         ),
//         ...sizes
//             .map(
//               (size) => TableCell(
//                 verticalAlignment: TableCellVerticalAlignment.middle,
//                 child: Center(
//                   child: Text(
//                     size,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ),
//             )
//             .toList(),
//       ],
//     );
//   }

//   TableRow _buildQuantityRow(String color, int i) {
//     return TableRow(
//       children: [
//         TableCell(
//           verticalAlignment: TableCellVerticalAlignment.middle,
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 GestureDetector(
//                   child: Icon(Icons.copy_all, size: 12),
//                   onTap: () {
//                     showDialog(
//                       context: context,
//                       builder: (BuildContext context) {
//                         return AlertDialog(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           title: Text('Select an Action'),
//                           content: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               GestureDetector(
//                                 onTap: () {
//                                   Navigator.of(context).pop();
//                                   // Add "Copy Qty in shade only" logic
//                                   final firstQty =
//                                       controllers[color]?.values.first.text;
//                                   for (var size in sizes) {
//                                     controllers[color]?[size]?.text =
//                                         firstQty ?? '0';
//                                   }
//                                 },
//                                 child: Container(
//                                   width: double.infinity,
//                                   padding: EdgeInsets.symmetric(vertical: 12),
//                                   margin: EdgeInsets.only(bottom: 10),
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue,
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   alignment: Alignment.center,
//                                   child: Text(
//                                     'Copy Qty in shade only',
//                                     style: TextStyle(color: Colors.white),
//                                   ),
//                                 ),
//                               ),
//                               GestureDetector(
//                                 onTap: () {
//                                   Navigator.of(context).pop();
//                                   // Add "Copy Row" logic
//                                   List<String> copiedRow = [];
//                                   for (var size in sizes) {
//                                     final qty =
//                                         controllers[color]?[size]?.text ?? '0';
//                                     copiedRow.add(qty);
//                                   }
//                                   // Store the copied row for pasting
//                                   _copiedRow = copiedRow;
//                                 },
//                                 child: Container(
//                                   width: double.infinity,
//                                   padding: EdgeInsets.symmetric(vertical: 12),
//                                   margin: EdgeInsets.only(bottom: 10),
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue,
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   alignment: Alignment.center,
//                                   child: Text(
//                                     'Copy Row',
//                                     style: TextStyle(color: Colors.white),
//                                   ),
//                                 ),
//                               ),
//                               GestureDetector(
//                                 onTap: () {
//                                   Navigator.of(context).pop();
//                                   // Add "Paste Row" logic
//                                   for (int j = 0; j < sizes.length; j++) {
//                                     controllers[color]?[sizes[j]]?.text =
//                                         _copiedRow[j];
//                                   }
//                                 },
//                                 child: Container(
//                                   width: double.infinity,
//                                   padding: EdgeInsets.symmetric(vertical: 12),
//                                   decoration: BoxDecoration(
//                                     color: Colors.green,
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   alignment: Alignment.center,
//                                   child: Text(
//                                     'Paste Row',
//                                     style: TextStyle(color: Colors.white),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//                 const SizedBox(width: 6),
//                 Flexible(
//                   child: Text(
//                     '${color} ',
//                     style: TextStyle(
//                       color: _getColorCode(color),
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         ...sizes.map((size) {
//           final controller = controllers[color]?[size];
//           final originalQty =
//               catalogItems
//                   .firstWhere(
//                     (item) => item.shadeName == color && item.sizeName == size,
//                     orElse:
//                         () => CatalogItem(
//                           styleCode: styleCode,
//                           shadeName: color,
//                           sizeName: size,
//                           clQty: 0,
//                           mrp: sizeMrpMap[size] ?? 0,
//                           wsp: sizeWspMap[size] ?? 0,
//                         ),
//                   )
//                   .clQty;

//           return TableCell(
//             verticalAlignment: TableCellVerticalAlignment.middle,
//             child: Padding(
//               padding: const EdgeInsets.all(4.0),
//               child: TextField(
//                 controller: controller,
//                 keyboardType: TextInputType.number,
//                 textAlign: TextAlign.center,
//                 decoration: InputDecoration(
//                   contentPadding: const EdgeInsets.symmetric(vertical: 8),
//                   hintText: originalQty > 0 ? originalQty.toString() : '0',
//                   hintStyle: const TextStyle(color: Colors.grey),
//                   border: InputBorder.none,
//                 ),
//               ),
//             ),
//           );
//         }).toList(),
//       ],
//     );
//   }

//   Future<void> _submitOrder() async {
//     List<Future> apiCalls = [];

//     for (var colorEntry in controllers.entries) {
//       String color = colorEntry.key;
//       for (var sizeEntry in colorEntry.value.entries) {
//         String size = sizeEntry.key;
//         String qty = sizeEntry.value.text;
//         if (qty.isNotEmpty && int.tryParse(qty) != null && int.parse(qty) > 0) {
//           final payload = {
//             "userId": userId,
//             "coBrId": coBrId,
//             "fcYrId": fcYrId,
//             "data": {
//               "designcode": styleCode,
//               "mrp": sizeMrpMap[size]?.toStringAsFixed(0) ?? '0',
//               "WSP": sizeWspMap[size]?.toStringAsFixed(0) ?? '0',
//               "size": size,
//               "TotQty": totalQty.toString(),
//               "Note": noteController.text,
//               "color": color,
//               "Qty": qty,
//               "cobrid": coBrId,
//               "user": userId.toLowerCase(),
//               "barcode": "",
//             },
//             "typ": 0,
//           };

//           apiCalls.add(
//             http.post(
//               Uri.parse(
//                 '${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails',
//               ),
//               headers: {'Content-Type': 'application/json'},
//               body: jsonEncode(payload),
//             ),
//           );
//         }
//       }
//     }

//     try {
//       final responses = await Future.wait(apiCalls);
//       if (responses.every((r) => r.statusCode == 200)) {
//         if (mounted) {
//           showDialog(
//             context: context,
//             builder:
//                 (_) => AlertDialog(
//                   title: const Text("Success"),
//                   content: const Text("Booking submitted."),
//                   actions: [
//                     TextButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         Navigator.pop(context);
//                         widget.onSuccess();
//                       },
//                       child: const Text("OK"),
//                     ),
//                   ],
//                 ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         showDialog(
//           context: context,
//           builder:
//               (_) => AlertDialog(
//                 title: const Text("Error"),
//                 content: Text("Failed to submit: $e"),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text("OK"),
//                   ),
//                 ],
//               ),
//         );
//       }
//     }
//   }
// }

// class _TableHeaderCell extends StatelessWidget {
//   const _TableHeaderCell();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 48,
//       child: CustomPaint(
//         painter: _DiagonalLinePainter(),
//         child: const Stack(
//           children: [
//             Positioned(
//               left: 12,
//               top: 20,
//               child: Text(
//                 'Shade',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue,
//                 ),
//               ),
//             ),
//             Positioned(
//               right: 14,
//               bottom: 20,
//               child: Text(
//                 'Size',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.red,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _DiagonalLinePainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint =
//         Paint()
//           ..color = Colors.grey.shade400
//           ..strokeWidth = 1
//           ..style = PaintingStyle.stroke;
//     canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

// class PriceTagPaint extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     Paint paint =
//         Paint()
//           ..color = AppColors.primaryColor
//           ..strokeCap = StrokeCap.round
//           ..style = PaintingStyle.fill;

//     Path path = Path();

//     path
//       ..moveTo(0, size.height * .5)
//       ..lineTo(size.width * .13, 0)
//       ..lineTo(size.width, 0)
//       ..lineTo(size.width, size.height)
//       ..lineTo(size.width * .13, size.height)
//       ..lineTo(0, size.height * .5)
//       ..close();
//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/constants/constants.dart';
import 'package:vrs_erp/models/CatalogItem.dart';
import 'package:vrs_erp/models/CatalogOrderData.dart';
import 'package:vrs_erp/models/OrderMatrix.dart';
import 'package:vrs_erp/models/catalog.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_data.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_screen.dart';

class CatalogBookingTable extends StatefulWidget {
  final String itemSubGrpKey;
  final String itemKey;
  final String styleKey;
  final VoidCallback onSuccess;
  final bool? isEdit;
  final double? markDwn;
  final String? type;

  const CatalogBookingTable({
    super.key,
    required this.itemSubGrpKey,
    required this.itemKey,
    required this.styleKey,
    required this.onSuccess,
    this.isEdit,
    this.markDwn,
    this.type,
  });

  @override
  State<CatalogBookingTable> createState() => _CatalogBookingTableState();
}

class _CatalogBookingTableState extends State<CatalogBookingTable> {
  List<CatalogItem> catalogItems = [];
  List<String> sizes = [];
  List<String> colors = [];
  Map<String, Map<String, TextEditingController>> controllers = {};
  String styleCode = '';
  late Map<String, double> sizeMrpMap;
  late Map<String, double> sizeWspMap;

  String itemSubGrpKey = '';
  String itemKey = '';
  String styleKey = '';
  String userId = UserSession.userName ?? '';
  String coBrId = UserSession.coBrId ?? '';
  String fcYrId = UserSession.userFcYr ?? '';
  bool stockWise = true;
  bool isLoading = true;
  List<String> _copiedRow = [];
  TextEditingController noteController = TextEditingController();
  bool isEdit = false;
  double? markDwn = 0.0;
  String? type;

  int get totalQty {
    int total = 0;
    for (var row in controllers.values) {
      for (var cell in row.values) {
        total += int.tryParse(cell.text) ?? 0;
      }
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    itemSubGrpKey = widget.itemSubGrpKey;
    itemKey = widget.itemKey;
    styleKey = widget.styleKey;
    setState(() {
      isEdit = widget.isEdit ?? false;
      markDwn = widget.markDwn;
      type = widget.type;
    });
    fetchCatalogData();
  }

  Future<void> fetchCatalogData() async {
    final String apiUrl = '${AppConstants.BASE_URL}/catalog/GetOrderDetails';

    final Map<String, dynamic> requestBody = {
      "itemSubGrpKey": itemSubGrpKey,
      "itemKey": itemKey,
      "styleKey": styleKey,
      "userId": userId,
      "coBrId": coBrId,
      "fcYrId": fcYrId,
      "stockWise": stockWise,
      "brandKey": null,
      "shadeKey": null,
      "styleSizeId": null,
      "fromMRP": null,
      "toMRP": null,
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        final items = data.map((e) => CatalogItem.fromJson(e)).toList();

        final uniqueSizes =
            items.map((e) => e.sizeName).toSet().toList()..sort();
        final uniqueColors = items.map((e) => e.shadeName).toSet().toList();

        sizeMrpMap = {};
        sizeWspMap = {};
        for (var item in items) {
          sizeMrpMap[item.sizeName] = item.mrp;
          if (markDwn == 0.0 || markDwn == null) {
            sizeWspMap[item.sizeName] = item.wsp;
          } else {
            double mrp = item.mrp;
            double discountedWsp = mrp - (mrp * markDwn! / 100);
            sizeWspMap[item.sizeName] = discountedWsp;
          }
        }

        setState(() {
          catalogItems = items;
          sizes = uniqueSizes;
          colors = uniqueColors;
          styleCode = items.first.styleCode;

          for (var color in colors) {
            controllers[color] = {};
            for (var size in sizes) {
              final match = items.firstWhere(
                (item) => item.shadeName == color && item.sizeName == size,
                orElse:
                    () => CatalogItem(
                      styleCode: styleCode,
                      shadeName: color,
                      sizeName: size,
                      clQty: 0,
                      mrp: sizeMrpMap[size] ?? 0,
                      wsp: sizeWspMap[size] ?? 0,
                    ),
              );
              final controller = TextEditingController();
              controller.addListener(() => setState(() {}));
              controllers[color]![size] = controller;
            }
          }
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      debugPrint('Failed to fetch catalog data: ${response.statusCode}');
    }
  }

  void _copyQtyInAllShade() {
    if (colors.isEmpty || sizes.isEmpty) return;

    final sourceColor = colors.first;
    final sourceSize = sizes.first;
    final valueToCopy = controllers[sourceColor]?[sourceSize]?.text ?? '';

    for (var color in colors) {
      for (var size in sizes) {
        controllers[color]?[size]?.text = valueToCopy;
      }
    }

    setState(() {});
  }

  void _copySizeQtyInAllShade() {
    if (colors.isEmpty || sizes.isEmpty) return;

    final sourceColor = colors.first;
    for (var size in sizes) {
      final valueToCopy = controllers[sourceColor]?[size]?.text ?? '';
      for (var color in colors) {
        controllers[color]?[size]?.text = valueToCopy;
      }
    }

    setState(() {});
  }

  Color _getColorCode(String color) {
    switch (color.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow[800]!;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (catalogItems.isEmpty) {
      return const Center(child: Text("Empty"));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildPriceTag(context),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.copy_outlined),
                      onSelected: (value) {
                        if (value == 'copy_qty_all_shade') {
                          _copyQtyInAllShade();
                        } else if (value == 'copy_size_qty_all_shade') {
                          _copySizeQtyInAllShade();
                        }
                      },
                      itemBuilder:
                          (BuildContext context) => [
                            const PopupMenuItem(
                              value: 'copy_qty_all_shade',
                              child: Text('Copy Qty in All Shade'),
                            ),
                            const PopupMenuItem(
                              value: 'copy_size_qty_all_shade',
                              child: Text('Copy Size Qty in All Shade'),
                            ),
                          ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCatalogTable(constraints.maxWidth),
                const SizedBox(height: 16),
                _buildNoteField(constraints.maxWidth),
                const SizedBox(height: 12),
                _buildTotalQtyField(constraints.maxWidth),
                const SizedBox(height: 16),
                _buildActionButtons(constraints.maxWidth),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceTag(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaleFactor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 35 * textScale,
        width: 120 * textScale,
        child: CustomPaint(
          painter: PriceTagPaint(),
          child: Center(
            child: Text(
              styleCode,
              style: TextStyle(
                fontSize: 20 * textScale,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogTable(double maxWidth) {
    final requiredTableWidth = 100 + (80 * sizes.length);
    final hasHorizontalScroll = requiredTableWidth > maxWidth;

    if (sizes.isEmpty || colors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text(
            'No items available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade500),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: maxWidth - 32),
          child: Container(
            width: requiredTableWidth.toDouble(),
            child: Table(
              border: TableBorder.symmetric(
                inside: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              columnWidths: _buildColumnWidths(maxWidth),
              children: [
                _buildPriceRow("MRP", sizeMrpMap, FontWeight.w600),
                _buildPriceRow(
                  markDwn == 0.0 ? "WSP" : "Rate",
                  sizeWspMap,
                  FontWeight.w400,
                ),
                _buildHeaderRow(),
                for (var i = 0; i < colors.length; i++)
                  _buildQuantityRow(colors[i], i),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<int, TableColumnWidth> _buildColumnWidths(double maxWidth) {
    final baseWidth = maxWidth < 600 ? 80.0 : 100.0;
    return {
      0: FixedColumnWidth(baseWidth),
      for (int i = 0; i < sizes.length; i++)
        (i + 1): FixedColumnWidth(baseWidth * 0.8),
    };
  }

  Widget _buildNoteField(double maxWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth - 32),
        child: TextField(
          controller: noteController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
            contentPadding: const EdgeInsets.all(16),
            labelText: 'Note',
          ),
        ),
      ),
    );
  }

  Widget _buildTotalQtyField(double maxWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth - 32),
        child: TextField(
          readOnly: true,
          controller: TextEditingController(text: totalQty.toString()),
          decoration: InputDecoration(
            border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
            contentPadding: const EdgeInsets.all(16),
            labelText: 'Total Qty',
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(double maxWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth - 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildAddButton()),
            const SizedBox(width: 16),
            Expanded(child: _buildCloseButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      height: 45,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: totalQty > 0 ? AppColors.primaryColor : Colors.grey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: totalQty > 0 ? _submitOrder : null,
      ),
    );
  }

  Widget _buildCloseButton() {
    return SizedBox(
      height: 45,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.close, color: AppColors.primaryColor),
        label: const Text(
          'Close',
          style: TextStyle(fontSize: 16, color: AppColors.primaryColor),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.primaryColor, width: 2),
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  TableRow _buildPriceRow(
    String label,
    Map<String, double> sizePriceMap,
    FontWeight weight,
  ) {
    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(label, style: TextStyle(fontWeight: weight)),
          ),
        ),
        ...sizes.map((size) {
          final price = sizePriceMap[size] ?? 0.0;
          return TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Center(
              child: Text(
                price.toStringAsFixed(0),
                style: TextStyle(fontWeight: weight),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 236, 212, 204),
      ),
      children: [
        const TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: _TableHeaderCell(),
        ),
        ...sizes
            .map(
              (size) => TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Center(
                  child: Text(
                    size,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  TableRow _buildQuantityRow(String color, int i) {
    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                GestureDetector(
                  child: Icon(Icons.copy_all, size: 12),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Text('Select an Action'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  final firstQty =
                                      controllers[color]?.values.first.text;
                                  for (var size in sizes) {
                                    controllers[color]?[size]?.text =
                                        firstQty ?? '0';
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  margin: EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Copy Qty in shade only',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  List<String> copiedRow = [];
                                  for (var size in sizes) {
                                    final qty =
                                        controllers[color]?[size]?.text ?? '0';
                                    copiedRow.add(qty);
                                  }
                                  _copiedRow = copiedRow;
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  margin: EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Copy Row',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  for (int j = 0; j < sizes.length; j++) {
                                    controllers[color]?[sizes[j]]?.text =
                                        _copiedRow[j];
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Paste Row',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '$color ',
                    style: TextStyle(
                      color: _getColorCode(color),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ...sizes.map((size) {
          final controller = controllers[color]?[size];
          final originalQty =
              catalogItems
                  .firstWhere(
                    (item) => item.shadeName == color && item.sizeName == size,
                    orElse:
                        () => CatalogItem(
                          styleCode: styleCode,
                          shadeName: color,
                          sizeName: size,
                          clQty: 0,
                          mrp: sizeMrpMap[size] ?? 0,
                          wsp: sizeWspMap[size] ?? 0,
                        ),
                  )
                  .clQty;

          return TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintText: originalQty > 0 ? originalQty.toString() : '0',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // Future<void> _submitOrder() async {
  //   List<Future> apiCalls = [];

  //   for (var colorEntry in controllers.entries) {
  //     String color = colorEntry.key;
  //     for (var sizeEntry in colorEntry.value.entries) {
  //       String size = sizeEntry.key;
  //       String qty = sizeEntry.value.text;
  //       if (qty.isNotEmpty && int.tryParse(qty) != null && int.parse(qty) > 0) {
  //         final payload = {
  //           "userId": userId,
  //           "coBrId": coBrId,
  //           "fcYrId": fcYrId,
  //           "data": {
  //             "designcode": styleCode,
  //             "mrp": sizeMrpMap[size]?.toStringAsFixed(0) ?? '0',
  //             "WSP": sizeWspMap[size]?.toStringAsFixed(0) ?? '0',
  //             "size": size,
  //             "TotQty": totalQty.toString(),
  //             "Note": noteController.text,
  //             "color": color,
  //             "Qty": qty,
  //             "cobrid": coBrId,
  //             "user": userId.toLowerCase(),
  //             "barcode": "",
  //           },
  //           "typ": 0,
  //         };

  //         apiCalls.add(
  //           http.post(
  //             Uri.parse(
  //               '${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails',
  //             ),
  //             headers: {'Content-Type': 'application/json'},
  //             body: jsonEncode(payload),
  //           ),
  //         );
  //       }
  //     }
  //   }

  //   try {
  //     final responses = await Future.wait(apiCalls);
  //     if (responses.every((r) => r.statusCode == 200)) {
  //       if (mounted) {
  //         showDialog(
  //           context: context,
  //           builder: (_) => AlertDialog(
  //             title: const Text("Success"),
  //             content: const Text("Booking submitted."),
  //             actions: [
  //               TextButton(
  //                 onPressed: () {
  //                   Navigator.pop(context);
  //                   Navigator.pop(context);
  //                   widget.onSuccess();
  //                 },
  //                 child: const Text("OK"),
  //               ),
  //             ],
  //           ),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       showDialog(
  //         context: context,
  //         builder: (_) => AlertDialog(
  //           title: const Text("Error"),
  //           content: Text("Failed to submit: $e"),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: const Text("OK"),
  //             ),
  //           ],
  //         ),
  //       );
  //     }
  //   }
  // }

  Future<void> _submitOrder() async {
    List<Future> apiCalls = [];

    for (var colorEntry in controllers.entries) {
      String color = colorEntry.key;
      for (var sizeEntry in colorEntry.value.entries) {
        String size = sizeEntry.key;
        String qty = sizeEntry.value.text;

        if (qty.isNotEmpty && int.tryParse(qty) != null && int.parse(qty) > 0) {
          if (!isEdit) {
            // Normal mode - API call
            final payload = {
              "userId": userId,
              "coBrId": coBrId,
              "fcYrId": fcYrId,
              "data": {
                "designcode": styleCode,
                "mrp": sizeMrpMap[size]?.toStringAsFixed(0) ?? '0',
                "WSP": sizeWspMap[size]?.toStringAsFixed(0) ?? '0',
                "size": size,
                "TotQty": totalQty.toString(),
                "Note": noteController.text,
                "color": color,
                "Qty": qty,
                "cobrid": coBrId,
                "user": userId.toLowerCase(),
                "barcode": "",
              },
              "typ": 0,
            };

            debugPrint(widget.type);
            debugPrint(widget.type);
            debugPrint(widget.type);
            debugPrint(widget.type);

            if (widget.type == Constants.packing) {
              apiCalls.add(
                http.post(
                  Uri.parse(
                    '${AppConstants.BASE_URL}/orderBooking/InsertPackingCart',
                  ),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(payload),
                ),
              );
            } else {
              apiCalls.add(
                http.post(
                  Uri.parse(
                    '${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails',
                  ),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(payload),
                ),
              );
            }
          }
        }
      }
    }

    if (isEdit) {
      // Build shades and sizes list
      final sizes = controllers.values.first.keys.toList();
      final shades = controllers.keys.toList();

      // Build matrix
      final matrix =
          shades.map((shade) {
            return sizes.map((size) {
              final qty = controllers[shade]?[size]?.text ?? '0';
              final mrp = sizeMrpMap[size]?.toStringAsFixed(0) ?? '0';
              final wsp = sizeWspMap[size]?.toStringAsFixed(0) ?? '0';
              final stock = '0';
              return '$mrp,$wsp,$qty,$stock';
            }).toList();
          }).toList();

      final catalog = Catalog(
        itemSubGrpKey: '',
        itemSubGrpName: '',
        itemKey: '',
        itemName: '',
        brandKey: '',
        brandName: '',
        styleKey: '',
        styleCode: styleCode,
        shadeKey: '',
        shadeName: shades.join(','),
        styleSizeId: '',
        sizeName: sizes.join(','),
        mrp: 0.0,
        wsp: 0.0,
        onlyMRP: 0.0,
        clqty: 0,
        total: totalQty,
        fullImagePath: '',
        remark: noteController.text,
        imageId: '',
        sizeDetails: '',
        sizeDetailsWithoutWSp: '',
        sizeWithMrp: '',
        styleCodeWithcount: styleCode,
        onlySizes: sizes.join(','),
        sizeWithWsp: '',
        createdDate: '',
        shadeImages: '',
        upcoming_Stk: '0',
        barcode: '',
      );

      final newData = CatalogOrderData(
        catalog: catalog,
        orderMatrix: OrderMatrix(sizes: sizes, matrix: matrix, shades: shades),
      );

      EditOrderData.data.add(newData);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => EditOrderScreen(docId: "-1")),
      );
    } else {
      try {
        final responses = await Future.wait(apiCalls);
        if (responses.every((r) => r.statusCode == 200)) {
          if (mounted) {
            showDialog(
              context: context,
              builder:
                  (_) => AlertDialog(
                    title: const Text("Success"),
                    content: const Text("Booking submitted."),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                          widget.onSuccess();
                        },
                        child: const Text("OK"),
                      ),
                    ],
                  ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text("Error"),
                  content: Text("Failed to submit: $e"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        }
      }
    }
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      child: CustomPaint(
        painter: _DiagonalLinePainter(),
        child: const Stack(
          children: [
            Positioned(
              left: 12,
              top: 20,
              child: Text(
                'Shade',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 20,
              child: Text(
                'Size',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.shade400
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PriceTagPaint extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint =
        Paint()
          ..color = AppColors.primaryColor
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.fill;

    Path path = Path();

    path
      ..moveTo(0, size.height * .5)
      ..lineTo(size.width * .13, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * .13, size.height)
      ..lineTo(0, size.height * .5)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
