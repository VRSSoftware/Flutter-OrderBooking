// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import 'package:vrs_erp/catalog/image_zoom1.dart';
// import 'package:vrs_erp/constants/app_constants.dart';
// import 'package:vrs_erp/models/CartModel.dart';
// import 'package:vrs_erp/models/CatalogOrderData.dart';
// import 'package:vrs_erp/models/OrderMatrix.dart';
// import 'package:vrs_erp/models/catalog.dart';
// import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_barcode2.dart';
// import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_data.dart';
// import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_screen_barcode.dart';

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
//     );
//   }
// }

// class BookOnBarcode2 extends StatefulWidget {
//   final String barcode;
//   final VoidCallback onSuccess;
//   final VoidCallback onCancel;
//   final bool edit;

//   const BookOnBarcode2({
//     Key? key,
//     required this.barcode,
//     required this.onSuccess,
//     required this.onCancel,
//     this.edit = false,
//   }) : super(key: key);

//   @override
//   State<BookOnBarcode2> createState() => _BookOnBarcode2State();
// }

// class _BookOnBarcode2State extends State<BookOnBarcode2> {
//   List<CatalogOrderData> catalogOrderList = [];
//   Map<String, Set<String>> selectedColors2 = {};
//   Map<String, Map<String, Map<String, int>>> quantities = {};
//   bool isLoading = true;
//   bool hasData = false;
//   final Map<String, TextEditingController> _controllers = {};
//   String barcode = '';
//   List<Map<String, dynamic>> addedItems = [];

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
//         final uniqueShades =
//             items.map((e) => e.shadeName).toSet().toList();
//         final uniqueSizes =
//             items.map((e) => e.sizeName).toSet().toList();

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
//           remark: '',
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
//         for (var shade in uniqueShades) {
//           quantities[styleCode]![shade] = {};
//           for (var size in uniqueSizes) {
//             quantities[styleCode]![shade]![size] = UserSession.coBrName=='G CUBE NX' ? 0 : 0; // Default to 1
//             final controllerKey = '$styleCode-$shade-$size';
//             final controller = TextEditingController(
//               text: '0',
//             ); // Default to '1'
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
//     return quantities[styleKey]?[shade]?[size] ?? 1; // Default to 1
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
//       _controllers.removeWhere((key, _) => key.contains('$styleKey-'));
//     });

//     widget.onCancel();
//     Navigator.pop(context);
//   }

//   void _copyFirstSizeQuantity(
//     String styleKey,
//     String shade,
//     List<String> sizes,
//   ) {
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

//   void _multiplyFirstSizeQuantity(
//     String styleKey,
//     String shade,
//     List<String> sizes,
//     int multiplier,
//   ) {
//     if (sizes.isEmpty) return;
//     final firstSize = sizes.first;
//     final firstQuantity = _getQuantity(styleKey, shade, firstSize);
//     final multipliedQuantity = firstQuantity * multiplier;
//     setState(() {
//       for (var size in sizes) {
//         _setQuantity(styleKey, shade, size, multipliedQuantity);
//         final controllerKey = '$styleKey-$shade-$size';
//         if (_controllers.containsKey(controllerKey)) {
//           _controllers[controllerKey]!.text = multipliedQuantity.toString();
//         }
//       }
//     });
//   }

//   Future<void> _submitAllOrders() async {
//     List<Future<http.Response>> apiCalls = [];
//     List<String> apiCallStyles = [];
//     final cartModel = Provider.of<CartModel>(context, listen: false);
//     addedItems.clear();

//     // Create a new list to store updated CatalogOrderData objects
//     List<CatalogOrderData> updatedCatalogOrderList = [];

//     for (var catalogOrder in catalogOrderList) {
//       final catalog = catalogOrder.catalog;
//       final matrix = catalogOrder.orderMatrix;
//       final styleCode = catalog.styleCode;
//       final styleKey = catalog.styleKey;

//       // Create a new matrix with updated quantities
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

//       // Create a new OrderMatrix with the updated matrix
//       final updatedOrderMatrix = OrderMatrix(
//         shades: matrix.shades,
//         sizes: matrix.sizes,
//         matrix: updatedMatrix,
//       );

//       // Create a new CatalogOrderData with the updated matrix
//       //catalog.barcode = widget.barcode;
//       final updatedCatalogOrder = CatalogOrderData(
//         catalog: catalog,
//         orderMatrix: updatedOrderMatrix,
//       );
//       //updatedCatalogOrder.catalog.barcode = widget.barcode;

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
//                 "Note": "",
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
//                   "Note": "",
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
//                 // builder: (context) => EditOrderScreenBarcode(docId: '-1'),
//                 // settings: RouteSettings(
//                 //   arguments: {'barcode': true, 'addedItems': addedItems},
//                 // ),
//               ),
//               // (route) => false,
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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text(
//           'Order Booking - BarcodeWise',
//           style: TextStyle(color: Colors.white),
//         ),
//         backgroundColor: AppColors.primaryColor,
//         elevation: 2,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: SafeArea(
//         child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             color: Colors.white,
//             child: Row(
//               children: [
//                 const Text(
//                   "Barcode:",
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Text(
//                   widget.barcode,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.red.shade900,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child:
//                 isLoading
//                     ? Stack(
//                       children: [
//                         Container(color: Colors.black.withOpacity(0.2)),
//                         Center(
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 12,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(4),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black12,
//                                   blurRadius: 8,
//                                   offset: Offset(0, 3),
//                                 ),
//                               ],
//                             ),
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: const [
//                                 Text(
//                                   'Please Wait...',
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black,
//                                   ),
//                                 ),
//                                 SizedBox(width: 12),
//                                 SizedBox(
//                                   width: 20,
//                                   height: 20,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2.5,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     )
//                     : SingleChildScrollView(
//                       padding: const EdgeInsets.only(
//                         left: 12.0,
//                         right: 12.0,
//                         bottom: 12.0,
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           ...catalogOrderList.map(
//                             (catalogOrder) => Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [buildOrderItem(catalogOrder, context)],
//                             ),
//                           ),
//                           const SizedBox(height: 20),
//                         ],
//                       ),
//                     ),
//           ),
//         ],
//       ),
//    ) );
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
//       final styleKey = catalogOrder.catalog.styleKey;
//       final matrix = catalogOrder.orderMatrix;
//       for (var shade in quantities[styleKey]?.keys ?? []) {
//         final shadeIndex = matrix.shades.indexOf(shade.toString().trim());
//         if (shadeIndex == -1) continue;
//         for (var size in quantities[styleKey]![shade]!.keys) {
//           final sizeIndex = matrix.sizes.indexOf(size.trim());
//           if (sizeIndex == -1) continue;
//           final rate =
//               double.tryParse(
//                 matrix.matrix[shadeIndex][sizeIndex].split(',')[0],
//               ) ??
//               0;
//           final quantity = quantities[styleKey]![shade]![size]!;
//           total += rate * quantity;
//         }
//       }
//     }
//     return total;
//   }

//   Widget buildOrderItem(CatalogOrderData catalogOrder, BuildContext context) {
//     final catalog = catalogOrder.catalog;
//     final Set<String> selectedColors = selectedColors2[catalog.styleKey] ?? {};

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
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
//                           (_) => ImageZoomScreen1(
//                             imageUrls: [imageUrl],
//                             item: catalog,
//                             showShades: true,
//                             showMRP: true,
//                             showWSP: true,
//                             showSizes: true,
//                             showProduct: true,
//                             showRemark: true,
//                             isLargeScreen:
//                                 MediaQuery.of(context).size.width > 600,
//                           ),
//                     ),
//                   );
//                 },
//                 child: Container(
//                   height: 160,
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey),
//                     borderRadius: BorderRadius.circular(4.0),
//                   ),
//                   child: Container(
//                     width: MediaQuery.of(context).size.width * 0.3,
//                     child: AspectRatio(
//                       aspectRatio: 3 / 4,
//                       child: Image.network(
//                         catalog.fullImagePath.contains("http")
//                             ? catalog.fullImagePath
//                             : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}',
//                         fit: BoxFit.contain,
//                         errorBuilder:
//                             (context, error, stackTrace) =>
//                                 const Icon(Icons.error, size: 60),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       catalog.styleCode,
//                       style: GoogleFonts.poppins(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                         color: Colors.red.shade900,
//                       ),
//                     ),
//                     Text(
//                       catalog.shadeName,
//                       style: GoogleFonts.roboto(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                         color: AppColors.primaryColor.shade900,
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Table(
//                       columnWidths: const {
//                         0: FixedColumnWidth(100),
//                         1: FixedColumnWidth(10),
//                         2: FlexColumnWidth(100),
//                       },
//                       defaultVerticalAlignment:
//                           TableCellVerticalAlignment.middle,
//                       children: [
//                         _buildTableRow(
//                           'Remark',
//                           catalog.remark.isNotEmpty ? catalog.remark : '',
//                         ),
//                         _buildTableRow(
//                           'Stk Type',
//                           catalog.upcoming_Stk == '1' ? 'Upcoming' : 'Ready',
//                         ),
//                         _buildTableRow(
//                           'Stock Qty',
//                           _calculateStockQuantity(catalog.styleKey).toString(),
//                           valueColor: Colors.green[700],
//                         ),
//                         _buildTableRow(
//                           'Order Qty',
//                           _calculateCatalogQuantity(
//                             catalog.styleKey,
//                           ).toString(),
//                           valueColor: Colors.orange[800],
//                         ),
//                         _buildTableRow(
//                           'Order Amount',
//                           _calculateCatalogPrice(
//                             catalog.styleKey,
//                           ).toStringAsFixed(2),
//                           valueColor: Colors.purple[800],
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 15),
//         ...selectedColors.map(
//           (color) => Column(
//             children: [
//               _buildColorSection(catalogOrder, color),
//               const SizedBox(height: 15),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   TableRow _buildTableRow(String label, String value, {Color? valueColor}) {
//     return TableRow(
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 4.0),
//           child: Align(
//             alignment: Alignment.centerLeft,
//             child: Text(label, style: GoogleFonts.roboto(fontSize: 14)),
//           ),
//         ),
//         const Padding(
//           padding: EdgeInsets.symmetric(vertical: 4.0),
//           child: Align(
//             alignment: Alignment.center,
//             child: Text(":", style: TextStyle(fontSize: 14)),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 4.0),
//           child: Align(
//             alignment: Alignment.centerLeft,
//             child: Text(
//               value,
//               style: GoogleFonts.roboto(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: valueColor ?? Colors.black,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
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

//   Widget _buildColorSection(CatalogOrderData catalogOrder, String shade) {
//     final sizes = catalogOrder.orderMatrix.sizes;
//     final styleKey = catalogOrder.catalog.styleKey;
//     final TextEditingController multiplierController = TextEditingController();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey.shade300),
//           ),
//           child: Column(
//             children: [
//               Divider(height: 1, color: Colors.grey.shade300),
//               Row(
//                 children: [
//                   _buildHeader("Size", 1),
//                   Expanded(
//                     flex: 2,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(vertical: 8),
//                       decoration: BoxDecoration(
//                         border: Border(
//                           right: BorderSide(color: Colors.grey.shade300),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             "Qty",
//                             style: GoogleFonts.roboto(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 14,
//                               color: Colors.red.shade900,
//                             ),
//                           ),
//                           const SizedBox(width: 4),
//                           IconButton(
//                             icon: const Icon(
//                               Icons.copy,
//                               size: 16,
//                               color: Colors.grey,
//                             ),
//                             padding: EdgeInsets.zero,
//                             constraints: const BoxConstraints(),
//                             onPressed: () async {
//                               final choice = await showDialog<String>(
//                                 context: context,
//                                 builder:
//                                     (context) => AlertDialog(
//                                       title: Text(
//                                         'Quantity Options',
//                                         style: GoogleFonts.poppins(),
//                                       ),
//                                       content: Column(
//                                         mainAxisSize: MainAxisSize.min,
//                                         children: [
//                                           ListTile(
//                                             title: Text(
//                                               'Copy qty to all sizes',
//                                               style: GoogleFonts.montserrat(),
//                                             ),
//                                             onTap:
//                                                 () => Navigator.pop(
//                                                   context,
//                                                   'copy',
//                                                 ),
//                                           ),
//                                           ListTile(
//                                             title: Text(
//                                               'Multiply qty * value to all sizes',
//                                               style: GoogleFonts.montserrat(),
//                                             ),
//                                             onTap:
//                                                 () => Navigator.pop(
//                                                   context,
//                                                   'multiply',
//                                                 ),
//                                           ),
//                                         ],
//                                       ),
//                                       actions: [
//                                         TextButton(
//                                           onPressed:
//                                               () => Navigator.pop(context),
//                                           child: Text(
//                                             'Cancel',
//                                             style: GoogleFonts.montserrat(),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                               );
//                               if (choice == 'copy') {
//                                 _copyFirstSizeQuantity(styleKey, shade, sizes);
//                               } else if (choice == 'multiply') {
//                                 final multiplier = await showDialog<int>(
//                                   context: context,
//                                   builder:
//                                       (context) => AlertDialog(
//                                         title: Text(
//                                           'Multiply Quantity',
//                                           style: GoogleFonts.poppins(),
//                                         ),
//                                         content: TextField(
//                                           controller: multiplierController,
//                                           keyboardType: TextInputType.number,
//                                           decoration: InputDecoration(
//                                             labelText: 'Enter multiplier',
//                                             border: OutlineInputBorder(),
//                                           ),
//                                           inputFormatters: [
//                                             FilteringTextInputFormatter
//                                                 .digitsOnly,
//                                             LengthLimitingTextInputFormatter(4),
//                                           ],
//                                         ),
//                                         actions: [
//                                           TextButton(
//                                             onPressed:
//                                                 () => Navigator.pop(context),
//                                             child: Text(
//                                               'Cancel',
//                                               style: GoogleFonts.montserrat(),
//                                             ),
//                                           ),
//                                           TextButton(
//                                             onPressed: () {
//                                               final value =
//                                                   int.tryParse(
//                                                     multiplierController.text,
//                                                   ) ??
//                                                   1;
//                                               Navigator.pop(context, value);
//                                             },
//                                             child: Text(
//                                               'OK',
//                                               style: GoogleFonts.montserrat(),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                 );
//                                 if (multiplier != null && multiplier > 0) {
//                                   _multiplyFirstSizeQuantity(
//                                     styleKey,
//                                     shade,
//                                     sizes,
//                                     multiplier,
//                                   );
//                                 }
//                               }
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   _buildHeader("MRP", 1),
//                   _buildHeader("WSP", 1),
//                   _buildHeader("Stock", 1),
//                 ],
//               ),
//               Divider(height: 1, color: Colors.grey.shade300),
//               for (var size in sizes) ...[
//                 _buildSizeRow(catalogOrder, shade, size),
//                 Divider(height: 1, color: Colors.grey.shade300),
//               ],
//             ],
//           ),
//         ),
//         const SizedBox(height: 16),
//         Row(
//           children: [
//             Expanded(
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.grey[300],
//                   shape: const RoundedRectangleBorder(
//                     borderRadius: BorderRadius.zero,
//                   ),
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                 ),
//                 onPressed: () => _deleteStyle(catalogOrder.catalog.styleKey),
//                 child: Text(
//                   'CANCEL',
//                   style: GoogleFonts.montserrat(color: Colors.black),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor:
//                       _calculateTotalQuantity() > 0
//                           ? Colors.green
//                           : Colors.grey,
//                   shape: const RoundedRectangleBorder(
//                     borderRadius: BorderRadius.zero,
//                   ),
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                 ),
//                 onPressed:
//                     _calculateTotalQuantity() > 0 ? _submitAllOrders : null,
//                 child: Text(
//                   'CONFIRM',
//                   style: GoogleFonts.montserrat(color: Colors.white),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildHeader(String text, int flex) => Expanded(
//     flex: flex,
//     child: Container(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       decoration: BoxDecoration(
//         border: Border(right: BorderSide(color: Colors.grey.shade300)),
//       ),
//       child: Text(
//         text,
//         textAlign: TextAlign.center,
//         style: GoogleFonts.lora(
//           fontWeight: FontWeight.bold,
//           fontSize: 14,
//           color: Colors.red.shade900,
//         ),
//       ),
//     ),
//   );

//   Widget _buildSizeRow(
//     CatalogOrderData catalogOrder,
//     String shade,
//     String size,
//   ) {
//     final matrix = catalogOrder.orderMatrix;
//     final shadeIndex = matrix.shades.indexOf(shade.trim());
//     final sizeIndex = matrix.sizes.indexOf(size?.trim() ?? '');
//     final styleKey = catalogOrder.catalog.styleKey;

//     String rate = '';
//     String wsp = '0';
//     String qty = '1'; // Default to '1'
//     String stkQty = '0';

//     if (shadeIndex != -1 && sizeIndex != -1) {
//       final matrixData = matrix.matrix[shadeIndex][sizeIndex].split(',');
//       rate = matrixData[0];
//       wsp = matrixData.length > 1 ? matrixData[1] : '0';
//       stkQty = matrixData.length > 3 ? matrixData[2] : '0';
//     }

//     int quantity = _getQuantity(styleKey, shade, size);

//     final controllerKey = '$styleKey-$shade-$size';
//     final controller = _controllers.putIfAbsent(
//       controllerKey,
//       () => TextEditingController(text: '1'), // Default to '1'
//     );

//     if (controller.text != quantity.toString()) {
//       controller.text = quantity.toString();
//     }

//     return Row(
//       children: [
//         _buildCell(size, 1),
//         Expanded(
//           flex: 2,
//           child: Container(
//             decoration: BoxDecoration(
//               border: Border(right: BorderSide(color: Colors.grey.shade300)),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 IconButton(
//                   onPressed: () {
//                     final newQuantity = quantity > 0 ? quantity - 1 : 0;
//                     _setQuantity(styleKey, shade, size, newQuantity);
//                     controller.text = newQuantity.toString();
//                   },
//                   icon: const Icon(Icons.remove, size: 20),
//                 ),
//                 SizedBox(
//                   width: 18,
//                   child: TextField(
//                     controller: controller,
//                     textAlign: TextAlign.center,
//                     keyboardType: TextInputType.number,
//                     decoration: InputDecoration(
//                       border: InputBorder.none,
//                       contentPadding: const EdgeInsets.symmetric(vertical: 8),
//                       hintText: stkQty,
//                       hintStyle: GoogleFonts.roboto(
//                         fontSize: 14,
//                         color: Colors.grey.shade500,
//                       ),
//                     ),
//                     style: GoogleFonts.roboto(fontSize: 14),
//                     inputFormatters: [
//                       FilteringTextInputFormatter.digitsOnly,
//                       LengthLimitingTextInputFormatter(4),
//                     ],
//                     onChanged: (value) {
//                       final newQuantity =
//                           int.tryParse(value.isEmpty ? '0' : value) ?? 0;
//                       _setQuantity(styleKey, shade, size, newQuantity);
//                     },
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: () {
//                     final newQuantity = quantity + 1;
//                     _setQuantity(styleKey, shade, size, newQuantity);
//                     controller.text = newQuantity.toString();
//                   },
//                   icon: const Icon(Icons.add, size: 20),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         _buildCell(rate, 1),
//         _buildCell(wsp, 1),
//         _buildCell(stkQty, 1),
//       ],
//     );
//   }

//   Widget _buildCell(String text, int flex) => Expanded(
//     flex: flex,
//     child: Container(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       decoration: BoxDecoration(
//         border: Border(right: BorderSide(color: Colors.grey.shade300)),
//       ),
//       child: Text(
//         text,
//         textAlign: TextAlign.center,
//         style: GoogleFonts.roboto(fontSize: 14),
//       ),
//     ),
//   );
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vrs_erp/catalog/image_zoom1.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/CartModel.dart';
import 'package:vrs_erp/models/CatalogOrderData.dart';
import 'package:vrs_erp/models/OrderMatrix.dart';
import 'package:vrs_erp/models/catalog.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_barcode2.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_data.dart';

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
    required this.fullImagePath,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      styleCode: json['styleCode']?.toString() ?? '',
      shadeName: json['shadeName']?.toString() ?? '',
      sizeName: json['sizeName']?.toString() ?? '',
      upcoming_Stk: json['upcoming_Stk']?.toString() ?? '',
      clQty: int.tryParse(json['clqty']?.toString() ?? '0') ?? 0,
      mrp: double.tryParse(json['mrp']?.toString() ?? '0') ?? 0,
      wsp: double.tryParse(json['wsp']?.toString() ?? '0') ?? 0,
      stkQty: json['data2']?.toString() ?? '0',
      barcode: json['barcode']?.toString() ?? '',  
      fullImagePath: json['fullImagePath']?.toString() ?? '/NoImage.jpg',
    );
  }
}

class BookOnBarcode2 extends StatefulWidget {
  final String barcode;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;
  final bool edit;

  const BookOnBarcode2({
    Key? key,
    required this.barcode,
    required this.onSuccess,
    required this.onCancel,
    this.edit = false,
  }) : super(key: key);

  @override
  State<BookOnBarcode2> createState() => _BookOnBarcode2State();
}

class _BookOnBarcode2State extends State<BookOnBarcode2> {
  List<CatalogOrderData> catalogOrderList = [];
  Map<String, Set<String>> selectedColors2 = {};
  Map<String, Map<String, Map<String, int>>> quantities = {};
  bool isLoading = true;
  bool hasData = false;
  final Map<String, TextEditingController> _controllers = {};
  String barcode = '';
  List<Map<String, dynamic>> addedItems = [];

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
    barcode = widget.barcode;
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      isLoading = true;
    });

    final catalogItems = await fetchCatalogData();
    final List<CatalogOrderData> tempList = [];

    if (catalogItems.isNotEmpty) {
      setState(() {
        hasData = true;
      });

      final styleGroups = <String, List<CatalogItem>>{};
      for (var item in catalogItems) {
        styleGroups.putIfAbsent(item.styleCode, () => []).add(item);
      }

      for (var styleCode in styleGroups.keys) {
        final items = styleGroups[styleCode]!;
        final uniqueShades = items.map((e) => e.shadeName).toSet().toList();
        final uniqueSizes = items.map((e) => e.sizeName).toSet().toList();

        final catalog = Catalog(
          itemSubGrpKey: '',
          itemSubGrpName: '',
          itemKey: '',
          itemName: 'Unknown Product',
          brandKey: '',
          brandName: '',
          styleKey: styleCode,
          styleCode: styleCode,
          shadeKey: '',
          shadeName: uniqueShades.join(','),
          styleSizeId: '',
          sizeName: uniqueSizes.join(','),
          mrp: items.first.mrp,
          wsp: items.first.wsp,
          onlyMRP: items.first.mrp,
          clqty: items.first.clQty,
          total: items.fold(0, (sum, item) => sum + item.clQty),
          upcoming_Stk: items.first.upcoming_Stk,
          fullImagePath: items.first.fullImagePath,
  
          remark: '',
          imageId: '',
          sizeDetails: uniqueSizes
              .map(
                (size) =>
                    '$size (${items.firstWhere((i) => i.sizeName == size).mrp},${items.firstWhere((i) => i.sizeName == size).wsp})',
              )
              .join(', '),
          sizeDetailsWithoutWSp: uniqueSizes
              .map(
                (size) =>
                    '$size (${items.firstWhere((i) => i.sizeName == size).mrp})',
              )
              .join(', '),
          sizeWithMrp: uniqueSizes
              .map(
                (size) =>
                    '$size (${items.firstWhere((i) => i.sizeName == size).mrp})',
              )
              .join(', '),
          styleCodeWithcount: styleCode,
          onlySizes: uniqueSizes.join(','),
          sizeWithWsp: uniqueSizes
              .map(
                (size) =>
                    '$size (${items.firstWhere((i) => i.sizeName == size).wsp})',
              )
              .join(', '),
          createdDate: '',
          shadeImages: '',
          barcode: items.first.barcode,
        );

        final matrix = <List<String>>[];
        for (var shade in uniqueShades) {
          final row = <String>[];
          for (var size in uniqueSizes) {
            final item = items.firstWhere(
              (i) => i.shadeName == shade && i.sizeName == size,
              orElse:
                  () => CatalogItem(
                    styleCode: styleCode,
                    shadeName: shade,
                    sizeName: size,
                    clQty: items.first.clQty,
                    mrp: items.first.mrp,
                    wsp: items.first.wsp,
                    upcoming_Stk: items.first.upcoming_Stk,
                    stkQty: items.first.stkQty,
                    barcode: items.first.barcode,
                    fullImagePath: items.first.fullImagePath,
  
                  ),
            );
            row.add('${item.mrp},${item.wsp},${item.clQty},${item.stkQty}');
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

        selectedColors2[styleCode] = uniqueShades.toSet();
        quantities[styleCode] = {};
        for (var shade in uniqueShades) {
          quantities[styleCode]![shade] = {};
          for (var size in uniqueSizes) {
            quantities[styleCode]![shade]![size] =
                UserSession.coBrName == 'G CUBE NX' ? 0 : 0;
            final controllerKey = '$styleCode-$shade-$size';
            final controller = TextEditingController(text: '0');
            controller.addListener(() => setState(() {}));
            _controllers[controllerKey] = controller;
          }
        }
      }
    } else {
      setState(() {
        hasData = false;
      });
    }

    setState(() {
      catalogOrderList = tempList;
      isLoading = false;
    });

    if (!hasData && mounted) {
      Navigator.pop(context, false);
    }
  }

  Future<List<CatalogItem>> fetchCatalogData() async {
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
        }
      } else if (response.statusCode == 500 &&
          response.body == 'Barcode already added') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This barcode is already added in the cart.'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      } else {
        debugPrint('Failed to fetch catalog data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching catalog data: $e');
    }
    return [];
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
      _controllers.removeWhere((key, _) => key.contains('$styleKey-'));
    });

    widget.onCancel();
    Navigator.pop(context);
  }

  void _copyFirstSizeQuantity(
    String styleKey,
    String shade,
    List<String> sizes,
  ) {
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

  void _multiplyFirstSizeQuantity(
    String styleKey,
    String shade,
    List<String> sizes,
    int multiplier,
  ) {
    if (sizes.isEmpty) return;
    final firstSize = sizes.first;
    final firstQuantity = _getQuantity(styleKey, shade, firstSize);
    final multipliedQuantity = firstQuantity * multiplier;
    setState(() {
      for (var size in sizes) {
        _setQuantity(styleKey, shade, size, multipliedQuantity);
        final controllerKey = '$styleKey-$shade-$size';
        if (_controllers.containsKey(controllerKey)) {
          _controllers[controllerKey]!.text = multipliedQuantity.toString();
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
                "Note": "",
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
                "itemName": catalog.itemName ?? 'Unknown Product',
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
                  "Note": "",
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
        cartModel.updateCount(cartModel.count + successfulLineItems);
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

  void _cancelAll() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel All Items'),
          content: const Text('Are you sure you want to cancel all items?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('NO'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (catalogOrderList.isNotEmpty) {
                  _deleteStyle(catalogOrderList.first.catalog.styleKey);
                } else {
                  widget.onCancel();
                  Navigator.pop(context);
                }
              },
              child: const Text('YES'),
            ),
          ],
        );
      },
    );
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
              // White divider line
              Container(
                height: 1,
                width: double.infinity,
                color: Colors.white.withOpacity(0.3),
              ),
              // Bottom container with totals
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
            // Main Content
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
                              const SizedBox(width: 16),
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
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...catalogOrderList.map(
                              (catalogOrder) => Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: buildOrderItem(catalogOrder, context),
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          !isLoading && hasData && catalogOrderList.isNotEmpty
              ? SafeArea(
                child: Container(
                  width: double.infinity,
                  child: Row(
                    children: [
                      // Cancel Button - 50% width
                      Expanded(
                        child: _buildCompactGradientButton(
                          label: 'CANCEL',
                          icon: Icons.close,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9E9E9E), Color(0xFF757575)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onPressed: _cancelAll,
                          height: 48,
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      // Confirm Button - 50% width
                      Expanded(
                        child: _buildCompactGradientButton(
                          label: 'CONFIRM',
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
                                    colors: [
                                      Color(0xFFBDBDBD),
                                      Color(0xFF9E9E9E),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                          onPressed:
                              _calculateTotalQuantity() > 0
                                  ? _submitAllOrders
                                  : null,
                          height: 48,
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : null,
    );
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
      final styleKey = catalogOrder.catalog.styleKey;
      final matrix = catalogOrder.orderMatrix;
      for (var shade in quantities[styleKey]?.keys ?? []) {
        final shadeIndex = matrix.shades.indexOf(shade.toString().trim());
        if (shadeIndex == -1) continue;
        for (var size in quantities[styleKey]![shade]!.keys) {
          final sizeIndex = matrix.sizes.indexOf(size.trim());
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
    return total;
  }

  Widget buildOrderItem(CatalogOrderData catalogOrder, BuildContext context) {
    final catalog = catalogOrder.catalog;
    final Set<String> selectedColors = selectedColors2[catalog.styleKey] ?? {};

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barcode inside card at top
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primaryColor.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "BARCODE :",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.barcode,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.maroon,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product Header with Image
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            (_) => ImageZoomScreen1(
                              imageUrls: [imageUrl],
                              item: catalog,
                              showShades: true,
                              showMRP: true,
                              showWSP: true,
                              showSizes: true,
                              showProduct: true,
                              showRemark: true,
                              isLargeScreen:
                                  MediaQuery.of(context).size.width > 600,
                            ),
                      ),
                    );
                  },
                  child: Container(
                    width: 90,
                    height: 83,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
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
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              color: Colors.grey[100],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey[400],
                                    size: 30,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'No Image',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              ],
                            ),
                            const SizedBox(height: 8),
                            Divider(
                              color: AppColors.primaryColor.withOpacity(0.2),
                              height: 1,
                              thickness: 1,
                            ),
                            const SizedBox(height: 8),
                            // Wrap for status chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                // Stock Type Chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        catalog.upcoming_Stk == '1'
                                            ? Colors.orange.withOpacity(0.8)
                                            : Colors.green.withOpacity(0.8),
                                        catalog.upcoming_Stk == '1'
                                            ? Colors.orange
                                            : Colors.green,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (catalog.upcoming_Stk == '1'
                                                ? Colors.orange
                                                : Colors.green)
                                            .withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        catalog.upcoming_Stk == '1'
                                            ? Icons.schedule
                                            : Icons.inventory,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        catalog.upcoming_Stk == '1'
                                            ? 'Upcoming'
                                            : 'Ready',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Shades Chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.withOpacity(0.8),
                                        Colors.blue.shade700,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.palette,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${uniqueShadesCount(catalog.styleKey)} Shades',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
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
              ],
            ),
          ),

          const SizedBox(height: 8),

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
                    '₹${_calculateCatalogPrice(catalog.styleKey).toStringAsFixed(0)}',
                    Icons.currency_rupee,
                    Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Color Sections - Original table design preserved
          ...selectedColors.map(
            (color) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildColorSection(catalogOrder, color),
            ),
          ),

          // const SizedBox(height: 5),

          // Note field
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
                  borderSide: BorderSide(color: Colors.grey.shade300),
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
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Helper method to count unique shades
  int uniqueShadesCount(String styleKey) {
    return selectedColors2[styleKey]?.length ?? 0;
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

  Widget _buildCompactGradientButton({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback? onPressed,
    double height = 48,
    BorderRadius borderRadius = BorderRadius.zero,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(gradient: gradient, borderRadius: borderRadius),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          minimumSize: Size(double.infinity, height),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Original table design - completely preserved
  TableRow _buildTableRow(String label, String value, {Color? valueColor}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(label, style: GoogleFonts.roboto(fontSize: 14)),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: Align(
            alignment: Alignment.center,
            child: Text(":", style: TextStyle(fontSize: 14)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
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

  // Add this method to your class to get color based on shade name
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
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'pink':
        return Colors.pink;
      case 'brown':
        return Colors.brown;
      case 'grey':
      case 'gray':
        return Colors.grey;
      default:
        // Return a random color based on string hash for variety
        return Colors.primaries[color.hashCode % Colors.primaries.length];
    }
  }

  // Helper method to calculate quantity for a specific shade
  int _calculateShadeQuantity(String styleKey, String shade) {
    int total = 0;
    final shadeQuantities = quantities[styleKey]?[shade];
    if (shadeQuantities != null) {
      for (var qty in shadeQuantities.values) {
        total += qty;
      }
    }
    return total;
  }

  Widget _buildColorSection(CatalogOrderData catalogOrder, String shade) {
    final sizes = catalogOrder.orderMatrix.sizes;
    final styleKey = catalogOrder.catalog.styleKey;
    final TextEditingController multiplierController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern Card-style Header (Option 4)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: _getColorCode(shade).withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border(
              left: BorderSide(color: _getColorCode(shade), width: 3),
            ),
          ),
          child: Row(
            children: [
              // Color indicator with shine effect
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    colors: [
                      _getColorCode(shade),
                      _getColorCode(shade).withOpacity(0.7),
                      _getColorCode(shade),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Shade name
              Expanded(
                child: Text(
                  shade,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Quantity summary for this shade
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getColorCode(shade).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Qty: ${_calculateShadeQuantity(styleKey, shade)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getColorCode(shade),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Original table structure preserved
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              // Header row
              Row(
                children: [
                  _buildHeader("Size", 1),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Qty",
                            style: GoogleFonts.lora(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.red.shade900,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(
                              Icons.copy,
                              size: 16,
                              color: Colors.grey,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              final choice = await showDialog<String>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text(
                                        'Quantity Options',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            title: Text(
                                              'Copy qty to all sizes',
                                              style: GoogleFonts.montserrat(),
                                            ),
                                            onTap:
                                                () => Navigator.pop(
                                                  context,
                                                  'copy',
                                                ),
                                          ),
                                          ListTile(
                                            title: Text(
                                              'Multiply qty * value to all sizes',
                                              style: GoogleFonts.montserrat(),
                                            ),
                                            onTap:
                                                () => Navigator.pop(
                                                  context,
                                                  'multiply',
                                                ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: Text(
                                            'Cancel',
                                            style: GoogleFonts.montserrat(),
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                              if (choice == 'copy') {
                                _copyFirstSizeQuantity(styleKey, shade, sizes);
                              } else if (choice == 'multiply') {
                                final multiplier = await showDialog<int>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: Text(
                                          'Multiply Quantity',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        content: TextField(
                                          controller: multiplierController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Enter multiplier',
                                            border: OutlineInputBorder(),
                                          ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(4),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: Text(
                                              'Cancel',
                                              style: GoogleFonts.montserrat(),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              final value =
                                                  int.tryParse(
                                                    multiplierController.text,
                                                  ) ??
                                                  1;
                                              Navigator.pop(context, value);
                                            },
                                            child: Text(
                                              'OK',
                                              style: GoogleFonts.montserrat(),
                                            ),
                                          ),
                                        ],
                                      ),
                                );
                                if (multiplier != null && multiplier > 0) {
                                  _multiplyFirstSizeQuantity(
                                    styleKey,
                                    shade,
                                    sizes,
                                    multiplier,
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildHeader("MRP", 1),
                  _buildHeader("WSP", 1),
                  _buildHeader("Stock", 1),
                ],
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              // Size rows
              for (var size in sizes) ...[
                _buildSizeRow(catalogOrder, shade, size),
                Divider(height: 1, color: Colors.grey.shade300),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Original header builder
  Widget _buildHeader(String text, int flex) => Expanded(
    flex: flex,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.lora(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.red.shade900,
        ),
      ),
    ),
  );

  // Original size row builder
  Widget _buildSizeRow(
    CatalogOrderData catalogOrder,
    String shade,
    String size,
  ) {
    final matrix = catalogOrder.orderMatrix;
    final shadeIndex = matrix.shades.indexOf(shade.trim());
    final sizeIndex = matrix.sizes.indexOf(size?.trim() ?? '');
    final styleKey = catalogOrder.catalog.styleKey;

    String rate = '';
    String wsp = '0';
    String qty = '1';
    String stkQty = '0';

    if (shadeIndex != -1 && sizeIndex != -1) {
      final matrixData = matrix.matrix[shadeIndex][sizeIndex].split(',');
      rate = matrixData[0];
      wsp = matrixData.length > 1 ? matrixData[1] : '0';
      stkQty = matrixData.length > 3 ? matrixData[2] : '0';
    }

    int quantity = _getQuantity(styleKey, shade, size);

    final controllerKey = '$styleKey-$shade-$size';
    final controller = _controllers.putIfAbsent(
      controllerKey,
      () => TextEditingController(text: '1'),
    );

    if (controller.text != quantity.toString()) {
      controller.text = quantity.toString();
    }

    return Row(
      children: [
        _buildCell(size, 1),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    final newQuantity = quantity > 0 ? quantity - 1 : 0;
                    _setQuantity(styleKey, shade, size, newQuantity);
                    controller.text = newQuantity.toString();
                  },
                  icon: const Icon(Icons.remove, size: 20),
                ),
                SizedBox(
                  width: 18,
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      hintText: stkQty,
                      hintStyle: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    style: GoogleFonts.roboto(fontSize: 14),
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
                IconButton(
                  onPressed: () {
                    final newQuantity = quantity + 1;
                    _setQuantity(styleKey, shade, size, newQuantity);
                    controller.text = newQuantity.toString();
                  },
                  icon: const Icon(Icons.add, size: 20),
                ),
              ],
            ),
          ),
        ),
        _buildCell(rate, 1),
        _buildCell(wsp, 1),
        _buildCell(stkQty, 1),
      ],
    );
  }

  // Original cell builder
  Widget _buildCell(String text, int flex) => Expanded(
    flex: flex,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.roboto(fontSize: 14),
      ),
    ),
  );
}
