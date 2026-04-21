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

  void _toggleSelection(dynamic item) {
    final String uniqueId = '${item['Doc_Id']}_${item['docDtl_Id']}';
    setState(() {
      if (_selectedOrderIds.contains(uniqueId)) {
        _selectedOrderIds.remove(uniqueId);
        _selectedOrdersMap.remove(uniqueId);
      } else {
        final double balQty = (item['BalQty'] as num?)?.toDouble() ?? 0;
        final double rate =
            double.tryParse(item['rate']?.toString() ?? '0') ?? 0;

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
          'sizes': [],
        };
        print(
          'Added to map - docId: ${item['Doc_Id']}, docDtlId: ${item['docDtl_Id']}',
        );
      }
    });
  }

Future<void> _addSelectedItems() async {
  // Get only the items that were newly selected (not already existing)
  final List<Map<String, dynamic>> newSelectedItems = [];
  
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
    
    if (!alreadyExists) {
      newSelectedItems.add(item);
    }
  }

  if (newSelectedItems.isEmpty) {
    // Just close the dialog if no new items
    if (mounted) {
      Navigator.pop(context);
      Navigator.pop(context, []); // Return empty list
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

        for (var sizeQty in sizeQtyList) {
          int balQty = (sizeQty['balQty'] as num?)?.toInt() ?? 0;
          
          updatedSizes.add({
            'size': sizeQty['Size_Name'] ?? 'N/A',
            'qty': balQty,
            'ordQty': (sizeQty['qty'] as num?)?.toInt() ?? 0,
            'stock': (sizeQty['stockQty'] as num?)?.toInt() ?? 0,
            'rate': (sizeQty['rate'] as num?)?.toDouble() ?? newSelectedItems[i]['rate'],
            'mrp': (sizeQty['mrp'] as num?)?.toDouble() ?? newSelectedItems[i]['mrp'],
            'netRate': (sizeQty['nettRate'] as num?)?.toDouble() ?? newSelectedItems[i]['rate'],
            'styleSize_Id': sizeQty['styleSize_Id'] ?? 0,
            'docDtlSzId': sizeQty['docDtlSzId'] ?? 0,
            'stkId': sizeQty['stkId'] ?? 0,
            'balQty': balQty,
          });
        }
        
        newSelectedItems[i]['sizes'] = updatedSizes;
        
        // Calculate total quantity
        double totalQty = 0;
        for (var size in updatedSizes) {
          totalQty += size['qty'];
        }
        newSelectedItems[i]['selectedQty'] = totalQty;
        newSelectedItems[i]['itemAmt'] = totalQty * (newSelectedItems[i]['rate'] as double);
      }
    }

    if (mounted) {
      Navigator.pop(context);
      print('Returning NEW selected items:');
      for (var item in newSelectedItems) {
        print('docId: ${item['docId']}, docDtlId: ${item['docDtlId']}, itemName: ${item['itemName']}, selectedQty: ${item['selectedQty']}');
      }
      Navigator.pop(context, newSelectedItems); // Return ONLY new items
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
                  return _buildOrderCard(item, isSelected);
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

  Widget _buildOrderCard(dynamic item, bool isSelected) {
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
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
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
                onTap: () => _toggleSelection(item),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: statusColor,
                    size: 22,
                  ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
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
                            Icon(
                              Icons.inventory,
                              size: 12,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              item['item_name'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              docDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
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
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                Expanded(
                                  child: _buildDetailRow(
                                    Icons.code,
                                    'Design',
                                    styleCode,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildDetailRow(
                                    Icons.color_lens,
                                    'Shade',
                                    shadeName,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailRow(
                                    Icons.branding_watermark,
                                    'Brand',
                                    brandName,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildDetailRow(
                                    Icons.category,
                                    'Type',
                                    typeName,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailRow(
                                    Icons.calendar_today,
                                    'Date',
                                    docDate,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildDetailRow(
                                    Icons.local_shipping,
                                    'Delivery',
                                    dlvDate,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailRow(
                                    Icons.inventory,
                                    'Unit',
                                    unitName,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildDetailRow(
                                    Icons.sell,
                                    'Free Qty',
                                    '${freeQty.toStringAsFixed(0)} $unitName',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildMetricRow(
                                Icons.currency_rupee,
                                'MRP',
                                '₹${mrp.toStringAsFixed(2)}',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.grey.shade300,
                            ),
                            Expanded(
                              child: _buildMetricRow(
                                Icons.price_change,
                                'Rate',
                                '₹${rate.toStringAsFixed(2)}',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.grey.shade300,
                            ),
                            Expanded(
                              child: _buildMetricRow(
                                Icons.attach_money,
                                'Amount',
                                '₹${amount.toStringAsFixed(2)}',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildMetricRow(
                                Icons.inventory_2,
                                'Balance Qty',
                                '${balQty.toStringAsFixed(0)} $unitName',
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C3E50),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
