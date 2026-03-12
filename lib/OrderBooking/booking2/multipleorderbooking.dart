// import 'dart:convert';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:vrs_erp/OrderBooking/orderbooking_booknow.dart';
// import 'package:vrs_erp/catalog/imagezoom.dart';
// import 'package:vrs_erp/constants/app_constants.dart';
// import 'package:vrs_erp/models/CartModel.dart';
// import 'package:vrs_erp/models/catalog.dart';

// class CatalogItem {
//   final String styleCode;
//   final String shadeName;
//   final String sizeName;
//   final int clQty;
//   final double mrp;
//   final double wsp;

//   CatalogItem({
//     required this.styleCode,
//     required this.shadeName,
//     required this.sizeName,
//     required this.clQty,
//     required this.mrp,
//     required this.wsp,
//   });

//   factory CatalogItem.fromJson(Map<String, dynamic> json) {
//     return CatalogItem(
//       styleCode: json['styleCode']?.toString() ?? '',
//       shadeName: json['shadeName']?.toString() ?? '',
//       sizeName: json['sizeName']?.toString() ?? '',
//       clQty: int.tryParse(json['clqty']?.toString() ?? '0') ?? 0,
//       mrp: double.tryParse(json['mrp']?.toString() ?? '0') ?? 0,
//       wsp: double.tryParse(json['wsp']?.toString() ?? '0') ?? 0,
//     );
//   }
// }

// class MultiCatalogBookingPage extends StatefulWidget {
//   final List<Catalog> catalogs;
//   final VoidCallback onSuccess; // Add this line
//   final Map<String, dynamic>? routeArguments;
//   const MultiCatalogBookingPage({
//     super.key,
//     required this.catalogs,
//     required this.onSuccess,
//     this.routeArguments,
//   });

//   @override
//   State<MultiCatalogBookingPage> createState() =>
//       _MultiCatalogBookingPageState();
// }

// class _MultiCatalogBookingPageState extends State<MultiCatalogBookingPage> {
//   Map<String, List<CatalogItem>> catalogItemsMap = {};
//   Map<String, List<String>> sizesMap = {};
//   Map<String, List<String>> colorsMap = {};
//   Map<String, Map<String, Map<String, TextEditingController>>> controllersMap =
//       {};
//   Map<String, String> styleCodeMap = {};
//   Map<String, Map<String, double>> sizeMrpMap = {};
//   Map<String, Map<String, double>> sizeWspMap = {};
//   Map<String, TextEditingController> noteControllersMap = {};
//   Map<String, bool> isLoadingMap = {};
//   Map<String, List<String>> copiedRowsMap = {};

//   String userId = UserSession.userName ?? '';
//   String coBrId = UserSession.coBrId ?? '';
//   String fcYrId = UserSession.userFcYr ?? '';
//   bool stockWise = true;
//   int maxSizes = 0;
//   bool isLoading = true;
//   int _loadingCounter = 0;

//   @override
//   void initState() {
//     super.initState();
//     _loadingCounter = widget.catalogs.length;
//     for (var catalog in widget.catalogs) {
//       noteControllersMap[catalog.styleCode] = TextEditingController();
//       copiedRowsMap[catalog.styleCode] = [];
//       fetchCatalogData(catalog);
//     }
//   }

//   Future<void> fetchCatalogData(Catalog catalog) async {
//     final String apiUrl = '${AppConstants.BASE_URL}/catalog/GetOrderDetails';

//     final Map<String, dynamic> requestBody = {
//       "itemSubGrpKey": catalog.itemSubGrpKey.toString(),
//       "itemKey": catalog.itemKey.toString(),
//       "styleKey": catalog.styleKey.toString(),
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

//     try {
//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(requestBody),
//       );

//       if (response.statusCode == 200) {
//         final List data = jsonDecode(response.body);
//         if (data.isNotEmpty) {
//           final items = data.map((e) => CatalogItem.fromJson(e)).toList();
//           final uniqueSizes = items.map((e) => e.sizeName).toSet().toList();
//           final uniqueColors = items.map((e) => e.shadeName).toSet().toList();

//           Map<String, double> tempSizeMrpMap = {};
//           Map<String, double> tempSizeWspMap = {};
//           for (var item in items) {
//             tempSizeMrpMap[item.sizeName] = item.mrp;
//             tempSizeWspMap[item.sizeName] = item.wsp;
//           }

//           Map<String, Map<String, TextEditingController>> tempControllers = {};
//           for (var color in uniqueColors) {
//             tempControllers[color] = {};
//             for (var size in uniqueSizes) {
//               final match = items.firstWhere(
//                 (item) => item.shadeName == color && item.sizeName == size,
//                 orElse:
//                     () => CatalogItem(
//                       styleCode: catalog.styleCode,
//                       shadeName: color,
//                       sizeName: size,
//                       clQty: 0,
//                       mrp: tempSizeMrpMap[size] ?? 0,
//                       wsp: tempSizeWspMap[size] ?? 0,
//                     ),
//               );
//               final controller = TextEditingController();
//               controller.addListener(() => setState(() {}));
//               tempControllers[color]![size] = controller;
//             }
//           }

//           setState(() {
//             catalogItemsMap[catalog.styleCode] = items;
//             sizesMap[catalog.styleCode] = uniqueSizes;
//             colorsMap[catalog.styleCode] = uniqueColors;
//             styleCodeMap[catalog.styleCode] = catalog.styleCode;
//             sizeMrpMap[catalog.styleCode] = tempSizeMrpMap;
//             sizeWspMap[catalog.styleCode] = tempSizeWspMap;
//             controllersMap[catalog.styleCode] = tempControllers;
//             isLoadingMap[catalog.styleCode] = false;
//             if (uniqueSizes.length > maxSizes) {
//               maxSizes = uniqueSizes.length;
//             }
//             _loadingCounter--;
//             if (_loadingCounter == 0) {
//               isLoading = false;
//             }
//           });
//         } else {
//           setState(() {
//             isLoadingMap[catalog.styleCode] = false;
//             _loadingCounter--;
//             if (_loadingCounter == 0) {
//               isLoading = false;
//             }
//           });
//         }
//       } else {
//         debugPrint(
//           'Failed to fetch catalog data for ${catalog.styleCode}: ${response.statusCode}',
//         );
//         setState(() {
//           isLoadingMap[catalog.styleCode] = false;
//           _loadingCounter--;
//           if (_loadingCounter == 0) {
//             isLoading = false;
//           }
//         });
//       }
//     } catch (e) {
//       debugPrint('Error fetching catalog data for ${catalog.styleCode}: $e');
//       setState(() {
//         isLoadingMap[catalog.styleCode] = false;
//         _loadingCounter--;
//         if (_loadingCounter == 0) {
//           isLoading = false;
//         }
//       });
//     }
//   }

//   int getTotalQty(String styleCode) {
//     int total = 0;
//     final controllers = controllersMap[styleCode];
//     if (controllers != null) {
//       for (var row in controllers.values) {
//         for (var cell in row.values) {
//           total += int.tryParse(cell.text) ?? 0;
//         }
//       }
//     }
//     return total;
//   }

//   double getTotalAmount(String styleCode) {
//     double total = 0;
//     final controllers = controllersMap[styleCode];
//     final wspMap = sizeWspMap[styleCode];
//     if (controllers != null && wspMap != null) {
//       for (var colorEntry in controllers.entries) {
//         for (var sizeEntry in colorEntry.value.entries) {
//           final qty = int.tryParse(sizeEntry.value.text) ?? 0;
//           final wsp = wspMap[sizeEntry.key] ?? 0;
//           total += qty * wsp;
//         }
//       }
//     }
//     return total;
//   }

//   int getTotalItems() {
//     return widget.catalogs.length;
//   }

//   int getTotalQtyAllStyles() {
//     int total = 0;
//     for (var catalog in widget.catalogs) {
//       total += getTotalQty(catalog.styleCode);
//     }
//     return total;
//   }

//   double getTotalAmountAllStyles() {
//     double total = 0;
//     for (var catalog in widget.catalogs) {
//       total += getTotalAmount(catalog.styleCode);
//     }
//     return total;
//   }

//   int getTotalStock(String styleCode) {
//     int total = 0;
//     final items = catalogItemsMap[styleCode];
//     if (items != null) {
//       for (var item in items) {
//         total += item.clQty;
//       }
//     }
//     return total;
//   }

//   void _copyQtyInAllShade(String styleCode) {
//     final colors = colorsMap[styleCode] ?? [];
//     final sizes = sizesMap[styleCode] ?? [];
//     if (colors.isEmpty || sizes.isEmpty) return;

//     final sourceColor = colors.first;
//     final sourceSize = sizes.first;
//     final valueToCopy =
//         controllersMap[styleCode]?[sourceColor]?[sourceSize]?.text ?? '';

//     for (var color in colors) {
//       for (var size in sizes) {
//         controllersMap[styleCode]?[color]?[size]?.text = valueToCopy;
//       }
//     }

//     setState(() {});
//   }

//   void _copySizeQtyInAllShade(String styleCode) {
//     final colors = colorsMap[styleCode] ?? [];
//     final sizes = sizesMap[styleCode] ?? [];
//     if (colors.isEmpty || sizes.isEmpty) return;

//     final sourceColor = colors.first;
//     for (var size in sizes) {
//       final valueToCopy =
//           controllersMap[styleCode]?[sourceColor]?[size]?.text ?? '';
//       for (var color in colors) {
//         controllersMap[styleCode]?[color]?[size]?.text = valueToCopy;
//       }
//     }

//     setState(() {});
//   }

//   void _copySizeQtyToOtherStyles(String sourceStyleCode) {
//     final sourceControllers = controllersMap[sourceStyleCode];
//     if (sourceControllers == null) return;

//     for (var catalog in widget.catalogs) {
//       final targetStyleCode = catalog.styleCode;
//       if (targetStyleCode == sourceStyleCode) continue;
//       final targetControllers = controllersMap[targetStyleCode];
//       if (targetControllers == null) continue;

//       for (var shade in sourceControllers.keys) {
//         if (targetControllers.containsKey(shade)) {
//           for (var size in sourceControllers[shade]!.keys) {
//             if (targetControllers[shade]!.containsKey(size)) {
//               final sourceQty = sourceControllers[shade]![size]!.text;
//               targetControllers[shade]![size]!.text = sourceQty;
//             }
//           }
//         }
//       }
//     }
//     setState(() {});
//   }

//   void _deleteCatalog(Catalog catalog) {
//     setState(() {
//       widget.catalogs.removeWhere((c) => c.styleCode == catalog.styleCode);
//       catalogItemsMap.remove(catalog.styleCode);
//       sizesMap.remove(catalog.styleCode);
//       colorsMap.remove(catalog.styleCode);
//       controllersMap.remove(catalog.styleCode);
//       styleCodeMap.remove(catalog.styleCode);
//       sizeMrpMap.remove(catalog.styleCode);
//       sizeWspMap.remove(catalog.styleCode);
//       noteControllersMap[catalog.styleCode]?.dispose();
//       noteControllersMap.remove(catalog.styleCode);
//       isLoadingMap.remove(catalog.styleCode);
//       copiedRowsMap.remove(catalog.styleCode);
//     });
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

//   String _getImageUrl(Catalog catalog) {
//     final path = catalog.fullImagePath ?? '';
//     if (UserSession.onlineImage == '0') {
//       final imageName = path.split('/').last.split('?').first;
//       return imageName.isEmpty
//           ? ''
//           : '${AppConstants.BASE_URL}/images/$imageName';
//     } else if (UserSession.onlineImage == '1') {
//       return path;
//     }
//     return '';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Book Multiple Items',
//           style: TextStyle(color: Colors.white),
//         ),
//         backgroundColor: AppColors.primaryColor,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(20.0),
//           child: Column(
//             children: [
//               const Divider(color: Colors.white),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   Text(
//                     'Total: ₹${getTotalAmountAllStyles().toStringAsFixed(2)}',
//                     style: GoogleFonts.roboto(
//                       color: Colors.white,
//                       fontSize: 12,
//                     ),
//                   ),
//                   const VerticalDivider(color: Colors.white, thickness: 1),
//                   Text(
//                     'Total Item: ${getTotalItems()}',
//                     style: GoogleFonts.roboto(
//                       color: Colors.white,
//                       fontSize: 12,
//                     ),
//                   ),
//                   const VerticalDivider(color: Colors.white, thickness: 1),
//                   Text(
//                     'Total Qty: ${getTotalQtyAllStyles()}',
//                     style: GoogleFonts.roboto(
//                       color: Colors.white,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),

//       body: SafeArea(
//         // Added SafeArea here
//         child:
//             isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : widget.catalogs.isEmpty
//                 ? const Center(child: Text("No items selected"))
//                 : Column(
//                   children: [
//                     Expanded(
//                       child: SingleChildScrollView(
//                         child: Column(
//                           children: [
//                             ...List.generate(widget.catalogs.length, (index) {
//                               final catalog = widget.catalogs[index];
//                               return Padding(
//                                 padding: const EdgeInsets.only(bottom: 24),
//                                 child: _buildItemBookingSection(
//                                   context,
//                                   catalog,
//                                 ),
//                               );
//                             }),
//                           ],
//                         ),
//                       ),
//                     ),
//                     _buildBottomBar(), // Fixed at the bottom
//                   ],
//                 ),
//         // bottomNavigationBar: _buildBottomBar(),
//       ),
//     );
//   }

//   Widget _buildItemBookingSection(BuildContext context, Catalog catalog) {
//     if ((catalogItemsMap[catalog.styleCode] ?? []).isEmpty) {
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
//               child: GestureDetector(
//                 onTap: () {
//                   final imageUrl = _getImageUrl(catalog);
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder:
//                           (context) => ImageZoomScreen(
//                             imageUrls: [imageUrl],
//                             initialIndex: 0,
//                           ),
//                     ),
//                   );
//                 },
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(12),
//                   child: Image.network(
//                     _getImageUrl(catalog),
//                     fit: BoxFit.contain,
//                     errorBuilder: (context, error, stackTrace) {
//                       return Container(
//                         color: Colors.grey.shade300,
//                         child: const Center(child: Icon(Icons.error)),
//                       );
//                     },
//                   ),
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
//                         child: _buildPriceTag(context, catalog.styleCode),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.copy_outlined),

//                         iconSize: 20,
//                         style: IconButton.styleFrom(
//                           backgroundColor: AppColors.lightBlue,
//                           shape: const CircleBorder(),
//                           padding: const EdgeInsets.all(8),
//                           foregroundColor: AppColors.primaryColor,
//                         ),
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
//                                           Navigator.of(dialogContext).pop();
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
//                                           _copyQtyInAllShade(catalog.styleCode);
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
//                                             color: AppColors.primaryColor,
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
//                                           _copySizeQtyInAllShade(
//                                             catalog.styleCode,
//                                           );
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
//                                             color: AppColors.primaryColor,
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
//                                           _copySizeQtyToOtherStyles(
//                                             catalog.styleCode,
//                                           );
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
//                         ),
//                         iconSize: 24,
//                         style: IconButton.styleFrom(
//                           backgroundColor:
//                               Colors.red.shade50, // Light red background
//                           shape: const CircleBorder(), // Circular shape
//                           padding: const EdgeInsets.all(
//                             8,
//                           ), // Padding around icon
//                         ),
//                         //onPressed: () => _deleteCatalog(catalog),
//                         onPressed: () {
//                           showDialog(
//                             context: context,
//                             builder: (dialogContext) {
//                               return AlertDialog(
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                                 title: const Text('Confirm Delete'),
//                                 content: const Text(
//                                   'Are you sure you want to delete this style?',
//                                 ),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () {
//                                       Navigator.of(dialogContext).pop();
//                                     },
//                                     child: const Text('Cancel'),
//                                   ),
//                                   ElevatedButton(
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.red,
//                                     ),
//                                     onPressed: () {
//                                       Navigator.of(dialogContext).pop();
//                                       _deleteCatalog(catalog);
//                                     },
//                                     child: const Text('Delete'),
//                                   ),
//                                 ],
//                               );
//                             },
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 8),
//                     child: Row(
//                       children: [
//                         Text(
//                           'Total Qty: ${getTotalQty(catalog.styleCode)}',
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.normal,
//                             color: Colors.black,
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Text(
//                           'Total Stock: ${getTotalStock(catalog.styleCode)}',
//                           style: const TextStyle(
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
//                       'Amt: ${getTotalAmount(catalog.styleCode).toStringAsFixed(0)}',
//                       style: const TextStyle(
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

//   Widget _buildPriceTag(BuildContext context, String styleCode) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       child: Text(
//         styleCode,
//         style: const TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//           color: Color(0xFF800000),
//         ),
//       ),
//     );
//   }

//   Widget _buildCatalogTable(Catalog catalog) {
//     final sizes = sizesMap[catalog.styleCode] ?? [];
//     final screenWidth = MediaQuery.of(context).size.width;

//     // Minimum table width: base column + 80px per size
//     final baseTableWidth = 100 + (80 * sizes.length);
//     // Use max(screen width, baseTableWidth) to ensure responsive scroll on small screens
//     final requiredTableWidth =
//         screenWidth > baseTableWidth ? screenWidth : baseTableWidth.toDouble();

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.black),
//         borderRadius: BorderRadius.circular(0),
//       ),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: ConstrainedBox(
//           constraints: BoxConstraints(minWidth: requiredTableWidth),
//           child: SingleChildScrollView(
//             scrollDirection: Axis.vertical,
//             child: Table(
//               border: TableBorder.symmetric(
//                 inside: BorderSide(color: Colors.grey.shade800, width: 1),
//               ),
//               columnWidths: _buildColumnWidths(),
//               children: [
//                 _buildPriceRow(
//                   "MRP",
//                   sizeMrpMap[catalog.styleCode] ?? {},
//                   FontWeight.w600,
//                   sizes,
//                 ),
//                 _buildPriceRow(
//                   "WSP",
//                   sizeWspMap[catalog.styleCode] ?? {},
//                   FontWeight.w400,
//                   sizes,
//                 ),
//                 _buildHeaderRow(catalog.styleCode, sizes),
//                 for (
//                   var i = 0;
//                   i < (colorsMap[catalog.styleCode]?.length ?? 0);
//                   i++
//                 )
//                   _buildQuantityRow(
//                     catalog,
//                     colorsMap[catalog.styleCode]![i],
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
//     const firstColumnWidth =
//         140.0; // Increased from 100 to 150 for shade name column
//     return {
//       0: const FixedColumnWidth(
//         firstColumnWidth,
//       ), // First column (Shade) - wider
//       for (int i = 0; i < maxSizes; i++)
//         (i + 1): const FixedColumnWidth(baseWidth * 0.8), // Size columns
//     };
//   }

//   Widget _buildBottomBar() {
//     final hasQty = widget.catalogs.any((c) => getTotalQty(c.styleCode) > 0);

//     return Row(
//       children: [
//         Expanded(
//           child: GestureDetector(
//             onTap: () {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => OrderPage(),
//                   settings: RouteSettings(arguments: widget.routeArguments),
//                 ),
//               );
//             },
//             child: Container(
//               padding: const EdgeInsets.symmetric(vertical: 14),
//                 color: const Color.fromARGB(255, 220, 239, 248),
//               child: const Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.close, color: AppColors.primaryColor),
//                   SizedBox(width: 6),
//                   Text(
//                     'Cancel',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: AppColors.primaryColor,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),

//         Expanded(
//           child: GestureDetector(
//             onTap: hasQty ? _submitAllOrders : null,
//             child: Container(
//               padding: const EdgeInsets.symmetric(vertical: 14),
//               color: hasQty ? AppColors.primaryColor : Colors.blueGrey,
//               child: const Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.add, color: Colors.white),
//                   SizedBox(width: 6),
//                   Text(
//                     'Confirm',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.white,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
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

//   TableRow _buildHeaderRow(String styleCode, List<String> sizes) {
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
//     Catalog catalog,
//     String color,
//     int i,
//     List<String> sizes,
//   ) {
//     // Get shade image URL
//     final imageUrl = _getShadeImageUrl(catalog, color);

//     return TableRow(
//       children: [
//         TableCell(
//           verticalAlignment: TableCellVerticalAlignment.middle,
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 // Copy icon
//                 GestureDetector(
//                   child: const Icon(Icons.copy_all, size: 18),
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
//                                         controllersMap[catalog
//                                                 .styleCode]?[color]
//                                             ?.values
//                                             .first
//                                             .text;
//                                     for (var size
//                                         in sizesMap[catalog.styleCode] ?? []) {
//                                       controllersMap[catalog
//                                               .styleCode]?[color]?[size]
//                                           ?.text = firstQty ?? '0';
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
//                                       color: AppColors.primaryColor,
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
//                                     for (var size
//                                         in sizesMap[catalog.styleCode] ?? []) {
//                                       final qty =
//                                           controllersMap[catalog
//                                                   .styleCode]?[color]?[size]
//                                               ?.text ??
//                                           '0';
//                                       copiedRow.add(qty);
//                                     }
//                                     copiedRowsMap[catalog.styleCode] =
//                                         copiedRow;
//                                     setState(() {});
//                                   },
//                                   child: Container(
//                                     width: double.infinity,
//                                     padding: const EdgeInsets.symmetric(
//                                       vertical: 12,
//                                     ),
//                                     margin: const EdgeInsets.only(bottom: 10),
//                                     decoration: BoxDecoration(
//                                       color: AppColors.primaryColor,
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
//                                         copiedRowsMap[catalog.styleCode] ?? [];
//                                     for (
//                                       int j = 0;
//                                       j <
//                                           (sizesMap[catalog.styleCode]
//                                                   ?.length ??
//                                               0);
//                                       j++
//                                     ) {
//                                       controllersMap[catalog
//                                               .styleCode]?[color]?[sizesMap[catalog
//                                               .styleCode]![j]]
//                                           ?.text = copiedRow[j];
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

//                 // Minimal space after copy icon
//                 const SizedBox(width: 2), // Reduced from 6 to 2

//                 Expanded(
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Text first
//                       Expanded(
//                         child: Text(
//                           color,
//                           style: TextStyle(
//                             color: _getColorCode(color),
//                             fontWeight: FontWeight.bold,
//                             fontSize: 12,
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                           maxLines: 1,
//                         ),
//                       ),

//                       // Image icon right after text with no margin
//                       if (UserSession.imageDependsOn == 'S' && imageUrl != null)
//                         Container(
//                           margin: EdgeInsets.zero, // No margin
//                           child: IconButton(
//                             icon: Icon(
//                               Icons.image,
//                               size: 14,
//                               color: AppColors.primaryColor,
//                             ),
//                             padding: EdgeInsets.zero, // No padding
//                             constraints: const BoxConstraints(
//                               minWidth: 16,
//                               minHeight: 16,
//                             ),
//                             tooltip: 'View shade image',
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder:
//                                       (context) => ImageZoomScreen(
//                                         imageUrls: [imageUrl],
//                                         initialIndex: 0,
//                                       ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         ...List.generate(maxSizes, (index) {
//           if (index < sizes.length) {
//             final size = sizes[index];
//             final controller = controllersMap[catalog.styleCode]?[color]?[size];
//             final originalQty =
//                 catalogItemsMap[catalog.styleCode]
//                     ?.firstWhere(
//                       (item) =>
//                           item.shadeName == color && item.sizeName == size,
//                       orElse:
//                           () => CatalogItem(
//                             styleCode: catalog.styleCode,
//                             shadeName: color,
//                             sizeName: size,
//                             clQty: 0,
//                             mrp: sizeMrpMap[catalog.styleCode]?[size] ?? 0,
//                             wsp: sizeWspMap[catalog.styleCode]?[size] ?? 0,
//                           ),
//                     )
//                     .clQty ??
//                 0;

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

//   String? _getShadeImageUrl(Catalog catalog, String shadeName) {
//     if (catalog.shadeImages.isEmpty) return null;

//     // Parse the shadeImages string - handle both ', ' and ',' separators
//     String shadeImagesStr = catalog.shadeImages;

//     // First try splitting by ', ' (comma + space)
//     List<String> shadeEntries = shadeImagesStr.split(', ');

//     // If that doesn't work (only one item), try splitting by ','
//     if (shadeEntries.length == 1 && shadeImagesStr.contains(',')) {
//       shadeEntries = shadeImagesStr.split(',');
//     }

//     for (var entry in shadeEntries) {
//       // Trim the entry to remove any extra spaces
//       entry = entry.trim();
//       if (entry.isEmpty) continue;

//       // Find the first ':' to split
//       final colonIndex = entry.indexOf(':');
//       if (colonIndex > 0) {
//         final shade = entry.substring(0, colonIndex).trim().toLowerCase();
//         final imageUrl = entry.substring(colonIndex + 1).trim();

//         // Case-insensitive comparison and trim both strings
//         if (shade.toLowerCase().trim() == shadeName.toLowerCase().trim()) {
//           return imageUrl;
//         }
//       }
//     }

//     return null;
//   }

//   Future<void> _submitAllOrders() async {
//     List<Future<http.Response>> apiCalls = [];
//     List<String> apiCallStyles = [];
//     final cartModel = Provider.of<CartModel>(context, listen: false);
//     Set<String> processedStyles = {};

//     for (var catalog in widget.catalogs) {
//       final controllers = controllersMap[catalog.styleCode];
//       final noteController = noteControllersMap[catalog.styleCode];
//       final styleCode = styleCodeMap[catalog.styleCode] ?? '';
//       final sizes = sizesMap[catalog.styleCode] ?? [];

//       // Skip if the item is already in the cart
//       if (cartModel.addedItems.contains(styleCode)) {
//         continue;
//       }

//       if (controllers != null) {
//         for (var colorEntry in controllers.entries) {
//           String color = colorEntry.key;
//           for (var sizeEntry in colorEntry.value.entries) {
//             String size = sizeEntry.key;
//             String qty = sizeEntry.value.text;
//             if (qty.isNotEmpty &&
//                 int.tryParse(qty) != null &&
//                 int.parse(qty) > 0) {
//               final payload = {
//                 "userId": userId,
//                 "coBrId": coBrId,
//                 "fcYrId": fcYrId,
//                 "data": {
//                   "designcode": styleCode,
//                   "mrp":
//                       sizeMrpMap[catalog.styleCode]?[size]?.toStringAsFixed(
//                         0,
//                       ) ??
//                       '0',
//                   "WSP":
//                       sizeWspMap[catalog.styleCode]?[size]?.toStringAsFixed(
//                         0,
//                       ) ??
//                       '0',
//                   "size": size,
//                   "TotQty": getTotalQty(catalog.styleCode).toString(),
//                   "Note": noteController?.text ?? '',
//                   "color": color,
//                   "Qty": qty,
//                   "cobrid": coBrId,
//                   "user": userId.toLowerCase(),
//                   "barcode": "",
//                 },
//                 "typ": 0,
//               };

//               apiCalls.add(
//                 http.post(
//                   Uri.parse(
//                     '${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails',
//                   ),
//                   headers: {'Content-Type': 'application/json'},
//                   body: jsonEncode(payload),
//                 ),
//               );
//               apiCallStyles.add(styleCode);
//             }
//           }
//         }
//       }
//     }

//     if (apiCalls.isEmpty) {
//       if (mounted) {
//         showDialog(
//           context: context,
//           builder:
//               (_) => AlertDialog(
//                 title: const Text("Warning"),
//                 content: const Text(
//                   "No new items with valid quantities to submit.",
//                 ),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text("OK"),
//                   ),
//                 ],
//               ),
//         );
//       }
//       return;
//     }

//     try {
//       final responses = await Future.wait(apiCalls);
//       final successfulStyles = <String>{};

//       for (int i = 0; i < responses.length; i++) {
//         final response = responses[i];
//         if (response.statusCode == 200) {
//           try {
//             // Try parsing as JSON first
//             final responseBody = jsonDecode(response.body);
//             if (responseBody is Map<String, dynamic> &&
//                 responseBody['success'] == true) {
//               successfulStyles.add(apiCallStyles[i]);
//               cartModel.addItem(apiCallStyles[i]);
//             }
//           } catch (e) {
//             // Handle plain text "Success" response
//             if (response.body.trim() == "Success") {
//               successfulStyles.add(apiCallStyles[i]);
//               cartModel.addItem(apiCallStyles[i]);
//             } else {
//               print(
//                 'Failed to parse response for style ${apiCallStyles[i]}: $e, response: ${response.body}',
//               );
//             }
//           }
//         } else {
//           print(
//             'API call failed for style ${apiCallStyles[i]}: ${response.statusCode}, response: ${response.body}',
//           );
//         }
//       }

//       if (successfulStyles.isNotEmpty) {
//         cartModel.updateCount(cartModel.count + successfulStyles.length);
//         processedStyles = successfulStyles;
//         widget.onSuccess();

//         if (mounted) {
//           showDialog(
//             context: context,
//             builder:
//                 (_) => AlertDialog(
//                   title: const Text("Success"),
//                   content: Text(
//                     "Successfully submitted ${successfulStyles.length} item${successfulStyles.length > 1 ? 's' : ''}.",
//                   ),
//                   actions: [
//                     TextButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => OrderPage(),
//                             settings: RouteSettings(
//                               arguments: widget.routeArguments,
//                             ),
//                           ),
//                         );
//                       },
//                       // Pop only the dialog
//                       child: const Text("OK"),
//                     ),
//                   ],
//                 ),
//           );
//         }
//       } else {
//         if (mounted) {
//           showDialog(
//             context: context,
//             builder:
//                 (_) => AlertDialog(
//                   title: const Text("Error"),
//                   content: const Text("No items were successfully submitted."),
//                   actions: [
//                     TextButton(
//                       onPressed: () => Navigator.pop(context),
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
//                 content: Text("Failed to submit orders: $e"),
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
//                   color: AppColors.primaryColor,
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

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vrs_erp/OrderBooking/orderbooking_booknow.dart';
import 'package:vrs_erp/catalog/imagezoom.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/CartModel.dart';
import 'package:vrs_erp/models/catalog.dart';

class CatalogItem {
  final String styleCode;
  final String shadeName;
  final String sizeName;
  final int clQty;
  final double mrp;
  final double wsp;

  CatalogItem({
    required this.styleCode,
    required this.shadeName,
    required this.sizeName,
    required this.clQty,
    required this.mrp,
    required this.wsp,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      styleCode: json['styleCode']?.toString() ?? '',
      shadeName: json['shadeName']?.toString() ?? '',
      sizeName: json['sizeName']?.toString() ?? '',
      clQty: int.tryParse(json['clqty']?.toString() ?? '0') ?? 0,
      mrp: double.tryParse(json['mrp']?.toString() ?? '0') ?? 0,
      wsp: double.tryParse(json['wsp']?.toString() ?? '0') ?? 0,
    );
  }
}

class MultiCatalogBookingPage extends StatefulWidget {
  final List<Catalog> catalogs;
  final VoidCallback onSuccess; // Add this line
  final Map<String, dynamic>? routeArguments;
  const MultiCatalogBookingPage({
    super.key,
    required this.catalogs,
    required this.onSuccess,
    this.routeArguments,
  });

  @override
  State<MultiCatalogBookingPage> createState() =>
      _MultiCatalogBookingPageState();
}

class _MultiCatalogBookingPageState extends State<MultiCatalogBookingPage> {
  Map<String, List<CatalogItem>> catalogItemsMap = {};
  Map<String, List<String>> sizesMap = {};
  Map<String, List<String>> colorsMap = {};
  Map<String, Map<String, Map<String, TextEditingController>>> controllersMap =
      {};
  Map<String, String> styleCodeMap = {};
  Map<String, Map<String, double>> sizeMrpMap = {};
  Map<String, Map<String, double>> sizeWspMap = {};
  Map<String, TextEditingController> noteControllersMap = {};
  Map<String, bool> isLoadingMap = {};
  Map<String, List<String>> copiedRowsMap = {};

  String userId = UserSession.userName ?? '';
  String coBrId = UserSession.coBrId ?? '';
  String fcYrId = UserSession.userFcYr ?? '';
  bool stockWise = true;
  int maxSizes = 0;
  bool isLoading = true;
  int _loadingCounter = 0;

  @override
  void initState() {
    super.initState();
    _loadingCounter = widget.catalogs.length;
    for (var catalog in widget.catalogs) {
      noteControllersMap[catalog.styleCode] = TextEditingController();
      copiedRowsMap[catalog.styleCode] = [];
      fetchCatalogData(catalog);
    }
  }

  Future<void> fetchCatalogData(Catalog catalog) async {
    final String apiUrl = '${AppConstants.BASE_URL}/catalog/GetOrderDetails';

    final Map<String, dynamic> requestBody = {
      "itemSubGrpKey": catalog.itemSubGrpKey.toString(),
      "itemKey": catalog.itemKey.toString(),
      "styleKey": catalog.styleKey.toString(),
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

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final items = data.map((e) => CatalogItem.fromJson(e)).toList();
          final uniqueSizes = items.map((e) => e.sizeName).toSet().toList();
          final uniqueColors = items.map((e) => e.shadeName).toSet().toList();

          Map<String, double> tempSizeMrpMap = {};
          Map<String, double> tempSizeWspMap = {};
          for (var item in items) {
            tempSizeMrpMap[item.sizeName] = item.mrp;
            tempSizeWspMap[item.sizeName] = item.wsp;
          }

          Map<String, Map<String, TextEditingController>> tempControllers = {};
          for (var color in uniqueColors) {
            tempControllers[color] = {};
            for (var size in uniqueSizes) {
              final match = items.firstWhere(
                (item) => item.shadeName == color && item.sizeName == size,
                orElse:
                    () => CatalogItem(
                      styleCode: catalog.styleCode,
                      shadeName: color,
                      sizeName: size,
                      clQty: 0,
                      mrp: tempSizeMrpMap[size] ?? 0,
                      wsp: tempSizeWspMap[size] ?? 0,
                    ),
              );
              final controller = TextEditingController();
              controller.addListener(() => setState(() {}));
              tempControllers[color]![size] = controller;
            }
          }

          setState(() {
            catalogItemsMap[catalog.styleCode] = items;
            sizesMap[catalog.styleCode] = uniqueSizes;
            colorsMap[catalog.styleCode] = uniqueColors;
            styleCodeMap[catalog.styleCode] = catalog.styleCode;
            sizeMrpMap[catalog.styleCode] = tempSizeMrpMap;
            sizeWspMap[catalog.styleCode] = tempSizeWspMap;
            controllersMap[catalog.styleCode] = tempControllers;
            isLoadingMap[catalog.styleCode] = false;
            if (uniqueSizes.length > maxSizes) {
              maxSizes = uniqueSizes.length;
            }
            _loadingCounter--;
            if (_loadingCounter == 0) {
              isLoading = false;
            }
          });
        } else {
          setState(() {
            isLoadingMap[catalog.styleCode] = false;
            _loadingCounter--;
            if (_loadingCounter == 0) {
              isLoading = false;
            }
          });
        }
      } else {
        debugPrint(
          'Failed to fetch catalog data for ${catalog.styleCode}: ${response.statusCode}',
        );
        setState(() {
          isLoadingMap[catalog.styleCode] = false;
          _loadingCounter--;
          if (_loadingCounter == 0) {
            isLoading = false;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching catalog data for ${catalog.styleCode}: $e');
      setState(() {
        isLoadingMap[catalog.styleCode] = false;
        _loadingCounter--;
        if (_loadingCounter == 0) {
          isLoading = false;
        }
      });
    }
  }

  int getTotalQty(String styleCode) {
    int total = 0;
    final controllers = controllersMap[styleCode];
    if (controllers != null) {
      for (var row in controllers.values) {
        for (var cell in row.values) {
          total += int.tryParse(cell.text) ?? 0;
        }
      }
    }
    return total;
  }

  double getTotalAmount(String styleCode) {
    double total = 0;
    final controllers = controllersMap[styleCode];
    final wspMap = sizeWspMap[styleCode];
    if (controllers != null && wspMap != null) {
      for (var colorEntry in controllers.entries) {
        for (var sizeEntry in colorEntry.value.entries) {
          final qty = int.tryParse(sizeEntry.value.text) ?? 0;
          final wsp = wspMap[sizeEntry.key] ?? 0;
          total += qty * wsp;
        }
      }
    }
    return total;
  }

  int getTotalItems() {
    return widget.catalogs.length;
  }

  int getTotalQtyAllStyles() {
    int total = 0;
    for (var catalog in widget.catalogs) {
      total += getTotalQty(catalog.styleCode);
    }
    return total;
  }

  double getTotalAmountAllStyles() {
    double total = 0;
    for (var catalog in widget.catalogs) {
      total += getTotalAmount(catalog.styleCode);
    }
    return total;
  }

  int getTotalStock(String styleCode) {
    int total = 0;
    final items = catalogItemsMap[styleCode];
    if (items != null) {
      for (var item in items) {
        total += item.clQty;
      }
    }
    return total;
  }

  void _copyQtyInAllShade(String styleCode) {
    final colors = colorsMap[styleCode] ?? [];
    final sizes = sizesMap[styleCode] ?? [];
    if (colors.isEmpty || sizes.isEmpty) return;

    final sourceColor = colors.first;
    final sourceSize = sizes.first;
    final valueToCopy =
        controllersMap[styleCode]?[sourceColor]?[sourceSize]?.text ?? '';

    for (var color in colors) {
      for (var size in sizes) {
        controllersMap[styleCode]?[color]?[size]?.text = valueToCopy;
      }
    }

    setState(() {});
  }

  void _copySizeQtyInAllShade(String styleCode) {
    final colors = colorsMap[styleCode] ?? [];
    final sizes = sizesMap[styleCode] ?? [];
    if (colors.isEmpty || sizes.isEmpty) return;

    final sourceColor = colors.first;
    for (var size in sizes) {
      final valueToCopy =
          controllersMap[styleCode]?[sourceColor]?[size]?.text ?? '';
      for (var color in colors) {
        controllersMap[styleCode]?[color]?[size]?.text = valueToCopy;
      }
    }

    setState(() {});
  }

  void _copySizeQtyToOtherStyles(String sourceStyleCode) {
    final sourceControllers = controllersMap[sourceStyleCode];
    if (sourceControllers == null) return;

    for (var catalog in widget.catalogs) {
      final targetStyleCode = catalog.styleCode;
      if (targetStyleCode == sourceStyleCode) continue;
      final targetControllers = controllersMap[targetStyleCode];
      if (targetControllers == null) continue;

      for (var shade in sourceControllers.keys) {
        if (targetControllers.containsKey(shade)) {
          for (var size in sourceControllers[shade]!.keys) {
            if (targetControllers[shade]!.containsKey(size)) {
              final sourceQty = sourceControllers[shade]![size]!.text;
              targetControllers[shade]![size]!.text = sourceQty;
            }
          }
        }
      }
    }
    setState(() {});
  }

  void _deleteCatalog(Catalog catalog) {
    setState(() {
      widget.catalogs.removeWhere((c) => c.styleCode == catalog.styleCode);
      catalogItemsMap.remove(catalog.styleCode);
      sizesMap.remove(catalog.styleCode);
      colorsMap.remove(catalog.styleCode);
      controllersMap.remove(catalog.styleCode);
      styleCodeMap.remove(catalog.styleCode);
      sizeMrpMap.remove(catalog.styleCode);
      sizeWspMap.remove(catalog.styleCode);
      noteControllersMap[catalog.styleCode]?.dispose();
      noteControllersMap.remove(catalog.styleCode);
      isLoadingMap.remove(catalog.styleCode);
      copiedRowsMap.remove(catalog.styleCode);
    });
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

  String _getImageUrl(Catalog catalog) {
    final path = catalog.fullImagePath ?? '';
    if (UserSession.onlineImage == '0') {
      final imageName = path.split('/').last.split('?').first;
      return imageName.isEmpty
          ? ''
          : '${AppConstants.BASE_URL}/images/$imageName';
    } else if (UserSession.onlineImage == '1') {
      return path;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Book Multiple Items',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        toolbarHeight: 40, // Reduced from default ~56 to 48
        titleSpacing: 0, // Remove extra spacing if needed

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            60.0,
          ), // Increased height to accommodate dividers
          child: Column(
            children: [
              // Top horizontal divider
              Container(
                height: 1,
                width: double.infinity,
                color: Colors.white.withOpacity(0.3),
              ),

              // Main content with vertical dividers
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.maroon.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryChip(
                      icon: Icons.currency_rupee,
                      label:
                          'Total: ₹${getTotalAmountAllStyles().toStringAsFixed(2)}',
                      color: Colors.amber,
                    ),

                    // White vertical divider
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.white.withOpacity(0.5),
                    ),

                    _buildSummaryChip(
                      icon: Icons.inventory,
                      label: 'Items: ${getTotalItems()}',
                      color: Colors.lightBlue,
                    ),

                    // White vertical divider
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.white.withOpacity(0.5),
                    ),

                    _buildSummaryChip(
                      icon: Icons.shopping_cart,
                      label: 'Qty: ${getTotalQtyAllStyles()}',
                      color: Colors.green,
                    ),
                  ],
                ),
              ),

              // Bottom horizontal divider
              Container(
                height: 1,
                width: double.infinity,
                color: Colors.white.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child:
            isLoading
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading catalog data...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
                : widget.catalogs.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No items selected",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
                : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: widget.catalogs.length,
                        itemBuilder: (context, index) {
                          final catalog = widget.catalogs[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _buildItemBookingSection(context, catalog),
                          );
                        },
                      ),
                    ),
                    _buildBottomBar(),
                  ],
                ),
      ),
    );
  }

  Widget _buildSummaryChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildItemBookingSection(BuildContext context, Catalog catalog) {
    if ((catalogItemsMap[catalog.styleCode] ?? []).isEmpty) {
      return const Center(child: Text("Empty"));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with image, style code and actions in same line
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image - fixed size, cover fit
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () {
                      final imageUrl = _getImageUrl(catalog);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ImageZoomScreen(
                                imageUrls: [imageUrl],
                                initialIndex: 0,
                              ),
                        ),
                      );
                    },
                    child: Image.network(
                      _getImageUrl(catalog),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade100,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey.shade400,
                            size: 30,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Style Code and Actions in a single row with background
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor.withOpacity(0.08),
                        Colors.white,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.15),
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
                      // Style Code with label
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'STYLE CODE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor.withOpacity(0.7),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              catalog.styleCode,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Copy and Delete buttons
                      Container(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildIconButton(
                              icon: Icons.copy_outlined,
                              color: AppColors.primaryColor,
                              onPressed: () => _showCopyDialog(catalog),
                            ),
                            Container(
                              height: 20,
                              width: 1,
                              color: Colors.grey.shade200,
                            ),
                            _buildIconButton(
                              icon: Icons.delete_outline,
                              color: AppColors.maroon,
                              onPressed: () => _showDeleteDialog(catalog),
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

        /// Stats row with Qty, Stock, Amount in same line
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade50,
                Colors.grey.shade100,
                Colors.grey.shade50,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              // Qty
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade50.withOpacity(0.7),
                        Colors.blue.shade100.withOpacity(0.3),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Qty: ${getTotalQty(catalog.styleCode)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stock
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade50.withOpacity(0.7),
                        Colors.green.shade100.withOpacity(0.3),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stock: ${getTotalStock(catalog.styleCode)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Amount
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.shade50.withOpacity(0.7),
                        Colors.amber.shade100.withOpacity(0.3),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.currency_rupee,
                        size: 16,
                        color: Colors.amber.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Amt: ${getTotalAmount(catalog.styleCode).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Table - full width
        _buildCatalogTable(catalog),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 23, color: color),
        ),
      ),
    );
  }

  void _showCopyDialog(Catalog catalog) {
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
              const Text(
                'Copy Quantities',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Divider(),
              _buildCopyOption(
                icon: Icons.copy_all,
                title: 'Copy Qty in All Shade',
                description: 'Copy first quantity to all shades',
                color: AppColors.primaryColor,
                onTap: () {
                  Navigator.pop(context);
                  _copyQtyInAllShade(catalog.styleCode);
                },
              ),
              _buildCopyOption(
                icon: Icons.content_copy,
                title: 'Copy Size Qty in All Shade',
                description: 'Copy each size quantity across all shades',
                color: AppColors.primaryColor,
                onTap: () {
                  Navigator.pop(context);
                  _copySizeQtyInAllShade(catalog.styleCode);
                },
              ),
              _buildCopyOption(
                icon: Icons.copy_all_rounded,
                title: 'Copy Size Qty to other Styles',
                description: 'Copy quantities to other selected styles',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _copySizeQtyToOtherStyles(catalog.styleCode);
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

  void _showDeleteDialog(Catalog catalog) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Confirm Delete',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete style "${catalog.styleCode}"?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.pinkAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _deleteCatalog(catalog);
                        },
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceTag(BuildContext context, String styleCode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        styleCode,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF800000),
        ),
      ),
    );
  }

  Widget _buildCatalogTable(Catalog catalog) {
    final sizes = sizesMap[catalog.styleCode] ?? [];

    return Container(
      width: double.infinity, // Use full width
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(0), // No border radius for table
      ),
      child: ClipRect(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth:
                  MediaQuery.of(context).size.width - 24, // Account for padding
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Table(
                border: TableBorder.all(
                  color: Colors.grey.shade300,
                  width: 0.5,
                ),
                columnWidths: _buildColumnWidths(sizes.length),
                children: [
                  _buildPriceRow(
                    "MRP",
                    sizeMrpMap[catalog.styleCode] ?? {},
                    FontWeight.w600,
                    sizes,
                  ),
                  _buildPriceRow(
                    "WSP",
                    sizeWspMap[catalog.styleCode] ?? {},
                    FontWeight.w400,
                    sizes,
                  ),
                  _buildHeaderRow(catalog.styleCode, sizes),
                  for (
                    var i = 0;
                    i < (colorsMap[catalog.styleCode]?.length ?? 0);
                    i++
                  )
                    _buildQuantityRow(
                      catalog,
                      colorsMap[catalog.styleCode]![i],
                      i,
                      sizes,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<int, TableColumnWidth> _buildColumnWidths(int sizeCount) {
    // Calculate dynamic column widths based on screen size
    double screenWidth =
        MediaQuery.of(context).size.width - 24; // Subtract padding

    // First column takes 120px, remaining space divided among size columns
    double firstColumnWidth = 140;
    double remainingWidth = screenWidth - firstColumnWidth;
    double sizeColumnWidth = remainingWidth / (sizeCount > 0 ? sizeCount : 1);

    // Ensure minimum width for size columns
    if (sizeColumnWidth < 70) {
      sizeColumnWidth = 70;
    }

    return {
      0: FixedColumnWidth(firstColumnWidth),
      for (int i = 0; i < maxSizes; i++)
        (i + 1): FixedColumnWidth(sizeColumnWidth),
    };
  }

  Widget _buildBottomBar() {
    final hasQty = widget.catalogs.any((c) => getTotalQty(c.styleCode) > 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderPage(),
                    settings: RouteSettings(arguments: widget.routeArguments),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: hasQty ? _submitAllOrders : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: hasQty ? AppColors.primaryColor : Colors.grey.shade400,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Confirm Order',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildPriceRow(
    String label,
    Map<String, double> sizePriceMap,
    FontWeight weight,
    List<String> sizes,
  ) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade50),
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: weight,
                color: Colors.grey.shade800,
                fontSize: 12,
              ),
            ),
          ),
        ),
        ...List.generate(maxSizes, (index) {
          if (index < sizes.length) {
            final size = sizes[index];
            final price = sizePriceMap[size] ?? 0.0;
            return TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Center(
                child: Text(
                  price.toStringAsFixed(0),
                  style: TextStyle(
                    fontWeight: weight,
                    color: Colors.grey.shade800,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          } else {
            return const TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Center(child: Text('')),
            );
          }
        }),
      ],
    );
  }

  TableRow _buildHeaderRow(String styleCode, List<String> sizes) {
    return TableRow(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 236, 212, 204).withOpacity(0.2),
      ),
      children: [
        const TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: _TableHeaderCell(),
        ),
        ...List.generate(maxSizes, (index) {
          if (index < sizes.length) {
            return TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    sizes[index],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          } else {
            return const TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Center(child: Text('')),
            );
          }
        }),
      ],
    );
  }

  TableRow _buildQuantityRow(
    Catalog catalog,
    String color,
    int i,
    List<String> sizes,
  ) {
    // Get shade image URL
    final imageUrl = _getShadeImageUrl(catalog, color);

    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // Copy icon
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showShadeCopyDialog(catalog, color),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.copy_all,
                        size: 14,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Text(
                          color,
                          style: TextStyle(
                            color: _getColorCode(color),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (UserSession.imageDependsOn == 'S' && imageUrl != null)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ImageZoomScreen(
                                        imageUrls: [imageUrl],
                                        initialIndex: 0,
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.image,
                                size: 12,
                                color: AppColors.primaryColor,
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
        ),
        ...List.generate(maxSizes, (index) {
          if (index < sizes.length) {
            final size = sizes[index];
            final controller = controllersMap[catalog.styleCode]?[color]?[size];
            final originalQty =
                catalogItemsMap[catalog.styleCode]
                    ?.firstWhere(
                      (item) =>
                          item.shadeName == color && item.sizeName == size,
                      orElse:
                          () => CatalogItem(
                            styleCode: catalog.styleCode,
                            shadeName: color,
                            sizeName: size,
                            clQty: 0,
                            mrp: sizeMrpMap[catalog.styleCode]?[size] ?? 0,
                            wsp: sizeWspMap[catalog.styleCode]?[size] ?? 0,
                          ),
                    )
                    .clQty ??
                0;

            return TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    hintText: originalQty > 0 ? originalQty.toString() : '0',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            );
          } else {
            return const TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Center(child: Text('')),
            );
          }
        }),
      ],
    );
  }

  void _showShadeCopyDialog(Catalog catalog, String color) {
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
                'Copy Options for $color',
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
                color: AppColors.primaryColor,
                onTap: () {
                  Navigator.pop(context);
                  final firstQty =
                      controllersMap[catalog.styleCode]?[color]
                          ?.values
                          .first
                          .text;
                  for (var size in sizesMap[catalog.styleCode] ?? []) {
                    controllersMap[catalog.styleCode]?[color]?[size]?.text =
                        firstQty ?? '0';
                  }
                  setState(() {});
                },
              ),
              _buildCopyOption(
                icon: Icons.content_copy,
                title: 'Copy Row',
                description: 'Copy this entire row',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  List<String> copiedRow = [];
                  for (var size in sizesMap[catalog.styleCode] ?? []) {
                    final qty =
                        controllersMap[catalog.styleCode]?[color]?[size]
                            ?.text ??
                        '0';
                    copiedRow.add(qty);
                  }
                  copiedRowsMap[catalog.styleCode] = copiedRow;
                  setState(() {});
                },
              ),
              _buildCopyOption(
                icon: Icons.paste,
                title: 'Paste Row',
                description: 'Paste previously copied row here',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  final copiedRow = copiedRowsMap[catalog.styleCode] ?? [];
                  for (
                    int j = 0;
                    j < (sizesMap[catalog.styleCode]?.length ?? 0);
                    j++
                  ) {
                    controllersMap[catalog.styleCode]?[color]?[sizesMap[catalog
                            .styleCode]![j]]
                        ?.text = copiedRow[j];
                  }
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String? _getShadeImageUrl(Catalog catalog, String shadeName) {
    if (catalog.shadeImages.isEmpty) return null;

    // Parse the shadeImages string - handle both ', ' and ',' separators
    String shadeImagesStr = catalog.shadeImages;

    // First try splitting by ', ' (comma + space)
    List<String> shadeEntries = shadeImagesStr.split(', ');

    // If that doesn't work (only one item), try splitting by ','
    if (shadeEntries.length == 1 && shadeImagesStr.contains(',')) {
      shadeEntries = shadeImagesStr.split(',');
    }

    for (var entry in shadeEntries) {
      // Trim the entry to remove any extra spaces
      entry = entry.trim();
      if (entry.isEmpty) continue;

      // Find the first ':' to split
      final colonIndex = entry.indexOf(':');
      if (colonIndex > 0) {
        final shade = entry.substring(0, colonIndex).trim().toLowerCase();
        final imageUrl = entry.substring(colonIndex + 1).trim();

        // Case-insensitive comparison and trim both strings
        if (shade.toLowerCase().trim() == shadeName.toLowerCase().trim()) {
          return imageUrl;
        }
      }
    }

    return null;
  }

  Future<void> _submitAllOrders() async {
    List<Future<http.Response>> apiCalls = [];
    List<String> apiCallStyles = [];
    final cartModel = Provider.of<CartModel>(context, listen: false);
    Set<String> processedStyles = {};

    for (var catalog in widget.catalogs) {
      final controllers = controllersMap[catalog.styleCode];
      final noteController = noteControllersMap[catalog.styleCode];
      final styleCode = styleCodeMap[catalog.styleCode] ?? '';
      final sizes = sizesMap[catalog.styleCode] ?? [];

      // Skip if the item is already in the cart
      if (cartModel.addedItems.contains(styleCode)) {
        continue;
      }

      if (controllers != null) {
        for (var colorEntry in controllers.entries) {
          String color = colorEntry.key;
          for (var sizeEntry in colorEntry.value.entries) {
            String size = sizeEntry.key;
            String qty = sizeEntry.value.text;
            if (qty.isNotEmpty &&
                int.tryParse(qty) != null &&
                int.parse(qty) > 0) {
              final payload = {
                "userId": userId,
                "coBrId": coBrId,
                "fcYrId": fcYrId,
                "data": {
                  "designcode": styleCode,
                  "mrp":
                      sizeMrpMap[catalog.styleCode]?[size]?.toStringAsFixed(
                        0,
                      ) ??
                      '0',
                  "WSP":
                      sizeWspMap[catalog.styleCode]?[size]?.toStringAsFixed(
                        0,
                      ) ??
                      '0',
                  "size": size,
                  "TotQty": getTotalQty(catalog.styleCode).toString(),
                  "Note": noteController?.text ?? '',
                  "color": color,
                  "Qty": qty,
                  "cobrid": coBrId,
                  "user": userId.toLowerCase(),
                  "barcode": "",
                },
                "typ": 0,
              };

              apiCalls.add(
                http.post(
                  Uri.parse(
                    '${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails',
                  ),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(payload),
                ),
              );
              apiCallStyles.add(styleCode);
            }
          }
        }
      }
    }

    if (apiCalls.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Text("Warning"),
                  ],
                ),
                content: const Text(
                  "No new items with valid quantities to submit.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              ),
        );
      }
      return;
    }

    try {
      final responses = await Future.wait(apiCalls);
      final successfulStyles = <String>{};

      for (int i = 0; i < responses.length; i++) {
        final response = responses[i];
        if (response.statusCode == 200) {
          try {
            // Try parsing as JSON first
            final responseBody = jsonDecode(response.body);
            if (responseBody is Map<String, dynamic> &&
                responseBody['success'] == true) {
              successfulStyles.add(apiCallStyles[i]);
              cartModel.addItem(apiCallStyles[i]);
            }
          } catch (e) {
            // Handle plain text "Success" response
            if (response.body.trim() == "Success") {
              successfulStyles.add(apiCallStyles[i]);
              cartModel.addItem(apiCallStyles[i]);
            } else {
              print(
                'Failed to parse response for style ${apiCallStyles[i]}: $e, response: ${response.body}',
              );
            }
          }
        } else {
          print(
            'API call failed for style ${apiCallStyles[i]}: ${response.statusCode}, response: ${response.body}',
          );
        }
      }

      if (successfulStyles.isNotEmpty) {
        cartModel.updateCount(cartModel.count + successfulStyles.length);
        processedStyles = successfulStyles;
        widget.onSuccess();

        if (mounted) {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text("Success"),
                    ],
                  ),
                  content: Text(
                    "Successfully submitted ${successfulStyles.length} item${successfulStyles.length > 1 ? 's' : ''}.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderPage(),
                            settings: RouteSettings(
                              arguments: widget.routeArguments,
                            ),
                          ),
                        );
                      },
                      // Pop only the dialog
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Error"),
                    ],
                  ),
                  content: const Text("No items were successfully submitted."),
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
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Error"),
                  ],
                ),
                content: Text("Failed to submit orders: $e"),
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
              top: 22,
              child: Text(
                'Shade',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                  fontSize: 12,
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 22,
              child: Text(
                'Size',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 12,
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
