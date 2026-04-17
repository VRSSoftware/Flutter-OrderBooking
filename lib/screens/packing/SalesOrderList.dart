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
      final String docId = item['docId'].toString();
      _selectedOrderIds.add(docId);
      _selectedOrdersMap[docId] = item;
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

  void _toggleSelection(dynamic item) {
    final String docId = item['Doc_Id'].toString();
    setState(() {
      if (_selectedOrderIds.contains(docId)) {
        _selectedOrderIds.remove(docId);
        _selectedOrdersMap.remove(docId);
      } else {
        _selectedOrderIds.add(docId);
        _selectedOrdersMap[docId] = {
          'docId': item['Doc_Id'],
          'docNo': item['Doc_No'],
          'docDt': item['Doc_Dt']?.toString().split('T')[0] ?? '',
          'dlvDate': item['DlvDate']?.toString().split('T')[0] ?? '',
          'itemName': item['item_name'] ?? 'N/A',
          'brandName': item['Brand_Name'] ?? '',
          'styleCode': item['Style_Code'] ?? item['Style_Key'] ?? 'N/A',
          'shadeName': item['shade_name'] ?? '',
          'typeName': item['Type_Name'] ?? '',
          'unitName': item['unit_name'] ?? 'PCS',
          'balQty': (item['BalQty'] ?? 0).toDouble(),
          'rate': double.tryParse(item['rate']?.toString() ?? '0') ?? 0,
          'mrp': double.tryParse(item['mrp']?.toString() ?? '0') ?? 0,
          'selectedQty': (item['BalQty'] ?? 0).toDouble(),
          'discPercent': 0.0,
          'discAmt': 0.0,
          'amtRemark': '',
          'itemAmt': (item['BalQty'] ?? 0) * (double.tryParse(item['rate']?.toString() ?? '0') ?? 0),
          'sizes': [
            {'size': 'S', 'qty': 0, 'ordQty': ((item['BalQty'] ?? 0) * 0.25).toInt(), 'stock': 50, 'rate': double.tryParse(item['rate']?.toString() ?? '0') ?? 0, 'mrp': double.tryParse(item['mrp']?.toString() ?? '0') ?? 0, 'netRate': double.tryParse(item['rate']?.toString() ?? '0') ?? 0},
            {'size': 'M', 'qty': 0, 'ordQty': ((item['BalQty'] ?? 0) * 0.35).toInt(), 'stock': 45, 'rate': double.tryParse(item['rate']?.toString() ?? '0') ?? 0, 'mrp': double.tryParse(item['mrp']?.toString() ?? '0') ?? 0, 'netRate': double.tryParse(item['rate']?.toString() ?? '0') ?? 0},
            {'size': 'L', 'qty': 0, 'ordQty': ((item['BalQty'] ?? 0) * 0.25).toInt(), 'stock': 30, 'rate': double.tryParse(item['rate']?.toString() ?? '0') ?? 0, 'mrp': double.tryParse(item['mrp']?.toString() ?? '0') ?? 0, 'netRate': double.tryParse(item['rate']?.toString() ?? '0') ?? 0},
            {'size': 'XL', 'qty': 0, 'ordQty': ((item['BalQty'] ?? 0) * 0.15).toInt(), 'stock': 20, 'rate': double.tryParse(item['rate']?.toString() ?? '0') ?? 0, 'mrp': double.tryParse(item['mrp']?.toString() ?? '0') ?? 0, 'netRate': double.tryParse(item['rate']?.toString() ?? '0') ?? 0},
          ],
        };
      }
    });
  }

  Future<void> _addSelectedItems() async {
    final List<Map<String, dynamic>> selectedItems = _selectedOrdersMap.values.toList();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final List<Map<String, dynamic>> itemsToAdd = selectedItems.map((item) {
        return {
          "Doc_Id": item['docId'],
          "Shade_Key": item['shadeName'],
          "Style_Key": item['styleCode'],
          "amt": item['itemAmt'],
          "rate": item['rate'],
          "selectedQty": item['selectedQty'],
          "discPercent": item['discPercent'],
          "discAmt": item['discAmt'],
          "amtRemark": item['amtRemark'],
        };
      }).toList();

      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/packing/addToPackingList'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "custKey": widget.custKey,
          "items": itemsToAdd,
        }),
      );

      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        for (int i = 0; i < selectedItems.length; i++) {
          if (responseData['data'] != null && i < responseData['data'].length) {
            final respItem = responseData['data'][i];
            selectedItems[i]['rate'] = double.tryParse(respItem['rate']?.toString() ?? selectedItems[i]['rate'].toString()) ?? selectedItems[i]['rate'];
            selectedItems[i]['mrp'] = double.tryParse(respItem['mrp']?.toString() ?? selectedItems[i]['mrp'].toString()) ?? selectedItems[i]['mrp'];
            selectedItems[i]['itemAmt'] = selectedItems[i]['selectedQty'] * selectedItems[i]['rate'];
          }
        }
        
        if (mounted) Navigator.pop(context, selectedItems);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add items'), backgroundColor: Colors.red),
          );
        }
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
                      Text('No pending orders found', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final item = _orders[index];
                    final String docId = item['Doc_Id'].toString();
                    final bool isSelected = _selectedOrderIds.contains(docId);
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
                  isSelected ? Icons.check_circle_outline : Icons.schedule,
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          isSelected ? 'SELECTED' : 'PENDING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
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
                      // Row 1: Style Code & Shade Name
                      Row(
                        children: [
                          Expanded(child: _buildDetailChip(Icons.code, 'Style Code', item['Style_Code'] ?? item['Style_Key'] ?? 'N/A')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildDetailChip(Icons.color_lens, 'Shade', item['shade_name'] ?? 'N/A')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Row 2: Brand & Type
                      Row(
                        children: [
                          Expanded(child: _buildDetailChip(Icons.branding_watermark, 'Brand', item['Brand_Name']?.isNotEmpty == true ? item['Brand_Name'] : 'N/A')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildDetailChip(Icons.category, 'Type', item['Type_Name']?.isNotEmpty == true ? item['Type_Name'] : 'N/A')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Row 3: Delivery Date
                      Row(
                        children: [
                          Expanded(child: _buildDetailChip(Icons.local_shipping, 'Delivery Date', item['DlvDate']?.toString().split('T')[0] ?? 'N/A')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildDetailChip(Icons.inventory, 'Unit', item['unit_name'] ?? 'PCS')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Metrics Section
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _buildMetricItem(Icons.currency_rupee, 'MRP', '₹${double.tryParse(item['mrp']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}')),
                            Container(width: 1, height: 30, color: Colors.grey.shade300),
                            Expanded(child: _buildMetricItem(Icons.price_change, 'Rate', '₹${double.tryParse(item['rate']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}')),
                            Container(width: 1, height: 30, color: Colors.grey.shade300),
                            Expanded(child: _buildMetricItem(Icons.inventory_2, 'Balance Qty', '${item['BalQty'] ?? 0} ${item['unit_name'] ?? ''}')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Select Button
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