// // import 'package:flutter/material.dart';
// // import 'package:intl/intl.dart';
// // import 'package:dropdown_search/dropdown_search.dart';
// // import 'package:loading_animation_widget/loading_animation_widget.dart';
// // import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:vrs_erp/constants/app_constants.dart';
// // import 'package:vrs_erp/dashboard/orderStatusFilter.dart';
// // import 'package:vrs_erp/models/brand.dart';
// // import 'dart:convert';
// // import 'package:vrs_erp/models/item.dart';
// // import 'package:vrs_erp/models/keyName.dart';
// // import 'package:vrs_erp/models/shade.dart';
// // import 'package:vrs_erp/models/size.dart';
// // import 'package:vrs_erp/models/style.dart';
// // import 'package:vrs_erp/services/app_services.dart';

// // class OrderStatus extends StatefulWidget {
// //   const OrderStatus({super.key}); // Correct constructor with super.key

// //   @override
// //   _OrderStatusState createState() => _OrderStatusState();
// // }

// // class _OrderStatusState extends State<OrderStatus> {
// //   List<String> _selectedProducts = [];
// //   String? _selectedCategory; // Single selection for category
// //   List<Item> _products = [];
// //   List<String> _categories = [];
// //   List<Brand> _brands = [];
// //   List<Style> _styles = [];
// //   List<Shade> _shades = [];
// //   List<Sizes> _sizes = [];
// //   List<dynamic> _orderData = [];
// //   bool _isLoading = false;
// //   bool _isLoadingProducts = false;
// //   Map<String, dynamic> _currentFilters = {};

// //   @override
// //   void initState() {
// //     super.initState();
// //     _currentFilters = {
// //       'fromDate': DateTime.now().subtract(const Duration(days: 30)),
// //       'toDate': DateTime.now(),
// //       'selectedBrand': <KeyName>[],
// //       'selectedStyle': <KeyName>[],
// //       'selectedShade': <KeyName>[],
// //       'selectedSize': <KeyName>[],
// //       'selectedStatus': KeyName(key: 'all', name: 'All'),
// //       'groupBy': KeyName(key: 'cust', name: 'Customer'),
// //       'withImage': false,
// //     };
// //     _fetchCategories();
// //     _fetchProducts();
// //     _fetchBrands();
// //   }

// //   Future<void> _fetchCategories() async {
// //     setState(() {
// //       _isLoading = true;
// //     });
// //     try {
// //       final response = await ApiService.fetchLedgers(
// //         ledCat: 'W',
// //         coBrId: '01',
// //       );
// //       if (response['statusCode'] == 200) {
// //         final List<KeyName> result = response['result'];
// //         setState(() {
// //           _categories = result.map((item) => item.name).toList();
// //           _isLoading = false;
// //         });
// //       } else {
// //         setState(() {
// //           _isLoading = false;
// //         });
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('Failed to fetch categories: ${response['statusCode']}')),
// //         );
// //       }
// //     } catch (e) {
// //       setState(() {
// //         _isLoading = false;
// //       });
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error loading categories: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _fetchProducts() async {
// //     setState(() {
// //       _isLoadingProducts = true;
// //     });
// //     try {
// //       final products = await ApiService.fetchAllItems();
// //       setState(() {
// //         _products = products;
// //         _isLoadingProducts = false;
// //       });
// //     } catch (e) {
// //       setState(() {
// //         _isLoadingProducts = false;
// //       });
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error loading products: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _fetchBrands() async {
// //     try {
// //       final brands = await ApiService.fetchBrands();
// //       setState(() {
// //         _brands = brands;
// //       });
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error loading brands: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _fetchStyles({String? itemKey}) async {
// //     try {
// //       List<Style> styles = [];
// //       if (itemKey != null && itemKey.isNotEmpty) {
// //         styles = await ApiService.fetchStylesByItemKey(itemKey);
// //       }
// //       setState(() {
// //         _styles = styles;
// //       });
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error loading styles: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _fetchShades({String? itemKey}) async {
// //     try {
// //       List<Shade> shades = [];
// //       if (itemKey != null && itemKey.isNotEmpty) {
// //         shades = await ApiService.fetchShadesByItemKey(itemKey);
// //       }
// //       setState(() {
// //         _shades = shades;
// //       });
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error loading shades: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _fetchSizes({String? itemKey}) async {
// //     try {
// //       List<Sizes> sizes = [];
// //       if (itemKey != null && itemKey.isNotEmpty) {
// //         sizes = await ApiService.fetchStylesSizeByItemKey(itemKey);
// //       }
// //       setState(() {
// //         _sizes = sizes;
// //       });
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error loading sizes: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _fetchOrderStatus(Map<String, dynamic> filters) async {
// //     if (_selectedProducts.isEmpty || _selectedCategory == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Please select at least one product and a category')),
// //       );
// //       return;
// //     }
// //     setState(() {
// //       _isLoading = true;
// //     });
// //     try {
// //       final selectedBrand = filters['selectedBrand'] as List<KeyName>?;
// //       final selectedStyle = filters['selectedStyle'] as List<KeyName>?;
// //       final selectedShade = filters['selectedShade'] as List<KeyName>?;
// //       final selectedSize = filters['selectedSize'] as List<KeyName>?;
// //       final selectedStatus = filters['selectedStatus'] as KeyName?;
// //       final groupBy = filters['groupBy'] as KeyName?;

// //       final requestBody = {
// //         'product': _selectedProducts.join(','),
// //         'groupby': groupBy?.key ?? 'cust',
// //         'CoBr_Id': UserSession.coBrId ?? '01',
// //         'brand': selectedBrand?.isNotEmpty == true ? selectedBrand?.map((b) => b.key).join(',') : null,
// //         'style': selectedStyle?.isNotEmpty == true ? selectedStyle?.map((s) => s.key).join(',') : null,
// //         'shade': selectedShade?.isNotEmpty == true ? selectedShade?.map((s) => s.key).join(',') : null,
// //         'size': selectedSize?.isNotEmpty == true ? selectedSize?.map((s) => s.key).join(',') : null,
// //         'status': selectedStatus?.key != 'all' ? selectedStatus?.key : null,
// //       };

// //       print('Request Body: ${jsonEncode(requestBody)}');

// //       final response = await http.post(
// //         Uri.parse('${AppConstants.BASE_URL}/report/GetOrderStatus'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: jsonEncode(requestBody),
// //       );

// //       print('Response Body: ${response.body}');

// //       if (response.statusCode == 200) {
// //         final List<dynamic> result = jsonDecode(response.body);
// //         setState(() {
// //           _orderData = result;
// //           _isLoading = false;
// //         });
// //       } else {
// //         setState(() {
// //           _isLoading = false;
// //         });
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('Failed to fetch order status: ${response.statusCode}')),
// //         );
// //       }
// //     } catch (e) {
// //       setState(() {
// //         _isLoading = false;
// //       });
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error fetching order status: $e')),
// //       );
// //     }
// //   }

// //   void _showFilterDialog() async {
// //     final List<KeyName> statusList = [
// //       KeyName(key: 'all', name: 'All'),
// //       KeyName(key: 'pending', name: 'Pending'),
// //       KeyName(key: 'completed', name: 'Completed'),
// //     ];

// //     final result = await Navigator.push(
// //       context,
// //       PageRouteBuilder(
// //         pageBuilder: (context, animation, secondaryAnimation) => OrderStatusFilterPage(
// //           brandsList: _brands
// //               .map((b) => KeyName(key: b.brandKey, name: b.brandName))
// //               .toList(),
// //           stylesList: _styles
// //               .map((s) => KeyName(key: s.styleKey, name: s.styleCode))
// //               .toList(),
// //           shadesList: _shades
// //               .map((s) => KeyName(key: s.shadeKey, name: s.shadeName))
// //               .toList(),
// //           sizesList: _sizes
// //               .map((s) => KeyName(key: s.itemSizeKey, name: s.sizeName))
// //               .toList(),
// //           statusList: statusList,
// //           initialFilters: _currentFilters,
// //           onApplyFilters: ({
// //             fromDate,
// //             toDate,
// //             selectedBrand,
// //             selectedStyle,
// //             selectedShade,
// //             selectedSize,
// //             selectedStatus,
// //             groupBy,
// //             withImage,
// //           }) {
// //             final newFilters = {
// //               'fromDate': fromDate,
// //               'toDate': toDate,
// //               'selectedBrand': selectedBrand,
// //               'selectedStyle': selectedStyle,
// //               'selectedShade': selectedShade,
// //               'selectedSize': selectedSize,
// //               'selectedStatus': selectedStatus,
// //               'groupBy': groupBy,
// //               'withImage': withImage,
// //             };
// //             Navigator.pop(context, newFilters);
// //           },
// //         ),
// //         transitionDuration: const Duration(milliseconds: 500),
// //         transitionsBuilder: (context, animation, secondaryAnimation, child) {
// //           return ScaleTransition(
// //             scale: animation,
// //             alignment: Alignment.bottomRight,
// //             child: FadeTransition(opacity: animation, child: child),
// //           );
// //         },
// //       ),
// //     );

// //     if (result != null) {
// //       setState(() {
// //         _currentFilters = result;
// //         _orderData = [];
// //       });
// //       await _fetchOrderStatus(_currentFilters);
// //     }
// //   }

// //   Future<void> _fetchStockReport({
// //     required String itemSubGrpKey,
// //     required String itemKey,
// //     String? brandKey,
// //     String? styleKey,
// //     String? shadeKey,
// //     String? sizeKey,
// //   }) async {
// //     setState(() {
// //       _isLoading = true;
// //     });
// //     try {
// //       final stockReport = await ApiService.fetchStockReport(
// //         itemSubGrpKey: itemSubGrpKey,
// //         itemKey: itemKey,
// //         userId: UserSession.userName ?? '',
// //         fcYrId: UserSession.userFcYr ?? '',
// //         cobr: UserSession.coBrId ?? '01',
// //         brandKey: brandKey,
// //         styleKey: styleKey,
// //         shadeKey: shadeKey,
// //         sizeKey: sizeKey,
// //         fromMRP: null,
// //         toMRP: null,
// //       );
// //       setState(() {
// //         _isLoading = false;
// //         print('Stock Report: $stockReport');
// //       });
// //     } catch (e) {
// //       setState(() {
// //         _isLoading = false;
// //       });
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error fetching stock report: $e')),
// //       );
// //     }
// //   }

// //   String _getImageUrl(dynamic catalog) {
// //     if (catalog['Style_Image'].startsWith('http')) {
// //       return catalog['Style_Image'];
// //     }
// //     final imageName = catalog['Style_Image'].split('/').last.split('?').first;
// //     return '${AppConstants.BASE_URL}/images/$imageName';
// //   }

// //   void clearFilters() {
// //     setState(() {
// //       _selectedProducts = [];
// //       _selectedCategory = null;
// //       _orderData = [];
// //       _styles = [];
// //       _shades = [];
// //       _sizes = [];
// //       _currentFilters = {
// //         'fromDate': DateTime.now().subtract(const Duration(days: 30)),
// //         'toDate': DateTime.now(),
// //         'selectedBrand': <KeyName>[],
// //         'selectedStyle': <KeyName>[],
// //         'selectedShade': <KeyName>[],
// //         'selectedSize': <KeyName>[],
// //         'selectedStatus': KeyName(key: 'all', name: 'All'),
// //         'groupBy': KeyName(key: 'cust', name: 'Customer'),
// //         'withImage': false,
// //       };
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Order Status'),
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(12.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             // Product Dropdown (Multi-select)
// //             Padding(
// //               padding: const EdgeInsets.symmetric(vertical: 8.0),
// //               child: DropdownSearch<String>.multiSelection(
// //                 items: _products.map((product) => product.itemKey).toList(),
// //                 selectedItems: _selectedProducts,
// //                 onChanged: (List<String> newValues) {
// //                   setState(() {
// //                     _selectedProducts = newValues;
// //                   });
// //                   if (newValues.isNotEmpty) {
// //                     for (var itemKey in newValues) {
// //                       _fetchStyles(itemKey: itemKey);
// //                       _fetchShades(itemKey: itemKey);
// //                       _fetchSizes(itemKey: itemKey);
// //                     }
// //                   } else {
// //                     setState(() {
// //                       _styles = [];
// //                       _shades = [];
// //                       _sizes = [];
// //                     });
// //                   }
// //                 },
// //                 popupProps: PopupPropsMultiSelection.menu(
// //                   showSearchBox: true,
// //                   loadingBuilder: (context, searchEntry) => Row(
// //                     mainAxisAlignment: MainAxisAlignment.center,
// //                     children: [
// //                       LoadingAnimationWidget.waveDots(
// //                         color: Colors.blue,
// //                         size: 20,
// //                       ),
// //                       const SizedBox(width: 8),
// //                       const Text('Loading Products...'),
// //                     ],
// //                   ),
// //                 ),
// //                 dropdownDecoratorProps: const DropDownDecoratorProps(
// //                   dropdownSearchDecoration: InputDecoration(
// //                     labelText: 'Select Products',
// //                     border: OutlineInputBorder(),
// //                     contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// //                   ),
// //                 ),
// //                 itemAsString: (String? key) {
// //                   final product = _products.firstWhere(
// //                     (p) => p.itemKey == key,
// //                     orElse: () => Item(itemKey: '', itemName: ''),
// //                   );
// //                   return product.itemName;
// //                 },
// //                 enabled: !_isLoadingProducts,
// //               ),
// //             ),
// //             // Category Dropdown (Single-select)
// //             Padding(
// //               padding: const EdgeInsets.symmetric(vertical: 8.0),
// //               child: DropdownSearch<String>(
// //                 items: _categories,
// //                 selectedItem: _selectedCategory,
// //                 onChanged: (String? newValue) {
// //                   setState(() {
// //                     _selectedCategory = newValue;
// //                   });
// //                 },
// //                 popupProps: PopupProps.menu(
// //                   showSearchBox: true,
// //                   loadingBuilder: (context, searchEntry) => Row(
// //                     mainAxisAlignment: MainAxisAlignment.center,
// //                     children: [
// //                       LoadingAnimationWidget.waveDots(
// //                         color: Colors.blue,
// //                         size: 20,
// //                       ),
// //                       const SizedBox(width: 8),
// //                       const Text('Loading Categories...'),
// //                     ],
// //                   ),
// //                 ),
// //                 dropdownDecoratorProps: const DropDownDecoratorProps(
// //                   dropdownSearchDecoration: InputDecoration(
// //                     labelText: 'Select Category',
// //                     border: OutlineInputBorder(),
// //                     contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// //                   ),
// //                 ),
// //                 enabled: !_isLoading,
// //               ),
// //             ),
// //             // Buttons Row
// //             Padding(
// //               padding: const EdgeInsets.symmetric(vertical: 8.0),
// //               child: Row(
// //                 children: [
// //                   _buildButton("View", Icons.visibility, Colors.blue, () async {
// //                     await _fetchOrderStatus(_currentFilters);
// //                   }),
// //                   const SizedBox(width: 8),
// //                   _buildButton("Download", Icons.download, Colors.deepPurple, () {
// //                     // TODO: Implement download logic
// //                   }),
// //                   const SizedBox(width: 8),
// //                   _buildButton("WhatsApp", FontAwesomeIcons.whatsapp, Colors.green, () {
// //                     // TODO: Implement WhatsApp logic
// //                   }, isFaIcon: true),
// //                   const SizedBox(width: 8),
// //                   _buildButton("Clear", Icons.clear, Colors.red, clearFilters),
// //                 ],
// //               ),
// //             ),
// //             // Display Order Data
// //             Expanded(
// //               child: _isLoading
// //                   ? const Center(child: CircularProgressIndicator())
// //                   : _orderData.isEmpty
// //                       ? const Center(child: Text('No orders found'))
// //                       : ListView.builder(
// //                           itemCount: _orderData.length,
// //                           itemBuilder: (context, index) {
// //                             final order = _orderData[index];
// //                             return Card(
// //                               margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
// //                               child: Padding(
// //                                 padding: const EdgeInsets.all(12.0),
// //                                 child: Column(
// //                                   crossAxisAlignment: CrossAxisAlignment.start,
// //                                   children: [
// //                                     Text(
// //                                       'Order: ${order['OrderNo']}',
// //                                       style: const TextStyle(
// //                                         fontWeight: FontWeight.bold,
// //                                         fontSize: 16,
// //                                       ),
// //                                     ),
// //                                     const SizedBox(height: 8),
// //                                     Text('Item: ${order['ItemName']}'),
// //                                     Text('Color: ${order['Color']}'),
// //                                     Text('Size: ${order['Size']}'),
// //                                     Text('Party: ${order['Party']}'),
// //                                     Text('Order Qty: ${order['OrderQty']}'),
// //                                     Text('Delivered Qty: ${order['DelvQty']}'),
// //                                     Text('Settled Qty: ${order['SettleQty']}'),
// //                                     Text('Pending Qty: ${order['PendingQty']}'),
// //                                     if (_currentFilters['withImage'] == true &&
// //                                         order['Style_Image'] != null &&
// //                                         order['Style_Image'].isNotEmpty)
// //                                       Padding(
// //                                         padding: const EdgeInsets.only(top: 8),
// //                                         child: Image.network(
// //                                           _getImageUrl(order),
// //                                           height: 100,
// //                                           width: double.infinity,
// //                                           fit: BoxFit.cover,
// //                                           errorBuilder: (context, error, stackTrace) =>
// //                                               const Text('Failed to load image'),
// //                                         ),
// //                                       ),
// //                                   ],
// //                                 ),
// //                               ),
// //                             );
// //                           },
// //                         ),
// //             ),
// //           ],
// //         ),
// //       ),
// //       floatingActionButton: Padding(
// //         padding: const EdgeInsets.only(bottom: 120.0),
// //         child: FloatingActionButton(
// //           onPressed: _showFilterDialog,
// //           backgroundColor: Colors.blue,
// //           child: const Icon(Icons.filter_list, color: Colors.white),
// //           tooltip: 'Filter Options',
// //         ),
// //       ),
// //     );
// //   }

// //   String _formatDate(DateTime? date) {
// //     return date != null ? DateFormat('dd-MM-yyyy').format(date) : '';
// //   }

// //   Widget _buildButton(String label, IconData icon, Color color, VoidCallback onPressed, {bool isFaIcon = false}) {
// //     return Expanded(
// //       child: SizedBox(
// //         height: 40,
// //         child: OutlinedButton.icon(
// //           onPressed: onPressed,
// //           icon: isFaIcon
// //               ? FaIcon(icon, size: 12, color: color)
// //               : Icon(icon, size: 12, color: color),
// //           label: Text(
// //             label,
// //             style: TextStyle(fontSize: 10, color: color),
// //             softWrap: false,
// //           ),
// //           style: OutlinedButton.styleFrom(
// //             padding: const EdgeInsets.symmetric(horizontal: 8),
// //             shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
// //             side: BorderSide(color: color),
// //             foregroundColor: color,
// //             backgroundColor: Colors.transparent,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:vrs_erp/constants/app_constants.dart';
// import 'package:vrs_erp/dashboard/orderStatusFilter.dart';
// import 'package:vrs_erp/models/brand.dart';
// import 'package:vrs_erp/models/item.dart';
// import 'dart:convert';
// import 'package:vrs_erp/models/keyName.dart';
// import 'package:vrs_erp/models/shade.dart';
// import 'package:vrs_erp/models/size.dart';
// import 'package:vrs_erp/models/style.dart';
// import 'package:vrs_erp/services/app_services.dart';
// import 'order_status_card.dart';

// class OrderStatus extends StatefulWidget {
//   const OrderStatus({super.key});

//   @override
//   _OrderStatusState createState() => _OrderStatusState();
// }

// class _OrderStatusState extends State<OrderStatus> {
//   List<String> _selectedProducts = [];
//   String? _selectedCategory;
//   List<Item> _products = [];
//   List<String> _categories = [];
//   List<Brand> _brands = [];
//   List<Style> _styles = [];
//   List<Shade> _shades = [];
//   List<Sizes> _sizes = [];
//   List<dynamic> _orderData = [];
//   bool _isLoading = false;
//   bool _isLoadingProducts = false;
//   Map<String, dynamic> _currentFilters = {};

//   @override
//   void initState() {
//     super.initState();
//     _currentFilters = {
//       'fromDate': DateTime.now().subtract(const Duration(days: 30)),
//       'toDate': DateTime.now(),
//       'selectedDateRange': 'Custom',
//       'selectedBrand': <KeyName>[],
//       'selectedStyle': <KeyName>[],
//       'selectedShade': <KeyName>[],
//       'selectedSize': <KeyName>[],
//       'selectedStatus': KeyName(key: 'all', name: 'All'),
//       'groupBy': KeyName(key: 'cust', name: 'Customer'),
//       'withImage': true,
//     };
//     _fetchCategories();
//     _fetchProducts();
//     _fetchBrands();
//   }

//   Future<void> _fetchCategories() async {
//     setState(() {
//       _isLoading = true;
//     });
//     try {
//       final response = await ApiService.fetchLedgers(ledCat: 'W', coBrId: '01');
//       if (response['statusCode'] == 200) {
//         final List<KeyName> result = response['result'];
//         setState(() {
//           _categories = result.map((item) => item.name).toList();
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           _isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Failed to fetch categories: ${response['statusCode']}',
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error loading categories: $e')));
//     }
//   }

//   Future<void> _fetchProducts() async {
//     setState(() {
//       _isLoadingProducts = true;
//     });
//     try {
//       final products = await ApiService.fetchAllItems();
//       setState(() {
//         _products = products;
//         _isLoadingProducts = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoadingProducts = false;
//       });
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
//     }
//   }

//   Future<void> _fetchBrands() async {
//     try {
//       final brands = await ApiService.fetchBrands();
//       setState(() {
//         _brands = brands;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error loading brands: $e')));
//     }
//   }

//   Future<void> _fetchStyles({String? itemKey}) async {
//     try {
//       List<Style> styles = [];
//       if (itemKey != null && itemKey.isNotEmpty) {
//         styles = await ApiService.fetchStylesByItemKey(itemKey);
//       }
//       setState(() {
//         _styles = _styles;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error loading styles: $e}')));
//     }
//   }

//   Future<void> _fetchShades({String? itemKey}) async {
//     try {
//       List<Shade> shades = [];
//       if (itemKey != null && itemKey.isNotEmpty) {
//         shades = await ApiService.fetchShadesByItemKey(itemKey);
//       }
//       setState(() {
//         _shades = shades;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error loading shades: $e')));
//     }
//   }

//   Future<void> _fetchSizes({String? itemKey}) async {
//     try {
//       List<Sizes> sizes = [];
//       if (itemKey != null && itemKey.isNotEmpty) {
//         sizes = await ApiService.fetchStylesSizeByItemKey(itemKey);
//       }
//       setState(() {
//         _sizes = sizes;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error loading sizes: $e')));
//     }
//   }

//   Future<void> _fetchOrderStatus(Map<String, dynamic> filters) async {
//     if (_selectedProducts.isEmpty || _selectedCategory == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select at least one product and a category'),
//         ),
//       );
//       return;
//     }
//     setState(() {
//       _isLoading = true;
//     });
//     try {
//       final selectedBrand = filters['selectedBrand'] as List<KeyName>?;
//       final selectedStyle = filters['selectedStyle'] as List<KeyName>?;
//       final selectedShade = filters['selectedShade'] as List<KeyName>?;
//       final selectedSize = filters['selectedSize'] as List<KeyName>?;
//       final selectedStatus = filters['selectedStatus'] as KeyName?;
//       final groupBy = filters['groupBy'] as KeyName?;

//       final requestBody = {
//         'product': _selectedProducts.join(','),
//         'groupby': groupBy?.key ?? 'cust',
//         'CoBr_Id': UserSession.coBrId ?? '01',
//         'brand':
//             selectedBrand?.isNotEmpty == true
//                 ? selectedBrand!.map((b) => b.key).join(',')
//                 : null,
//         'style':
//             selectedStyle?.isNotEmpty == true
//                 ? selectedStyle!.map((s) => s.key).join(',')
//                 : null,
//         'shade':
//             selectedShade?.isNotEmpty == true
//                 ? selectedShade!.map((s) => s.key).join(',')
//                 : null,
//         'size':
//             selectedSize?.isNotEmpty == true
//                 ? selectedSize!.map((s) => s.key).join(',')
//                 : null,
//         'status': selectedStatus?.key != 'all' ? selectedStatus?.key : null,
//       };

//       print('Request Body: ${jsonEncode(requestBody)}');

//       final response = await http.post(
//         Uri.parse(
//           '${AppConstants.BASE_URL}/report/GetOrderStatus?t=${DateTime.now().millisecondsSinceEpoch}',
//         ),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(requestBody),
//       );

//       print('Response Body: ${response.body}');

//       if (response.statusCode == 200) {
//         final dynamic result = jsonDecode(response.body);
//         List<dynamic> flattenedResult =
//             result is List && result.isNotEmpty && result[0] is List
//                 ? result.expand((i) => i).toList()
//                 : result is List
//                 ? result
//                 : [];

//              for (var item in flattenedResult) {
//       final colorCode = item['Color']?.toString();
//       if (colorCode != null && colorCode.isNotEmpty) {
//         try {
//           var shade = _shades.firstWhere((s) => s.shadeKey == colorCode);
//           item['ColorName'] = shade.shadeName;
//         } catch (e) {
//           item['ColorName'] = 'NA';
//         }
//       } else {
//         item['ColorName'] = 'NA';
//       }
//     }

//         // Client-side filtering for API issue
//         List<dynamic> filteredResult =
//             flattenedResult.where((item) {
//               bool brandMatch =
//                   selectedBrand?.isEmpty ??
//                   true || selectedBrand!.any((b) => b.key == item['brand']);
//               bool styleMatch =
//                   selectedStyle?.isEmpty ??
//                   true || selectedStyle!.any((s) => s.key == item['StyleCode']);
//               bool shadeMatch =
//                   selectedShade?.isEmpty ??
//                   true || selectedShade!.any((s) => s.key == item['Color']);
//               bool sizeMatch =
//                   selectedSize?.isEmpty ??
//                   true || selectedSize!.any((s) => s.key == item['Size']);
//               bool statusMatch =
//                   selectedStatus?.key == 'all' ||
//                   item['Status'] == selectedStatus?.key;
//               return brandMatch &&
//                   styleMatch &&
//                   shadeMatch &&
//                   sizeMatch &&
//                   statusMatch;
//             }).toList();
//         setState(() {
//           _orderData = filteredResult;
//           _isLoading = false;
//         });
//         if (filteredResult.isEmpty) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('No data returned. Check filters or API.'),
//             ),
//           );
//         }
//       } else {
//         setState(() {
//           _isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Failed to fetch order status: ${response.statusCode}',
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching order status: $e')),
//       );
//     }
//   }

//   void _showFilterDialog() async {
//     final List<KeyName> statusList = [
//       KeyName(key: 'all', name: 'All'),
//       KeyName(key: 'pending', name: 'Pending'),
//       KeyName(key: 'completed', name: 'Completed'),
//     ];
//     final List<KeyName> groupByOptions = [
//       KeyName(key: 'cust', name: 'Customer'),
//       KeyName(key: 'design', name: 'Design'),

//     ];

//     final result = await Navigator.push(
//       context,
//       PageRouteBuilder(
//         pageBuilder:
//             (context, animation, secondaryAnimation) => OrderStatusFilterPage(
//               brandsList:
//                   _brands
//                       .map((b) => KeyName(key: b.brandKey, name: b.brandName))
//                       .toList(),
//               stylesList:
//                   _styles
//                       .map((s) => KeyName(key: s.styleKey, name: s.styleCode))
//                       .toList(),
//               shadesList:
//                   _shades
//                       .map((s) => KeyName(key: s.shadeKey, name: s.shadeName))
//                       .toList(),
//               sizesList:
//                   _sizes
//                       .map((s) => KeyName(key: s.itemSizeKey, name: s.sizeName))
//                       .toList(),
//               statusList: statusList,
//               groupByOptions: groupByOptions,
//               filters:
//                   _currentFilters, // Changed from initialFilters to filters
//               onApplyFilters: ({
//                 fromDate,
//                 toDate,
//                 selectedBrand,
//                 selectedStyle,
//                 selectedShade,
//                 selectedSize,
//                 selectedStatus,
//                 groupBy,
//                 withImage,
//                 selectedDateRange,
//               }) {
//                 final newFilters = {
//                   'fromDate': fromDate,
//                   'toDate': toDate,
//                   'selectedDateRange': selectedDateRange,
//                   'selectedBrand': selectedBrand,
//                   'selectedStyle': selectedStyle,
//                   'selectedShade': selectedShade,
//                   'selectedSize': selectedSize,
//                   'selectedStatus': selectedStatus,
//                   'groupBy': groupBy,
//                   'withImage': withImage,
//                 };
//                 Navigator.pop(context, newFilters);
//               },
//             ),
//         transitionDuration: const Duration(milliseconds: 500),
//         transitionsBuilder: (context, animation, secondaryAnimation, child) {
//           return ScaleTransition(
//             scale: animation,
//             alignment: Alignment.bottomRight,
//             child: FadeTransition(opacity: animation, child: child),
//           );
//         },
//       ),
//     );

//     if (result != null) {
//       setState(() {
//         _currentFilters = result;
//         _orderData = [];
//       });
//       await _fetchOrderStatus(_currentFilters);
//     }
//   }

//   Future<void> _fetchStockReport({
//     required String itemSubGrpKey,
//     required String itemKey,
//     String? brandKey,
//     String? styleKey,
//     String? shadeKey,
//     String? sizeKey,
//   }) async {
//     setState(() {
//       _isLoading = true;
//     });
//     try {
//       final stockReport = await ApiService.fetchStockReport(
//         itemSubGrpKey: itemSubGrpKey,
//         itemKey: itemKey,
//         userId: UserSession.userName ?? '',
//         fcYrId: UserSession.userFcYr ?? '',
//         cobr: UserSession.coBrId ?? '01',
//         brandKey: brandKey,
//         styleKey: styleKey,
//         shadeKey: shadeKey,
//         sizeKey: sizeKey,
//         fromMRP: null,
//         toMRP: null,
//       );
//       setState(() {
//         _isLoading = false;
//         print('Stock Report: $stockReport');
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching stock report: $e')),
//       );
//     }
//   }

//  String _getImageUrl(dynamic catalog) {
//   final imagePath = catalog['Style_Image'] ?? '';

//   if (imagePath.isEmpty) {
//     return '';
//   }

//   if (UserSession.onlineImage == '1') {
//     // If onlineImage == '1', treat Style_Image as full URL
//     return imagePath;
//   } else if (UserSession.onlineImage == '0') {
//     // If onlineImage == '0', extract image name and append base URL
//     if (imagePath.startsWith('http')) {
//       // Sometimes imagePath might already be a full URL even if onlineImage == '0'
//       return imagePath;
//     }
//     final imageName = imagePath.split('/').last.split('?').first;
//     if (imageName.isEmpty) {
//       return '';
//     }
//     return '${AppConstants.BASE_URL}/images/$imageName';
//   }

//   // Fallback
//   return '';
// }

//   void clearFilters() {
//     setState(() {
//       _selectedProducts = [];
//       _selectedCategory = null;
//       _orderData = [];
//       _styles = [];
//       _shades = [];
//       _sizes = [];
//       _currentFilters = {
//         'fromDate': DateTime.now().subtract(const Duration(days: 30)),
//         'toDate': DateTime.now(),
//         'selectedDateRange': 'Custom',
//         'selectedBrand': <KeyName>[],
//         'selectedStyle': <KeyName>[],
//         'selectedShade': <KeyName>[],
//         'selectedSize': <KeyName>[],
//         'selectedStatus': KeyName(key: 'all', name: 'All'),
//         'groupBy': KeyName(key: 'cust', name: 'Customer'),
//         'withImage': false,
//       };
//     });
//   }

//   List<Map<String, dynamic>> _groupOrderData() {
//     final groupBy = _currentFilters['groupBy']?.key ?? 'cust';
//     final groupedData = <String, List<dynamic>>{};

//     for (var item in _orderData) {
//       String key;
//       if (groupBy == 'style' && item['StyleCode'] != null) {
//         key = '${item['ItemName']}---${item['StyleCode']}';
//       } else {
//         key = '${item['ItemName']}---${item['OrderNo']}';
//       }
//       groupedData.putIfAbsent(key, () => []).add(item);
//     }

//     return groupedData.entries.map((entry) {
//       final parts = entry.key.split('---');
//       return {
//         'productName': parts[0],
//         'groupKey': parts[1], // OrderNo or StyleCode
//         'items': entry.value,
//       };
//     }).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final groupedData = _groupOrderData();

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Order Status',
//           style: TextStyle(color: Colors.white),
//         ),
//         backgroundColor: AppColors.primaryColor,
//         elevation: 1,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Product Dropdown (Multi-select)
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8.0),
//               child: DropdownSearch<String>.multiSelection(
//                 items: _products.map((product) => product.itemKey).toList(),
//                 selectedItems: _selectedProducts,
//                 onChanged: (List<String> newValues) {
//                   setState(() {
//                     _selectedProducts = newValues;
//                   });
//                   if (newValues.isNotEmpty) {
//                     for (var itemKey in newValues) {
//                       _fetchStyles(itemKey: itemKey);
//                       _fetchShades(itemKey: itemKey);
//                       _fetchSizes(itemKey: itemKey);
//                     }
//                   } else {
//                     setState(() {
//                       _styles = [];
//                       _shades = [];
//                       _sizes = [];
//                     });
//                   }
//                 },
//                 popupProps: PopupPropsMultiSelection.menu(
//                   showSearchBox: true,
//                   loadingBuilder:
//                       (context, searchEntry) => Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           LoadingAnimationWidget.waveDots(
//                             color: Colors.blue,
//                             size: 20,
//                           ),
//                           const SizedBox(width: 8),
//                           const Text('Loading Products...'),
//                         ],
//                       ),
//                 ),
//                 dropdownDecoratorProps: const DropDownDecoratorProps(
//                   dropdownSearchDecoration: InputDecoration(
//                     labelText: 'Select Products',
//                     border: OutlineInputBorder(),
//                     contentPadding: EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 8,
//                     ),
//                   ),
//                 ),
//                 itemAsString: (String? key) {
//                   final product = _products.firstWhere(
//                     (p) => p.itemKey == key,
//                     orElse: () => Item(itemKey: '', itemName: ''),
//                   );
//                   return product.itemName;
//                 },
//                 enabled: !_isLoadingProducts,
//               ),
//             ),
//             // Category Dropdown (Single-select)
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8.0),
//               child: DropdownSearch<String>(
//                 items: _categories,
//                 selectedItem: _selectedCategory,
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _selectedCategory = newValue;
//                   });
//                 },
//                 popupProps: PopupProps.menu(
//                   showSearchBox: true,
//                   loadingBuilder:
//                       (context, searchEntry) => Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           LoadingAnimationWidget.waveDots(
//                             color: Colors.blue,
//                             size: 20,
//                           ),
//                           const SizedBox(width: 8),
//                           const Text('Loading Categories...'),
//                         ],
//                       ),
//                 ),
//                 dropdownDecoratorProps: const DropDownDecoratorProps(
//                   dropdownSearchDecoration: InputDecoration(
//                     labelText: 'Select Category',
//                     border: OutlineInputBorder(),
//                     contentPadding: EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 8,
//                     ),
//                   ),
//                 ),
//                 enabled: !_isLoading,
//               ),
//             ),
//             // Buttons Row
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8.0),
//               child: Row(
//                 children: [
//                   _buildButton("View", Icons.visibility, Colors.blue, () async {
//                     await _fetchOrderStatus(_currentFilters);
//                   }),
//                   const SizedBox(width: 8),
//                   _buildButton(
//                     "Download",
//                     Icons.download,
//                     Colors.deepPurple,
//                     () {
//                       // TODO: Implement download logic
//                     },
//                   ),
//                   const SizedBox(width: 8),
//                   _buildButton(
//                     "WhatsApp",
//                     FontAwesomeIcons.whatsapp,
//                     Colors.green,
//                     () {
//                       // TODO: Implement WhatsApp logic
//                     },
//                     isFaIcon: true,
//                   ),
//                   const SizedBox(width: 8),
//                   _buildButton("Clear", Icons.clear, Colors.red, clearFilters),
//                 ],
//               ),
//             ),
//             // Display Order Data
//             Expanded(
//               child:
//                   _isLoading
//                       ? const Center(child: CircularProgressIndicator())
//                       : _orderData.isEmpty
//                       ? const Center(child: Text('No orders found'))
//                       : ListView.builder(
//                         itemCount: groupedData.length,
//                         itemBuilder: (context, index) {
//                           final group = groupedData[index];
//                           return OrderStatusCard(
//                             productName: group['productName'],
//                             orderNo: group['groupKey'], // OrderNo or StyleCode
//                             items: group['items'],
//                             showImage: _currentFilters['withImage'] == true,
//                           );
//                         },
//                       ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: Padding(
//         padding: const EdgeInsets.only(bottom: 120.0),
//         child: FloatingActionButton(
//           onPressed: _showFilterDialog,
//           backgroundColor: Colors.blue,
//           child: const Icon(Icons.filter_list, color: Colors.white),
//           tooltip: 'Filter Options',
//         ),
//       ),
//     );
//   }

//   String _formatDate(DateTime? date) {
//     return date != null ? DateFormat('dd-MM-yyyy').format(date) : '';
//   }

//   Widget _buildButton(
//     String label,
//     IconData icon,
//     Color color,
//     VoidCallback onPressed, {
//     bool isFaIcon = false,
//   }) {
//     return Expanded(
//       child: SizedBox(
//         height: 40,
//         child: OutlinedButton.icon(
//           onPressed: onPressed,
//           icon:
//               isFaIcon
//                   ? FaIcon(icon, size: 12, color: color)
//                   : Icon(icon, size: 12, color: color),
//           label: Text(
//             label,
//             style: TextStyle(fontSize: 10, color: color),
//             softWrap: false,
//           ),
//           style: OutlinedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(horizontal: 8),
//             shape: const RoundedRectangleBorder(
//               borderRadius: BorderRadius.zero,
//             ),
//             side: BorderSide(color: color),
//             foregroundColor: color,
//             backgroundColor: Colors.transparent,
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/dashboard/orderStatusFilter.dart';
import 'package:vrs_erp/models/brand.dart';
import 'package:vrs_erp/models/item.dart';
import 'dart:convert';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/models/shade.dart';
import 'package:vrs_erp/models/size.dart';
import 'package:vrs_erp/models/style.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'order_status_card.dart';

class OrderStatus extends StatefulWidget {
  const OrderStatus({super.key});

  @override
  _OrderStatusState createState() => _OrderStatusState();
}

class _OrderStatusState extends State<OrderStatus> {
  List<String> _selectedProducts = [];
  String? _selectedCategory;
  List<Item> _products = [];
  List<String> _categories = [];
  List<Brand> _brands = [];
  List<Style> _styles = [];
  List<Shade> _shades = [];
  List<Sizes> _sizes = [];
  List<dynamic> _orderData = [];
  bool _isLoading = false;
  bool _isLoadingProducts = false;
  Map<String, dynamic> _currentFilters = {};

  // Controllers for search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentFilters = {
      'fromDate': DateTime.now().subtract(const Duration(days: 30)),
      'toDate': DateTime.now(),
      'selectedDateRange': 'Custom',
      'selectedBrand': <KeyName>[],
      'selectedStyle': <KeyName>[],
      'selectedShade': <KeyName>[],
      'selectedSize': <KeyName>[],
      'selectedStatus': KeyName(key: 'all', name: 'All'),
      'groupBy': KeyName(key: 'cust', name: 'Customer'),
      'withImage': true,
    };
    _fetchCategories();
    _fetchProducts();
    _fetchBrands();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await ApiService.fetchLedgers(ledCat: 'W', coBrId: '01');
      if (response['statusCode'] == 200) {
        final List<KeyName> result = response['result'];
        setState(() {
          _categories = result.map((item) => item.name).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Failed to fetch categories: ${response['statusCode']}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error loading categories: $e');
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });
    try {
      final products = await ApiService.fetchAllItems();
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
      _showSnackBar('Error loading products: $e');
    }
  }

  Future<void> _fetchBrands() async {
    try {
      final brands = await ApiService.fetchBrands();
      setState(() {
        _brands = brands;
      });
    } catch (e) {
      _showSnackBar('Error loading brands: $e');
    }
  }

  Future<void> _fetchStyles({String? itemKey}) async {
    try {
      List<Style> styles = [];
      if (itemKey != null && itemKey.isNotEmpty) {
        styles = await ApiService.fetchStylesByItemKey(itemKey);
      }
      setState(() {
        _styles = styles;
      });
    } catch (e) {
      _showSnackBar('Error loading styles: $e');
    }
  }

  Future<void> _fetchShades({String? itemKey}) async {
    try {
      List<Shade> shades = [];
      if (itemKey != null && itemKey.isNotEmpty) {
        shades = await ApiService.fetchShadesByItemKey(itemKey);
      }
      setState(() {
        _shades = shades;
      });
    } catch (e) {
      _showSnackBar('Error loading shades: $e');
    }
  }

  Future<void> _fetchSizes({String? itemKey}) async {
    try {
      List<Sizes> sizes = [];
      if (itemKey != null && itemKey.isNotEmpty) {
        sizes = await ApiService.fetchStylesSizeByItemKey(itemKey);
      }
      setState(() {
        _sizes = sizes;
      });
    } catch (e) {
      _showSnackBar('Error loading sizes: $e');
    }
  }

  Future<void> _fetchOrderStatus(Map<String, dynamic> filters) async {
    if (_selectedProducts.isEmpty || _selectedCategory == null) {
      _showSnackBar('Please select at least one product and a category');
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final selectedBrand = filters['selectedBrand'] as List<KeyName>?;
      final selectedStyle = filters['selectedStyle'] as List<KeyName>?;
      final selectedShade = filters['selectedShade'] as List<KeyName>?;
      final selectedSize = filters['selectedSize'] as List<KeyName>?;
      final selectedStatus = filters['selectedStatus'] as KeyName?;
      final groupBy = filters['groupBy'] as KeyName?;

      final requestBody = {
        'product': _selectedProducts.join(','),
        'groupby': groupBy?.key ?? 'cust',
        'CoBr_Id': UserSession.coBrId ?? '01',
        'brand':
            selectedBrand?.isNotEmpty == true
                ? selectedBrand!.map((b) => b.key).join(',')
                : null,
        'style':
            selectedStyle?.isNotEmpty == true
                ? selectedStyle!.map((s) => s.key).join(',')
                : null,
        'shade':
            selectedShade?.isNotEmpty == true
                ? selectedShade!.map((s) => s.key).join(',')
                : null,
        'size':
            selectedSize?.isNotEmpty == true
                ? selectedSize!.map((s) => s.key).join(',')
                : null,
        'status': selectedStatus?.key != 'all' ? selectedStatus?.key : null,
      };

      print('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(
          '${AppConstants.BASE_URL}/report/GetOrderStatus?t=${DateTime.now().millisecondsSinceEpoch}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic result = jsonDecode(response.body);
        List<dynamic> flattenedResult =
            result is List && result.isNotEmpty && result[0] is List
                ? result.expand((i) => i).toList()
                : result is List
                ? result
                : [];

        for (var item in flattenedResult) {
          final colorCode = item['Color']?.toString();
          if (colorCode != null && colorCode.isNotEmpty) {
            try {
              var shade = _shades.firstWhere((s) => s.shadeKey == colorCode);
              item['ColorName'] = shade.shadeName;
            } catch (e) {
              item['ColorName'] = 'NA';
            }
          } else {
            item['ColorName'] = 'NA';
          }
        }

        // Client-side filtering for API issue
        List<dynamic> filteredResult =
            flattenedResult.where((item) {
              bool brandMatch =
                  selectedBrand?.isEmpty ??
                  true || selectedBrand!.any((b) => b.key == item['brand']);
              bool styleMatch =
                  selectedStyle?.isEmpty ??
                  true || selectedStyle!.any((s) => s.key == item['StyleCode']);
              bool shadeMatch =
                  selectedShade?.isEmpty ??
                  true || selectedShade!.any((s) => s.key == item['Color']);
              bool sizeMatch =
                  selectedSize?.isEmpty ??
                  true || selectedSize!.any((s) => s.key == item['Size']);
              bool statusMatch =
                  selectedStatus?.key == 'all' ||
                  item['Status'] == selectedStatus?.key;
              return brandMatch &&
                  styleMatch &&
                  shadeMatch &&
                  sizeMatch &&
                  statusMatch;
            }).toList();

        setState(() {
          _orderData = filteredResult;
          _isLoading = false;
        });

        if (filteredResult.isEmpty) {
          _showSnackBar('No data returned. Check filters or API.');
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Failed to fetch order status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error fetching order status: $e');
    }
  }

  void _showFilterDialog() async {
    final List<KeyName> statusList = [
      KeyName(key: 'all', name: 'All'),
      KeyName(key: 'pending', name: 'Pending'),
      KeyName(key: 'completed', name: 'Completed'),
    ];
    final List<KeyName> groupByOptions = [
      KeyName(key: 'cust', name: 'Customer'),
      KeyName(key: 'design', name: 'Design'),
    ];

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => OrderStatusFilterPage(
              brandsList:
                  _brands
                      .map((b) => KeyName(key: b.brandKey, name: b.brandName))
                      .toList(),
              stylesList:
                  _styles
                      .map((s) => KeyName(key: s.styleKey, name: s.styleCode))
                      .toList(),
              shadesList:
                  _shades
                      .map((s) => KeyName(key: s.shadeKey, name: s.shadeName))
                      .toList(),
              sizesList:
                  _sizes
                      .map((s) => KeyName(key: s.itemSizeKey, name: s.sizeName))
                      .toList(),
              statusList: statusList,
              groupByOptions: groupByOptions,
              filters: _currentFilters,
              onApplyFilters: ({
                fromDate,
                toDate,
                selectedBrand,
                selectedStyle,
                selectedShade,
                selectedSize,
                selectedStatus,
                groupBy,
                withImage,
                selectedDateRange,
              }) {
                final newFilters = {
                  'fromDate': fromDate,
                  'toDate': toDate,
                  'selectedDateRange': selectedDateRange,
                  'selectedBrand': selectedBrand,
                  'selectedStyle': selectedStyle,
                  'selectedShade': selectedShade,
                  'selectedSize': selectedSize,
                  'selectedStatus': selectedStatus,
                  'groupBy': groupBy,
                  'withImage': withImage,
                };
                Navigator.pop(context, newFilters);
              },
            ),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: animation,
            alignment: Alignment.bottomRight,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );

    if (result != null) {
      setState(() {
        _currentFilters = result;
        _orderData = [];
      });
      await _fetchOrderStatus(_currentFilters);
    }
  }

  Future<void> _fetchStockReport({
    required String itemSubGrpKey,
    required String itemKey,
    String? brandKey,
    String? styleKey,
    String? shadeKey,
    String? sizeKey,
  }) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final stockReport = await ApiService.fetchStockReport(
        itemSubGrpKey: itemSubGrpKey,
        itemKey: itemKey,
        userId: UserSession.userName ?? '',
        fcYrId: UserSession.userFcYr ?? '',
        cobr: UserSession.coBrId ?? '01',
        brandKey: brandKey,
        styleKey: styleKey,
        shadeKey: shadeKey,
        sizeKey: sizeKey,
        fromMRP: null,
        toMRP: null,
      );
      setState(() {
        _isLoading = false;
        print('Stock Report: $stockReport');
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error fetching stock report: $e');
    }
  }

  String _getImageUrl(dynamic catalog) {
    final imagePath = catalog['Style_Image'] ?? '';

    if (imagePath.isEmpty) {
      return '';
    }

    if (UserSession.onlineImage == '1') {
      return imagePath;
    } else if (UserSession.onlineImage == '0') {
      if (imagePath.startsWith('http')) {
        return imagePath;
      }
      final imageName = imagePath.split('/').last.split('?').first;
      if (imageName.isEmpty) {
        return '';
      }
      return '${AppConstants.BASE_URL}/images/$imageName';
    }
    return '';
  }

  void clearFilters() {
    setState(() {
      _selectedProducts = [];
      _selectedCategory = null;
      _orderData = [];
      _styles = [];
      _shades = [];
      _sizes = [];
      _searchQuery = '';
      _searchController.clear();
      _currentFilters = {
        'fromDate': DateTime.now().subtract(const Duration(days: 30)),
        'toDate': DateTime.now(),
        'selectedDateRange': 'Custom',
        'selectedBrand': <KeyName>[],
        'selectedStyle': <KeyName>[],
        'selectedShade': <KeyName>[],
        'selectedSize': <KeyName>[],
        'selectedStatus': KeyName(key: 'all', name: 'All'),
        'groupBy': KeyName(key: 'cust', name: 'Customer'),
        'withImage': false,
      };
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  List<Map<String, dynamic>> _groupOrderData() {
    final groupBy = _currentFilters['groupBy']?.key ?? 'cust';
    final groupedData = <String, List<dynamic>>{};

    // Apply search filter
    var filteredData = _orderData;
    if (_searchQuery.isNotEmpty) {
      filteredData =
          _orderData.where((item) {
            final orderNo = item['OrderNo']?.toString().toLowerCase() ?? '';
            final party = item['Party']?.toString().toLowerCase() ?? '';
            final itemName = item['ItemName']?.toString().toLowerCase() ?? '';
            final query = _searchQuery.toLowerCase();
            return orderNo.contains(query) ||
                party.contains(query) ||
                itemName.contains(query);
          }).toList();
    }

    for (var item in filteredData) {
      String key;
      if (groupBy == 'design' && item['StyleCode'] != null) {
        key = '${item['ItemName']}---${item['StyleCode']}';
      } else {
        key = '${item['ItemName']}---${item['OrderNo']}';
      }
      groupedData.putIfAbsent(key, () => []).add(item);
    }

    return groupedData.entries.map((entry) {
      final parts = entry.key.split('---');
      return {
        'productName': parts[0],
        'groupKey': parts[1],
        'items': entry.value,
      };
    }).toList();
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_currentFilters['selectedBrand']?.isNotEmpty == true) count++;
    if (_currentFilters['selectedStyle']?.isNotEmpty == true) count++;
    if (_currentFilters['selectedShade']?.isNotEmpty == true) count++;
    if (_currentFilters['selectedSize']?.isNotEmpty == true) count++;
    if (_currentFilters['selectedStatus']?.key != 'all') count++;
    if (_currentFilters['groupBy']?.key != 'cust') count++;
    return count;
  }

  // Load image for PDF
  Future<pw.MemoryImage?> _loadPdfImage(String url) async {
    try {
      if (url.isEmpty) return null;

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {
      print('Error loading image for PDF: $e');
    }
    return null;
  }

  // Helper method to get shade name for PDF (same logic as OrderStatusCard)
  String _getShadeNameForPdf(dynamic item) {
    // First try to get ColorName (mapped in main screen)
    if (item['ColorName'] != null &&
        item['ColorName'].toString().isNotEmpty &&
        item['ColorName'] != 'NA') {
      return item['ColorName'].toString();
    }

    // If ColorName is not available or is 'NA', use the color code
    if (item['Color'] != null && item['Color'].toString().isNotEmpty) {
      return item['Color'].toString();
    }

    return 'Unknown';
  }

  // Get PDF color
  PdfColor _getPdfColor(String color) {
    switch (color.toLowerCase()) {
      case 'red':
        return PdfColors.red;
      case 'green':
        return PdfColors.green;
      case 'blue':
        return PdfColors.blue;
      case 'yellow':
        return PdfColors.yellow;
      case 'black':
        return PdfColors.black;
      case 'brown':
        return PdfColors.brown;
      case 'pink':
        return PdfColors.pink;
      case 'orange':
        return PdfColors.orange;
      case 'purple':
        return PdfColors.purple;
      default:
        return PdfColors.grey;
    }
  }

  // PDF Cell helper
  pw.Widget _pdfCell(
    String text, {
    double width = 35,
    bool isHeader = false,
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.all(1),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 6,
          fontWeight:
              isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Extract order number (same as in OrderStatusCard)
  String _extractOrderNumber(String orderNo) {
    if (orderNo.contains('\n')) {
      return orderNo.split('\n')[0];
    }
    return orderNo;
  }

  // Get filter summary for PDF header
  String _getFilterSummary() {
    List<String> parts = [];

    if (_currentFilters['selectedBrand']?.isNotEmpty == true) {
      parts.add('Brands: ${(_currentFilters['selectedBrand'] as List).length}');
    }
    if (_currentFilters['selectedStyle']?.isNotEmpty == true) {
      parts.add('Styles: ${(_currentFilters['selectedStyle'] as List).length}');
    }
    if (_currentFilters['selectedShade']?.isNotEmpty == true) {
      parts.add('Shades: ${(_currentFilters['selectedShade'] as List).length}');
    }
    if (_currentFilters['selectedSize']?.isNotEmpty == true) {
      parts.add('Sizes: ${(_currentFilters['selectedSize'] as List).length}');
    }
    if (_currentFilters['selectedStatus']?.key != 'all') {
      parts.add('Status: ${_currentFilters['selectedStatus']?.name}');
    }

    return parts.join(' | ');
  }

  // PDF Generation for Order Status
  Future<pw.Document> _generateOrderStatusPDF(List<dynamic> orderData) async {
    final pdf = pw.Document();

    // Group data by product name - each product should be separate
    final Map<String, List<dynamic>> groupedByProduct = {};
    for (var item in orderData) {
      final productName = item['ItemName'] ?? 'Unknown';
      if (!groupedByProduct.containsKey(productName)) {
        groupedByProduct[productName] = [];
      }
      groupedByProduct[productName]!.add(item);
    }

    print(
      'Number of products found: ${groupedByProduct.length}',
    ); // Debug print
    groupedByProduct.forEach((key, value) {
      print('Product: $key - Items: ${value.length}');
    });

    List<pw.Widget> allProductSections = [];
    int grandTotal = 0;
    int grandOrderQty = 0;
    int grandDelvQty = 0;
    int grandSettleQty = 0;
    int grandPendingQty = 0;

    for (var productEntry in groupedByProduct.entries) {
      final productName = productEntry.key;
      final productItems = productEntry.value;

      print(
        'Processing product: $productName with ${productItems.length} items',
      );

      // Group by shade within product
      final Map<String, List<dynamic>> groupedByShade = {};
      for (var item in productItems) {
        String shade = _getShadeNameForPdf(item);
        if (!groupedByShade.containsKey(shade)) {
          groupedByShade[shade] = [];
        }
        groupedByShade[shade]!.add(item);
      }

      // Calculate product totals
      int productOrderQty = 0;
      int productDelvQty = 0;
      int productSettleQty = 0;
      int productPendingQty = 0;

      for (var item in productItems) {
        productOrderQty += (item['OrderQty'] as num?)?.toInt() ?? 0;
        productDelvQty += (item['DelvQty'] as num?)?.toInt() ?? 0;
        productSettleQty += (item['SettleQty'] as num?)?.toInt() ?? 0;
        productPendingQty += (item['PendingQty'] as num?)?.toInt() ?? 0;
      }

      grandOrderQty += productOrderQty;
      grandDelvQty += productDelvQty;
      grandSettleQty += productSettleQty;
      grandPendingQty += productPendingQty;

      // Get product image if available
      pw.MemoryImage? productImage;
      if (_currentFilters['withImage'] == true && productItems.isNotEmpty) {
        final imageUrl = _getImageUrl(productItems.first);
        if (imageUrl.isNotEmpty) {
          productImage = await _loadPdfImage(imageUrl);
        }
      }

      // Build shade tables for this product
      List<pw.Widget> shadeTables = [];

      for (var shadeEntry in groupedByShade.entries) {
        final shade = shadeEntry.key;
        final shadeItems = shadeEntry.value;

        // Get unique sizes and aggregate quantities
        final Map<String, Map<String, dynamic>> sizeData = {};
        String party = '';
        Set<String> orderNumbers = {}; // Collect unique order numbers

        for (var item in shadeItems) {
          party = item['Party'] ?? 'Unknown';
          final size = item['Size']?.toString() ?? 'Unknown';

          // Extract order number without date
          String orderNo = item['OrderNo'] ?? '';
          if (orderNo.contains('\n')) {
            orderNo = orderNo.split('\n')[0];
          }
          orderNumbers.add(orderNo);

          if (!sizeData.containsKey(size)) {
            sizeData[size] = {
              'orderQty': 0,
              'delvQty': 0,
              'settleQty': 0,
              'pendingQty': 0,
            };
          }

          sizeData[size]!['orderQty'] +=
              (item['OrderQty'] as num?)?.toInt() ?? 0;
          sizeData[size]!['delvQty'] += (item['DelvQty'] as num?)?.toInt() ?? 0;
          sizeData[size]!['settleQty'] +=
              (item['SettleQty'] as num?)?.toInt() ?? 0;
          sizeData[size]!['pendingQty'] +=
              (item['PendingQty'] as num?)?.toInt() ?? 0;
        }

        // Calculate shade totals
        int shadeOrderQty = 0;
        int shadeDelvQty = 0;
        int shadeSettleQty = 0;
        int shadePendingQty = 0;

        for (var data in sizeData.values) {
          shadeOrderQty += data['orderQty'] as int;
          shadeDelvQty += data['delvQty'] as int;
          shadeSettleQty += data['settleQty'] as int;
          shadePendingQty += data['pendingQty'] as int;
        }

        // Build table for this shade
        List<pw.TableRow> tableRows = [];

        // Header
        tableRows.add(
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              _pdfCell('Size', width: 40, isHeader: true),
              _pdfCell('Ord', width: 30, isHeader: true),
              _pdfCell('Del', width: 30, isHeader: true),
              _pdfCell('Set', width: 30, isHeader: true),
              _pdfCell('Pen', width: 30, isHeader: true),
            ],
          ),
        );

        // Data rows
        for (var sizeEntry in sizeData.entries) {
          final size = sizeEntry.key;
          final data = sizeEntry.value;

          tableRows.add(
            pw.TableRow(
              children: [
                _pdfCell(size, width: 40),
                _pdfCell(data['orderQty'].toString(), width: 30),
                _pdfCell(
                  data['delvQty'].toString(),
                  width: 30,
                  color: PdfColors.green700,
                ),
                _pdfCell(
                  data['settleQty'].toString(),
                  width: 30,
                  color: PdfColors.orange700,
                ),
                _pdfCell(
                  data['pendingQty'].toString(),
                  width: 30,
                  color:
                      data['pendingQty'] > 0
                          ? PdfColors.red700
                          : data['pendingQty'] < 0
                          ? PdfColors.orange700
                          : PdfColors.green700,
                  isBold: true,
                ),
              ],
            ),
          );
        }

        // Shade total row
        tableRows.add(
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              _pdfCell('Total', width: 40, isBold: true),
              _pdfCell(shadeOrderQty.toString(), width: 30, isBold: true),
              _pdfCell(
                shadeDelvQty.toString(),
                width: 30,
                isBold: true,
                color: PdfColors.green700,
              ),
              _pdfCell(
                shadeSettleQty.toString(),
                width: 30,
                isBold: true,
                color: PdfColors.orange700,
              ),
              _pdfCell(
                shadePendingQty.toString(),
                width: 30,
                isBold: true,
                color:
                    shadePendingQty > 0 ? PdfColors.red700 : PdfColors.green700,
              ),
            ],
          ),
        );

        // Add shade section with header
        shadeTables.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 10,
                      height: 10,
                      decoration: pw.BoxDecoration(
                        color: _getPdfColor(shade),
                        border: pw.Border.all(color: PdfColors.grey400),
                      ),
                    ),
                    pw.SizedBox(width: 3),
                    pw.Text(
                      shade,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: _getPdfColor(shade),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text('Party: $party', style: pw.TextStyle(fontSize: 7)),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'Orders: ${orderNumbers.join(', ')}',
                      style: pw.TextStyle(
                        fontSize: 6,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(40),
                    1: const pw.FixedColumnWidth(30),
                    2: const pw.FixedColumnWidth(30),
                    3: const pw.FixedColumnWidth(30),
                    4: const pw.FixedColumnWidth(30),
                  },
                  children: tableRows,
                ),
              ],
            ),
          ),
        );
      }

      // Add product section
      allProductSections.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blue700),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Product Header with Image
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(color: PdfColors.blue700),
                child: pw.Row(
                  children: [
                    // Product Image
                    if (productImage != null)
                      pw.Container(
                        width: 30,
                        height: 30,
                        margin: const pw.EdgeInsets.only(right: 4),
                        decoration: pw.BoxDecoration(color: PdfColors.white),
                        child: pw.Image(productImage, fit: pw.BoxFit.contain),
                      )
                    else if (_currentFilters['withImage'] == true)
                      pw.Container(
                        width: 30,
                        height: 30,
                        margin: const pw.EdgeInsets.only(right: 4),
                        decoration: pw.BoxDecoration(color: PdfColors.grey200),
                        child: pw.Center(
                          child: pw.Text(
                            'No\nImg',
                            style: pw.TextStyle(
                              fontSize: 5,
                              color: PdfColors.grey600,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ),

                    // Product Name and Totals
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            productName,
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.Row(
                            children: [
                              pw.Text(
                                'Ord: $productOrderQty',
                                style: pw.TextStyle(
                                  fontSize: 6,
                                  color: PdfColors.white,
                                ),
                              ),
                              pw.SizedBox(width: 6),
                              pw.Text(
                                'Del: $productDelvQty',
                                style: pw.TextStyle(
                                  fontSize: 6,
                                  color: PdfColors.white,
                                ),
                              ),
                              pw.SizedBox(width: 6),
                              pw.Text(
                                'Set: $productSettleQty',
                                style: pw.TextStyle(
                                  fontSize: 6,
                                  color: PdfColors.white,
                                ),
                              ),
                              pw.SizedBox(width: 6),
                              pw.Text(
                                'Pen: $productPendingQty',
                                style: pw.TextStyle(
                                  fontSize: 6,
                                  color: PdfColors.white,
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
              // Shade Tables
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Column(children: shadeTables),
              ),
            ],
          ),
        ),
      );
    }

    print('Total product sections created: ${allProductSections.length}');

    // Add Grand Total section
    allProductSections.add(
      pw.Container(
        margin: const pw.EdgeInsets.only(top: 8),
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(color: PdfColors.blue700),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'GRAND TOTAL',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
            pw.Row(
              children: [
                pw.Text(
                  'Ord: $grandOrderQty',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.white),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  'Del: $grandDelvQty',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.white),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  'Set: $grandSettleQty',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.white),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  'Pen: $grandPendingQty',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // Split content into pages (2 product sections per page to ensure all data fits)
    const int itemsPerPage = 2;
    for (int i = 0; i < allProductSections.length; i += itemsPerPage) {
      final end =
          (i + itemsPerPage < allProductSections.length)
              ? i + itemsPerPage
              : allProductSections.length;
      final pageContent = allProductSections.sublist(i, end);
      final pageNumber = (i ~/ itemsPerPage) + 1;
      final totalPages = ((allProductSections.length - 1) ~/ itemsPerPage) + 1;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(6),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header only on first page
                if (i == 0)
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'VRS SOFTWARE',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'Date: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}',
                              style: pw.TextStyle(fontSize: 7),
                            ),
                          ],
                        ),
                        pw.Text(
                          'Order Status Report',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Row(
                          children: [
                            pw.Text(
                              'Category: ${_selectedCategory ?? 'All'}',
                              style: pw.TextStyle(fontSize: 7),
                            ),
                            pw.SizedBox(width: 10),
                            pw.Text(
                              'Products: ${groupedByProduct.length}',
                              style: pw.TextStyle(fontSize: 7),
                            ),
                          ],
                        ),
                        if (_getActiveFilterCount() > 0) ...[
                          pw.SizedBox(height: 1),
                          pw.Text(
                            'Filters: ${_getFilterSummary()}',
                            style: pw.TextStyle(
                              fontSize: 6,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                        pw.SizedBox(height: 2),
                        pw.Divider(height: 1),
                      ],
                    ),
                  ),

                // Page content
                ...pageContent,

                // Spacer to push footer down
                pw.Expanded(child: pw.SizedBox()),

                // Footer with page number
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Page $pageNumber of $totalPages',
                        style: pw.TextStyle(
                          fontSize: 6,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf;
  }

  // Download PDF
  Future<void> _downloadOrderStatusPDF() async {
    if (_orderData.isEmpty) {
      _showSnackBar('No data to download');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingAnimationWidget.waveDots(
                  color: AppColors.primaryColor,
                  size: 50,
                ),
                const SizedBox(height: 20),
                Text(
                  'Generating PDF...',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final pdf = await _generateOrderStatusPDF(_orderData);
      final bytes = await pdf.save();

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'Order_Status_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        await OpenFile.open(file.path);

        _showSnackBar('PDF downloaded successfully');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSnackBar('Error generating PDF: $e');
      }
    }
  }

  // WhatsApp Sharing
  Future<void> _shareOrderStatusViaWhatsApp() async {
    if (_orderData.isEmpty) {
      _showSnackBar('No data to share');
      return;
    }

    final result = await _showMobileNumberDialog();
    if (result == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingAnimationWidget.waveDots(color: Colors.green, size: 50),
                const SizedBox(height: 20),
                Text(
                  'Preparing for WhatsApp...',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final pdf = await _generateOrderStatusPDF(_orderData);
      final bytes = await pdf.save();
      final fileBase64 = base64Encode(bytes);

      final response = await http.post(
        Uri.parse("http://node4.wabapi.com/v4/postfile.php"),
        body: {
          'data': fileBase64,
          'filename': 'order_status.pdf',
          'key': AppConstants.whatsappKey,
          'number': '91${result['mobileNo']}',
          'caption': _prepareWhatsAppCaption(),
        },
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        if (response.statusCode == 200) {
          _showSnackBar(
            'Order status sent successfully to ${result['mobileNo']}',
          );
        } else {
          _showSnackBar('Failed to send via WhatsApp');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSnackBar('Error: $e');
      }
    }
  }

  // Mobile Number Dialog
  Future<Map<String, String>?> _showMobileNumberDialog() {
    TextEditingController mobileController = TextEditingController();

    return showDialog<Map<String, String>?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Enter Mobile Number",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: "Mobile Number",
                  prefixIcon: const Icon(Icons.phone, size: 20),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Order status report will be sent as PDF via WhatsApp',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final mobileNo = mobileController.text.trim();
                if (mobileNo.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter mobile number'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (mobileNo.length != 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter valid 10-digit mobile number',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (!RegExp(r'^[0-9]+$').hasMatch(mobileNo)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter numbers only'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, {'mobileNo': mobileNo});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Send via WhatsApp"),
            ),
          ],
        );
      },
    );
  }

  // Prepare WhatsApp Caption
  String _prepareWhatsAppCaption() {
    int totalOrders = _orderData.length;
    int totalQty = 0;
    for (var item in _orderData) {
      totalQty += (item['OrderQty'] as num?)?.toInt() ?? 0;
    }

    return '''
📊 *Order Status Report*
📅 Date: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}
🏢 Company: VRS Software
📦 Category: ${_selectedCategory ?? 'All'}
📋 Total Orders: $totalOrders
🔢 Total Quantity: $totalQty

Generated from VRS ERP App
  ''';
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = _groupOrderData();
    final activeFilterCount = _getActiveFilterCount();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 2,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Order Status',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Filter Button with Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: _showFilterDialog,
              ),
              if (activeFilterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      activeFilterCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // More Options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'download':
                  _downloadOrderStatusPDF();
                  break;
                case 'whatsapp':
                  _shareOrderStatusViaWhatsApp();
                  break;
                case 'clear':
                  clearFilters();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: const [
                        Icon(Icons.download, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Download PDF'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'whatsapp',
                    child: Row(
                      children: const [
                        Icon(
                          FontAwesomeIcons.whatsapp,
                          size: 18,
                          color: Colors.green,
                        ),
                        SizedBox(width: 8),
                        Text('WhatsApp'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: const [
                        Icon(Icons.clear, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Clear Filters'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips (if any filters are active)
          if (activeFilterCount > 0)
            Container(
              height: 48,
              color: Colors.white,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  if (_currentFilters['selectedBrand']?.isNotEmpty == true)
                    FilterChip(
                      label: Text(
                        'Brand: ${_currentFilters['selectedBrand'].length}',
                      ),
                      onSelected: (bool selected) {},
                      onDeleted: () {
                        setState(() {
                          _currentFilters['selectedBrand'] = <KeyName>[];
                        });
                        _fetchOrderStatus(_currentFilters);
                      },
                    ),
                  if (_currentFilters['selectedStyle']?.isNotEmpty == true)
                    FilterChip(
                      label: Text(
                        'Style: ${_currentFilters['selectedStyle'].length}',
                      ),
                      onSelected: (bool selected) {},
                      onDeleted: () {
                        setState(() {
                          _currentFilters['selectedStyle'] = <KeyName>[];
                        });
                        _fetchOrderStatus(_currentFilters);
                      },
                    ),
                  if (_currentFilters['selectedShade']?.isNotEmpty == true)
                    FilterChip(
                      label: Text(
                        'Shade: ${_currentFilters['selectedShade'].length}',
                      ),
                      onSelected: (bool selected) {},
                      onDeleted: () {
                        setState(() {
                          _currentFilters['selectedShade'] = <KeyName>[];
                        });
                        _fetchOrderStatus(_currentFilters);
                      },
                    ),
                  if (_currentFilters['selectedSize']?.isNotEmpty == true)
                    FilterChip(
                      label: Text(
                        'Size: ${_currentFilters['selectedSize'].length}',
                      ),
                      onSelected: (bool selected) {},
                      onDeleted: () {
                        setState(() {
                          _currentFilters['selectedSize'] = <KeyName>[];
                        });
                        _fetchOrderStatus(_currentFilters);
                      },
                    ),
                  if (_currentFilters['selectedStatus']?.key != 'all')
                    FilterChip(
                      label: Text(
                        'Status: ${_currentFilters['selectedStatus'].name}',
                      ),
                      onSelected: (bool selected) {},
                      onDeleted: () {
                        setState(() {
                          _currentFilters['selectedStatus'] = KeyName(
                            key: 'all',
                            name: 'All',
                          );
                        });
                        _fetchOrderStatus(_currentFilters);
                      },
                    ),
                ],
              ),
            ),

          // Main Content
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // Selection Cards
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Products Selection
                            DropdownSearch<String>.multiSelection(
                              items:
                                  _products
                                      .map((product) => product.itemKey)
                                      .toList(),
                              selectedItems: _selectedProducts,
                              onChanged: (List<String> newValues) {
                                setState(() {
                                  _selectedProducts = newValues;
                                });
                                if (newValues.isNotEmpty) {
                                  for (var itemKey in newValues) {
                                    _fetchStyles(itemKey: itemKey);
                                    _fetchShades(itemKey: itemKey);
                                    _fetchSizes(itemKey: itemKey);
                                  }
                                } else {
                                  setState(() {
                                    _styles = [];
                                    _shades = [];
                                    _sizes = [];
                                  });
                                }
                              },
                              popupProps: PopupPropsMultiSelection.menu(
                                showSearchBox: true,
                                containerBuilder: (context, popup) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: popup,
                                  );
                                },
                                loadingBuilder:
                                    (context, searchEntry) => Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        LoadingAnimationWidget.waveDots(
                                          color: AppColors.primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Loading Products...'),
                                      ],
                                    ),
                              ),
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: 'Select Products',
                                  hintText: 'Choose products...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  prefixIcon: const Icon(Icons.inventory),
                                ),
                              ),
                              itemAsString: (String? key) {
                                final product = _products.firstWhere(
                                  (p) => p.itemKey == key,
                                  orElse: () => Item(itemKey: '', itemName: ''),
                                );
                                return product.itemName;
                              },
                              enabled: !_isLoadingProducts,
                            ),
                            const SizedBox(height: 16),

                            // Category Selection
                            DropdownSearch<String>(
                              items: _categories,
                              selectedItem: _selectedCategory,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedCategory = newValue;
                                });
                              },
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                containerBuilder: (context, popup) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: popup,
                                  );
                                },
                                loadingBuilder:
                                    (context, searchEntry) => Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        LoadingAnimationWidget.waveDots(
                                          color: AppColors.primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Loading Categories...'),
                                      ],
                                    ),
                              ),
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: 'Select Category',
                                  hintText: 'Choose category...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  prefixIcon: const Icon(Icons.category),
                                ),
                              ),
                              enabled: !_isLoading,
                            ),

                            const SizedBox(height: 16),

                            // View Button (Primary Action)
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await _fetchOrderStatus(_currentFilters);
                                },
                                icon: const Icon(Icons.visibility),
                                label: const Text(
                                  'VIEW ORDER STATUS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Results Header
                    if (_orderData.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Text(
                              'Results',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${groupedData.length} items',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (_searchQuery.isNotEmpty)
                              Text(
                                'Search: "$_searchQuery"',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Results List
                    Expanded(
                      child:
                          _isLoading
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    LoadingAnimationWidget.waveDots(
                                      color: AppColors.primaryColor,
                                      size: 50,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Loading order status...',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              )
                              : _orderData.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No orders found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Select products and category to view orders',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : groupedData.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No results match your search',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _searchController.clear();
                                        });
                                      },
                                      child: const Text('Clear Search'),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                itemCount: groupedData.length,
                                itemBuilder: (context, index) {
                                  final group = groupedData[index];
                                  return OrderStatusCard(
                                    productName: group['productName'],
                                    orderNo: group['groupKey'],
                                    items: group['items'],
                                    showImage:
                                        _currentFilters['withImage'] == true,
                                  );
                                },
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
}
