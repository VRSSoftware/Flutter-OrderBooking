import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/constants/constants.dart';

class SalesOrderListScreen extends StatefulWidget {
  final String custKey;
  final List<Map<String, dynamic>> existingSelectedItems;

  const SalesOrderListScreen({
    Key? key,
    required this.custKey,
    this.existingSelectedItems = const [],
  }) : super(key: key);

  @override
  _SalesOrderListScreenState createState() => _SalesOrderListScreenState();
}

class _SalesOrderListScreenState extends State<SalesOrderListScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  Set<String> _selectedOrderIds = {};
  Map<String, Map<String, dynamic>> _selectedOrdersMap = {};

  @override
  void initState() {
    super.initState();
    for (var item in widget.existingSelectedItems) {
      final String uniqueId = '${item['docId']}_${item['docDtlId']}';
      _selectedOrderIds.add(uniqueId);
      _selectedOrdersMap[uniqueId] = item;
    }
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/packing/getPendingPackingListAgainstSO'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "custKey": widget.custKey,
          "fcYrId": UserSession.userFcYr ?? '',
          "coBrId": UserSession.coBrId ?? '',
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

  Future<List<dynamic>> _fetchSizeQty(List<Map<String, dynamic>> selectedItems) async {
    try {
      List<int> docDtlIds = [];
      String shadeKey = '';
      String shadeName = '';
      
      for (var item in selectedItems) {
        docDtlIds.add(item['docDtlId'] as int);
        if (item['shadeKey'] != null && item['shadeKey'].toString().isNotEmpty) {
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
          "shadeName": shadeName
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

  void _toggleSelection(dynamic item) {
    final String uniqueId = '${item['Doc_Id']}_${item['docDtl_Id']}';
    setState(() {
      if (_selectedOrderIds.contains(uniqueId)) {
        _selectedOrderIds.remove(uniqueId);
        _selectedOrdersMap.remove(uniqueId);
      } else {
        final sizeList = _buildSizeList(item);
        final double balQty = (item['BalQty'] as num?)?.toDouble() ?? 0;
        final double rate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
        
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
          'selectedQty': balQty,
          'discPercent': 0.0,
          'discAmt': 0.0,
          'amtRemark': '',
          'itemAmt': balQty * rate,
          'sizes': sizeList,
        };
      }
    });
  }

  List<Map<String, dynamic>> _buildSizeList(dynamic item) {
    final double balQty = (item['BalQty'] as num?)?.toDouble() ?? 0;
    final double rate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
    final double mrp = double.tryParse(item['mrp']?.toString() ?? '0') ?? 0;
    
    return [
      {'size': 'S', 'qty': 0, 'ordQty': ((balQty * 0.25)).toInt(), 'stock': 50, 'rate': rate, 'mrp': mrp, 'netRate': rate},
      {'size': 'M', 'qty': 0, 'ordQty': ((balQty * 0.35)).toInt(), 'stock': 45, 'rate': rate, 'mrp': mrp, 'netRate': rate},
      {'size': 'L', 'qty': 0, 'ordQty': ((balQty * 0.25)).toInt(), 'stock': 30, 'rate': rate, 'mrp': mrp, 'netRate': rate},
      {'size': 'XL', 'qty': 0, 'ordQty': ((balQty * 0.15)).toInt(), 'stock': 20, 'rate': rate, 'mrp': mrp, 'netRate': rate},
    ];
  }

  Future<void> _addSelectedItems() async {
    final List<Map<String, dynamic>> selectedItems = _selectedOrdersMap.values.toList();
    
    if (selectedItems.isEmpty) return;
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final List<dynamic> sizeData = await _fetchSizeQty(selectedItems);
      
      for (int i = 0; i < selectedItems.length && i < sizeData.length; i++) {
        final sizeInfo = sizeData[i];
        if (sizeInfo != null && sizeInfo['sizeQty'] != null) {
          final List<dynamic> sizeQtyList = sizeInfo['sizeQty'];
          final List<Map<String, dynamic>> updatedSizes = [];
          
          for (var sizeQty in sizeQtyList) {
            updatedSizes.add({
              'size': sizeQty['Size_Name'] ?? 'N/A',
              'qty': 0,
              'ordQty': (sizeQty['qty'] as num?)?.toInt() ?? 0,
              'stock': int.tryParse(sizeQty['stockQty']?.toString() ?? '0') ?? 0,
              'rate': (sizeQty['rate'] as num?)?.toDouble() ?? selectedItems[i]['rate'],
              'mrp': (sizeQty['mrp'] as num?)?.toDouble() ?? selectedItems[i]['mrp'],
              'netRate': (sizeQty['nettRate'] as num?)?.toDouble() ?? selectedItems[i]['rate'],
              'styleSize_Id': sizeQty['styleSize_Id'] ?? 0,
            });
          }
          selectedItems[i]['sizes'] = updatedSizes;
        }
      }
      
      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context, selectedItems);
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
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: _onCancel),
        title: const Text('Sales Orders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No orders found', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final item = _orders[index];
                    final String uniqueId = '${item['Doc_Id']}_${item['docDtl_Id']}';
                    final bool isSelected = _selectedOrderIds.contains(uniqueId);
                    return _buildOrderCard(item, isSelected);
                  },
                ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2))]),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedOrderIds.isEmpty ? null : _addSelectedItems,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('ADD SO (${_selectedOrderIds.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic item, bool isSelected) {
    final statusColor = isSelected ? AppColors.primaryColor : Colors.grey;
    final statusBgColor = isSelected ? AppColors.primaryColor.withOpacity(0.1) : Colors.grey.shade50;
    
    final double amount = double.tryParse(item['amt']?.toString() ?? '0') ?? 0;
    final double rate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
    final double balQty = (item['BalQty'] as num?)?.toDouble() ?? 0;
    final double freeQty = double.tryParse(item['freeQty']?.toString() ?? '0') ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 2, offset: const Offset(0, 1))],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isSelected ? AppColors.primaryColor : Colors.grey.shade200, width: isSelected ? 2 : 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              childrenPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSelected ? Icons.check_circle_outline : Icons.shopping_cart,
                  color: statusColor,
                  size: 22,
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['Doc_No'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Text(
                            'SELECTED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.inventory, size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 2),
                            Text(
                              item['item_name'] ?? 'N/A',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 2),
                            Text(
                              item['Doc_Dt']?.toString().split('T')[0] ?? 'N/A',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.primaryColor,
                  size: 18,
                ),
              ),
              backgroundColor: Colors.white,
              collapsedBackgroundColor: Colors.white,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildDetailChip(Icons.code, 'Style Code', item['Style_Code'] ?? item['Style_Key'] ?? 'N/A')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildDetailChip(Icons.color_lens, 'Shade', (item['shade_name']?.toString().isNotEmpty == true) ? item['shade_name'].toString() : 'N/A')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildDetailChip(Icons.branding_watermark, 'Brand', (item['Brand_Name']?.toString().isNotEmpty == true) ? item['Brand_Name'].toString() : 'N/A')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildDetailChip(Icons.category, 'Type', (item['Type_Name']?.toString().isNotEmpty == true) ? item['Type_Name'].toString() : 'N/A')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildDetailChip(Icons.local_shipping, 'Delivery Date', item['DlvDate']?.toString().split('T')[0] ?? 'N/A')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildDetailChip(Icons.inventory, 'Unit', item['unit_name'] ?? 'PCS')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildMetricItem(Icons.currency_rupee, 'MRP', '₹${double.tryParse(item['mrp']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}')),
                                Container(width: 1, height: 30, color: Colors.grey.shade300),
                                Expanded(child: _buildMetricItem(Icons.price_change, 'Rate', '₹${rate.toStringAsFixed(2)}')),
                                Container(width: 1, height: 30, color: Colors.grey.shade300),
                                Expanded(child: _buildMetricItem(Icons.inventory_2, 'Balance Qty', '${balQty.toStringAsFixed(0)} ${item['unit_name'] ?? ''}')),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildMetricItem(Icons.card_giftcard, 'Free Qty', '${freeQty.toStringAsFixed(0)} ${item['unit_name'] ?? ''}')),
                                Container(width: 1, height: 30, color: Colors.grey.shade300),
                                Expanded(child: _buildMetricItem(Icons.attach_money, 'Amount', '₹${amount.toStringAsFixed(2)}')),
                                Container(width: 1, height: 30, color: Colors.grey.shade300),
                                Expanded(child: _buildMetricItem(Icons.shopping_cart, 'Order Qty', '${balQty.toStringAsFixed(0)} ${item['unit_name'] ?? ''}')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _toggleSelection(item),
                              icon: Icon(isSelected ? Icons.check_circle : Icons.add_circle, size: 16),
                              label: Text(isSelected ? 'SELECTED' : 'SELECT ITEM'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? Colors.green : AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
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
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF2C3E50)), overflow: TextOverflow.ellipsis, maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
              Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}