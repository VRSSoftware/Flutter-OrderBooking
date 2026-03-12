// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter/services.dart';
// import 'package:vrs_erp/constants/app_constants.dart';
// import 'package:vrs_erp/models/CatalogOrderData.dart';
// import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_data.dart';

// class TransactionTab3 extends StatefulWidget {
//   const TransactionTab3({super.key});

//   @override
//   State<TransactionTab3> createState() => _TransactionTab3State();
// }

// class _TransactionTab3State extends State<TransactionTab3> {
//   final Map<String, Map<String, Map<String, TextEditingController>>>
//   controllersMap = {};
//   final Map<String, List<String>> copiedRowsMap = {};
//   final Map<String, List<String>> sizesMap = {};
//   final Map<String, Map<String, double>> sizeMrpMap = {};
//   final Map<String, Map<String, double>> sizeWspMap = {};
//   final Map<String, List<String>> colorsMap = {};
//   final int maxSizes = 10; // Adjust based on maximum sizes

//   @override
//   void initState() {
//     super.initState();
//     _initializeData();
//   }

//   void _initializeData() {
//     for (var order in EditOrderData.data) {
//       final styleKey = order.catalog.styleKey;
//       final shades = order.orderMatrix.shades;
//       final sizes = order.orderMatrix.sizes;

//       sizesMap[styleKey] = sizes;
//       colorsMap[styleKey] = shades;
//       sizeMrpMap[styleKey] = {};
//       sizeWspMap[styleKey] = {};
//       controllersMap.putIfAbsent(styleKey, () => {});
//       for (var shade in shades) {
//         controllersMap[styleKey]!.putIfAbsent(shade, () => {});
//         for (var size in sizes) {
//           final value = _getMatrixValue(order, shade, size);
//           controllersMap[styleKey]![shade]![size] = TextEditingController(
//             text: value['qty'].toString(),
//           );
//           sizeMrpMap[styleKey]![size] = double.tryParse(value['mrp']) ?? 0;
//           sizeWspMap[styleKey]![size] = double.tryParse(value['wsp']) ?? 0;
//         }
//       }
//     }
//   }

//   Map<String, dynamic> _getMatrixValue(
//     CatalogOrderData order,
//     String shade,
//     String size,
//   ) {
//     final shadeIndex = order.orderMatrix.shades.indexOf(shade);
//     final sizeIndex = order.orderMatrix.sizes.indexOf(size);

//     if (shadeIndex < 0 || sizeIndex < 0) {
//       return {'mrp': '0', 'wsp': '0', 'qty': '0', 'stock': '0'};
//     }

//     final matrixEntry = order.orderMatrix.matrix[shadeIndex][sizeIndex];
//     final parts = matrixEntry.split(',');
//     if (parts.length < 4) {
//       return {' three': '0', 'wsp': '0', 'qty': '0', 'stock': '0'};
//     }

//     return {
//       'mrp': parts[0],
//       'wsp': parts[1],
//       'qty': parts[2],
//       'stock': parts[3],
//     };
//   }

//   void _setQuantity(String styleKey, String shade, String size, String value) {
//     final newQty = int.tryParse(value.isEmpty ? '0' : value) ?? 0;
//     if (newQty < 0) return;
//     setState(() {
//       final order = EditOrderData.data.firstWhere(
//         (o) => o.catalog.styleKey == styleKey,
//       );
//       final shadeIndex = order.orderMatrix.shades.indexOf(shade);
//       final sizeIndex = order.orderMatrix.sizes.indexOf(size);
//       if (shadeIndex >= 0 && sizeIndex >= 0) {
//         final parts = order.orderMatrix.matrix[shadeIndex][sizeIndex].split(
//           ',',
//         );
//         if (parts.length >= 4) {
//           parts[2] = newQty.toString();
//           order.orderMatrix.matrix[shadeIndex][sizeIndex] = parts.join(',');
//         }
//       }
//       controllersMap[styleKey]?[shade]?[size]?.text = newQty.toString();
//     });
//   }

//   int getTotalQty(String styleKey) {
//     int total = 0;
//     final order = EditOrderData.data.firstWhere(
//       (o) => o.catalog.styleKey == styleKey,
//     );
//     if (order == null) return 0;
//     for (var shade in order.orderMatrix.shades) {
//       for (var size in order.orderMatrix.sizes) {
//         final value = _getMatrixValue(order, shade, size);
//         total += int.tryParse(value['qty']) ?? 0;
//       }
//     }
//     return total;
//   }

//   int getTotalStock(String styleKey) {
//     int total = 0;
//     final order = EditOrderData.data.firstWhere(
//       (o) => o.catalog.styleKey == styleKey,
//     );
//     if (order == null) return 0;
//     for (var shade in order.orderMatrix.shades) {
//       for (var size in order.orderMatrix.sizes) {
//         final value = _getMatrixValue(order, shade, size);
//         total += int.tryParse(value['stock']) ?? 0;
//       }
//     }
//     return total;
//   }

//   double getTotalAmount(String styleKey) {
//     double total = 0;
//     final order = EditOrderData.data.firstWhere(
//       (o) => o.catalog.styleKey == styleKey,
//     );
//     if (order == null) return 0;
//     for (var shade in order.orderMatrix.shades) {
//       for (var size in order.orderMatrix.sizes) {
//         final value = _getMatrixValue(order, shade, size);
//         final wsp = double.tryParse(value['wsp']) ?? 0;
//         final qty = int.tryParse(value['qty']) ?? 0;
//         total += wsp * qty;
//       }
//     }
//     return total;
//   }

//   void _copyQtyInAllShade(String styleKey) {
//     final order = EditOrderData.data.firstWhere(
//       (o) => o.catalog.styleKey == styleKey,
//     );
//     if (order == null) return;
//     final firstShade = order.orderMatrix.shades.first;
//     final sizes = order.orderMatrix.sizes;
//     setState(() {
//       for (var size in sizes) {
//         final firstQty =
//             controllersMap[styleKey]?[firstShade]?[size]?.text ?? '0';
//         for (var shade in order.orderMatrix.shades) {
//           controllersMap[styleKey]?[shade]?[size]?.text = firstQty;
//           _setQuantity(styleKey, shade, size, firstQty);
//         }
//       }
//     });
//   }

//   void _copySizeQtyInAllShade(String styleKey) {
//     final order = EditOrderData.data.firstWhere(
//       (o) => o.catalog.styleKey == styleKey,
//     );
//     if (order == null) return;
//     final shades = order.orderMatrix.shades;
//     final sizes = order.orderMatrix.sizes;
//     setState(() {
//       for (var shade in shades) {
//         for (var size in sizes) {
//           final qty =
//               controllersMap[styleKey]?[shades.first]?[size]?.text ?? '0';
//           controllersMap[styleKey]?[shade]?[size]?.text = qty;
//           _setQuantity(styleKey, shade, size, qty);
//         }
//       }
//     });
//   }

//   void _copySizeQtyToOtherStyles(String sourceStyleKey) {
//     final order = EditOrderData.data.firstWhere(
//       (o) => o.catalog.styleKey == sourceStyleKey,
//     );
//     if (order == null) return;
//     final sizes = order.orderMatrix.sizes;
//     setState(() {
//       for (var targetOrder in EditOrderData.data) {
//         if (targetOrder.catalog.styleKey == sourceStyleKey) continue;
//         final targetShades = targetOrder.orderMatrix.shades;
//         for (var shade in targetShades) {
//           for (var size in sizes) {
//             if (targetOrder.orderMatrix.sizes.contains(size)) {
//               final qty =
//                   controllersMap[sourceStyleKey]?[order
//                           .orderMatrix
//                           .shades
//                           .first]?[size]
//                       ?.text ??
//                   '0';
//               controllersMap[targetOrder.catalog.styleKey]?[shade]?[size]
//                   ?.text = qty;
//               _setQuantity(targetOrder.catalog.styleKey, shade, size, qty);
//             }
//           }
//         }
//       }
//     });
//   }

//   void _deleteCatalog(CatalogOrderData catalog) {
//     setState(() {
//       EditOrderData.data.removeWhere(
//         (order) => order.catalog.styleKey == catalog.catalog.styleKey,
//       );
//       controllersMap.remove(catalog.catalog.styleKey);
//       copiedRowsMap.remove(catalog.catalog.styleKey);
//       sizesMap.remove(catalog.catalog.styleKey);
//       sizeMrpMap.remove(catalog.catalog.styleKey);
//       sizeWspMap.remove(catalog.catalog.styleKey);
//       colorsMap.remove(catalog.catalog.styleKey);
//     });
//   }

//   Color _getColorCode(String color) {
//     // Placeholder: Map color names to Color objects
//     return Colors.black;
//   }

//   String _getImageUrl(CatalogOrderData catalog) {
//     return catalog.catalog.fullImagePath.contains("http")
//         ? catalog.catalog.fullImagePath
//         : '${AppConstants.BASE_URL}/images${catalog.catalog.fullImagePath}';
//   }

//   Widget _buildItemBookingSection(
//     BuildContext context,
//     CatalogOrderData catalog,
//   ) {
//     final styleKey = catalog.catalog.styleKey;
//     if (catalog.orderMatrix.shades.isEmpty) {
//       return const Center(child: Text("Empty"));
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               margin: const EdgeInsets.only(left: 16, top: 8),
//               width: 100,
//               height: 100,
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(12),
//                 child: Image.network(
//                   _getImageUrl(catalog),
//                   fit: BoxFit.contain,
//                   errorBuilder: (context, error, stackTrace) {
//                     return Container(
//                       color: Colors.grey.shade300,
//                       child: const Center(child: Icon(Icons.error)),
//                     );
//                   },
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 8),
//                           child: Text(
//                             catalog.catalog.styleCode,
//                             style: GoogleFonts.poppins(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.copy_outlined, size: 20),
//                         onPressed: () {
//                           showDialog(
//                             context: context,
//                             builder: (BuildContext dialogContext) {
//                               return AlertDialog(
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 titlePadding: EdgeInsets.zero,
//                                 contentPadding: EdgeInsets.zero,
//                                 title: Container(
//                                   width: double.infinity,
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 16,
//                                     vertical: 12,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: Colors.grey.shade200,
//                                     borderRadius: const BorderRadius.vertical(
//                                       top: Radius.circular(12),
//                                     ),
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       const Expanded(
//                                         child: Text(
//                                           'Select an Action',
//                                           style: TextStyle(
//                                             fontSize: 18,
//                                             fontWeight: FontWeight.w600,
//                                           ),
//                                         ),
//                                       ),
//                                       IconButton(
//                                         icon: const Icon(Icons.close),
//                                         onPressed: () {
//                                           Navigator.of(context).pop();
//                                         },
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 content: Padding(
//                                   padding: const EdgeInsets.all(16),
//                                   child: Column(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       GestureDetector(
//                                         onTap: () {
//                                           Navigator.of(dialogContext).pop();
//                                           _copyQtyInAllShade(styleKey);
//                                         },
//                                         child: Container(
//                                           width: double.infinity,
//                                           padding: const EdgeInsets.symmetric(
//                                             vertical: 12,
//                                           ),
//                                           margin: const EdgeInsets.only(
//                                             bottom: 10,
//                                           ),
//                                           decoration: BoxDecoration(
//                                             color: Colors.blue,
//                                             borderRadius: BorderRadius.circular(
//                                               8,
//                                             ),
//                                           ),
//                                           alignment: Alignment.center,
//                                           child: const Text(
//                                             'Copy Qty in All Shade',
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                       GestureDetector(
//                                         onTap: () {
//                                           Navigator.of(dialogContext).pop();
//                                           _copySizeQtyInAllShade(styleKey);
//                                         },
//                                         child: Container(
//                                           width: double.infinity,
//                                           padding: const EdgeInsets.symmetric(
//                                             vertical: 12,
//                                           ),
//                                           margin: const EdgeInsets.only(
//                                             bottom: 10,
//                                           ),
//                                           decoration: BoxDecoration(
//                                             color: Colors.blue,
//                                             borderRadius: BorderRadius.circular(
//                                               8,
//                                             ),
//                                           ),
//                                           alignment: Alignment.center,
//                                           child: const Text(
//                                             'Copy Size Qty in All Shade',
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                       GestureDetector(
//                                         onTap: () {
//                                           Navigator.of(dialogContext).pop();
//                                           _copySizeQtyToOtherStyles(styleKey);
//                                         },
//                                         child: Container(
//                                           width: double.infinity,
//                                           padding: const EdgeInsets.symmetric(
//                                             vertical: 12,
//                                           ),
//                                           decoration: BoxDecoration(
//                                             color: Colors.green,
//                                             borderRadius: BorderRadius.circular(
//                                               8,
//                                             ),
//                                           ),
//                                           alignment: Alignment.center,
//                                           child: const Text(
//                                             'Copy Size Qty to other Styles',
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           );
//                         },
//                       ),
//                       IconButton(
//                         icon: const Icon(
//                           Icons.delete_outline,
//                           color: Colors.red,
//                           size: 24,
//                         ),
//                         onPressed: () => _deleteCatalog(catalog),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 8),
//                     child: Row(
//                       children: [
//                         Text(
//                           'Total Qty: ${getTotalQty(styleKey)}',
//                           style: GoogleFonts.roboto(
//                             fontSize: 14,
//                             fontWeight: FontWeight.normal,
//                             color: Colors.black,
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Text(
//                           'Total Stock: ${getTotalStock(styleKey)}',
//                           style: GoogleFonts.roboto(
//                             fontSize: 14,
//                             fontWeight: FontWeight.normal,
//                             color: Colors.black,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     child: Text(
//                       'Amt: ${getTotalAmount(styleKey).toStringAsFixed(0)}',
//                       style: GoogleFonts.roboto(
//                         fontSize: 14,
//                         fontWeight: FontWeight.normal,
//                         color: Colors.black,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         _buildCatalogTable(catalog),
//       ],
//     );
//   }

//   Widget _buildCatalogTable(CatalogOrderData catalog) {
//     final sizes = catalog.orderMatrix.sizes;
//     final screenWidth = MediaQuery.of(context).size.width;
//     final baseTableWidth = 100 + (80 * sizes.length);
//     final requiredTableWidth =
//         screenWidth > baseTableWidth ? screenWidth : baseTableWidth.toDouble();

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade500),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: ConstrainedBox(
//           constraints: BoxConstraints(minWidth: requiredTableWidth),
//           child: SingleChildScrollView(
//             scrollDirection: Axis.vertical,
//             child: Table(
//               border: TableBorder.symmetric(
//                 inside: BorderSide(color: Colors.grey.shade400, width: 1),
//               ),
//               columnWidths: _buildColumnWidths(),
//               children: [
//                 _buildPriceRow(
//                   "MRP",
//                   sizeMrpMap[catalog.catalog.styleKey] ?? {},
//                   FontWeight.w600,
//                   sizes,
//                 ),
//                 _buildPriceRow(
//                   "WSP",
//                   sizeWspMap[catalog.catalog.styleKey] ?? {},
//                   FontWeight.w400,
//                   sizes,
//                 ),
//                 _buildHeaderRow(catalog.catalog.styleKey, sizes),
//                 for (
//                   var i = 0;
//                   i < (colorsMap[catalog.catalog.styleKey]?.length ?? 0);
//                   i++
//                 )
//                   _buildQuantityRow(
//                     catalog,
//                     colorsMap[catalog.catalog.styleKey]![i],
//                     i,
//                     sizes,
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Map<int, TableColumnWidth> _buildColumnWidths() {
//     const baseWidth = 100.0;
//     return {
//       0: const FixedColumnWidth(baseWidth),
//       for (int i = 0; i < maxSizes; i++)
//         (i + 1): const FixedColumnWidth(baseWidth * 0.8),
//     };
//   }

//   TableRow _buildPriceRow(
//     String label,
//     Map<String, double> sizePriceMap,
//     FontWeight weight,
//     List<String> sizes,
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
//         ...List.generate(maxSizes, (index) {
//           if (index < sizes.length) {
//             final size = sizes[index];
//             final price = sizePriceMap[size] ?? 0.0;
//             return TableCell(
//               verticalAlignment: TableCellVerticalAlignment.middle,
//               child: Center(
//                 child: Text(
//                   price.toStringAsFixed(0),
//                   style: TextStyle(fontWeight: weight),
//                 ),
//               ),
//             );
//           } else {
//             return const TableCell(
//               verticalAlignment: TableCellVerticalAlignment.middle,
//               child: Center(child: Text('')),
//             );
//           }
//         }),
//       ],
//     );
//   }

//   TableRow _buildHeaderRow(String styleKey, List<String> sizes) {
//     return TableRow(
//       decoration: const BoxDecoration(
//         color: Color.fromARGB(255, 236, 212, 204),
//       ),
//       children: [
//         const TableCell(
//           verticalAlignment: TableCellVerticalAlignment.middle,
//           child: _TableHeaderCell(),
//         ),
//         ...List.generate(maxSizes, (index) {
//           if (index < sizes.length) {
//             return TableCell(
//               verticalAlignment: TableCellVerticalAlignment.middle,
//               child: Center(
//                 child: Text(
//                   sizes[index],
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             );
//           } else {
//             return const TableCell(
//               verticalAlignment: TableCellVerticalAlignment.middle,
//               child: Center(child: Text('')),
//             );
//           }
//         }),
//       ],
//     );
//   }

//   TableRow _buildQuantityRow(
//     CatalogOrderData catalog,
//     String color,
//     int i,
//     List<String> sizes,
//   ) {
//     final styleKey = catalog.catalog.styleKey;
//     return TableRow(
//       children: [
//         TableCell(
//           verticalAlignment: TableCellVerticalAlignment.middle,
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 GestureDetector(
//                   child: const Icon(Icons.copy_all, size: 12),
//                   onTap: () {
//                     showDialog(
//                       context: context,
//                       builder: (BuildContext context) {
//                         return AlertDialog(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           titlePadding: EdgeInsets.zero,
//                           contentPadding: EdgeInsets.zero,
//                           title: Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 12,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.grey.shade200,
//                               borderRadius: const BorderRadius.vertical(
//                                 top: Radius.circular(12),
//                               ),
//                             ),
//                             child: Row(
//                               children: [
//                                 const Expanded(
//                                   child: Text(
//                                     'Select an Action',
//                                     style: TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ),
//                                 IconButton(
//                                   icon: const Icon(Icons.close),
//                                   onPressed: () {
//                                     Navigator.of(context).pop();
//                                   },
//                                 ),
//                               ],
//                             ),
//                           ),
//                           content: Padding(
//                             padding: const EdgeInsets.all(16),
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 GestureDetector(
//                                   onTap: () {
//                                     Navigator.of(context).pop();
//                                     final firstQty =
//                                         controllersMap[styleKey]?[color]
//                                             ?.values
//                                             .first
//                                             .text ??
//                                         '0';
//                                     for (var size in sizesMap[styleKey] ?? []) {
//                                       controllersMap[styleKey]?[color]?[size]
//                                           ?.text = firstQty;
//                                       _setQuantity(
//                                         styleKey,
//                                         color,
//                                         size,
//                                         firstQty,
//                                       );
//                                     }
//                                     setState(() {});
//                                   },
//                                   child: Container(
//                                     width: double.infinity,
//                                     padding: const EdgeInsets.symmetric(
//                                       vertical: 12,
//                                     ),
//                                     margin: const EdgeInsets.only(bottom: 10),
//                                     decoration: BoxDecoration(
//                                       color: Colors.blue,
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     alignment: Alignment.center,
//                                     child: const Text(
//                                       'Copy Qty in shade only',
//                                       style: TextStyle(color: Colors.white),
//                                     ),
//                                   ),
//                                 ),
//                                 GestureDetector(
//                                   onTap: () {
//                                     Navigator.of(context).pop();
//                                     List<String> copiedRow = [];
//                                     for (var size in sizesMap[styleKey] ?? []) {
//                                       final qty =
//                                           controllersMap[styleKey]?[color]?[size]
//                                               ?.text ??
//                                           '0';
//                                       copiedRow.add(qty);
//                                     }
//                                     copiedRowsMap[styleKey] = copiedRow;
//                                     setState(() {});
//                                   },
//                                   child: Container(
//                                     width: double.infinity,
//                                     padding: const EdgeInsets.symmetric(
//                                       vertical: 12,
//                                     ),
//                                     margin: const EdgeInsets.only(bottom: 10),
//                                     decoration: BoxDecoration(
//                                       color: Colors.blue,
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     alignment: Alignment.center,
//                                     child: const Text(
//                                       'Copy Row',
//                                       style: TextStyle(color: Colors.white),
//                                     ),
//                                   ),
//                                 ),
//                                 GestureDetector(
//                                   onTap: () {
//                                     Navigator.of(context).pop();
//                                     final copiedRow =
//                                         copiedRowsMap[styleKey] ?? [];
//                                     for (
//                                       int j = 0;
//                                       j < (sizesMap[styleKey]?.length ?? 0);
//                                       j++
//                                     ) {
//                                       controllersMap[styleKey]?[color]?[sizesMap[styleKey]![j]]
//                                           ?.text = copiedRow[j];
//                                       _setQuantity(
//                                         styleKey,
//                                         color,
//                                         sizesMap[styleKey]![j],
//                                         copiedRow[j],
//                                       );
//                                     }
//                                     setState(() {});
//                                   },
//                                   child: Container(
//                                     width: double.infinity,
//                                     padding: const EdgeInsets.symmetric(
//                                       vertical: 12,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color: Colors.green,
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     alignment: Alignment.center,
//                                     child: const Text(
//                                       'Paste Row',
//                                       style: TextStyle(color: Colors.white),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//                 const SizedBox(width: 6),
//                 Flexible(
//                   child: Text(
//                     color,
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
//         ...List.generate(maxSizes, (index) {
//           if (index < sizes.length) {
//             final size = sizes[index];
//             final controller = controllersMap[styleKey]?[color]?[size];
//             final originalQty =
//                 int.tryParse(_getMatrixValue(catalog, color, size)['qty']) ?? 0;

//             return TableCell(
//               verticalAlignment: TableCellVerticalAlignment.middle,
//               child: Padding(
//                 padding: const EdgeInsets.all(4.0),
//                 child: TextField(
//                   controller: controller,
//                   keyboardType: TextInputType.number,
//                   textAlign: TextAlign.center,
//                   decoration: InputDecoration(
//                     contentPadding: const EdgeInsets.symmetric(vertical: 8),
//                     hintText: originalQty > 0 ? originalQty.toString() : '0',
//                     hintStyle: const TextStyle(color: Colors.grey),
//                     border: InputBorder.none,
//                   ),
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     LengthLimitingTextInputFormatter(4),
//                   ],
//                   onChanged:
//                       (value) => _setQuantity(styleKey, color, size, value),
//                 ),
//               ),
//             );
//           } else {
//             return const TableCell(
//               verticalAlignment: TableCellVerticalAlignment.middle,
//               child: Center(child: Text('')),
//             );
//           }
//         }),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Expanded(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(12.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 10),
//                 ...EditOrderData.data.map((catalogOrder) {
//                   return Column(
//                     children: [
//                       _buildItemBookingSection(context, catalogOrder),
//                       const Divider(),
//                     ],
//                   );
//                 }).toList(),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/CatalogOrderData.dart';
import 'package:vrs_erp/models/catalog.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_data.dart';
import 'package:vrs_erp/catalog/imagezoom.dart';

// Add this color class at the top
class TableColors {
  static const Color headerBg = Color(0xFF2C3E50); // Dark blue-grey
  static const Color headerText = Colors.white;
  static const Color priceRowBg = Color(0xFFF8F9FA); // Very light grey
  static const Color evenRowBg = Colors.white;
  static const Color oddRowBg = Color(0xFFF8F9FA); // Alternating row colors
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color accentColor = Color(0xFF3498DB); // Blue accent
  static const Color totalRowBg = Color(0xFFE8F4FD); // Light blue for totals
}

class TransactionTab3 extends StatefulWidget {
  final VoidCallback? onUpdate;

  const TransactionTab3({super.key, this.onUpdate});

  @override
  State<TransactionTab3> createState() => _TransactionTab3State();
}

class _TransactionTab3State extends State<TransactionTab3> {
  final Map<String, Map<String, Map<String, TextEditingController>>>
  controllersMap = {};
  final Map<String, List<String>> copiedRowsMap = {};
  final Map<String, List<String>> sizesMap = {};
  final Map<String, Map<String, double>> sizeMrpMap = {};
  final Map<String, Map<String, double>> sizeWspMap = {};
  final Map<String, List<String>> colorsMap = {};
  final int maxSizes = 10;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    for (var order in EditOrderData.data) {
      final styleKey = order.catalog.styleKey;
      final shades = order.orderMatrix.shades;
      final sizes = order.orderMatrix.sizes;

      sizesMap[styleKey] = sizes;
      colorsMap[styleKey] = shades;
      sizeMrpMap[styleKey] = {};
      sizeWspMap[styleKey] = {};
      controllersMap.putIfAbsent(styleKey, () => {});
      for (var shade in shades) {
        controllersMap[styleKey]!.putIfAbsent(shade, () => {});
        for (var size in sizes) {
          final value = _getMatrixValue(order, shade, size);
          controllersMap[styleKey]![shade]![size] = TextEditingController(
            text: value['qty'].toString(),
          );
          sizeMrpMap[styleKey]![size] = double.tryParse(value['mrp']) ?? 0;
          sizeWspMap[styleKey]![size] = double.tryParse(value['wsp']) ?? 0;
        }
      }
    }
  }

  Map<String, dynamic> _getMatrixValue(
    CatalogOrderData order,
    String shade,
    String size,
  ) {
    final shadeIndex = order.orderMatrix.shades.indexOf(shade);
    final sizeIndex = order.orderMatrix.sizes.indexOf(size);

    if (shadeIndex < 0 || sizeIndex < 0) {
      return {'mrp': '0', 'wsp': '0', 'qty': '0', 'stock': '0'};
    }

    final matrixEntry = order.orderMatrix.matrix[shadeIndex][sizeIndex];
    final parts = matrixEntry.split(',');
    if (parts.length < 4) {
      return {'mrp': '0', 'wsp': '0', 'qty': '0', 'stock': '0'};
    }

    return {
      'mrp': parts[0],
      'wsp': parts[1],
      'qty': parts[2],
      'stock': parts[3],
    };
  }

  void _showStyleCopyDialog(BuildContext context, String styleKey) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          titlePadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          title: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select an Action',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    _copyQtyInAllShade(styleKey);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Copy Qty in All Shade',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    _copySizeQtyInAllShade(styleKey);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Copy Size Qty in All Shade',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    _copySizeQtyToOtherStyles(styleKey);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Copy Size Qty to other Styles',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _setQuantity(String styleKey, String shade, String size, String value) {
    final newQty = int.tryParse(value.isEmpty ? '0' : value) ?? 0;
    if (newQty < 0) return;

    setState(() {
      final order = EditOrderData.data.firstWhere(
        (o) => o.catalog.styleKey == styleKey,
      );
      final shadeIndex = order.orderMatrix.shades.indexOf(shade);
      final sizeIndex = order.orderMatrix.sizes.indexOf(size);
      if (shadeIndex >= 0 && sizeIndex >= 0) {
        final parts = order.orderMatrix.matrix[shadeIndex][sizeIndex].split(
          ',',
        );
        if (parts.length >= 4) {
          parts[2] = newQty.toString();
          order.orderMatrix.matrix[shadeIndex][sizeIndex] = parts.join(',');
        }
      }
      controllersMap[styleKey]?[shade]?[size]?.text = newQty.toString();
    });

    widget.onUpdate?.call();
  }

  int getTotalQty(String styleKey) {
    int total = 0;
    final order = EditOrderData.data.firstWhere(
      (o) => o.catalog.styleKey == styleKey,
    );
    if (order == null) return 0;
    for (var shade in order.orderMatrix.shades) {
      for (var size in order.orderMatrix.sizes) {
        final value = _getMatrixValue(order, shade, size);
        total += int.tryParse(value['qty']) ?? 0;
      }
    }
    return total;
  }

  int getTotalStock(String styleKey) {
    int total = 0;
    final order = EditOrderData.data.firstWhere(
      (o) => o.catalog.styleKey == styleKey,
    );
    if (order == null) return 0;
    for (var shade in order.orderMatrix.shades) {
      for (var size in order.orderMatrix.sizes) {
        final value = _getMatrixValue(order, shade, size);
        total += int.tryParse(value['stock']) ?? 0;
      }
    }
    return total;
  }

  double getTotalAmount(String styleKey) {
    double total = 0;
    final order = EditOrderData.data.firstWhere(
      (o) => o.catalog.styleKey == styleKey,
    );
    if (order == null) return 0;
    for (var shade in order.orderMatrix.shades) {
      for (var size in order.orderMatrix.sizes) {
        final value = _getMatrixValue(order, shade, size);
        final wsp = double.tryParse(value['wsp']) ?? 0;
        final qty = int.tryParse(value['qty']) ?? 0;
        total += wsp * qty;
      }
    }
    return total;
  }

  void _copyQtyInAllShade(String styleKey) {
    final order = EditOrderData.data.firstWhere(
      (o) => o.catalog.styleKey == styleKey,
    );
    if (order == null) return;
    final firstShade = order.orderMatrix.shades.first;
    final sizes = order.orderMatrix.sizes;
    setState(() {
      for (var size in sizes) {
        final firstQty =
            controllersMap[styleKey]?[firstShade]?[size]?.text ?? '0';
        for (var shade in order.orderMatrix.shades) {
          controllersMap[styleKey]?[shade]?[size]?.text = firstQty;
          _setQuantity(styleKey, shade, size, firstQty);
        }
      }
    });
  }

  void _copySizeQtyInAllShade(String styleKey) {
    final order = EditOrderData.data.firstWhere(
      (o) => o.catalog.styleKey == styleKey,
    );
    if (order == null) return;
    final shades = order.orderMatrix.shades;
    final sizes = order.orderMatrix.sizes;
    setState(() {
      for (var shade in shades) {
        for (var size in sizes) {
          final qty =
              controllersMap[styleKey]?[shades.first]?[size]?.text ?? '0';
          controllersMap[styleKey]?[shade]?[size]?.text = qty;
          _setQuantity(styleKey, shade, size, qty);
        }
      }
    });
  }

  void _copySizeQtyToOtherStyles(String sourceStyleKey) {
    final order = EditOrderData.data.firstWhere(
      (o) => o.catalog.styleKey == sourceStyleKey,
    );
    if (order == null) return;
    final sizes = order.orderMatrix.sizes;
    setState(() {
      for (var targetOrder in EditOrderData.data) {
        if (targetOrder.catalog.styleKey == sourceStyleKey) continue;
        final targetShades = targetOrder.orderMatrix.shades;
        for (var shade in targetShades) {
          for (var size in sizes) {
            if (targetOrder.orderMatrix.sizes.contains(size)) {
              final qty =
                  controllersMap[sourceStyleKey]?[order
                          .orderMatrix
                          .shades
                          .first]?[size]
                      ?.text ??
                  '0';
              controllersMap[targetOrder.catalog.styleKey]?[shade]?[size]
                  ?.text = qty;
              _setQuantity(targetOrder.catalog.styleKey, shade, size, qty);
            }
          }
        }
      }
    });
  }

  void _deleteCatalog(CatalogOrderData catalog) {
    setState(() {
      EditOrderData.data.removeWhere(
        (order) => order.catalog.styleKey == catalog.catalog.styleKey,
      );
      controllersMap.remove(catalog.catalog.styleKey);
      copiedRowsMap.remove(catalog.catalog.styleKey);
      sizesMap.remove(catalog.catalog.styleKey);
      sizeMrpMap.remove(catalog.catalog.styleKey);
      sizeWspMap.remove(catalog.catalog.styleKey);
      colorsMap.remove(catalog.catalog.styleKey);
    });
    widget.onUpdate?.call();
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

  String _getImageUrl(CatalogOrderData catalog) {
    return catalog.catalog.fullImagePath.contains("http")
        ? catalog.catalog.fullImagePath
        : '${AppConstants.BASE_URL}/images${catalog.catalog.fullImagePath}';
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: EditOrderData.data.length,
      itemBuilder: (context, index) {
        final catalogOrder = EditOrderData.data[index];
        return Card(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          child: _buildEditStyleCard(catalogOrder),
        );
      },
    );
  }

  Widget _buildEditStyleCard(CatalogOrderData catalogOrder) {
    final styleKey = catalogOrder.catalog.styleKey;
    final catalog = catalogOrder.catalog;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section with image and details
        Padding(
          padding: const EdgeInsets.all(12),
          child: _buildHeaderSection(catalogOrder),
        ),

        const SizedBox(height: 4),

        // Stats in single line
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildStatRow(
                  'Stock',
                  getTotalStock(styleKey).toString(),
                  Icons.inventory,
                  Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatRow(
                  'Qty',
                  getTotalQty(styleKey).toString(),
                  Icons.shopping_bag,
                  Colors.orange.shade700,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatRow(
                  'Amt',
                  '${getTotalAmount(styleKey).toStringAsFixed(0)}',
                  Icons.currency_rupee,
                  Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Enhanced Price Table - FULL WIDTH
        _buildEnhancedPriceTable(catalogOrder),

        
      ],
    );
  }

  Widget _buildHeaderSection(CatalogOrderData catalogOrder) {
    final catalog = catalogOrder.catalog;
    final styleKey = catalog.styleKey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildItemImage(catalog),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Combined Style Code and Details in one container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor.withOpacity(0.08),
                      Colors.white,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Style Code (prominent)
                    // Style Code (prominent)
                    Row(
                      children: [
                      
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            catalog.styleCode,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Copy button - with smaller circular light background
                        Container(
                          margin: const EdgeInsets.only(right: 2),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.copy_outlined,
                              size: 16,
                              color: Colors.blue,
                            ),
                            onPressed:
                                () => _showStyleCopyDialog(context, styleKey),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 18,
                            iconSize: 18,
                          ),
                        ),

                        // Delete button - with smaller circular light background
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 16,
                            ),
                            onPressed:
                                () => _showDeleteDialog(context, catalogOrder),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 18,
                            iconSize: 18,
                          ),
                        ),
                      ],
                    ),

                    // Divider
                    Divider(
                      color: AppColors.primaryColor.withOpacity(0.2),
                      height: 1,
                      thickness: 1,
                    ),

                    const SizedBox(height: 8),

                    // Details in a grid-like layout
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (catalog.itemName.isNotEmpty)
                          _buildCompactDetailChip('Product', catalog.itemName),
                        if (catalog.brandName.isNotEmpty)
                          _buildCompactDetailChip('Brand', catalog.brandName),
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

  Widget _buildItemImage(Catalog catalog) {
    return GestureDetector(
      onDoubleTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ImageZoomScreen(
                  imageUrls: [_getImageUrlFromCatalog(catalog)],
                  initialIndex: 0,
                ),
          ),
        );
      },
      child: Container(
        width: 90,
        height: 85,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: TableColors.borderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            _getImageUrlFromCatalog(catalog),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 24,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'No Image',
                        style: TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _getImageUrlFromCatalog(Catalog catalog) {
    if (catalog.fullImagePath.isEmpty) {
      return '${AppConstants.BASE_URL}/images/NoImage.jpg';
    }

    if (UserSession.onlineImage == '0') {
      final fileName =
          catalog.fullImagePath
              .split('/')
              .last
              .split('\\')
              .last
              .split('?')
              .first;
      return fileName.isEmpty
          ? '${AppConstants.BASE_URL}/images/NoImage.jpg'
          : '${AppConstants.BASE_URL}/images/$fileName';
    } else if (UserSession.onlineImage == '1') {
      return catalog.fullImagePath.contains("http")
          ? catalog.fullImagePath
          : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}';
    }

    return '${AppConstants.BASE_URL}/images/NoImage.jpg';
  }

  Widget _buildCompactDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: TableColors.priceRowBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TableColors.borderColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
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
    );
  }

  // ENHANCED PRICE TABLE - FULL WIDTH
  Widget _buildEnhancedPriceTable(CatalogOrderData catalogOrder) {
    final styleKey = catalogOrder.catalog.styleKey;
    final sizes = catalogOrder.orderMatrix.sizes;
    final shades = catalogOrder.orderMatrix.shades;
    final sizeDetails = _getSizeDetails(catalogOrder);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: TableColors.borderColor),
          bottom: BorderSide(color: TableColors.borderColor),
        ),
        color: Colors.white,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Table(
              border: TableBorder.all(
                color: TableColors.borderColor,
                width: 0.5,
              ),
              columnWidths: _buildColumnWidths(sizes),
              children: [
                // Header row with diagonal cell
                _buildEnhancedHeaderRow(sizes),

                // MRP row
                _buildEnhancedPriceRow('MRP', sizes, sizeDetails, 'mrp'),

                // WSP row
                _buildEnhancedPriceRow('WSP', sizes, sizeDetails, 'wsp'),

                // Shade rows with alternating colors
                ...shades.asMap().entries.map((entry) {
                  final index = entry.key;
                  final shade = entry.value;
                  return _buildEnhancedShadeRow(
                    catalogOrder,
                    shade,
                    sizes,
                    index,
                    styleKey,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, Map<String, dynamic>> _getSizeDetails(
    CatalogOrderData catalogOrder,
  ) {
    final details = <String, Map<String, dynamic>>{};
    for (var i = 0; i < catalogOrder.orderMatrix.sizes.length; i++) {
      final size = catalogOrder.orderMatrix.sizes[i];
      if (sizeMrpMap[catalogOrder.catalog.styleKey]?.containsKey(size) ??
          false) {
        details[size] = {
          'mrp': sizeMrpMap[catalogOrder.catalog.styleKey]![size],
          'wsp': sizeWspMap[catalogOrder.catalog.styleKey]![size],
        };
      }
    }
    return details;
  }

  Map<int, TableColumnWidth> _buildColumnWidths(List<String> sizes) {
    double screenWidth = MediaQuery.of(context).size.width;
    double firstColumnWidth = 140;
    double remainingWidth = screenWidth - firstColumnWidth;
    double sizeColumnWidth =
        remainingWidth / (sizes.length > 0 ? sizes.length : 1);

    if (sizeColumnWidth < 70) {
      sizeColumnWidth = 70;
    }

    return {
      0: FixedColumnWidth(firstColumnWidth),
      for (var i = 0; i < sizes.length; i++)
        i + 1: FixedColumnWidth(sizeColumnWidth),
    };
  }

  TableRow _buildEnhancedHeaderRow(List<String> sizes) {
    return TableRow(
      decoration: BoxDecoration(color: TableColors.headerBg),
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Container(
            height: 50,
            child: CustomPaint(
              painter: _SimpleDiagonalPainter(),
              child: const Stack(
                children: [
                  Positioned(
                    left: 10,
                    top: 22,
                    child: Text(
                      'SHADE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 14,
                    bottom: 22,
                    child: Text(
                      'SIZE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        fontSize: 14,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ...sizes.map(
          (size) => TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  size,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  TableRow _buildEnhancedPriceRow(
    String label,
    List<String> sizes,
    Map<String, Map<String, dynamic>> sizeDetails,
    String key,
  ) {
    return TableRow(
      decoration: BoxDecoration(color: TableColors.priceRowBg),
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Container(
            padding: const EdgeInsets.all(8),
            color: TableColors.accentColor.withOpacity(0.1),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: TableColors.accentColor,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        ...sizes.map(
          (size) => TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: TableColors.borderColor, width: 0.5),
                ),
              ),
              child: Center(
                child: Text(
                  sizeDetails.containsKey(size)
                      ? '${sizeDetails[size]?[key]?.toStringAsFixed(0) ?? '0'}'
                      : '0',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  TableRow _buildEnhancedShadeRow(
    CatalogOrderData catalogOrder,
    String shade,
    List<String> sizes,
    int rowIndex,
    String styleKey,
  ) {
    final isEvenRow = rowIndex % 2 == 0;

    return TableRow(
      decoration: BoxDecoration(
        color: isEvenRow ? TableColors.evenRowBg : TableColors.oddRowBg,
      ),
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: TableColors.borderColor, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                // Copy icon
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => _showShadeCopyOptions(styleKey, shade),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: TableColors.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.copy_all,
                          size: 14,
                          color: TableColors.accentColor,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    shade,
                    style: TextStyle(
                      color: _getColorCode(shade),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        ...sizes.map(
          (size) => TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: TableColors.borderColor, width: 0.5),
                ),
              ),
              child: TextField(
                controller: controllersMap[styleKey]?[shade]?[size],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (_) {
                  _setQuantity(
                    styleKey,
                    shade,
                    size,
                    controllersMap[styleKey]?[shade]?[size]?.text ?? '0',
                  );
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintText: _getMatrixValue(catalogOrder, shade, size)['stock'],
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  // focusedBorder: UnderlineInputBorder(
                  //   borderSide: BorderSide(
                  //     color: TableColors.accentColor,
                  //     width: 1,
                  //   ),
                  // ),
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showShadeCopyOptions(String styleKey, String shade) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Copy Options for $shade',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              _buildCopyOption(
                icon: Icons.copy_all,
                title: 'Copy Qty in shade only',
                description: 'Copy first quantity to all sizes in this shade',
                color: TableColors.accentColor,
                onTap: () {
                  Navigator.pop(context);
                  final firstQty =
                      controllersMap[styleKey]?[shade]?.values.first.text ??
                      '0';
                  for (var size in controllersMap[styleKey]![shade]!.keys) {
                    controllersMap[styleKey]![shade]![size]?.text = firstQty;
                    _setQuantity(styleKey, shade, size, firstQty);
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildCopyOption(
                icon: Icons.copy,
                title: 'Copy Row',
                description: 'Copy this row to clipboard',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  List<String> copiedRow = [];
                  for (var size in sizesMap[styleKey] ?? []) {
                    final qty =
                        controllersMap[styleKey]?[shade]?[size]?.text ?? '0';
                    copiedRow.add(qty);
                  }
                  copiedRowsMap[styleKey] = copiedRow;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Row copied')));
                },
              ),
              const SizedBox(height: 8),
              _buildCopyOption(
                icon: Icons.paste,
                title: 'Paste Row',
                description: 'Paste previously copied row',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  final copiedRow = copiedRowsMap[styleKey] ?? [];
                  if (copiedRow.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No row copied yet')),
                    );
                    return;
                  }
                  for (int j = 0; j < (sizesMap[styleKey]?.length ?? 0); j++) {
                    if (j < copiedRow.length) {
                      controllersMap[styleKey]?[shade]?[sizesMap[styleKey]![j]]
                          ?.text = copiedRow[j];
                      _setQuantity(
                        styleKey,
                        shade,
                        sizesMap[styleKey]![j],
                        copiedRow[j],
                      );
                    }
                  }
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Row pasted')));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCopyOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        description,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteDialog(BuildContext context, CatalogOrderData catalogOrder) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete', style: TextStyle(fontSize: 16)),
            content: Text(
              'Are you sure you want to delete style ${catalogOrder.catalog.styleCode}?',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(fontSize: 14)),
              ),
              TextButton(
                onPressed: () {
                  _deleteCatalog(catalogOrder);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Style ${catalogOrder.catalog.styleCode} removed',
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            ],
          ),
    );
  }
}

// Simple diagonal painter
class _SimpleDiagonalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
