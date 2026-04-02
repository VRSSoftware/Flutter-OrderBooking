// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import 'package:vrs_erp/catalog/image_zoom1.dart';
// import 'package:vrs_erp/catalog/imagezoom.dart';
// import 'package:vrs_erp/constants/app_constants.dart';
// import 'package:vrs_erp/models/CartModel.dart';
// import 'package:vrs_erp/models/CatalogOrderData.dart';
// import 'package:vrs_erp/models/OrderMatrix.dart';
// import 'package:vrs_erp/models/catalog.dart';
// import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_barcode2.dart';
// import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_data.dart';

// class CatalogItem {
//   final String styleCode;
//   final String shadeName;
//   final String sizeName;
//   final int clQty;
//   final double mrp;
//   final double wsp;
//   final String stkQty;
//   final String upcoming_Stk;
//   final String barcode;
//   final String remark;

//   CatalogItem({
//     required this.styleCode,
//     required this.shadeName,
//     required this.sizeName,
//     required this.clQty,
//     required this.mrp,
//     required this.wsp,
//     required this.upcoming_Stk,
//     required this.stkQty,
//     required this.barcode,
//     required this.remark,
//   });

//   factory CatalogItem.fromJson(Map<String, dynamic> json) {
//     return CatalogItem(
//       styleCode: json['styleCode']?.toString() ?? '',
//       shadeName: json['shadeName']?.toString() ?? '',
//       sizeName: json['sizeName']?.toString() ?? '',
//       upcoming_Stk: json['upcoming_Stk']?.toString() ?? '',
//       clQty: int.tryParse(json['clqty']?.toString() ?? '0') ?? 0,
//       mrp: double.tryParse(json['mrp']?.toString() ?? '0') ?? 0,
//       wsp: double.tryParse(json['wsp']?.toString() ?? '0') ?? 0,
//       stkQty: json['data2']?.toString() ?? '0',
//       barcode: json['barcode']?.toString() ?? '',
//       remark: json['remark']?.toString() ?? '',
//     );
//   }
// }

// class BookOnBarcode1 extends StatefulWidget {
//   final String barcode;
//   final VoidCallback onSuccess;
//   final VoidCallback onCancel;
//   final bool edit;

//   const BookOnBarcode1({
//     Key? key,
//     required this.barcode,
//     required this.onSuccess,
//     required this.onCancel,
//     this.edit = false,
//   }) : super(key: key);

//   @override
//   State<BookOnBarcode1> createState() => _BookOnBarcode1State();
// }

// class _BookOnBarcode1State extends State<BookOnBarcode1> {
//   List<CatalogOrderData> catalogOrderList = [];
//   Map<String, Set<String>> selectedColors2 = {};
//   Map<String, Map<String, Map<String, int>>> quantities = {};
//   bool isLoading = true;
//   bool hasData = false;
//   final Map<String, TextEditingController> _controllers = {};
//   String barcode = '';
//   List<Map<String, dynamic>> addedItems = [];
//   Map<String, List<String>> copiedRowsMap = {};
//   Map<String, Map<String, double>> sizeMrpMap = {};
//   Map<String, Map<String, double>> sizeWspMap = {};

//   @override
//   void initState() {
//     super.initState();
//     _loadOrderDetails();
//     barcode = widget.barcode;
//   }

//   @override
//   void dispose() {
//     _controllers.forEach((_, controller) => controller.dispose());
//     super.dispose();
//   }

//   Future<void> _loadOrderDetails() async {
//     setState(() {
//       isLoading = true;
//     });

//     final catalogItems = await fetchCatalogData();
//     final List<CatalogOrderData> tempList = [];

//     if (catalogItems.isNotEmpty) {
//       setState(() {
//         hasData = true;
//       });

//       final styleGroups = <String, List<CatalogItem>>{};
//       for (var item in catalogItems) {
//         styleGroups.putIfAbsent(item.styleCode, () => []).add(item);
//       }

//       for (var styleCode in styleGroups.keys) {
//         final items = styleGroups[styleCode]!;
//         final uniqueShades = items.map((e) => e.shadeName).toSet().toList();
//         final uniqueSizes = items.map((e) => e.sizeName).toSet().toList();

//         // Build size MRP and WSP maps
//         Map<String, double> tempSizeMrpMap = {};
//         Map<String, double> tempSizeWspMap = {};
//         for (var item in items) {
//           tempSizeMrpMap[item.sizeName] = item.mrp;
//           tempSizeWspMap[item.sizeName] = item.wsp;
//         }
//         sizeMrpMap[styleCode] = tempSizeMrpMap;
//         sizeWspMap[styleCode] = tempSizeWspMap;

//         final catalog = Catalog(
//           itemSubGrpKey: '',
//           itemSubGrpName: '',
//           itemKey: '',
//           itemName: 'Unknown Product',
//           brandKey: '',
//           brandName: '',
//           styleKey: styleCode,
//           styleCode: styleCode,
//           shadeKey: '',
//           shadeName: uniqueShades.join(','),
//           styleSizeId: '',
//           sizeName: uniqueSizes.join(','),
//           mrp: items.first.mrp,
//           wsp: items.first.wsp,
//           onlyMRP: items.first.mrp,
//           clqty: items.first.clQty,
//           total: items.fold(0, (sum, item) => sum + item.clQty),
//           upcoming_Stk: items.first.upcoming_Stk,
//           fullImagePath: '/NoImage.jpg',
//           remark:
//               items.first.upcoming_Stk == '0'
//                   ? 'Upcoming Stock'
//                   : '', // Set remark based on stk type
//           imageId: '',
//           sizeDetails: uniqueSizes
//               .map(
//                 (size) =>
//                     '$size (${items.firstWhere((i) => i.sizeName == size).mrp},${items.firstWhere((i) => i.sizeName == size).wsp})',
//               )
//               .join(', '),
//           sizeDetailsWithoutWSp: uniqueSizes
//               .map(
//                 (size) =>
//                     '$size (${items.firstWhere((i) => i.sizeName == size).mrp})',
//               )
//               .join(', '),
//           sizeWithMrp: uniqueSizes
//               .map(
//                 (size) =>
//                     '$size (${items.firstWhere((i) => i.sizeName == size).mrp})',
//               )
//               .join(', '),
//           styleCodeWithcount: styleCode,
//           onlySizes: uniqueSizes.join(','),
//           sizeWithWsp: uniqueSizes
//               .map(
//                 (size) =>
//                     '$size (${items.firstWhere((i) => i.sizeName == size).wsp})',
//               )
//               .join(', '),
//           createdDate: '',
//           shadeImages: '',
//           barcode: items.first.barcode,
//         );

//         final matrix = <List<String>>[];
//         for (var shade in uniqueShades) {
//           final row = <String>[];
//           for (var size in uniqueSizes) {
//             final item = items.firstWhere(
//               (i) => i.shadeName == shade && i.sizeName == size,
//               orElse:
//                   () => CatalogItem(
//                     styleCode: styleCode,
//                     shadeName: shade,
//                     sizeName: size,
//                     clQty: items.first.clQty,
//                     mrp: items.first.mrp,
//                     wsp: items.first.wsp,
//                     upcoming_Stk: items.first.upcoming_Stk,
//                     stkQty: items.first.stkQty,
//                     barcode: items.first.barcode,
//                     remark: items.first.remark,
//                   ),
//             );
//             row.add('${item.mrp},${item.wsp},${item.clQty},${item.stkQty}');
//           }
//           matrix.add(row);
//         }

//         final orderMatrix = OrderMatrix(
//           shades: uniqueShades,
//           sizes: uniqueSizes,
//           matrix: matrix,
//         );

//         tempList.add(
//           CatalogOrderData(catalog: catalog, orderMatrix: orderMatrix),
//         );

//         selectedColors2[styleCode] = uniqueShades.toSet();
//         quantities[styleCode] = {};
//         copiedRowsMap[styleCode] = [];

//         for (var shade in uniqueShades) {
//           quantities[styleCode]![shade] = {};
//           for (var size in uniqueSizes) {
//             quantities[styleCode]![shade]![size] =
//                 UserSession.coBrName == 'G CUBE NX' ? 0 : 0;
//             final controllerKey = '$styleCode-$shade-$size';
//             final controller = TextEditingController(
//               text: UserSession.coBrName == 'G CUBE NX' ? '0' : '0',
//             );
//             controller.addListener(() => setState(() {}));
//             _controllers[controllerKey] = controller;
//           }
//         }
//       }
//     } else {
//       setState(() {
//         hasData = false;
//       });
//     }

//     setState(() {
//       catalogOrderList = tempList;
//       isLoading = false;
//     });

//     if (!hasData && mounted) {
//       Navigator.pop(context, false);
//     }
//   }

//   Future<List<CatalogItem>> fetchCatalogData() async {
//     String apiUrl = '';
//     if (widget.edit) {
//       apiUrl = '${AppConstants.BASE_URL}/orderBooking/GetBarcodeDetailsUpdated';
//     } else {
//       apiUrl = '${AppConstants.BASE_URL}/orderBooking/GetBarcodeDetails';
//     }
//     final Map<String, dynamic> requestBody = {
//       "coBrId": UserSession.coBrId ?? '',
//       "userId": UserSession.userName ?? '',
//       "fcYrId": UserSession.userFcYr ?? '',
//       "barcode": widget.barcode.trim(),
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
//           return data.map((e) => CatalogItem.fromJson(e)).toList();
//         }
//       } else if (response.statusCode == 500 &&
//           response.body == 'Barcode already added') {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('This barcode is already added in the cart.'),
//             backgroundColor: AppColors.primaryColor,
//           ),
//         );
//       } else {
//         debugPrint('Failed to fetch catalog data: ${response.statusCode}');
//       }
//     } catch (e) {
//       debugPrint('Error fetching catalog data: $e');
//     }
//     return [];
//   }

//   int _getQuantity(String styleKey, String shade, String size) {
//     return quantities[styleKey]?[shade]?[size] ?? 1;
//   }

//   void _setQuantity(String styleKey, String shade, String size, int value) {
//     setState(() {
//       quantities.putIfAbsent(styleKey, () => {});
//       quantities[styleKey]!.putIfAbsent(shade, () => {});
//       quantities[styleKey]![shade]![size] = value.clamp(0, 9999);
//     });
//   }

//   void _deleteStyle(String styleKey) {
//     setState(() {
//       catalogOrderList.removeWhere(
//         (order) => order.catalog.styleKey == styleKey,
//       );
//       selectedColors2.remove(styleKey);
//       quantities.remove(styleKey);
//       sizeMrpMap.remove(styleKey);
//       sizeWspMap.remove(styleKey);
//       _controllers.removeWhere((key, _) => key.contains('$styleKey-'));
//     });

//     widget.onCancel();
//     Navigator.pop(context);
//   }

//   void _copyQtyInAllShade(String styleKey, String shade, List<String> sizes) {
//     if (sizes.isEmpty) return;
//     final firstSize = sizes.first;
//     final firstQuantity = _getQuantity(styleKey, shade, firstSize);
//     setState(() {
//       for (var size in sizes) {
//         _setQuantity(styleKey, shade, size, firstQuantity);
//         final controllerKey = '$styleKey-$shade-$size';
//         if (_controllers.containsKey(controllerKey)) {
//           _controllers[controllerKey]!.text = firstQuantity.toString();
//         }
//       }
//     });
//   }

//   void _copySizeQtyInAllShade(
//     String styleKey,
//     List<String> shades,
//     List<String> sizes,
//   ) {
//     if (shades.isEmpty || sizes.isEmpty) return;
//     final sourceShade = shades.first;

//     for (var size in sizes) {
//       final valueToCopy = _getQuantity(styleKey, sourceShade, size);
//       for (var shade in shades) {
//         _setQuantity(styleKey, shade, size, valueToCopy);
//         final controllerKey = '$styleKey-$shade-$size';
//         if (_controllers.containsKey(controllerKey)) {
//           _controllers[controllerKey]!.text = valueToCopy.toString();
//         }
//       }
//     }
//     setState(() {});
//   }

//   void _copySizeQtyToOtherStyles(String sourceStyleKey) {
//     for (var catalogOrder in catalogOrderList) {
//       final targetStyleKey = catalogOrder.catalog.styleKey;
//       if (targetStyleKey == sourceStyleKey) continue;

//       final targetShades = catalogOrder.orderMatrix.shades;
//       final targetSizes = catalogOrder.orderMatrix.sizes;
//       final sourceShades =
//           catalogOrderList
//               .firstWhere((order) => order.catalog.styleKey == sourceStyleKey)
//               .orderMatrix
//               .shades;

//       for (var shade in sourceShades) {
//         if (targetShades.contains(shade)) {
//           for (var size in targetSizes) {
//             final sourceQty = _getQuantity(sourceStyleKey, shade, size);
//             _setQuantity(targetStyleKey, shade, size, sourceQty);
//             final controllerKey = '$targetStyleKey-$shade-$size';
//             if (_controllers.containsKey(controllerKey)) {
//               _controllers[controllerKey]!.text = sourceQty.toString();
//             }
//           }
//         }
//       }
//     }
//     setState(() {});
//   }

//   void _copyRow(String styleKey, String shade, List<String> sizes) {
//     List<String> copiedRow = [];
//     for (var size in sizes) {
//       final qty = _getQuantity(styleKey, shade, size).toString();
//       copiedRow.add(qty);
//     }
//     copiedRowsMap[styleKey] = copiedRow;
//     setState(() {});
//   }

//   void _pasteRow(String styleKey, String shade, List<String> sizes) {
//     final copiedRow = copiedRowsMap[styleKey] ?? [];
//     if (copiedRow.isEmpty) return;

//     for (int i = 0; i < sizes.length && i < copiedRow.length; i++) {
//       final qty = int.tryParse(copiedRow[i]) ?? 0;
//       _setQuantity(styleKey, shade, sizes[i], qty);
//       final controllerKey = '$styleKey-$shade-${sizes[i]}';
//       if (_controllers.containsKey(controllerKey)) {
//         _controllers[controllerKey]!.text = qty.toString();
//       }
//     }
//     setState(() {});
//   }

//   void _copyQtyInShadeOnly(String styleKey, String shade, List<String> sizes) {
//     if (sizes.isEmpty) return;
//     final firstSize = sizes.first;
//     final firstQuantity = _getQuantity(styleKey, shade, firstSize);
//     for (var size in sizes) {
//       _setQuantity(styleKey, shade, size, firstQuantity);
//       final controllerKey = '$styleKey-$shade-$size';
//       if (_controllers.containsKey(controllerKey)) {
//         _controllers[controllerKey]!.text = firstQuantity.toString();
//       }
//     }
//     setState(() {});
//   }

//   Future<void> _submitAllOrders() async {
//     List<Future<http.Response>> apiCalls = [];
//     List<String> apiCallStyles = [];
//     final cartModel = Provider.of<CartModel>(context, listen: false);
//     addedItems.clear();

//     List<CatalogOrderData> updatedCatalogOrderList = [];

//     for (var catalogOrder in catalogOrderList) {
//       final catalog = catalogOrder.catalog;
//       final matrix = catalogOrder.orderMatrix;
//       final styleCode = catalog.styleCode;
//       final styleKey = catalog.styleKey;
//       final remark = catalog.remark; // Use remark from catalog data

//       final updatedMatrix = <List<String>>[];
//       for (
//         var shadeIndex = 0;
//         shadeIndex < matrix.shades.length;
//         shadeIndex++
//       ) {
//         final shade = matrix.shades[shadeIndex];
//         final row = <String>[];
//         for (var sizeIndex = 0; sizeIndex < matrix.sizes.length; sizeIndex++) {
//           final size = matrix.sizes[sizeIndex];
//           final matrixData = matrix.matrix[shadeIndex][sizeIndex].split(',');
//           final mrp = matrixData.isNotEmpty ? matrixData[0] : '0';
//           final wsp = matrixData.length > 1 ? matrixData[1] : '0';
//           final stkQty = matrixData.length > 2 ? matrixData[2] : '0';
//           final qty = quantities[styleKey]?[shade]?[size]?.toString() ?? '1';
//           row.add('$mrp,$wsp,$qty,$stkQty');
//         }
//         updatedMatrix.add(row);
//       }

//       final updatedOrderMatrix = OrderMatrix(
//         shades: matrix.shades,
//         sizes: matrix.sizes,
//         matrix: updatedMatrix,
//       );

//       final updatedCatalogOrder = CatalogOrderData(
//         catalog: catalog,
//         orderMatrix: updatedOrderMatrix,
//       );
//       updatedCatalogOrderList.add(updatedCatalogOrder);

//       final quantityMap = quantities[styleKey];
//       if (quantityMap != null) {
//         for (var shade in quantityMap.keys) {
//           final shadeIndex = matrix.shades.indexOf(shade.trim());
//           if (shadeIndex == -1) continue;

//           for (var size in quantityMap[shade]!.keys) {
//             final sizeIndex = matrix.sizes.indexOf(size.trim());
//             if (sizeIndex == -1) continue;

//             final quantity = quantityMap[shade]![size]!;
//             if (quantity > 0) {
//               final matrixData = updatedMatrix[shadeIndex][sizeIndex].split(
//                 ',',
//               );
//               final mrp = matrixData.isNotEmpty ? matrixData[0] : '0';
//               final wsp = matrixData.length > 1 ? matrixData[1] : mrp;
//               final stkQty = matrixData.length > 2 ? matrixData[2] : '0';
//               final item = {
//                 "designcode": styleCode,
//                 "mrp": mrp,
//                 "wsp": wsp,
//                 "size": size,
//                 "TotQty": _calculateCatalogQuantity(styleKey).toString(),
//                 "Note": remark,
//                 "color": shade,
//                 "Qty": quantity.toString(),
//                 "clqty": quantity.toString(),
//                 "cobrid": UserSession.coBrId ?? '',
//                 "user": "admin",
//                 "barcode": widget.barcode.trim(),
//                 "styleCode": styleCode,
//                 "shadeName": shade,
//                 "sizeName": size,
//                 "imagePath": catalog.fullImagePath ?? '/NoImage.jpg',
//                 "itemName": catalog.itemName ?? 'Unknown Product',
//                 "upcoming_Stk": stkQty,
//               };
//               addedItems.add(item);

//               final payload = {
//                 "userId": UserSession.userName ?? '',
//                 "coBrId": UserSession.coBrId ?? '',
//                 "fcYrId": UserSession.userFcYr ?? '',
//                 "data": {
//                   "designcode": styleCode,
//                   "mrp": mrp,
//                   "wsp": wsp,
//                   "size": size,
//                   "TotQty": _calculateCatalogQuantity(styleKey).toString(),
//                   "Note": remark,
//                   "color": shade,
//                   "Qty": quantity.toString(),
//                   "cobrid": UserSession.coBrId ?? '',
//                   "user": "admin",
//                   "barcode": widget.barcode.trim(),
//                 },
//                 "typ": 0,
//                 "barcode": "true",
//               };
//               if (!widget.edit) {
//                 apiCalls.add(
//                   http.post(
//                     Uri.parse(
//                       '${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails',
//                     ),
//                     headers: {'Content-Type': 'application/json'},
//                     body: jsonEncode(payload),
//                   ),
//                 );
//               }
//               apiCallStyles.add(styleCode);
//             }
//           }
//         }
//       }
//     }

//     if (apiCalls.isEmpty && addedItems.isEmpty) {
//       if (mounted) {
//         showDialog(
//           context: context,
//           builder:
//               (_) => AlertDialog(
//                 title: const Text("No Items"),
//                 content: const Text(
//                   "No items with quantity greater than 0 to submit.",
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
//       int successfulLineItems = 0;
//       if (!widget.edit) {
//         final responses = await Future.wait(apiCalls);
//         for (final response in responses) {
//           if (response.statusCode == 200) {
//             try {
//               final responseBody = jsonDecode(response.body);
//               if (responseBody is Map<String, dynamic> &&
//                   responseBody['success'] == true) {
//                 successfulLineItems++;
//               } else if (response.body.trim() == "Success") {
//                 successfulLineItems++;
//               }
//             } catch (e) {
//               if (response.body.trim() == "Success") {
//                 successfulLineItems++;
//               } else {
//                 debugPrint('Error parsing response: $e');
//               }
//             }
//           } else {
//             debugPrint('API call failed with status: ${response.statusCode}');
//           }
//         }
//       } else {
//         successfulLineItems = addedItems.length;
//       }

//       if (successfulLineItems > 0) {
//         cartModel.updateCount(cartModel.count + successfulLineItems);
//         widget.onSuccess();
//         if (widget.edit) {
//           EditOrderData.data.addAll(updatedCatalogOrderList);
//           if (mounted) {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => EditOrderBarcode2(docId: '-1'),
//               ),
//             );
//           }
//         } else {
//           if (mounted) {
//             Navigator.pop(context, true);
//           }
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
//       debugPrint('Submission error: $e');
//     }
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
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text(
//           'Order Booking - BarcodeWise',
//           style: TextStyle(color: Colors.white),
//         ),
//         backgroundColor: Colors.blue,
//         elevation: 2,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(12),
//               color: Colors.white,
//               child: Row(
//                 children: [
//                   const Text(
//                     "Barcode:",
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Text(
//                     widget.barcode,
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.red.shade900,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child:
//                   isLoading
//                       ? Center(
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 24,
//                             vertical: 12,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(8),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black12,
//                                 blurRadius: 8,
//                                 offset: Offset(0, 3),
//                               ),
//                             ],
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: const [
//                               Text(
//                                 'Please Wait...',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w500,
//                                   color: Colors.black,
//                                 ),
//                               ),
//                               SizedBox(width: 16),
//                               SizedBox(
//                                 width: 20,
//                                 height: 20,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2.5,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       )
//                       : SingleChildScrollView(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             ...catalogOrderList.map(
//                               (catalogOrder) => Padding(
//                                 padding: const EdgeInsets.only(bottom: 24),
//                                 child: _buildOrderItem(catalogOrder),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildOrderItem(CatalogOrderData catalogOrder) {
//     final catalog = catalogOrder.catalog;
//     final Set<String> selectedColors = selectedColors2[catalog.styleKey] ?? {};
//     final sizes = catalogOrder.orderMatrix.sizes;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Header with image and details
//         Container(
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey.shade300),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           margin: const EdgeInsets.symmetric(horizontal: 0.1, vertical: 8),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               GestureDetector(
//                 onTap: () {
//                   final imageUrl =
//                       catalog.fullImagePath.contains("http")
//                           ? catalog.fullImagePath
//                           : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}';
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder:
//                           (_) => ImageZoomScreen(
//                             imageUrls: [imageUrl],
//                             initialIndex: 0,
//                           ),
//                     ),
//                   );
//                 },
//                 child: Container(
//                   width: 80,
//                   height: 115,
//                   margin: const EdgeInsets.only(
//                     left: 8,
//                     top: 8,
//                     right: 8,
//                     bottom: 8,
//                   ),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey.shade300),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: Image.network(
//                       catalog.fullImagePath.contains("http")
//                           ? catalog.fullImagePath
//                           : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}',
//                       fit: BoxFit.contain,
//                       errorBuilder: (context, error, stackTrace) {
//                         return Container(
//                           color: Colors.grey.shade200,
//                           child: const Center(
//                             child: Icon(
//                               Icons.error,
//                               size: 30,
//                               color: Colors.grey,
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         // Style code as tag
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 10,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.red.shade50,
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(color: Colors.red.shade200),
//                           ),
//                           child: Text(
//                             catalog.styleCode,
//                             style: GoogleFonts.poppins(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 14,
//                               color: Colors.red.shade900,
//                             ),
//                           ),
//                         ),
//                         const Spacer(),
//                         // Copy icon with circular background
//                         Container(
//                           decoration: const BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: Colors.white,
//                           ),
//                           child: IconButton(
//                             icon: const Icon(
//                               Icons.copy_outlined,
//                               size: 18,
//                               color: Colors.blue,
//                             ),
//                             padding: EdgeInsets.zero,
//                             constraints: const BoxConstraints(
//                               minWidth: 32,
//                               minHeight: 32,
//                             ),
//                             onPressed: () {
//                               showDialog(
//                                 context: context,
//                                 builder: (BuildContext dialogContext) {
//                                   return AlertDialog(
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     titlePadding: EdgeInsets.zero,
//                                     contentPadding: EdgeInsets.zero,
//                                     title: Container(
//                                       width: double.infinity,
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 16,
//                                         vertical: 12,
//                                       ),
//                                       decoration: BoxDecoration(
//                                         color: Colors.grey.shade200,
//                                         borderRadius:
//                                             const BorderRadius.vertical(
//                                               top: Radius.circular(12),
//                                             ),
//                                       ),
//                                       child: Row(
//                                         children: [
//                                           const Expanded(
//                                             child: Text(
//                                               'Select an Action',
//                                               style: TextStyle(
//                                                 fontSize: 18,
//                                                 fontWeight: FontWeight.w600,
//                                               ),
//                                             ),
//                                           ),
//                                           IconButton(
//                                             icon: const Icon(Icons.close),
//                                             onPressed: () {
//                                               Navigator.of(context).pop();
//                                             },
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                     content: Padding(
//                                       padding: const EdgeInsets.all(16),
//                                       child: Column(
//                                         mainAxisSize: MainAxisSize.min,
//                                         children: [
//                                           GestureDetector(
//                                             onTap: () {
//                                               Navigator.of(dialogContext).pop();
//                                               _copySizeQtyToOtherStyles(
//                                                 catalog.styleKey,
//                                               );
//                                             },
//                                             child: Container(
//                                               width: double.infinity,
//                                               padding:
//                                                   const EdgeInsets.symmetric(
//                                                     vertical: 10,
//                                                   ),
//                                               margin: const EdgeInsets.only(
//                                                 bottom: 8,
//                                               ),
//                                               decoration: BoxDecoration(
//                                                 color: Colors.green,
//                                                 borderRadius:
//                                                     BorderRadius.circular(6),
//                                               ),
//                                               alignment: Alignment.center,
//                                               child: const Text(
//                                                 'Copy Size Qty to other Styles',
//                                                 style: TextStyle(
//                                                   color: Colors.white,
//                                                   fontSize: 13,
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               );
//                             },
//                           ),
//                         ),

//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Wrap(
//                       spacing: 8,
//                       runSpacing: 4,
//                       children: [
//                         // Order - always show
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 6,
//                             vertical: 2,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.blue.shade50,
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: Text(
//                             'Order: ${_calculateCatalogQuantity(catalog.styleKey)}',
//                             style: const TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.blue,
//                             ),
//                           ),
//                         ),

//                         // Stock - always show
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 6,
//                             vertical: 2,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.green.shade50,
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: Text(
//                             'Stock: ${_calculateStockQuantity(catalog.styleKey)}',
//                             style: const TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.green,
//                             ),
//                           ),
//                         ),

//                         // Amount - always show
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 6,
//                             vertical: 2,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.purple.shade50,
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: Text(
//                             'Amt: ₹${_calculateCatalogPrice(catalog.styleKey).toStringAsFixed(0)}',
//                             style: const TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.purple,
//                             ),
//                           ),
//                         ),

//                         // Stock Type - always show with dynamic value
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 8,
//                             vertical: 4,
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               const Text(
//                                 'Stock Type:',
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   fontWeight: FontWeight.w500,
//                                   color: Colors.blueGrey,
//                                 ),
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 catalog.upcoming_Stk == '1'
//                                     ? 'Upcoming'
//                                     : 'Ready',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w500,
//                                   color:
//                                       catalog.upcoming_Stk == '1'
//                                           ? Colors.orange.shade800
//                                           : Colors.green.shade800,
//                                 ),
//                               ),

//                               const SizedBox(width: 4),
//                               const Text(
//                                 'Remark:',
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   fontWeight: FontWeight.w500,
//                                   color: Colors.blueGrey,
//                                 ),
//                               ),
//                               const SizedBox(width: 4),
//                               Flexible(
//                                 child: Text(
//                                   catalog.remark.isNotEmpty
//                                       ? catalog.remark
//                                       : 'No remarks',
//                                   style: const TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.black87,
//                                     //fontStyle: FontStyle.italic,
//                                   ),
//                                   overflow: TextOverflow.ellipsis,
//                                   maxLines: 1,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),

//         const SizedBox(height: 0.5),

//         // Table for each shade
//         ...selectedColors.map(
//           (shade) => Padding(
//             padding: const EdgeInsets.only(bottom: 12),
//             child: _buildShadeTable(catalogOrder, shade),
//           ),
//         ),

//         // Cancel/Confirm buttons for each style
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//           child: Row(
//             children: [
//               Expanded(
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.grey.shade300,
//                     foregroundColor: Colors.black,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     padding: const EdgeInsets.symmetric(vertical: 10),
//                   ),
//                   onPressed: () => _deleteStyle(catalog.styleKey),
//                   child: const Text('CANCEL', style: TextStyle(fontSize: 13)),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor:
//                         _calculateTotalQuantity() > 0
//                             ? Colors.green
//                             : Colors.grey,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     padding: const EdgeInsets.symmetric(vertical: 10),
//                   ),
//                   onPressed:
//                       _calculateTotalQuantity() > 0 ? _submitAllOrders : null,
//                   child: const Text('CONFIRM', style: TextStyle(fontSize: 13)),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildShadeTable(CatalogOrderData catalogOrder, String shade) {
//     final styleKey = catalogOrder.catalog.styleKey;
//     final sizes = catalogOrder.orderMatrix.sizes;
//     final sizeMrp = sizeMrpMap[styleKey] ?? {};
//     final sizeWsp = sizeWspMap[styleKey] ?? {};

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 0.2, vertical: 4),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade400),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(6),
//         child: SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: ConstrainedBox(
//             constraints: BoxConstraints(
//               minWidth: MediaQuery.of(context).size.width - 16,
//             ),
//             child: SingleChildScrollView(
//               scrollDirection: Axis.vertical,
//               child: Table(
//                 border: TableBorder.symmetric(
//                   inside: BorderSide(color: Colors.grey.shade300, width: 1),
//                 ),
//                 columnWidths: _buildColumnWidths(sizes.length),
//                 defaultVerticalAlignment: TableCellVerticalAlignment.middle,
//                 children: [
//                   // MRP Row
//                   _buildPriceRow("MRP", sizeMrp, FontWeight.w600, sizes),
//                   // WSP Row
//                   _buildPriceRow("WSP", sizeWsp, FontWeight.w400, sizes),
//                   // Header Row with Shade/Size diagonal
//                   _buildHeaderRow(styleKey, shade, sizes),
//                   // Quantity Row for this shade
//                   _buildQuantityRow(catalogOrder, shade, sizes),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Map<int, TableColumnWidth> _buildColumnWidths(int sizeCount) {
//     const baseWidth = 70.0;
//     return {
//       0: const FixedColumnWidth(
//         90,
//       ), // Slightly wider for shade column with icon
//       for (int i = 0; i < sizeCount; i++)
//         (i + 1): const FixedColumnWidth(baseWidth),
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
//             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontWeight: weight,
//                 fontSize: 12,
//                 color: Colors.black,
//               ),
//             ),
//           ),
//         ),
//         ...List.generate(sizes.length, (index) {
//           final size = sizes[index];
//           final price = sizePriceMap[size] ?? 0.0;
//           return TableCell(
//             verticalAlignment: TableCellVerticalAlignment.middle,
//             child: Center(
//               child: Text(
//                 price.toStringAsFixed(0),
//                 style: TextStyle(
//                   fontWeight: weight,
//                   fontSize: 12,
//                   color: Colors.black, // Black color for values
//                 ),
//               ),
//             ),
//           );
//         }),
//       ],
//     );
//   }

//   TableRow _buildHeaderRow(String styleKey, String shade, List<String> sizes) {
//     return TableRow(
//       decoration: const BoxDecoration(
//         color: Color.fromARGB(255, 236, 212, 204),
//       ),
//       children: [
//         TableCell(
//           verticalAlignment: TableCellVerticalAlignment.middle,
//           child: Container(
//             height: 42,
//             child: CustomPaint(
//               painter: _DiagonalLinePainter(),
//               child: Stack(
//                 children: [
//                   Positioned(
//                     left: 10,
//                     top: 16,
//                     child: Text(
//                       'Shade',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 11,
//                         color: Colors.blue,
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     right: 12,
//                     bottom: 16,
//                     child: Text(
//                       'Size',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 11,
//                         color: Colors.red,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         ...List.generate(sizes.length, (index) {
//           return TableCell(
//             verticalAlignment: TableCellVerticalAlignment.middle,
//             child: Center(
//               child: Text(
//                 sizes[index],
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12,
//                   color: Colors.black,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           );
//         }),
//       ],
//     );
//   }

//   TableRow _buildQuantityRow(
//     CatalogOrderData catalogOrder,
//     String shade,
//     List<String> sizes,
//   ) {
//     final styleKey = catalogOrder.catalog.styleKey;

//     return TableRow(
//       children: [
//         TableCell(
//           verticalAlignment: TableCellVerticalAlignment.middle,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 GestureDetector(
//                   onTap: () {
//                     showDialog(
//                       context: context,
//                       builder: (BuildContext context) {
//                         return AlertDialog(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
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
//                                 _buildDialogOption(
//                                   'Copy Qty in shade only',
//                                   Colors.blue,
//                                   () {
//                                     Navigator.of(context).pop();
//                                     _copyQtyInShadeOnly(styleKey, shade, sizes);
//                                   },
//                                 ),
//                                 _buildDialogOption('Copy Row', Colors.blue, () {
//                                   Navigator.of(context).pop();
//                                   _copyRow(styleKey, shade, sizes);
//                                 }),
//                                 _buildDialogOption(
//                                   'Paste Row',
//                                   Colors.green,
//                                   () {
//                                     Navigator.of(context).pop();
//                                     _pasteRow(styleKey, shade, sizes);
//                                   },
//                                 ),
//                                 _buildDialogOption(
//                                   'Copy Qty in All Shade',
//                                   Colors.purple,
//                                   () {
//                                     Navigator.of(context).pop();
//                                     _copyQtyInAllShade(styleKey, shade, sizes);
//                                   },
//                                 ),
//                                 if (catalogOrderList.length > 1)
//                                   _buildDialogOption(
//                                     'Copy Size Qty to other Styles',
//                                     Colors.orange,
//                                     () {
//                                       Navigator.of(context).pop();
//                                       _copySizeQtyToOtherStyles(styleKey);
//                                     },
//                                   ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                   child: Container(
//                     padding: const EdgeInsets.all(2),
//                     child: const Icon(Icons.copy_all, size: 14),
//                   ),
//                 ),
//                 const SizedBox(width: 2),
//                 Flexible(
//                   child: Text(
//                     shade.length > 8 ? '${shade.substring(0, 6)}..' : shade,
//                     style: TextStyle(
//                       color: _getColorCode(shade),
//                       fontWeight: FontWeight.bold,
//                       fontSize: 11,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         ...List.generate(sizes.length, (index) {
//           final size = sizes[index];
//           final quantity = _getQuantity(styleKey, shade, size);
//           final controllerKey = '$styleKey-$shade-$size';
//           final controller = _controllers[controllerKey];

//           // Get stock quantity from matrix for hint
//           final matrix = catalogOrder.orderMatrix;
//           final shadeIndex = matrix.shades.indexOf(shade.trim());
//           final sizeIndex = matrix.sizes.indexOf(size.trim());
//           String stkQty = '0';
//           if (shadeIndex != -1 && sizeIndex != -1) {
//             final matrixData = matrix.matrix[shadeIndex][sizeIndex].split(',');
//             stkQty = matrixData.length > 2 ? matrixData[2] : '0';
//           }

//           return TableCell(
//             verticalAlignment: TableCellVerticalAlignment.middle,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
//               child: TextField(
//                 controller: controller,
//                 textAlign: TextAlign.center,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(
//                   border: InputBorder.none,
//                   isDense: true,
//                   contentPadding: const EdgeInsets.symmetric(vertical: 4),
//                   hintText: stkQty,
//                   hintStyle: TextStyle(
//                     fontSize: 10,
//                     color: Colors.grey.shade500,
//                   ),
//                 ),
//                 style: const TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black, // Black color for quantity
//                 ),
//                 inputFormatters: [
//                   FilteringTextInputFormatter.digitsOnly,
//                   LengthLimitingTextInputFormatter(4),
//                 ],
//                 onChanged: (value) {
//                   final newQuantity =
//                       int.tryParse(value.isEmpty ? '0' : value) ?? 0;
//                   _setQuantity(styleKey, shade, size, newQuantity);
//                 },
//               ),
//             ),
//           );
//         }),
//       ],
//     );
//   }

//   Widget _buildDialogOption(String title, Color color, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(vertical: 10),
//         margin: const EdgeInsets.only(bottom: 6),
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: BorderRadius.circular(6),
//         ),
//         alignment: Alignment.center,
//         child: Text(
//           title,
//           style: const TextStyle(color: Colors.white, fontSize: 12),
//         ),
//       ),
//     );
//   }

//   int _calculateTotalQuantity() {
//     int total = 0;
//     for (var styleKey in quantities.keys) {
//       for (var shade in quantities[styleKey]!.keys) {
//         for (var size in quantities[styleKey]![shade]!.keys) {
//           total += quantities[styleKey]![shade]![size]!;
//         }
//       }
//     }
//     return total;
//   }

//   double _calculateTotalPrice() {
//     double total = 0;
//     for (var catalogOrder in catalogOrderList) {
//       total += _calculateCatalogPrice(catalogOrder.catalog.styleKey);
//     }
//     return total;
//   }

//   int _calculateCatalogQuantity(String styleKey) {
//     int total = 0;
//     for (var shade in quantities[styleKey]?.keys ?? []) {
//       for (var size in quantities[styleKey]![shade]!.keys) {
//         total += quantities[styleKey]![shade]![size]!;
//       }
//     }
//     return total;
//   }

//   int _calculateStockQuantity(String styleKey) {
//     int total = 0;
//     for (var catalogOrder in catalogOrderList) {
//       if (catalogOrder.catalog.styleKey == styleKey) {
//         final matrix = catalogOrder.orderMatrix;
//         for (
//           var shadeIndex = 0;
//           shadeIndex < matrix.shades.length;
//           shadeIndex++
//         ) {
//           for (
//             var sizeIndex = 0;
//             sizeIndex < matrix.sizes.length;
//             sizeIndex++
//           ) {
//             final matrixData = matrix.matrix[shadeIndex][sizeIndex].split(',');
//             final stock =
//                 int.tryParse(matrixData.length > 2 ? matrixData[2] : '0') ?? 0;
//             total += stock;
//           }
//         }
//       }
//     }
//     return total;
//   }

//   double _calculateCatalogPrice(String styleKey) {
//     double total = 0;
//     for (var catalogOrder in catalogOrderList) {
//       if (catalogOrder.catalog.styleKey == styleKey) {
//         final matrix = catalogOrder.orderMatrix;
//         for (var shade in quantities[styleKey]?.keys ?? <String>[]) {
//           final shadeIndex = matrix.shades.indexOf(shade.trim());
//           if (shadeIndex == -1) continue;
//           for (var size in quantities[styleKey]![shade]!.keys) {
//             final sizeIndex = matrix.sizes.indexOf(size?.trim() ?? '');
//             if (sizeIndex == -1) continue;
//             final rate =
//                 double.tryParse(
//                   matrix.matrix[shadeIndex][sizeIndex].split(',')[0],
//                 ) ??
//                 0;
//             final quantity = quantities[styleKey]![shade]![size]!;
//             total += rate * quantity;
//           }
//         }
//       }
//     }
//     return total;
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vrs_erp/catalog/image_zoom1.dart';
import 'package:vrs_erp/catalog/imagezoom.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/CartModel.dart';
import 'package:vrs_erp/models/CatalogOrderData.dart';
import 'package:vrs_erp/models/OrderMatrix.dart';
import 'package:vrs_erp/models/catalog.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_barcode2.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_data.dart';

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

class CatalogItem {
  final String styleCode;
  final String shadeName;
  final String sizeName;
  final int clQty;
  final double mrp;
  final double wsp;
  final String stkQty;
  final String upcoming_Stk;
  final String barcode;
  final String remark;
  final String itemName;
  final String brandName;
  final String fullImagePath;

  CatalogItem({
    required this.styleCode,
    required this.shadeName,
    required this.sizeName,
    required this.clQty,
    required this.mrp,
    required this.wsp,
    required this.upcoming_Stk,
    required this.stkQty,
    required this.barcode,
    required this.remark,
    required this.itemName,
    required this.brandName,
    required this.fullImagePath,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      styleCode: json['styleCode']?.toString() ?? '',
      shadeName: json['shadeName']?.toString() ?? '',
      sizeName: json['sizeName']?.toString() ?? '',
      upcoming_Stk: json['upcoming_Stk']?.toString() ?? '0',
      clQty: int.tryParse(json['clqty']?.toString() ?? '0') ?? 0,
      mrp: double.tryParse(json['mrp']?.toString() ?? '0') ?? 0,
      wsp: double.tryParse(json['wsp']?.toString() ?? '0') ?? 0,
      stkQty: json['data2']?.toString() ?? '0',
      barcode: json['barcode']?.toString() ?? '',
      remark: json['remark']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      brandName: json['brandName']?.toString() ?? '',
      fullImagePath: json['fullImagePath']?.toString() ?? '/NoImage.jpg',
    );
  }
}

class BookOnBarcode1 extends StatefulWidget {
  final String barcode;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;
  final bool edit;

  const BookOnBarcode1({
    Key? key,
    required this.barcode,
    required this.onSuccess,
    required this.onCancel,
    this.edit = false,
  }) : super(key: key);

  @override
  State<BookOnBarcode1> createState() => _BookOnBarcode1State();
}

class _BookOnBarcode1State extends State<BookOnBarcode1> {
  List<CatalogOrderData> catalogOrderList = [];
  Map<String, Set<String>> selectedColors2 = {};
  Map<String, Map<String, Map<String, int>>> quantities = {};
  bool isLoading = true;
  bool hasData = false;
  final Map<String, TextEditingController> _controllers = {};
  String barcode = '';
  List<Map<String, dynamic>> addedItems = [];
  Map<String, List<String>> copiedRowsMap = {};
  Map<String, Map<String, double>> sizeMrpMap = {};
  Map<String, Map<String, double>> sizeWspMap = {};

  List<String> _allBarcodes = [];

  @override
  void initState() {
    super.initState();
    _parseBarcodes();
    _loadOrderDetails();
    barcode = widget.barcode;
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  // Add this method after initState
  void _parseBarcodes() {
    if (widget.barcode.contains(',')) {
      _allBarcodes = widget.barcode.split(',').map((b) => b.trim()).toList();
    } else {
      _allBarcodes = [widget.barcode];
    }
  }

  // REPLACE the existing fetchCatalogData with these two methods

  // Method to fetch data for a specific barcode
  Future<List<CatalogItem>?> fetchCatalogDataForBarcode(String barcode) async {
    String apiUrl = '';
    if (widget.edit) {
      apiUrl = '${AppConstants.BASE_URL}/orderBooking/GetBarcodeDetailsUpdated';
    } else {
      apiUrl = '${AppConstants.BASE_URL}/orderBooking/GetBarcodeDetails';
    }
    final Map<String, dynamic> requestBody = {
      "coBrId": UserSession.coBrId ?? '',
      "userId": UserSession.userName ?? '',
      "fcYrId": UserSession.userFcYr ?? '',
      "barcode": barcode.trim(),
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
          return data.map((e) => CatalogItem.fromJson(e)).toList();
        } else {
          return [];
        }
      } else if (response.statusCode == 500) {
        if (response.body.contains('Barcode already added')) {
          if (mounted) {
            await _showAlertDialogAndPop(
              context,
              'Already Added',
              'This barcode is already added in the cart.',
            );
          }
          return null;
        }
      }
    } catch (e) {
      debugPrint('Error fetching catalog data for $barcode: $e');
    }
    return [];
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      isLoading = true;
    });

    // Collect all items from all barcodes
    List<CatalogItem> allCatalogItems = [];

    for (String barcode in _allBarcodes) {
      final catalogItems = await fetchCatalogDataForBarcode(barcode);
      if (catalogItems != null && catalogItems.isNotEmpty) {
        allCatalogItems.addAll(catalogItems);
      }
    }

    final List<CatalogOrderData> tempList = [];

    // Check if any items were found
    if (allCatalogItems.isEmpty) {
      setState(() {
        isLoading = false;
        hasData = false;
      });
      if (mounted) {
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted && allCatalogItems.isEmpty) {
            Navigator.pop(context, false);
          }
        });
      }
      return;
    }

    setState(() {
      hasData = true;
    });

    // Group by style code
    final styleGroups = <String, List<CatalogItem>>{};
    for (var item in allCatalogItems) {
      styleGroups.putIfAbsent(item.styleCode, () => []).add(item);
    }

    for (var styleCode in styleGroups.keys) {
      final items = styleGroups[styleCode]!;

      // Get unique shades and sizes
      final uniqueShades = items.map((e) => e.shadeName).toSet().toList();
      final uniqueSizes = items.map((e) => e.sizeName).toSet().toList();

      // CRITICAL FIX: Build size MRP and WSP maps from ALL items
      // This ensures MRP/WSP is consistent across shades
      Map<String, double> tempSizeMrpMap = {};
      Map<String, double> tempSizeWspMap = {};

      for (var size in uniqueSizes) {
        // Get the MRP for this size - should be same across all shades
        // Take the first occurrence of this size
        final sizeItem = items.firstWhere(
          (i) => i.sizeName == size,
          orElse: () => items.first,
        );
        tempSizeMrpMap[size] = sizeItem.mrp;
        tempSizeWspMap[size] = sizeItem.wsp;
      }
      sizeMrpMap[styleCode] = tempSizeMrpMap;
      sizeWspMap[styleCode] = tempSizeWspMap;

      // Build a map for quick lookup of shade+size combinations for stock qty
      final Map<String, CatalogItem> itemMap = {};
      for (var item in items) {
        final key = '${item.shadeName}|${item.sizeName}';
        if (!itemMap.containsKey(key)) {
          itemMap[key] = item;
        }
      }

      // Get first item for common data
      final firstItem = items.first;

      final catalog = Catalog(
        itemSubGrpKey: '',
        itemSubGrpName: '',
        itemKey: '',
        itemName: firstItem.itemName,
        brandKey: '',
        brandName: firstItem.brandName,
        styleKey: styleCode,
        styleCode: styleCode,
        shadeKey: '',
        shadeName: uniqueShades.join(','),
        styleSizeId: '',
        sizeName: uniqueSizes.join(','),
        mrp: firstItem.mrp,
        wsp: firstItem.wsp,
        onlyMRP: firstItem.mrp,
        clqty: firstItem.clQty,
        total: items.fold(0, (sum, item) => sum + item.clQty),
        upcoming_Stk: firstItem.upcoming_Stk,
        fullImagePath: items.first.fullImagePath,
        remark: firstItem.remark,
        imageId: '',
        sizeDetails: uniqueSizes
            .map(
              (size) =>
                  '$size (${tempSizeMrpMap[size]},${tempSizeWspMap[size]})',
            )
            .join(', '),
        sizeDetailsWithoutWSp: uniqueSizes
            .map((size) => '$size (${tempSizeMrpMap[size]})')
            .join(', '),
        sizeWithMrp: uniqueSizes
            .map((size) => '$size (${tempSizeMrpMap[size]})')
            .join(', '),
        styleCodeWithcount: styleCode,
        onlySizes: uniqueSizes.join(','),
        sizeWithWsp: uniqueSizes
            .map((size) => '$size (${tempSizeWspMap[size]})')
            .join(', '),
        createdDate: '',
        shadeImages: '',
        barcode: firstItem.barcode,
      );

      // Build matrix - each row is a shade, each column is a size
      // The matrix data format: "MRP,WSP,STOCK_QTY,STK_QTY"
      final matrix = <List<String>>[];
      for (var shade in uniqueShades) {
        final row = <String>[];
        for (var size in uniqueSizes) {
          final key = '$shade|$size';
          final item = itemMap[key];

          if (item != null) {
            // Use the item's data for stock, but use the size-based MRP/WSP
            // This ensures MRP/WSP are consistent across shades
            row.add(
              '${tempSizeMrpMap[size]},${tempSizeWspMap[size]},${item.clQty},${item.stkQty}',
            );
          } else {
            // If combination doesn't exist, use default values with size-based MRP/WSP
            row.add('${tempSizeMrpMap[size]},${tempSizeWspMap[size]},0,0');
          }
        }
        matrix.add(row);
      }

      final orderMatrix = OrderMatrix(
        shades: uniqueShades,
        sizes: uniqueSizes,
        matrix: matrix,
      );

      tempList.add(
        CatalogOrderData(catalog: catalog, orderMatrix: orderMatrix),
      );

      // Update selectedColors2 properly - add ALL shades to the set
      if (selectedColors2.containsKey(styleCode)) {
        selectedColors2[styleCode]!.addAll(uniqueShades.toSet());
      } else {
        selectedColors2[styleCode] = uniqueShades.toSet();
      }

      // Initialize quantities
      if (!quantities.containsKey(styleCode)) {
        quantities[styleCode] = {};
      }

      copiedRowsMap[styleCode] = [];

      // Initialize quantities for all shades and sizes
      for (var shade in uniqueShades) {
        if (!quantities[styleCode]!.containsKey(shade)) {
          quantities[styleCode]![shade] = {};
        }
        for (var size in uniqueSizes) {
          if (!quantities[styleCode]![shade]!.containsKey(size)) {
            quantities[styleCode]![shade]![size] = 1;

            final controllerKey = '$styleCode-$shade-$size';
            if (!_controllers.containsKey(controllerKey)) {
              final controller = TextEditingController(text: '1');
              controller.addListener(() => setState(() {}));
              _controllers[controllerKey] = controller;
            }
          }
        }
      }
    }

    setState(() {
      catalogOrderList = tempList;
      isLoading = false;
    });
  }
  // Future<List<CatalogItem>> fetchCatalogData() async {
  //   String apiUrl = '';
  //   if (widget.edit) {
  //     apiUrl = '${AppConstants.BASE_URL}/orderBooking/GetBarcodeDetailsUpdated';
  //   } else {
  //     apiUrl = '${AppConstants.BASE_URL}/orderBooking/GetBarcodeDetails';
  //   }
  //   final Map<String, dynamic> requestBody = {
  //     "coBrId": UserSession.coBrId ?? '',
  //     "userId": UserSession.userName ?? '',
  //     "fcYrId": UserSession.userFcYr ?? '',
  //     "barcode": widget.barcode.trim(),
  //   };

  //   try {
  //     final response = await http.post(
  //       Uri.parse(apiUrl),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(requestBody),
  //     );

  //     if (response.statusCode == 200) {
  //       final List data = jsonDecode(response.body);
  //       if (data.isNotEmpty) {
  //         return data.map((e) => CatalogItem.fromJson(e)).toList();
  //       }
  //     } else if (response.statusCode == 500 &&
  //         response.body == 'Barcode already added') {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('This barcode is already added in the cart.'),
  //           backgroundColor: AppColors.primaryColor,
  //         ),
  //       );
  //     } else {
  //       debugPrint('Failed to fetch catalog data: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     debugPrint('Error fetching catalog data: $e');
  //   }
  //   return [];
  // }

  // Add this new method
  Future<void> _showAlertDialogAndPop(
    BuildContext context,
    String title,
    String message,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Text(message, style: const TextStyle(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
              ),
              child: const Text('OK'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );
      },
    );
  }

  Future<List<CatalogItem>?> fetchCatalogData() async {
    String apiUrl = '';
    if (widget.edit) {
      apiUrl = '${AppConstants.BASE_URL}/orderBooking/GetBarcodeDetailsUpdated';
    } else {
      apiUrl = '${AppConstants.BASE_URL}/orderBooking/GetBarcodeDetails';
    }
    final Map<String, dynamic> requestBody = {
      "coBrId": UserSession.coBrId ?? '',
      "userId": UserSession.userName ?? '',
      "fcYrId": UserSession.userFcYr ?? '',
      "barcode": widget.barcode.trim(),
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
          return data.map((e) => CatalogItem.fromJson(e)).toList();
        } else {
          // Empty response - No data found
          return []; // Return empty list for no data
        }
      } else if (response.statusCode == 500) {
        // Check if the response body contains "Barcode already added"
        if (response.body.contains('Barcode already added')) {
          // ✅ Show dialog for already added barcode
          if (mounted) {
            await _showAlertDialogAndPop(
              context,
              'Already Added',
              'This barcode is already added in the cart.',
            );
          }
          return null; // 🔴 Return null for already added case
        } else {
          // Other 500 errors
          debugPrint('Server error: ${response.body}');
        }
      } else {
        debugPrint('Failed to fetch catalog data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching catalog data: $e');
    }
    return []; // Return empty list for other errors
  }

  int _getQuantity(String styleKey, String shade, String size) {
    return quantities[styleKey]?[shade]?[size] ?? 1;
  }

  void _setQuantity(String styleKey, String shade, String size, int value) {
    setState(() {
      quantities.putIfAbsent(styleKey, () => {});
      quantities[styleKey]!.putIfAbsent(shade, () => {});
      quantities[styleKey]![shade]![size] = value.clamp(0, 9999);
    });
  }

  void _deleteStyle(String styleKey) {
    setState(() {
      catalogOrderList.removeWhere(
        (order) => order.catalog.styleKey == styleKey,
      );
      selectedColors2.remove(styleKey);
      quantities.remove(styleKey);
      sizeMrpMap.remove(styleKey);
      sizeWspMap.remove(styleKey);
      _controllers.removeWhere((key, _) => key.contains('$styleKey-'));
    });

    widget.onCancel();
    Navigator.pop(context);
  }

  void _copyQtyInAllShade(String styleKey, String shade, List<String> sizes) {
    if (sizes.isEmpty) return;
    final firstSize = sizes.first;
    final firstQuantity = _getQuantity(styleKey, shade, firstSize);
    setState(() {
      for (var size in sizes) {
        _setQuantity(styleKey, shade, size, firstQuantity);
        final controllerKey = '$styleKey-$shade-$size';
        if (_controllers.containsKey(controllerKey)) {
          _controllers[controllerKey]!.text = firstQuantity.toString();
        }
      }
    });
  }

  void _copySizeQtyInAllShade(
    String styleKey,
    List<String> shades,
    List<String> sizes,
  ) {
    if (shades.isEmpty || sizes.isEmpty) return;
    final sourceShade = shades.first;

    for (var size in sizes) {
      final valueToCopy = _getQuantity(styleKey, sourceShade, size);
      for (var shade in shades) {
        _setQuantity(styleKey, shade, size, valueToCopy);
        final controllerKey = '$styleKey-$shade-$size';
        if (_controllers.containsKey(controllerKey)) {
          _controllers[controllerKey]!.text = valueToCopy.toString();
        }
      }
    }
    setState(() {});
  }

  void _copySizeQtyToOtherStyles(String sourceStyleKey) {
    for (var catalogOrder in catalogOrderList) {
      final targetStyleKey = catalogOrder.catalog.styleKey;
      if (targetStyleKey == sourceStyleKey) continue;

      final targetShades = catalogOrder.orderMatrix.shades;
      final targetSizes = catalogOrder.orderMatrix.sizes;
      final sourceShades =
          catalogOrderList
              .firstWhere((order) => order.catalog.styleKey == sourceStyleKey)
              .orderMatrix
              .shades;

      for (var shade in sourceShades) {
        if (targetShades.contains(shade)) {
          for (var size in targetSizes) {
            final sourceQty = _getQuantity(sourceStyleKey, shade, size);
            _setQuantity(targetStyleKey, shade, size, sourceQty);
            final controllerKey = '$targetStyleKey-$shade-$size';
            if (_controllers.containsKey(controllerKey)) {
              _controllers[controllerKey]!.text = sourceQty.toString();
            }
          }
        }
      }
    }
    setState(() {});
  }

  void _copyRow(String styleKey, String shade, List<String> sizes) {
    List<String> copiedRow = [];
    for (var size in sizes) {
      final qty = _getQuantity(styleKey, shade, size).toString();
      copiedRow.add(qty);
    }
    copiedRowsMap[styleKey] = copiedRow;
    setState(() {});
  }

  void _pasteRow(String styleKey, String shade, List<String> sizes) {
    final copiedRow = copiedRowsMap[styleKey] ?? [];
    if (copiedRow.isEmpty) return;

    for (int i = 0; i < sizes.length && i < copiedRow.length; i++) {
      final qty = int.tryParse(copiedRow[i]) ?? 0;
      _setQuantity(styleKey, shade, sizes[i], qty);
      final controllerKey = '$styleKey-$shade-${sizes[i]}';
      if (_controllers.containsKey(controllerKey)) {
        _controllers[controllerKey]!.text = qty.toString();
      }
    }
    setState(() {});
  }

  void _copyQtyInShadeOnly(String styleKey, String shade, List<String> sizes) {
    if (sizes.isEmpty) return;
    final firstSize = sizes.first;
    final firstQuantity = _getQuantity(styleKey, shade, firstSize);

    setState(() {
      for (var size in sizes) {
        // Update the quantities map
        _setQuantity(styleKey, shade, size, firstQuantity);

        // Update the controller text
        final controllerKey = '$styleKey-$shade-$size';
        if (_controllers.containsKey(controllerKey)) {
          _controllers[controllerKey]!.text = firstQuantity.toString();
        } else {
          // Create new controller if it doesn't exist
          final controller = TextEditingController(
            text: firstQuantity.toString(),
          );
          controller.addListener(() => setState(() {}));
          _controllers[controllerKey] = controller;
        }
      }
    });
  }

  Future<void> _submitAllOrders() async {
    List<Future<http.Response>> apiCalls = [];
    List<String> apiCallStyles = [];
    final cartModel = Provider.of<CartModel>(context, listen: false);
    addedItems.clear();

    List<CatalogOrderData> updatedCatalogOrderList = [];

    for (var catalogOrder in catalogOrderList) {
      final catalog = catalogOrder.catalog;
      final matrix = catalogOrder.orderMatrix;
      final styleCode = catalog.styleCode;
      final styleKey = catalog.styleKey;
      final remark = catalog.remark;

      final updatedMatrix = <List<String>>[];
      for (
        var shadeIndex = 0;
        shadeIndex < matrix.shades.length;
        shadeIndex++
      ) {
        final shade = matrix.shades[shadeIndex];
        final row = <String>[];
        for (var sizeIndex = 0; sizeIndex < matrix.sizes.length; sizeIndex++) {
          final size = matrix.sizes[sizeIndex];
          final matrixData = matrix.matrix[shadeIndex][sizeIndex].split(',');
          final mrp = matrixData.isNotEmpty ? matrixData[0] : '0';
          final wsp = matrixData.length > 1 ? matrixData[1] : '0';
          final stkQty = matrixData.length > 2 ? matrixData[2] : '0';
          final qty = quantities[styleKey]?[shade]?[size]?.toString() ?? '1';
          row.add('$mrp,$wsp,$qty,$stkQty');
        }
        updatedMatrix.add(row);
      }

      final updatedOrderMatrix = OrderMatrix(
        shades: matrix.shades,
        sizes: matrix.sizes,
        matrix: updatedMatrix,
      );

      final updatedCatalogOrder = CatalogOrderData(
        catalog: catalog,
        orderMatrix: updatedOrderMatrix,
      );
      updatedCatalogOrderList.add(updatedCatalogOrder);

      final quantityMap = quantities[styleKey];
      if (quantityMap != null) {
        for (var shade in quantityMap.keys) {
          final shadeIndex = matrix.shades.indexOf(shade.trim());
          if (shadeIndex == -1) continue;

          for (var size in quantityMap[shade]!.keys) {
            final sizeIndex = matrix.sizes.indexOf(size.trim());
            if (sizeIndex == -1) continue;

            final quantity = quantityMap[shade]![size]!;
            if (quantity > 0) {
              final matrixData = updatedMatrix[shadeIndex][sizeIndex].split(
                ',',
              );
              final mrp = matrixData.isNotEmpty ? matrixData[0] : '0';
              final wsp = matrixData.length > 1 ? matrixData[1] : mrp;
              final stkQty = matrixData.length > 2 ? matrixData[2] : '0';
              final item = {
                "designcode": styleCode,
                "mrp": mrp,
                "wsp": wsp,
                "size": size,
                "TotQty": _calculateCatalogQuantity(styleKey).toString(),
                "Note": remark,
                "color": shade,
                "Qty": quantity.toString(),
                "clqty": quantity.toString(),
                "cobrid": UserSession.coBrId ?? '',
                "user": "admin",
                "barcode": widget.barcode.trim(),
                "styleCode": styleCode,
                "shadeName": shade,
                "sizeName": size,
                "imagePath": catalog.fullImagePath ?? '/NoImage.jpg',
                "itemName": catalog.itemName ?? '',
                "upcoming_Stk": stkQty,
              };
              addedItems.add(item);

              final payload = {
                "userId": UserSession.userName ?? '',
                "coBrId": UserSession.coBrId ?? '',
                "fcYrId": UserSession.userFcYr ?? '',
                "data": {
                  "designcode": styleCode,
                  "mrp": mrp,
                  "wsp": wsp,
                  "size": size,
                  "TotQty": _calculateCatalogQuantity(styleKey).toString(),
                  "Note": remark,
                  "color": shade,
                  "Qty": quantity.toString(),
                  "cobrid": UserSession.coBrId ?? '',
                  "user": "admin",
                  "barcode": widget.barcode.trim(),
                },
                "typ": 0,
                "barcode": "true",
              };
              if (!widget.edit) {
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
              apiCallStyles.add(styleCode);
            }
          }
        }
      }
    }

    if (apiCalls.isEmpty && addedItems.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text("No Items"),
                content: const Text(
                  "No items with quantity greater than 0 to submit.",
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
      int successfulLineItems = 0;
      if (!widget.edit) {
        final responses = await Future.wait(apiCalls);
        for (final response in responses) {
          if (response.statusCode == 200) {
            try {
              final responseBody = jsonDecode(response.body);
              if (responseBody is Map<String, dynamic> &&
                  responseBody['success'] == true) {
                successfulLineItems++;
              } else if (response.body.trim() == "Success") {
                successfulLineItems++;
              }
            } catch (e) {
              if (response.body.trim() == "Success") {
                successfulLineItems++;
              } else {
                debugPrint('Error parsing response: $e');
              }
            }
          } else {
            debugPrint('API call failed with status: ${response.statusCode}');
          }
        }
      } else {
        successfulLineItems = addedItems.length;
      }

      if (successfulLineItems > 0) {
        // cartModel.updateCount(cartModel.count + successfulLineItems);
        widget.onSuccess();
        if (widget.edit) {
          EditOrderData.data.addAll(updatedCatalogOrderList);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => EditOrderBarcode2(docId: '-1'),
              ),
            );
          }
        } else {
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text("Error"),
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
                title: const Text("Error"),
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
      debugPrint('Submission error: $e');
    }
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Order Booking - BarcodeWise',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 48,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49.0),
          child: Column(
            children: [
              Container(
                height: 1,
                width: double.infinity,
                color: Colors.white.withOpacity(0.3),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                color: AppColors.maroon,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Total: ${_calculateTotalPrice().toStringAsFixed(2)}',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: Colors.white.withOpacity(0.5),
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    ),
                    Flexible(
                      child: Text(
                        'Items: ${catalogOrderList.length}',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: Colors.white.withOpacity(0.5),
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    ),
                    Flexible(
                      child: Text(
                        'Qty: ${_calculateTotalQuantity()}',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content area
            Expanded(
              child:
                  isLoading
                      ? Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Loading...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(width: 16),
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      : SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...catalogOrderList.map(
                              (catalogOrder) => Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                child: _buildOrderItem(catalogOrder),
                              ),
                            ),
                          ],
                        ),
                      ),
            ),

            // Bottom buttons (fixed at bottom, not scrollable)
            Row(
              children: [
                Expanded(
                  child: _buildCompactGradientButton(
                    label: 'CANCEL ALL',
                    icon: Icons.close,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9E9E9E), Color(0xFF757575)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onPressed: () {
                      widget.onCancel();
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 1),
                Expanded(
                  child: _buildCompactGradientButton(
                    label: 'CONFIRM ALL',
                    icon: Icons.check,
                    gradient:
                        _calculateTotalQuantity() > 0
                            ? LinearGradient(
                              colors: [
                                AppColors.primaryColor,
                                AppColors.primaryColor.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                            : const LinearGradient(
                              colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                    onPressed:
                        _calculateTotalQuantity() > 0 ? _submitAllOrders : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(CatalogOrderData catalogOrder) {
    final catalog = catalogOrder.catalog;
    final Set<String> selectedColors = selectedColors2[catalog.styleKey] ?? {};
    final sizes = catalogOrder.orderMatrix.sizes;
    final items =
        catalogOrderList
            .firstWhere((order) => order.catalog.styleKey == catalog.styleKey)
            .orderMatrix;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with image and details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                GestureDetector(
                  onTap: () {
                    final imageUrl =
                        catalog.fullImagePath.contains("http")
                            ? catalog.fullImagePath
                            : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ImageZoomScreen(
                              imageUrls: [imageUrl],
                              initialIndex: 0,
                            ),
                      ),
                    );
                  },
                  child: Container(
                    width: 90,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: TableColors.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        catalog.fullImagePath.contains("http")
                            ? catalog.fullImagePath
                            : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 30,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Style Code with copy and delete buttons
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
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'STYLE :',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                                // Copy Style Button
                                Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      _showStyleCopyDialog(catalog);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.copy,
                                        size: 14,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Delete Style Button
                                Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      _showDeleteStyleDialog(catalog);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.delete,
                                        size: 14,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Divider(
                              color: AppColors.primaryColor.withOpacity(0.2),
                              height: 1,
                              thickness: 1,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                if (catalog.itemName.isNotEmpty &&
                                    catalog.itemName != '')
                                  _buildCompactDetailChip(
                                    'Product',
                                    catalog.itemName,
                                  ),
                                if (catalog.brandName.isNotEmpty)
                                  _buildCompactDetailChip(
                                    'Brand',
                                    catalog.brandName,
                                  ),
                                _buildCompactStatusChip(
                                  'Stock Type',
                                  catalog.upcoming_Stk == '1'
                                      ? 'Upcoming'
                                      : 'Ready',
                                  catalog.upcoming_Stk == '1'
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatRow(
                    'Stock',
                    _calculateStockQuantity(catalog.styleKey).toString(),
                    Icons.inventory,
                    Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildStatRow(
                    'Order',
                    _calculateCatalogQuantity(catalog.styleKey).toString(),
                    Icons.shopping_bag,
                    Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildStatRow(
                    'Amt',
                    '${_calculateCatalogPrice(catalog.styleKey).toStringAsFixed(0)}',
                    Icons.currency_rupee,
                    Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Combined Table with MRP, WSP, and all shades
          _buildCombinedTable(catalogOrder),

          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Note',
                labelStyle: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: TableColors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                prefixIcon: Icon(
                  Icons.note_outlined,
                  size: 16,
                  color: AppColors.primaryColor,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 30,
                ),
              ),
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
            ),
          ),

          const SizedBox(height: 5),
        ],
      ),
    );
  }

  void _showStyleCopyDialog(Catalog catalog) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
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
                // Option 1: Copy Qty in All Shade
                _buildCopyOption(
                  icon: Icons.copy_all,
                  title: 'Copy Qty in All Shade',
                  description: 'Copy first quantity to all shades',
                  color: AppColors.primaryColor,
                  onTap: () {
                    Navigator.pop(context);
                    final shades = selectedColors2[catalog.styleKey] ?? {};
                    final sizes = sizesMapForStyle(catalog.styleKey);
                    if (shades.isNotEmpty && sizes.isNotEmpty) {
                      _copySizeQtyInAllShade(
                        catalog.styleKey,
                        shades.toList(),
                        sizes,
                      );
                    }
                  },
                ),
                // Option 2: Copy Size Qty in All Shade
                _buildCopyOption(
                  icon: Icons.content_copy,
                  title: 'Copy Size Qty in All Shade',
                  description: 'Copy each size quantity across all shades',
                  color: AppColors.primaryColor,
                  onTap: () {
                    Navigator.pop(context);
                    final shades = selectedColors2[catalog.styleKey] ?? {};
                    final sizes = sizesMapForStyle(catalog.styleKey);
                    if (shades.isNotEmpty && sizes.isNotEmpty) {
                      _copySizeQtyInAllShade(
                        catalog.styleKey,
                        shades.toList(),
                        sizes,
                      );
                    }
                  },
                ),
                // Option 3: Copy Size Qty to other Styles (if multiple styles exist)
                if (catalogOrderList.length > 1)
                  _buildCopyOption(
                    icon: Icons.copy_all_rounded,
                    title: 'Copy Size Qty to other Styles',
                    description: 'Copy quantities to other selected styles',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _copySizeQtyToOtherStyles(catalog.styleKey);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteStyleDialog(Catalog catalog) {
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
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _deleteStyle(catalog.styleKey);
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

  List<String> sizesMapForStyle(String styleKey) {
    final catalogOrder = catalogOrderList.firstWhere(
      (order) => order.catalog.styleKey == styleKey,
    );
    return catalogOrder.orderMatrix.sizes;
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

  Widget _buildCompactStatusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
              color: color,
            ),
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

  // Combined table with MRP, WSP, and all shades
  Widget _buildCombinedTable(CatalogOrderData catalogOrder) {
    final styleKey = catalogOrder.catalog.styleKey;
    final sizes = catalogOrder.orderMatrix.sizes;
    final sizeMrp = sizeMrpMap[styleKey] ?? {};
    final sizeWsp = sizeWspMap[styleKey] ?? {};
    final allShades = selectedColors2[styleKey] ?? {};
    final items =
        catalogOrderList
            .firstWhere((order) => order.catalog.styleKey == styleKey)
            .orderMatrix;

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
              columnWidths: _buildColumnWidths(sizes.length),
              children: [
                // Header row with diagonal line
                TableRow(
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
                                left: 8,
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
                                right: 10,
                                bottom: 20,
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
                ),

                // MRP row (shown only once)
                TableRow(
                  decoration: BoxDecoration(color: TableColors.priceRowBg),
                  children: [
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: AppColors.primaryColor.withOpacity(0.1),
                        child: const Text(
                          'MRP',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    ...sizes.map((size) {
                      final price = sizeMrp[size] ?? 0.0;
                      return TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: TableColors.borderColor,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),

                // WSP row (shown only once)
                TableRow(
                  decoration: BoxDecoration(color: TableColors.priceRowBg),
                  children: [
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: AppColors.primaryColor.withOpacity(0.1),
                        child: const Text(
                          'WSP',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    ...sizes.map((size) {
                      final price = sizeWsp[size] ?? 0.0;
                      return TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: TableColors.borderColor,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),

                // All shade rows (multiple rows)
                ...allShades.map(
                  (shade) => _buildShadeRow(catalogOrder, shade, sizes, items),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build individual shade rows - returns TableRow
  TableRow _buildShadeRow(
    CatalogOrderData catalogOrder,
    String shade,
    List<String> sizes,
    OrderMatrix items,
  ) {
    final styleKey = catalogOrder.catalog.styleKey;

    return TableRow(
      decoration: BoxDecoration(color: TableColors.evenRowBg),
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
                // Copy icon for shade
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () {
                        _showShadeCopyDialog(styleKey, shade, sizes);
                      },
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
        ...sizes.map((size) {
          final quantity = _getQuantity(styleKey, shade, size);
          final controllerKey = '$styleKey-$shade-$size';
          final controller = _controllers[controllerKey];

          // Get clqty from matrix for hint
          final shadeIndex = items.shades.indexOf(shade.trim());
          final sizeIndex = items.sizes.indexOf(size.trim());
          String clQty = '0';
          if (shadeIndex != -1 && sizeIndex != -1) {
            final matrixData = items.matrix[shadeIndex][sizeIndex].split(',');
            clQty = matrixData.length > 2 ? matrixData[2] : '0';
          }

          return TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: TableColors.borderColor, width: 0.5),
                ),
              ),
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintText: clQty,
                  hintStyle: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    fontStyle: FontStyle.italic,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: (value) {
                  final newQuantity =
                      int.tryParse(value.isEmpty ? '0' : value) ?? 0;
                  _setQuantity(styleKey, shade, size, newQuantity);
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showShadeCopyDialog(String styleKey, String shade, List<String> sizes) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
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
                // Option 1: Copy Qty in shade only
                _buildCopyOption(
                  icon: Icons.copy_all,
                  title: 'Copy Qty in shade only',
                  description: 'Copy first quantity to all sizes in this shade',
                  color: AppColors.primaryColor,
                  onTap: () {
                    Navigator.pop(context);
                    _copyQtyInShadeOnly(styleKey, shade, sizes);
                  },
                ),
                // Option 2: Copy Row
                _buildCopyOption(
                  icon: Icons.content_copy,
                  title: 'Copy Row',
                  description: 'Copy this entire row',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _copyRow(styleKey, shade, sizes);
                  },
                ),
                // Option 3: Paste Row
                _buildCopyOption(
                  icon: Icons.paste,
                  title: 'Paste Row',
                  description: 'Paste previously copied row here',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _pasteRow(styleKey, shade, sizes);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactGradientButton({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          minimumSize: const Size(double.infinity, 48),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<int, TableColumnWidth> _buildColumnWidths(int sizeCount) {
    double screenWidth = MediaQuery.of(context).size.width;
    double firstColumnWidth = 140;
    double remainingWidth = screenWidth - firstColumnWidth;
    double sizeColumnWidth = remainingWidth / (sizeCount > 0 ? sizeCount : 1);

    if (sizeColumnWidth < 70) {
      sizeColumnWidth = 70;
    }

    return {
      0: FixedColumnWidth(firstColumnWidth),
      for (int i = 0; i < sizeCount; i++)
        i + 1: FixedColumnWidth(sizeColumnWidth),
    };
  }

  int _calculateTotalQuantity() {
    int total = 0;
    for (var styleKey in quantities.keys) {
      for (var shade in quantities[styleKey]!.keys) {
        for (var size in quantities[styleKey]![shade]!.keys) {
          total += quantities[styleKey]![shade]![size]!;
        }
      }
    }
    return total;
  }

  double _calculateTotalPrice() {
    double total = 0;
    for (var catalogOrder in catalogOrderList) {
      total += _calculateCatalogPrice(catalogOrder.catalog.styleKey);
    }
    return total;
  }

  int _calculateCatalogQuantity(String styleKey) {
    int total = 0;
    for (var shade in quantities[styleKey]?.keys ?? []) {
      for (var size in quantities[styleKey]![shade]!.keys) {
        total += quantities[styleKey]![shade]![size]!;
      }
    }
    return total;
  }

  int _calculateStockQuantity(String styleKey) {
    int total = 0;
    for (var catalogOrder in catalogOrderList) {
      if (catalogOrder.catalog.styleKey == styleKey) {
        final matrix = catalogOrder.orderMatrix;
        for (
          var shadeIndex = 0;
          shadeIndex < matrix.shades.length;
          shadeIndex++
        ) {
          for (
            var sizeIndex = 0;
            sizeIndex < matrix.sizes.length;
            sizeIndex++
          ) {
            final matrixData = matrix.matrix[shadeIndex][sizeIndex].split(',');
            final stock =
                int.tryParse(matrixData.length > 2 ? matrixData[2] : '0') ?? 0;
            total += stock;
          }
        }
      }
    }
    return total;
  }

  double _calculateCatalogPrice(String styleKey) {
    double total = 0;
    for (var catalogOrder in catalogOrderList) {
      if (catalogOrder.catalog.styleKey == styleKey) {
        final matrix = catalogOrder.orderMatrix;
        for (var shade in quantities[styleKey]?.keys ?? <String>[]) {
          final shadeIndex = matrix.shades.indexOf(shade.trim());
          if (shadeIndex == -1) continue;
          for (var size in quantities[styleKey]![shade]!.keys) {
            final sizeIndex = matrix.sizes.indexOf(size?.trim() ?? '');
            if (sizeIndex == -1) continue;
            final rate =
                double.tryParse(
                  matrix.matrix[shadeIndex][sizeIndex].split(',')[0],
                ) ??
                0;
            final quantity = quantities[styleKey]![shade]![size]!;
            total += rate * quantity;
          }
        }
      }
    }
    return total;
  }
}

// Simple diagonal painter for enhanced header
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
