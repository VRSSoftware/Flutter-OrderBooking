// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:vrs_erp/constants/app_constants.dart';
// import 'package:vrs_erp/constants/constants.dart';

// class SalesOrderListScreen extends StatefulWidget {
//   final String custKey;
//   final List<Map<String, dynamic>> existingSelectedItems;
//   final bool isEditMode;
//   final String? currentPackingId;

//   const SalesOrderListScreen({
//     Key? key,
//     required this.custKey,
//     this.existingSelectedItems = const [],
//     this.isEditMode = false,
//     this.currentPackingId,
//   }) : super(key: key);

//   @override
//   _SalesOrderListScreenState createState() => _SalesOrderListScreenState();
// }

// class _SalesOrderListScreenState extends State<SalesOrderListScreen> {
//   List<dynamic> _orders = [];
//   bool _isLoading = true;
//   Set<String> _selectedOrderIds = {};
//   Map<String, Map<String, dynamic>> _selectedOrdersMap = {};
//   Map<String, Map<String, int>> _selectedQuantities = {};

//   @override
//   void initState() {
//     super.initState();
//     for (var item in widget.existingSelectedItems) {
//       final String uniqueId = '${item['docId']}_${item['docDtlId']}';
//       _selectedOrderIds.add(uniqueId);
//       _selectedOrdersMap[uniqueId] = item;
//       // Calculate total quantity from sizes
//       int totalQty = 0;
//       final sizes = item['sizes'] as List? ?? [];
//       for (var size in sizes) {
//         totalQty += (size['qty'] as int? ?? 0);
//       }
//       _selectedQuantities[uniqueId] = {'qty': totalQty};
//     }
//     _fetchOrders();
//   }

//   Future<void> _fetchOrders() async {
//     setState(() => _isLoading = true);

//     try {
//       final response = await http.post(
//         Uri.parse(
//           '${AppConstants.BASE_URL}/packing/getPendingPackingListAgainstSO',
//         ),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           "custKey": widget.custKey,
//           "fcYrId": UserSession.userFcYr ?? '',
//           "coBrId": UserSession.coBrId ?? '',
//           "isEditMode": widget.isEditMode,
//           "currentPackingId": widget.currentPackingId,
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data['data'] != null && data['data'] is List) {
//           setState(() => _orders = data['data']);
//         }
//       }
//     } catch (e) {
//       print('Error fetching orders: $e');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<List<dynamic>> _fetchSizeQty(
//     List<Map<String, dynamic>> selectedItems,
//   ) async {
//     try {
//       List<int> docDtlIds = [];
//       String shadeKey = '';
//       String shadeName = '';

//       for (var item in selectedItems) {
//         docDtlIds.add(item['docDtlId'] as int);
//         if (item['shadeKey'] != null &&
//             item['shadeKey'].toString().isNotEmpty) {
//           shadeKey = item['shadeKey'].toString();
//           shadeName = item['shadeName'].toString();
//         }
//       }

//       final response = await http.post(
//         Uri.parse('${AppConstants.BASE_URL}/packing/getSOSizeQty'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           "docDtl_Id": docDtlIds,
//           "shadeKey": shadeKey,
//           "shadeName": shadeName,
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data['data'] != null && data['data'] is List) {
//           return data['data'];
//         }
//       }
//     } catch (e) {
//       print('Error fetching size qty: $e');
//     }
//     return [];
//   }

// void _toggleSelection(dynamic item) {
//   final String uniqueId = '${item['Doc_Id']}_${item['docDtl_Id']}';
//   final double stkQty = (item['stkQty'] as num?)?.toDouble() ?? 0;

//   // Don't allow selection if stock is zero
//   if (stkQty <= 0) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Cannot select this item as stock is not available'),
//         backgroundColor: Colors.red,
//         duration: Duration(seconds: 2),
//       ),
//     );
//     return;
//   }

//   // Check if the item is already in existingSelectedItems
//   bool alreadyExists = false;
//   for (var existingItem in widget.existingSelectedItems) {
//     if (existingItem['docDtlId'] == item['docDtl_Id']) {
//       alreadyExists = true;
//       break;
//     }
//   }

//   if (alreadyExists) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('This item has already been added to the packing list'),
//         backgroundColor: Colors.orange,
//         duration: Duration(seconds: 2),
//       ),
//     );
//     return;
//   }

//   setState(() {
//     if (_selectedOrderIds.contains(uniqueId)) {
//       _selectedOrderIds.remove(uniqueId);
//       _selectedOrdersMap.remove(uniqueId);
//       _selectedQuantities.remove(uniqueId);
//     } else {
//       final double balQty = (item['BalQty'] as num?)?.toDouble() ?? 0;
//       final double rate =
//           double.tryParse(item['rate']?.toString() ?? '0') ?? 0;

//       _selectedOrderIds.add(uniqueId);
//       _selectedOrdersMap[uniqueId] = {
//         'docId': item['Doc_Id'],
//         'docDtlId': item['docDtl_Id'],
//         'docNo': item['Doc_No'],
//         'docDt': item['Doc_Dt']?.toString().split('T')[0] ?? '',
//         'dlvDate': item['DlvDate']?.toString().split('T')[0] ?? '',
//         'itemName': item['item_name'] ?? 'N/A',
//         'brandName': item['Brand_Name'] ?? '',
//         'styleCode': item['Style_Code'] ?? item['Style_Key'] ?? 'N/A',
//         'shadeName': item['shade_name'] ?? '',
//         'shadeKey': item['Shade_Key'] ?? '',
//         'typeName': item['Type_Name'] ?? '',
//         'unitName': item['unit_name'] ?? 'PCS',
//         'balQty': balQty,
//         'rate': rate,
//         'mrp': double.tryParse(item['mrp']?.toString() ?? '0') ?? 0,
//         'amt': double.tryParse(item['amt']?.toString() ?? '0') ?? 0,
//         'freeQty': double.tryParse(item['freeQty']?.toString() ?? '0') ?? 0,
//         'selectedQty': balQty,
//         'discPercent': 0.0,
//         'discAmt': 0.0,
//         'amtRemark': '',
//         'itemAmt': balQty * rate,
//         'sizes': [],
//       };
//       _selectedQuantities[uniqueId] = {'qty': balQty.toInt()};
//     }
//   });
// }

//   void _updateQuantity(String uniqueId, int newQty, double balQty, double rate) {
//     setState(() {
//       int clampedQty = newQty.clamp(0, balQty.toInt());
//       _selectedQuantities[uniqueId] = {'qty': clampedQty};
//       if (_selectedOrdersMap.containsKey(uniqueId)) {
//         _selectedOrdersMap[uniqueId]!['selectedQty'] = clampedQty.toDouble();
//         _selectedOrdersMap[uniqueId]!['itemAmt'] = clampedQty * rate;
//       }
//     });
//   }

//  void _addSelectedItems() async {
//   final List<Map<String, dynamic>> newSelectedItems = [];

//   // First, collect ALL selected items including those that might be already added
//   for (var entry in _selectedOrdersMap.entries) {
//     final String uniqueId = entry.key;
//     final Map<String, dynamic> item = entry.value;

//     // Check if this item already exists in existingSelectedItems
//     bool alreadyExists = false;
//     for (var existingItem in widget.existingSelectedItems) {
//       if (existingItem['docDtlId'] == item['docDtlId']) {
//         alreadyExists = true;
//         break;
//       }
//     }

//     // Skip items that are already added
//     if (!alreadyExists) {
//       final int selectedQty = _selectedQuantities[uniqueId]?['qty'] ?? (item['selectedQty'] as int);
//       if (selectedQty > 0) {
//         item['selectedQty'] = selectedQty.toDouble();
//         item['itemAmt'] = selectedQty * (item['rate'] as double);
//         newSelectedItems.add(item);
//       }
//     }
//   }

//   // If no new items to add, show message and close
//   if (newSelectedItems.isEmpty) {
//     if (mounted) {
//       // Show a message that no new items were selected
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('No new items selected. All selected items are already added.'),
//           backgroundColor: Colors.orange,
//           duration: Duration(seconds: 2),
//         ),
//       );
//       // Still close the screen without adding anything
//       Navigator.pop(context);
//     }
//     return;
//   }

//   if (!mounted) return;

//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (context) => const Center(child: CircularProgressIndicator()),
//   );

//   try {
//     final List<dynamic> sizeData = await _fetchSizeQty(newSelectedItems);

//     for (int i = 0; i < newSelectedItems.length && i < sizeData.length; i++) {
//       final sizeInfo = sizeData[i];
//       if (sizeInfo != null && sizeInfo['sizeQty'] != null) {
//         final List<dynamic> sizeQtyList = sizeInfo['sizeQty'];
//         final List<Map<String, dynamic>> updatedSizes = [];

//         // Keep each size separate with its own quantity
//         for (var sizeQty in sizeQtyList) {
//           int availableQty = (sizeQty['stockQty'] as num?)?.toInt() ?? 0;
//           int ordQty = (sizeQty['qty'] as num?)?.toInt() ?? 0;

//           // Use the original order quantity as default
//           int qtyToTake = ordQty;

//           // Don't exceed stock if stock is available and less than order quantity
//           if (availableQty > 0 && availableQty < ordQty) {
//             qtyToTake = availableQty;
//           }

//           updatedSizes.add({
//             'size': sizeQty['Size_Name'] ?? 'N/A',
//             'qty': qtyToTake,
//             'ordQty': ordQty,
//             'stock': availableQty,
//             'rate': (sizeQty['rate'] as num?)?.toDouble() ?? newSelectedItems[i]['rate'],
//             'mrp': (sizeQty['mrp'] as num?)?.toDouble() ?? newSelectedItems[i]['mrp'],
//             'netRate': (sizeQty['nettRate'] as num?)?.toDouble() ?? newSelectedItems[i]['rate'],
//             'styleSize_Id': sizeQty['styleSize_Id'] ?? 0,
//             'docDtlSzId': sizeQty['docDtlSzId'] ?? 0,
//             'stkId': sizeQty['stkId'] ?? 0,
//             'balQty': qtyToTake,
//           });
//         }

//         newSelectedItems[i]['sizes'] = updatedSizes;

//         // Calculate total quantity from all sizes
//         double totalQty = 0;
//         for (var size in updatedSizes) {
//           totalQty += size['qty'];
//         }
//         newSelectedItems[i]['selectedQty'] = totalQty;
//         newSelectedItems[i]['itemAmt'] = totalQty * (newSelectedItems[i]['rate'] as double);
//       } else {
//         // If no size data, create a single entry
//         final int userSelectedQty = newSelectedItems[i]['selectedQty'].toInt();
//         newSelectedItems[i]['sizes'] = [
//           {
//             'size': 'One Size',
//             'qty': userSelectedQty,
//             'ordQty': userSelectedQty,
//             'stock': userSelectedQty,
//             'rate': newSelectedItems[i]['rate'],
//             'mrp': newSelectedItems[i]['mrp'],
//             'netRate': newSelectedItems[i]['rate'],
//             'styleSize_Id': 0,
//             'docDtlSzId': 0,
//             'stkId': 0,
//             'balQty': userSelectedQty,
//           }
//         ];
//       }
//     }

//     if (mounted) {
//       Navigator.pop(context);
//       // Only return items that were actually selected and not already existing
//       Navigator.pop(context, newSelectedItems);
//     }
//   } catch (e) {
//     if (mounted) {
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
//       );
//     }
//   }
// }
//   void _onCancel() {
//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       appBar: AppBar(
//         backgroundColor: AppColors.primaryColor,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: _onCancel,
//         ),
//         title: const Text(
//           'Sales Orders',
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//             fontSize: 18,
//           ),
//         ),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _orders.isEmpty
//           ? const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.inbox, size: 64, color: Colors.grey),
//                   SizedBox(height: 16),
//                   Text(
//                     'No orders found',
//                     style: TextStyle(fontSize: 16, color: Colors.grey),
//                   ),
//                 ],
//               ),
//             )
//           : ListView.builder(
//               padding: const EdgeInsets.all(8),
//               itemCount: _orders.length,
//               itemBuilder: (context, index) {
//                 final item = _orders[index];
//                 final String uniqueId = '${item['Doc_Id']}_${item['docDtl_Id']}';
//                 final bool isSelected = _selectedOrderIds.contains(uniqueId);
//                 return _buildOrderCard(item, isSelected, uniqueId);
//               },
//             ),
//       bottomNavigationBar: Container(
//         padding: EdgeInsets.zero,
//         margin: EdgeInsets.zero,
//         decoration: const BoxDecoration(color: Colors.transparent),
//         child: SafeArea(
//           top: false,
//           bottom: true,
//           child: Row(
//             children: [
//               Expanded(
//                 child: SizedBox(
//                   height: 42,
//                   child: ElevatedButton.icon(
//                     onPressed: _onCancel,
//                     icon: const Icon(Icons.close, size: 18, color: Colors.white),
//                     label: const Text(
//                       'CANCEL',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 12,
//                         color: Colors.white,
//                       ),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red,
//                       foregroundColor: Colors.white,
//                       padding: EdgeInsets.zero,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.zero,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: SizedBox(
//                   height: 42,
//                   child: ElevatedButton.icon(
//                     onPressed: _selectedOrderIds.isEmpty ? null : _addSelectedItems,
//                     icon: const Icon(Icons.add_shopping_cart, size: 18, color: Colors.white),
//                     label: Text(
//                       'ADD SO (${_selectedOrderIds.length})',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 12,
//                         color: Colors.white,
//                       ),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.primaryColor,
//                       foregroundColor: Colors.white,
//                       padding: EdgeInsets.zero,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.zero,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

// Widget _buildOrderCard(dynamic item, bool isSelected, String uniqueId) {
//   final statusColor = isSelected ? AppColors.primaryColor : Colors.grey;
//   final statusBgColor = isSelected
//       ? AppColors.primaryColor.withOpacity(0.1)
//       : Colors.grey.shade50;

//   final double amount = double.tryParse(item['amt']?.toString() ?? '0') ?? 0;
//   final double rate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
//   final double mrp = double.tryParse(item['mrp']?.toString() ?? '0') ?? 0;
//   final double balQty = (item['BalQty'] as num?)?.toDouble() ?? 0;
//   final double freeQty = double.tryParse(item['freeQty']?.toString() ?? '0') ?? 0;
//   final double stkQty = (item['stkQty'] as num?)?.toDouble() ?? 0;

//   final bool isStockZero = stkQty <= 0;

//   final String styleCode = item['Style_Code'] ?? item['Style_Key'] ?? 'N/A';
//   final String shadeName = (item['shade_name'] != null && item['shade_name'].toString().isNotEmpty)
//       ? item['shade_name'].toString()
//       : 'N/A';
//   final String brandName = (item['Brand_Name'] != null && item['Brand_Name'].toString().isNotEmpty)
//       ? item['Brand_Name'].toString()
//       : 'N/A';
//   final String typeName = (item['Type_Name'] != null && item['Type_Name'].toString().isNotEmpty)
//       ? item['Type_Name'].toString()
//       : 'N/A';
//   final String unitName = item['unit_name'] ?? 'PCS';
//   final String docDate = item['Doc_Dt']?.toString().split('T')[0] ?? 'N/A';
//   final String dlvDate = item['DlvDate']?.toString().split('T')[0] ?? 'N/A';
//   final String consigneeName = item['consigneeName']?.toString().isNotEmpty == true
//       ? item['consigneeName'].toString()
//       : 'N/A';
//   final String pdesign = item['Pdesign']?.toString().isNotEmpty == true
//       ? item['Pdesign'].toString()
//       : 'N/A';

//   return Container(
//     margin: const EdgeInsets.only(bottom: 8),
//     decoration: BoxDecoration(
//       borderRadius: BorderRadius.circular(12),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.grey.withOpacity(0.1),
//           spreadRadius: 1,
//           blurRadius: 2,
//           offset: const Offset(0, 1),
//         ),
//       ],
//     ),
//     child: Card(
//       elevation: 0,
//       margin: EdgeInsets.zero,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(
//           color: isStockZero ? Colors.red.shade200 : (isSelected ? AppColors.primaryColor : Colors.grey.shade200),
//           width: isStockZero ? 1 : (isSelected ? 2 : 1),
//         ),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(12),
//         child: Theme(
//           data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
//           child: ExpansionTile(
//             tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//             childrenPadding: EdgeInsets.zero,
//             leading: GestureDetector(
//               onTap: isStockZero ? null : () => _toggleSelection(item),
//               child: Container(
//                 width: 36,
//                 height: 36,
//                 decoration: BoxDecoration(
//                   color: isStockZero ? Colors.red.shade50 : statusBgColor,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: isStockZero
//                     ? Icon(Icons.block, color: Colors.red.shade400, size: 20)
//                     : Icon(
//                         isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
//                         color: statusColor,
//                         size: 20,
//                       ),
//               ),
//             ),
//             title: Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     item['Doc_No'] ?? 'N/A',
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF2C3E50),
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 const SizedBox(width: 4),
//                 // Status Badge
//                 if (isStockZero)
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                     decoration: BoxDecoration(
//                       color: Colors.red.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: Colors.red.withOpacity(0.3)),
//                     ),
//                     child: Text(
//                       'OUT',
//                       style: TextStyle(
//                         fontSize: 9,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.red.shade700,
//                       ),
//                     ),
//                   )
//                 else if (isSelected)
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                     decoration: BoxDecoration(
//                       color: Colors.green.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: Colors.green.withOpacity(0.3)),
//                     ),
//                     child: Text(
//                       'SELECTED',
//                       style: TextStyle(
//                         fontSize: 9,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.green.shade700,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//             subtitle: Padding(
//               padding: const EdgeInsets.only(top: 4),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Product: ${item['item_name'] ?? 'N/A'}',
//                     style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     'Doc Dt: $docDate',
//                     style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//             trailing: Container(
//               padding: const EdgeInsets.all(4),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryColor, size: 16),
//             ),
//             backgroundColor: Colors.white,
//             collapsedBackgroundColor: Colors.white,
//             children: [
//               Container(
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade50,
//                   border: Border(top: BorderSide(color: Colors.grey.shade200)),
//                 ),
//                 padding: const EdgeInsets.all(10),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Main Details Container
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.grey.shade200),
//                       ),
//                       child: Column(
//                         children: [
//                           // Row 1: Design & Shade
//                           Row(
//                             children: [
//                               Expanded(child: _buildCompactDetailRow('Design', styleCode)),
//                               const SizedBox(width: 6),
//                               Expanded(child: _buildCompactDetailRow('Shade', shadeName)),
//                             ],
//                           ),
//                           const SizedBox(height: 8),
//                           // Row 2: Brand & Type
//                           Row(
//                             children: [
//                               Expanded(child: _buildCompactDetailRow('Brand', brandName)),
//                               const SizedBox(width: 6),
//                               Expanded(child: _buildCompactDetailRow('Type', typeName)),
//                             ],
//                           ),
//                           const SizedBox(height: 8),
//                           // Row 3: Unit & Delivery Date
//                           Row(
//                             children: [
//                               Expanded(child: _buildCompactDetailRow('Unit', unitName)),
//                               const SizedBox(width: 6),
//                               Expanded(child: _buildCompactDetailRow('Dlv Date', dlvDate)),
//                             ],
//                           ),
//                           const SizedBox(height: 10),
//                           // Row 4: MRP, Rate & Amount
//                           Container(
//                             decoration: BoxDecoration(
//                               border: Border.all(color: Colors.grey.shade300),
//                               borderRadius: BorderRadius.circular(6),
//                             ),
//                             child: Row(
//                               children: [
//                                 Expanded(
//                                   child: Padding(
//                                     padding: const EdgeInsets.symmetric(vertical: 8),
//                                     child: Column(
//                                       children: [
//                                         Text(
//                                           'MRP',
//                                           style: TextStyle(
//                                             fontSize: 9,
//                                             color: Colors.grey.shade600,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 2),
//                                         Text(
//                                           mrp > 0 ? '₹${mrp.toStringAsFixed(0)}' : 'N/A',
//                                           style: const TextStyle(
//                                             fontSize: 11,
//                                             fontWeight: FontWeight.bold,
//                                             color: Color(0xFF2C3E50),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                                 Container(
//                                   width: 0.5,
//                                   height: 35,
//                                   color: Colors.grey.shade300,
//                                 ),
//                                 Expanded(
//                                   child: Padding(
//                                     padding: const EdgeInsets.symmetric(vertical: 8),
//                                     child: Column(
//                                       children: [
//                                         Text(
//                                           'Rate',
//                                           style: TextStyle(
//                                             fontSize: 9,
//                                             color: Colors.grey.shade600,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 2),
//                                         Text(
//                                           rate > 0 ? '₹${rate.toStringAsFixed(0)}' : 'N/A',
//                                           style: const TextStyle(
//                                             fontSize: 11,
//                                             fontWeight: FontWeight.bold,
//                                             color: Color(0xFF2C3E50),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                                 Container(
//                                   width: 0.5,
//                                   height: 35,
//                                   color: Colors.grey.shade300,
//                                 ),
//                                 Expanded(
//                                   child: Padding(
//                                     padding: const EdgeInsets.symmetric(vertical: 8),
//                                     child: Column(
//                                       children: [
//                                         Text(
//                                           'Amount',
//                                           style: TextStyle(
//                                             fontSize: 9,
//                                             color: Colors.grey.shade600,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 2),
//                                         Text(
//                                           amount > 0 ? '₹${amount.toStringAsFixed(0)}' : 'N/A',
//                                           style: const TextStyle(
//                                             fontSize: 11,
//                                             fontWeight: FontWeight.bold,
//                                             color: Color(0xFF2C3E50),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(height: 10),
//                           // Row 5: Pdesign & Consignee Name
//                           Row(
//                             children: [
//                               Expanded(child: _buildCompactDetailRow('Pdesign', pdesign)),
//                               const SizedBox(width: 6),
//                               Expanded(child: _buildCompactDetailRow('Consignee', consigneeName)),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 10),

//                     // Quantity Details Container
//                     Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.grey.shade200),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Quantity Details',
//                             style: TextStyle(
//                               fontSize: 11,
//                               fontWeight: FontWeight.bold,
//                               color: AppColors.primaryColor
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           // Quantity rows
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: _buildCompactDetailRow(
//                                   'Free Qty',
//                                   '${freeQty.toStringAsFixed(0)} $unitName'
//                                 ),
//                               ),
//                               const SizedBox(width: 6),
//                               Expanded(
//                                 child: _buildCompactDetailRow(
//                                   'Stock Qty',
//                                   '${stkQty.toStringAsFixed(0)} $unitName',
//                                   valueColor: Colors.red.shade700,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 8),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: _buildCompactDetailRow(
//                                   'Balance Qty',
//                                   '${balQty.toStringAsFixed(0)} $unitName'
//                                 ),
//                               ),
//                               const SizedBox(width: 6),
//                               Expanded(child: SizedBox()),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 10),

//                     // Stock zero message
//                     if (isStockZero)
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: Colors.red.shade50,
//                           borderRadius: BorderRadius.circular(6),
//                           border: Border.all(color: Colors.red.shade200),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 16),
//                             const SizedBox(width: 6),
//                             Expanded(
//                               child: Text(
//                                 'Stock not available',
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.red.shade700,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     ),
//   );
// }

// Widget _buildCompactDetailRow(String label, String value, {Color? valueColor}) {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Text(
//         label,
//         style: TextStyle(
//           fontSize: 9,
//           color: Colors.grey.shade600,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       const SizedBox(height: 2),
//       Text(
//         value.isEmpty || value == 'N/A' ? 'N/A' : value,
//         style: TextStyle(
//           fontSize: 11,
//           fontWeight: FontWeight.w500,
//           color: valueColor ?? const Color(0xFF2C3E50),
//         ),
//         maxLines: 1,
//         overflow: TextOverflow.ellipsis,
//       ),
//     ],
//   );
// }
//   Widget _buildMetricRow(IconData icon, String label, String value) {
//     return Row(
//       children: [
//         Icon(icon, size: 14, color: Colors.grey.shade600),
//         const SizedBox(width: 6),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
//               Text(
//                 value,
//                 style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/constants/constants.dart';

class SalesOrderListScreen extends StatefulWidget {
  final String custKey;
  final List<Map<String, dynamic>> existingSelectedItems;
  final bool isEditMode;
  final String? currentPackingId;

  const SalesOrderListScreen({
    Key? key,
    required this.custKey,
    this.existingSelectedItems = const [],
    this.isEditMode = false,
    this.currentPackingId,
  }) : super(key: key);

  @override
  _SalesOrderListScreenState createState() => _SalesOrderListScreenState();
}

class _SalesOrderListScreenState extends State<SalesOrderListScreen> {
  List<dynamic> _orders = [];
    List<dynamic> _filteredOrders = [];
  bool _isLoading = true;
   bool _isSearching = false; 
     final TextEditingController _searchController = TextEditingController(); 
  Set<String> _selectedOrderIds = {};
  Map<String, Map<String, dynamic>> _selectedOrdersMap = {};
  Map<String, Map<String, int>> _selectedQuantities = {};

  @override
  void initState() {
    super.initState();
    for (var item in widget.existingSelectedItems) {
      final String uniqueId = '${item['docId']}_${item['docDtlId']}';
      _selectedOrderIds.add(uniqueId);
      _selectedOrdersMap[uniqueId] = item;
      // Calculate total quantity from sizes
      int totalQty = 0;
      final sizes = item['sizes'] as List? ?? [];
      for (var size in sizes) {
        totalQty += (size['qty'] as int? ?? 0);
      }
      _selectedQuantities[uniqueId] = {'qty': totalQty};
    }
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(
          '${AppConstants.BASE_URL}/packing/getPendingPackingListAgainstSO',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "custKey": widget.custKey,
          "fcYrId": UserSession.userFcYr ?? '',
          "coBrId": UserSession.coBrId ?? '',
          "isEditMode": widget.isEditMode,
          "currentPackingId": widget.currentPackingId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data'] is List) {
          setState(() => _orders = data['data']);
        }
      }
    } catch (e) {
      print('Error fetching orders: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<dynamic>> _fetchSizeQty(
    List<Map<String, dynamic>> selectedItems,
  ) async {
    try {
      List<int> docDtlIds = [];
      String shadeKey = '';
      String shadeName = '';

      for (var item in selectedItems) {
        docDtlIds.add(item['docDtlId'] as int);
        if (item['shadeKey'] != null &&
            item['shadeKey'].toString().isNotEmpty) {
          shadeKey = item['shadeKey'].toString();
          shadeName = item['shadeName'].toString();
        }
      }

      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/packing/getSOSizeQty'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "docDtl_Id": docDtlIds,
          "shadeKey": shadeKey,
          "shadeName": shadeName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data'] is List) {
          return data['data'];
        }
      }
    } catch (e) {
      print('Error fetching size qty: $e');
    }
    return [];
  }

  double _calculateVarQty(double balQty, double varPerc) {
    if (varPerc <= 0) return 0;
    return (balQty * varPerc) / 100;
  }

  double _calculateTotalAllowedQty(double balQty, double varPerc) {
    if (varPerc <= 0) return double.infinity;
    double varQty = _calculateVarQty(balQty, varPerc);
    return balQty + varQty;
  }

  void _toggleSelection(dynamic item) {
    final String uniqueId = '${item['Doc_Id']}_${item['docDtl_Id']}';
    final double stkQty = (item['stkQty'] as num?)?.toDouble() ?? 0;
    final double balQty = (item['BalQty'] as num?)?.toDouble() ?? 0;
    final double varPerc = (item['varPerc'] as num?)?.toDouble() ?? 0;
    final bool hasVarPerc = varPerc > 0;
    final double totalAllowedQty = _calculateTotalAllowedQty(balQty, varPerc);

    // Don't allow selection if stock is zero
    if (stkQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot select this item as stock is not available'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Check if the item is already in existingSelectedItems
    bool alreadyExists = false;
    for (var existingItem in widget.existingSelectedItems) {
      if (existingItem['docDtlId'] == item['docDtl_Id']) {
        alreadyExists = true;
        break;
      }
    }

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This item has already been added to the packing list'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      if (_selectedOrderIds.contains(uniqueId)) {
        _selectedOrderIds.remove(uniqueId);
        _selectedOrdersMap.remove(uniqueId);
        _selectedQuantities.remove(uniqueId);
      } else {
        final double rate =
            double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
        final double totQty = (item['totQty'] as num?)?.toDouble() ?? 0;
        final double netAmt = (item['net_amt'] as num?)?.toDouble() ?? 0;
        
        // Default selected quantity: if has varPerc, use totalAllowedQty, else use stkQty (but not more than balQty)
        double defaultSelectedQty = hasVarPerc 
            ? totalAllowedQty 
            : (stkQty > balQty ? balQty : stkQty);

        _selectedOrderIds.add(uniqueId);
        _selectedOrdersMap[uniqueId] = {
          'docId': item['Doc_Id'],
          'docDtlId': item['docDtl_Id'],
          'docNo': item['Doc_No'],
          'docDt': item['Doc_Dt']?.toString().split('T')[0] ?? '',
          'dlvDate': item['DlvDate']?.toString().split('T')[0] ?? '',
          'itemName': item['item_name'] ?? 'N/A',
          'brandName': item['Brand_Name'] ?? '',
          'styleCode': item['Style_Code'] ?? item['Style_Key'] ?? 'N/A',
          'shadeName': item['shade_name'] ?? '',
          'shadeKey': item['Shade_Key'] ?? '',
          'typeName': item['Type_Name'] ?? '',
          'unitName': item['unit_name'] ?? 'PCS',
          'balQty': balQty,
          'rate': rate,
          'mrp': double.tryParse(item['mrp']?.toString() ?? '0') ?? 0,
          'amt': double.tryParse(item['amt']?.toString() ?? '0') ?? 0,
          'freeQty': double.tryParse(item['freeQty']?.toString() ?? '0') ?? 0,
          'selectedQty': defaultSelectedQty,
          'discPercent': 0.0,
          'discAmt': 0.0,
          'amtRemark': '',
          'itemAmt': defaultSelectedQty * rate,
          'sizes': [],
          'varPerc': varPerc,
          'totQty': totQty,
          'netAmt': netAmt,
          'stkQty': stkQty,
        };
        _selectedQuantities[uniqueId] = {'qty': defaultSelectedQty.toInt()};
      }
    });
  }

 void _updateQuantity(
  String uniqueId,
  int newQty,
  double balQty,
  double rate,
  double varPerc,
) {
  final bool hasVarPerc = varPerc > 0;
  final double stkQty = _selectedOrdersMap[uniqueId]?['stkQty'] as double? ?? 0;
  final double totalAllowedQty = _calculateTotalAllowedQty(balQty, varPerc);
  
  // Determine max allowed quantity
  double maxAllowedQty = hasVarPerc ? totalAllowedQty : stkQty;
  
  // Show error if quantity exceeds max allowed
  if (newQty > maxAllowedQty) {
    String errorMsg = hasVarPerc
        ? 'Quantity cannot exceed ${totalAllowedQty.toStringAsFixed(0)}'
        : 'Quantity cannot exceed available stock: ${stkQty.toStringAsFixed(0)}';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMsg),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }

  setState(() {
    int clampedQty = newQty.clamp(0, maxAllowedQty.toInt());
    _selectedQuantities[uniqueId] = {'qty': clampedQty};
    if (_selectedOrdersMap.containsKey(uniqueId)) {
      _selectedOrdersMap[uniqueId]!['selectedQty'] = clampedQty.toDouble();
      _selectedOrdersMap[uniqueId]!['itemAmt'] = clampedQty * rate;
    }
  });
}
  void _addSelectedItems() async {
    final List<Map<String, dynamic>> newSelectedItems = [];

    // First, collect ALL selected items including those that might be already added
    for (var entry in _selectedOrdersMap.entries) {
      final String uniqueId = entry.key;
      final Map<String, dynamic> item = entry.value;

      // Check if this item already exists in existingSelectedItems
      bool alreadyExists = false;
      for (var existingItem in widget.existingSelectedItems) {
        if (existingItem['docDtlId'] == item['docDtlId']) {
          alreadyExists = true;
          break;
        }
      }

      // Skip items that are already added
      if (!alreadyExists) {
        final int selectedQty =
            _selectedQuantities[uniqueId]?['qty'] ??
            (item['selectedQty'] as int);
        if (selectedQty > 0) {
          item['selectedQty'] = selectedQty.toDouble();
          item['itemAmt'] = selectedQty * (item['rate'] as double);
          newSelectedItems.add(item);
        }
      }
    }

    // If no new items to add, show message and close
    if (newSelectedItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No new items selected. All selected items are already added.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final List<dynamic> sizeData = await _fetchSizeQty(newSelectedItems);

      for (int i = 0; i < newSelectedItems.length && i < sizeData.length; i++) {
        final sizeInfo = sizeData[i];
        if (sizeInfo != null && sizeInfo['sizeQty'] != null) {
          final List<dynamic> sizeQtyList = sizeInfo['sizeQty'];
          final List<Map<String, dynamic>> updatedSizes = [];

          // Keep each size separate with its own quantity
          for (var sizeQty in sizeQtyList) {
            int availableQty = (sizeQty['stockQty'] as num?)?.toInt() ?? 0;
            int ordQty = (sizeQty['qty'] as num?)?.toInt() ?? 0;
            int sizeBalQty = (sizeQty['balQty'] as num?)?.toInt() ?? ordQty;

            // Use the original order quantity as default
            int qtyToTake = ordQty;

            // Don't exceed stock if stock is available and less than order quantity
            if (availableQty > 0 && availableQty < ordQty) {
              qtyToTake = availableQty;
            }

            updatedSizes.add({
              'size': sizeQty['Size_Name'] ?? 'N/A',
              'qty': qtyToTake,
              'ordQty': ordQty,
              'balQty': sizeBalQty, // size-specific balance quantity
              'stock': availableQty,
              'rate':
                  (sizeQty['rate'] as num?)?.toDouble() ??
                  newSelectedItems[i]['rate'],
              'mrp':
                  (sizeQty['mrp'] as num?)?.toDouble() ??
                  newSelectedItems[i]['mrp'],
              'netRate':
                  (sizeQty['nettRate'] as num?)?.toDouble() ??
                  newSelectedItems[i]['rate'],
              'styleSize_Id': sizeQty['styleSize_Id'] ?? 0,
              'docDtlSzId': sizeQty['docDtlSzId'] ?? 0,
              'stkId': sizeQty['stkId'] ?? 0,
            });
          }

          newSelectedItems[i]['sizes'] = updatedSizes;

          // Calculate total quantity from all sizes
          double totalQty = 0;
          for (var size in updatedSizes) {
            totalQty += size['qty'];
          }
          newSelectedItems[i]['selectedQty'] = totalQty;
          newSelectedItems[i]['itemAmt'] =
              totalQty * (newSelectedItems[i]['rate'] as double);
        } else {
          // If no size data, create a single entry
          final int userSelectedQty =
              newSelectedItems[i]['selectedQty'].toInt();
          newSelectedItems[i]['sizes'] = [
            {
              'size': 'One Size',
              'qty': userSelectedQty,
              'ordQty': userSelectedQty,
              'stock': userSelectedQty,
              'rate': newSelectedItems[i]['rate'],
              'mrp': newSelectedItems[i]['mrp'],
              'netRate': newSelectedItems[i]['rate'],
              'styleSize_Id': 0,
              'docDtlSzId': 0,
              'stkId': 0,
              'balQty': userSelectedQty,
            },
          ];
        }
      }

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context, newSelectedItems);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onCancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _onCancel,
        ),
        title: const Text(
          'Sales Orders',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _orders.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No orders found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final item = _orders[index];
                  final String uniqueId =
                      '${item['Doc_Id']}_${item['docDtl_Id']}';
                  final bool isSelected = _selectedOrderIds.contains(uniqueId);
                  return _buildOrderCard(item, isSelected, uniqueId);
                },
              ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        decoration: const BoxDecoration(color: Colors.transparent),
        child: SafeArea(
          top: false,
          bottom: true,
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: _onCancel,
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'CANCEL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed:
                        _selectedOrderIds.isEmpty ? null : _addSelectedItems,
                    icon: const Icon(
                      Icons.add_shopping_cart,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      'ADD SO (${_selectedOrderIds.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic item, bool isSelected, String uniqueId) {
    final statusColor = isSelected ? AppColors.primaryColor : Colors.grey;
    final statusBgColor =
        isSelected
            ? AppColors.primaryColor.withOpacity(0.1)
            : Colors.grey.shade50;

    final double amount = double.tryParse(item['amt']?.toString() ?? '0') ?? 0;
    final double rate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
    final double mrp = double.tryParse(item['mrp']?.toString() ?? '0') ?? 0;
    final double balQty = (item['BalQty'] as num?)?.toDouble() ?? 0;
    final double freeQty =
        double.tryParse(item['freeQty']?.toString() ?? '0') ?? 0;
    final double stkQty = (item['stkQty'] as num?)?.toDouble() ?? 0;
    final double varPerc = (item['varPerc'] as num?)?.toDouble() ?? 0;
    final bool hasVarPerc = varPerc > 0;
    final double varQty = hasVarPerc ? (balQty * varPerc) / 100 : 0;
    final double totalAllowedQty = hasVarPerc ? balQty + varQty : stkQty;
    final double totQty = (item['totQty'] as num?)?.toDouble() ?? 0;
    final double netAmt = (item['net_amt'] as num?)?.toDouble() ?? 0;

    final bool isStockZero = stkQty <= 0;

    final String styleCode = item['Style_Code'] ?? item['Style_Key'] ?? 'N/A';
    final String shadeName =
        (item['shade_name'] != null && item['shade_name'].toString().isNotEmpty)
            ? item['shade_name'].toString()
            : 'N/A';
    final String brandName =
        (item['Brand_Name'] != null && item['Brand_Name'].toString().isNotEmpty)
            ? item['Brand_Name'].toString()
            : 'N/A';
    final String typeName =
        (item['Type_Name'] != null && item['Type_Name'].toString().isNotEmpty)
            ? item['Type_Name'].toString()
            : 'N/A';
    final String unitName = item['unit_name'] ?? 'PCS';
    final String docDate = item['Doc_Dt']?.toString().split('T')[0] ?? 'N/A';
    final String dlvDate = item['DlvDate']?.toString().split('T')[0] ?? 'N/A';
    final String consigneeName =
        item['consigneeName']?.toString().isNotEmpty == true
            ? item['consigneeName'].toString()
            : 'N/A';
    final String pdesign =
        item['Pdesign']?.toString().isNotEmpty == true
            ? item['Pdesign'].toString()
            : 'N/A';

    // Get selected quantity for this item
    final int selectedQty =
        _selectedQuantities[uniqueId]?['qty'] ??
        (isSelected ? (hasVarPerc ? totalAllowedQty.toInt() : (stkQty > balQty ? balQty.toInt() : stkQty.toInt())) : 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color:
                isStockZero
                    ? Colors.red.shade200
                    : (isSelected
                        ? AppColors.primaryColor
                        : Colors.grey.shade200),
            width: isStockZero ? 1 : (isSelected ? 2 : 1),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              childrenPadding: EdgeInsets.zero,
              leading: GestureDetector(
                onTap: isStockZero ? null : () => _toggleSelection(item),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isStockZero ? Colors.red.shade50 : statusBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      isStockZero
                          ? Icon(
                            Icons.block,
                            color: Colors.red.shade400,
                            size: 20,
                          )
                          : Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: statusColor,
                            size: 20,
                          ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item['Doc_No'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Status Badge
                  if (isStockZero)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        'OUT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    )
                  else if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'SELECTED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product: ${item['item_name'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Doc Dt: $docDate',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.primaryColor,
                  size: 16,
                ),
              ),
              backgroundColor: Colors.white,
              collapsedBackgroundColor: Colors.white,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Details Container
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            // Row 1: Design & Shade
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCompactDetailRow(
                                    'Design',
                                    styleCode,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _buildCompactDetailRow(
                                    'Shade',
                                    shadeName,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Row 2: Brand & Type
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCompactDetailRow(
                                    'Brand',
                                    brandName,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _buildCompactDetailRow(
                                    'Type',
                                    typeName,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Row 3: Unit & Delivery Date
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCompactDetailRow(
                                    'Unit',
                                    unitName,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _buildCompactDetailRow(
                                    'Dlv Date',
                                    dlvDate,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Row 4: MRP, Rate & Amount
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'MRP',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            mrp > 0
                                                ? '₹${mrp.toStringAsFixed(0)}'
                                                : 'N/A',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2C3E50),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 0.5,
                                    height: 35,
                                    color: Colors.grey.shade300,
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Rate',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            rate > 0
                                                ? '₹${rate.toStringAsFixed(0)}'
                                                : 'N/A',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2C3E50),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 0.5,
                                    height: 35,
                                    color: Colors.grey.shade300,
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Amount',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            amount > 0
                                                ? '₹${amount.toStringAsFixed(0)}'
                                                : 'N/A',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2C3E50),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Row 5: Pdesign & Consignee Name
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCompactDetailRow(
                                    'Pdesign',
                                    pdesign,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _buildCompactDetailRow(
                                    'Consignee',
                                    consigneeName,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Quantity Details Container
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quantity Details',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Quantity rows
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCompactDetailRow(
                                    'Free Qty',
                                    '${freeQty.toStringAsFixed(0)} $unitName',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _buildCompactDetailRow(
                                    'Stock Qty',
                                    '${stkQty.toStringAsFixed(0)} $unitName',
                                    valueColor: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCompactDetailRow(
                                    'Balance Qty',
                                    '${balQty.toStringAsFixed(0)} $unitName',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _buildCompactDetailRow(
                                    'Var %',
                                    '${varPerc.toStringAsFixed(2)}%',
                                  ),
                                ),
                              ],
                            ),
                            if (hasVarPerc) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildCompactDetailRow(
                                      'Var Qty',
                                      '${varQty.toStringAsFixed(0)} $unitName',
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _buildCompactDetailRow(
                                      'Total Allowed',
                                      '${totalAllowedQty.toStringAsFixed(0)} $unitName',
                                      valueColor: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            // Total Qty and Net Amount row
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.primaryColor.withOpacity(
                                    0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Qty',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${totQty.toStringAsFixed(0)} $unitName',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 30,
                                    color: Colors.grey.shade300,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Net Amount',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '₹${netAmt.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryColor,
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
                      ),
                      const SizedBox(height: 10),
                      if (isStockZero)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red.shade700,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Stock not available',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDetailRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty || value == 'N/A' ? 'N/A' : value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: valueColor ?? const Color(0xFF2C3E50),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}