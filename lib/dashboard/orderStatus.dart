// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:vrs_erp/constants/app_constants.dart';
// import 'package:vrs_erp/dashboard/orderStatusFilter.dart';
// import 'package:vrs_erp/models/brand.dart';
// import 'dart:convert';
// import 'package:vrs_erp/models/item.dart';
// import 'package:vrs_erp/models/keyName.dart';
// import 'package:vrs_erp/models/shade.dart';
// import 'package:vrs_erp/models/size.dart';
// import 'package:vrs_erp/models/style.dart';
// import 'package:vrs_erp/services/app_services.dart';

// class OrderStatus extends StatefulWidget {
//   const OrderStatus({super.key}); // Correct constructor with super.key

//   @override
//   _OrderStatusState createState() => _OrderStatusState();
// }

// class _OrderStatusState extends State<OrderStatus> {
//   List<String> _selectedProducts = [];
//   String? _selectedCategory; // Single selection for category
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
//       'selectedBrand': <KeyName>[],
//       'selectedStyle': <KeyName>[],
//       'selectedShade': <KeyName>[],
//       'selectedSize': <KeyName>[],
//       'selectedStatus': KeyName(key: 'all', name: 'All'),
//       'groupBy': KeyName(key: 'cust', name: 'Customer'),
//       'withImage': false,
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
//       final response = await ApiService.fetchLedgers(
//         ledCat: 'W',
//         coBrId: '01',
//       );
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
//           SnackBar(content: Text('Failed to fetch categories: ${response['statusCode']}')),
//         );
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading categories: $e')),
//       );
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
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading products: $e')),
//       );
//     }
//   }

//   Future<void> _fetchBrands() async {
//     try {
//       final brands = await ApiService.fetchBrands();
//       setState(() {
//         _brands = brands;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading brands: $e')),
//       );
//     }
//   }

//   Future<void> _fetchStyles({String? itemKey}) async {
//     try {
//       List<Style> styles = [];
//       if (itemKey != null && itemKey.isNotEmpty) {
//         styles = await ApiService.fetchStylesByItemKey(itemKey);
//       }
//       setState(() {
//         _styles = styles;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading styles: $e')),
//       );
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
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading shades: $e')),
//       );
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
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading sizes: $e')),
//       );
//     }
//   }

//   Future<void> _fetchOrderStatus(Map<String, dynamic> filters) async {
//     if (_selectedProducts.isEmpty || _selectedCategory == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select at least one product and a category')),
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
//         'brand': selectedBrand?.isNotEmpty == true ? selectedBrand?.map((b) => b.key).join(',') : null,
//         'style': selectedStyle?.isNotEmpty == true ? selectedStyle?.map((s) => s.key).join(',') : null,
//         'shade': selectedShade?.isNotEmpty == true ? selectedShade?.map((s) => s.key).join(',') : null,
//         'size': selectedSize?.isNotEmpty == true ? selectedSize?.map((s) => s.key).join(',') : null,
//         'status': selectedStatus?.key != 'all' ? selectedStatus?.key : null,
//       };

//       print('Request Body: ${jsonEncode(requestBody)}');

//       final response = await http.post(
//         Uri.parse('${AppConstants.BASE_URL}/report/GetOrderStatus'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(requestBody),
//       );

//       print('Response Body: ${response.body}');

//       if (response.statusCode == 200) {
//         final List<dynamic> result = jsonDecode(response.body);
//         setState(() {
//           _orderData = result;
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           _isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to fetch order status: ${response.statusCode}')),
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

//     final result = await Navigator.push(
//       context,
//       PageRouteBuilder(
//         pageBuilder: (context, animation, secondaryAnimation) => OrderStatusFilterPage(
//           brandsList: _brands
//               .map((b) => KeyName(key: b.brandKey, name: b.brandName))
//               .toList(),
//           stylesList: _styles
//               .map((s) => KeyName(key: s.styleKey, name: s.styleCode))
//               .toList(),
//           shadesList: _shades
//               .map((s) => KeyName(key: s.shadeKey, name: s.shadeName))
//               .toList(),
//           sizesList: _sizes
//               .map((s) => KeyName(key: s.itemSizeKey, name: s.sizeName))
//               .toList(),
//           statusList: statusList,
//           initialFilters: _currentFilters,
//           onApplyFilters: ({
//             fromDate,
//             toDate,
//             selectedBrand,
//             selectedStyle,
//             selectedShade,
//             selectedSize,
//             selectedStatus,
//             groupBy,
//             withImage,
//           }) {
//             final newFilters = {
//               'fromDate': fromDate,
//               'toDate': toDate,
//               'selectedBrand': selectedBrand,
//               'selectedStyle': selectedStyle,
//               'selectedShade': selectedShade,
//               'selectedSize': selectedSize,
//               'selectedStatus': selectedStatus,
//               'groupBy': groupBy,
//               'withImage': withImage,
//             };
//             Navigator.pop(context, newFilters);
//           },
//         ),
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

//   String _getImageUrl(dynamic catalog) {
//     if (catalog['Style_Image'].startsWith('http')) {
//       return catalog['Style_Image'];
//     }
//     final imageName = catalog['Style_Image'].split('/').last.split('?').first;
//     return '${AppConstants.BASE_URL}/images/$imageName';
//   }

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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Order Status'),
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
//                   loadingBuilder: (context, searchEntry) => Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       LoadingAnimationWidget.waveDots(
//                         color: Colors.blue,
//                         size: 20,
//                       ),
//                       const SizedBox(width: 8),
//                       const Text('Loading Products...'),
//                     ],
//                   ),
//                 ),
//                 dropdownDecoratorProps: const DropDownDecoratorProps(
//                   dropdownSearchDecoration: InputDecoration(
//                     labelText: 'Select Products',
//                     border: OutlineInputBorder(),
//                     contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
//                   loadingBuilder: (context, searchEntry) => Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       LoadingAnimationWidget.waveDots(
//                         color: Colors.blue,
//                         size: 20,
//                       ),
//                       const SizedBox(width: 8),
//                       const Text('Loading Categories...'),
//                     ],
//                   ),
//                 ),
//                 dropdownDecoratorProps: const DropDownDecoratorProps(
//                   dropdownSearchDecoration: InputDecoration(
//                     labelText: 'Select Category',
//                     border: OutlineInputBorder(),
//                     contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
//                   _buildButton("Download", Icons.download, Colors.deepPurple, () {
//                     // TODO: Implement download logic
//                   }),
//                   const SizedBox(width: 8),
//                   _buildButton("WhatsApp", FontAwesomeIcons.whatsapp, Colors.green, () {
//                     // TODO: Implement WhatsApp logic
//                   }, isFaIcon: true),
//                   const SizedBox(width: 8),
//                   _buildButton("Clear", Icons.clear, Colors.red, clearFilters),
//                 ],
//               ),
//             ),
//             // Display Order Data
//             Expanded(
//               child: _isLoading
//                   ? const Center(child: CircularProgressIndicator())
//                   : _orderData.isEmpty
//                       ? const Center(child: Text('No orders found'))
//                       : ListView.builder(
//                           itemCount: _orderData.length,
//                           itemBuilder: (context, index) {
//                             final order = _orderData[index];
//                             return Card(
//                               margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(12.0),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Order: ${order['OrderNo']}',
//                                       style: const TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 16,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 8),
//                                     Text('Item: ${order['ItemName']}'),
//                                     Text('Color: ${order['Color']}'),
//                                     Text('Size: ${order['Size']}'),
//                                     Text('Party: ${order['Party']}'),
//                                     Text('Order Qty: ${order['OrderQty']}'),
//                                     Text('Delivered Qty: ${order['DelvQty']}'),
//                                     Text('Settled Qty: ${order['SettleQty']}'),
//                                     Text('Pending Qty: ${order['PendingQty']}'),
//                                     if (_currentFilters['withImage'] == true &&
//                                         order['Style_Image'] != null &&
//                                         order['Style_Image'].isNotEmpty)
//                                       Padding(
//                                         padding: const EdgeInsets.only(top: 8),
//                                         child: Image.network(
//                                           _getImageUrl(order),
//                                           height: 100,
//                                           width: double.infinity,
//                                           fit: BoxFit.cover,
//                                           errorBuilder: (context, error, stackTrace) =>
//                                               const Text('Failed to load image'),
//                                         ),
//                                       ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
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

//   Widget _buildButton(String label, IconData icon, Color color, VoidCallback onPressed, {bool isFaIcon = false}) {
//     return Expanded(
//       child: SizedBox(
//         height: 40,
//         child: OutlinedButton.icon(
//           onPressed: onPressed,
//           icon: isFaIcon
//               ? FaIcon(icon, size: 12, color: color)
//               : Icon(icon, size: 12, color: color),
//           label: Text(
//             label,
//             style: TextStyle(fontSize: 10, color: color),
//             softWrap: false,
//           ),
//           style: OutlinedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(horizontal: 8),
//             shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
//             side: BorderSide(color: color),
//             foregroundColor: color,
//             backgroundColor: Colors.transparent,
//           ),
//         ),
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to fetch categories: ${response['statusCode']}',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading categories: $e')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
    }
  }

  Future<void> _fetchBrands() async {
    try {
      final brands = await ApiService.fetchBrands();
      setState(() {
        _brands = brands;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading brands: $e')));
    }
  }

  Future<void> _fetchStyles({String? itemKey}) async {
    try {
      List<Style> styles = [];
      if (itemKey != null && itemKey.isNotEmpty) {
        styles = await ApiService.fetchStylesByItemKey(itemKey);
      }
      setState(() {
        _styles = _styles;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading styles: $e}')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading shades: $e')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading sizes: $e')));
    }
  }

  Future<void> _fetchOrderStatus(Map<String, dynamic> filters) async {
    if (_selectedProducts.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one product and a category'),
        ),
      );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No data returned. Check filters or API.'),
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to fetch order status: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching order status: $e')),
      );
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
              filters:
                  _currentFilters, // Changed from initialFilters to filters
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching stock report: $e')),
      );
    }
  }

 String _getImageUrl(dynamic catalog) {
  final imagePath = catalog['Style_Image'] ?? '';

  if (imagePath.isEmpty) {
    return '';
  }

  if (UserSession.onlineImage == '1') {
    // If onlineImage == '1', treat Style_Image as full URL
    return imagePath;
  } else if (UserSession.onlineImage == '0') {
    // If onlineImage == '0', extract image name and append base URL
    if (imagePath.startsWith('http')) {
      // Sometimes imagePath might already be a full URL even if onlineImage == '0'
      return imagePath;
    }
    final imageName = imagePath.split('/').last.split('?').first;
    if (imageName.isEmpty) {
      return '';
    }
    return '${AppConstants.BASE_URL}/images/$imageName';
  }

  // Fallback
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

  List<Map<String, dynamic>> _groupOrderData() {
    final groupBy = _currentFilters['groupBy']?.key ?? 'cust';
    final groupedData = <String, List<dynamic>>{};

    for (var item in _orderData) {
      String key;
      if (groupBy == 'style' && item['StyleCode'] != null) {
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
        'groupKey': parts[1], // OrderNo or StyleCode
        'items': entry.value,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = _groupOrderData();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Status',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Dropdown (Multi-select)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DropdownSearch<String>.multiSelection(
                items: _products.map((product) => product.itemKey).toList(),
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
                  loadingBuilder:
                      (context, searchEntry) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LoadingAnimationWidget.waveDots(
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('Loading Products...'),
                        ],
                      ),
                ),
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: 'Select Products',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
            ),
            // Category Dropdown (Single-select)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DropdownSearch<String>(
                items: _categories,
                selectedItem: _selectedCategory,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  loadingBuilder:
                      (context, searchEntry) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LoadingAnimationWidget.waveDots(
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('Loading Categories...'),
                        ],
                      ),
                ),
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: 'Select Category',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                enabled: !_isLoading,
              ),
            ),
            // Buttons Row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  _buildButton("View", Icons.visibility, Colors.blue, () async {
                    await _fetchOrderStatus(_currentFilters);
                  }),
                  const SizedBox(width: 8),
                  _buildButton(
                    "Download",
                    Icons.download,
                    Colors.deepPurple,
                    () {
                      // TODO: Implement download logic
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildButton(
                    "WhatsApp",
                    FontAwesomeIcons.whatsapp,
                    Colors.green,
                    () {
                      // TODO: Implement WhatsApp logic
                    },
                    isFaIcon: true,
                  ),
                  const SizedBox(width: 8),
                  _buildButton("Clear", Icons.clear, Colors.red, clearFilters),
                ],
              ),
            ),
            // Display Order Data
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _orderData.isEmpty
                      ? const Center(child: Text('No orders found'))
                      : ListView.builder(
                        itemCount: groupedData.length,
                        itemBuilder: (context, index) {
                          final group = groupedData[index];
                          return OrderStatusCard(
                            productName: group['productName'],
                            orderNo: group['groupKey'], // OrderNo or StyleCode
                            items: group['items'],
                            showImage: _currentFilters['withImage'] == true,
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120.0),
        child: FloatingActionButton(
          onPressed: _showFilterDialog,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.filter_list, color: Colors.white),
          tooltip: 'Filter Options',
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    return date != null ? DateFormat('dd-MM-yyyy').format(date) : '';
  }

  Widget _buildButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool isFaIcon = false,
  }) {
    return Expanded(
      child: SizedBox(
        height: 40,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon:
              isFaIcon
                  ? FaIcon(icon, size: 12, color: color)
                  : Icon(icon, size: 12, color: color),
          label: Text(
            label,
            style: TextStyle(fontSize: 10, color: color),
            softWrap: false,
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            side: BorderSide(color: color),
            foregroundColor: color,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}
