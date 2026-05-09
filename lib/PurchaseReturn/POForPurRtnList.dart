import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/services/app_services.dart';

class POReturnListScreen extends StatefulWidget {
  final String supplierKey;
  final List<Map<String, dynamic>> existingSelectedItems;

  const POReturnListScreen({
    Key? key,
    required this.supplierKey,
    this.existingSelectedItems = const [],
  }) : super(key: key);

  @override
  _POReturnListScreenState createState() => _POReturnListScreenState();
}

class _POReturnListScreenState extends State<POReturnListScreen> {
  List<dynamic> _poItems = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading = true;
  bool _isLoadingDetails = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Set<int> _selectedDocDtlIds = {};
  Map<int, Map<String, dynamic>> _selectedItemsMap = {};

  @override
  void initState() {
    super.initState();
    _selectedDocDtlIds.clear();
    _selectedItemsMap.clear();
    _fetchPOItems();
  }

  Future<void> _fetchPOItems() async {
    setState(() => _isLoading = true);

    try {
      // API returns Map<String, dynamic>
      final response = await ApiService.fetchPOForPurchaseReturn(widget.supplierKey);

      print('PO Items Response: $response');

      // Extract the data array from the response map
      if (response['status'] == 'success' && response['data'] != null) {
        List<dynamic> allItems = [];
        
        // Check if response['data'] is a List
        if (response['data'] is List) {
          allItems = response['data'];
        } else {
          print('Response data is not a List: ${response['data'].runtimeType}');
          allItems = [];
        }
        
        // Get IDs of already selected items from existing return
        Set<int> existingSelectedIds = {};
        for (var item in widget.existingSelectedItems) {
          final docDtlId = item['docDtlId'] as int?;
          if (docDtlId != null) {
            existingSelectedIds.add(docDtlId);
          }
        }
        
        print('Existing item IDs in return: $existingSelectedIds');
        
        // Filter out items that are already in the return
        List<dynamic> pendingItems = allItems.where((item) {
          final docDtlId = item['DocDtl_Id'] as int?;
          return !existingSelectedIds.contains(docDtlId);
        }).toList();
        
        print('Total items: ${allItems.length}');
        print('Already in return: ${existingSelectedIds.length}');
        print('Available to add: ${pendingItems.length}');
        
        setState(() {
          _poItems = pendingItems;
          _filteredItems = pendingItems;
        });
      } else {
        setState(() {
          _poItems = [];
          _filteredItems = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to fetch PO items'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error fetching PO items: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching PO items: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
Future<void> _fetchSizeDetailsAndAdd() async {
  if (_selectedDocDtlIds.isEmpty) return;

  setState(() => _isLoadingDetails = true);

  try {
    // Get IDs of already selected items from existing return
    Set<int> existingSelectedIds = {};
    for (var item in widget.existingSelectedItems) {
      final docDtlId = item['docDtlId'] as int?;
      if (docDtlId != null) {
        existingSelectedIds.add(docDtlId);
      }
    }
    
    // Only get NEWLY selected item IDs (not already in return)
    List<int> newDocDtlIds = _selectedDocDtlIds
        .where((id) => !existingSelectedIds.contains(id))
        .toList();
    
    print('All selected IDs: $_selectedDocDtlIds');
    print('Existing IDs in return: $existingSelectedIds');
    print('New Doc Dtl IDs to add: $newDocDtlIds');
    
    if (newDocDtlIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No new items to add'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => _isLoadingDetails = false);
      return;
    }
    
    // Prepare request body
    final Map<String, dynamic> requestBody = {
      'docDtlIds': newDocDtlIds,
    };
    
    // API returns Map<String, dynamic> with status, data
    final response = await ApiService.fetchSizeDetailsForPurchaseReturn(requestBody);

    print('Size Details Response: $response');

    // Extract the data array from the response map
    if (response['status'] == 'success' && response['data'] != null) {
      List<dynamic> sizeDetailsData = [];
      
      // Check if response['data'] is a List
      if (response['data'] is List) {
        sizeDetailsData = response['data'];
      } else {
        print('Response data is not a List: ${response['data'].runtimeType}');
        sizeDetailsData = [];
      }
      
      // Transform size details to match the expected format
      List<Map<String, dynamic>> newItems = [];
      
      for (var item in sizeDetailsData) {
        final int docDtlId = item['docDtlId'] as int;
        
        // Find the original PO item to get other details
        final originalItem = _poItems.firstWhere(
          (poItem) => poItem['DocDtl_Id'] == docDtlId,
          orElse: () => null,
        );
        
        if (originalItem == null) continue;
        
        double actQty = (originalItem['ActQty'] as num?)?.toDouble() ?? 0;
        double chlnQty = (originalItem['ChlnQty'] as num?)?.toDouble() ?? 0;
        
        // Get sizes from the response
        List<dynamic> sizes = item['sizes'] ?? [];
        
        // Calculate total quantity from sizes
        double totalQty = 0;
        for (var size in sizes) {
          totalQty += (size['Qty'] as num?)?.toDouble() ?? 0;
        }
        
        double rate = (originalItem['PurRate'] as num?)?.toDouble() ?? 0;
        double amount = totalQty * rate;
        
        // Transform sizes to include all required fields
        List<Map<String, dynamic>> transformedSizes = [];
        for (var size in sizes) {
          transformedSizes.add({
            'Size_Name': size['Size_Name']?.toString() ?? '',
            'Qty': (size['Qty'] as num?)?.toDouble() ?? 0,
            'ClQty': (size['ClQty'] as num?)?.toDouble() ?? 0,
            'PurRate': (size['PurRate'] as num?)?.toDouble() ?? 0,
            'NettRate': (size['NettRate'] as num?)?.toDouble() ?? 0,
            'DocDtlSz_Id': size['DocDtlSz_Id'] as int? ?? 0,
            'DocDtl_Id': size['DocDtl_Id'] as int? ?? docDtlId,
          });
        }
        
        newItems.add({
          'docDtlId': docDtlId,
          'PONo': originalItem['PONo'] ?? '',
          'GRNNo': originalItem['GRNNo'] ?? '',
          'Product': originalItem['Item_Name'] ?? 'N/A',
          'Style_Code': originalItem['Style_Code'] ?? 'N/A',
          'Shade_Name': originalItem['Shade_Name'] ?? 'N/A',
          'Brand_Name': originalItem['Brand_Name'] ?? 'N/A',
          'Type_Name': originalItem['Type_Name'] ?? 'N/A',
          'Unit_Name': originalItem['Unit_Name'] ?? 'PCS',
          'ActQty': actQty,
          'ChlnQty': chlnQty,
          'Rate': rate,
          'Qty': totalQty > 0 ? totalQty : actQty,
          'Disc': 0.0,
          'Amount': amount,
          'NetAmt': amount,
          'sizes': transformedSizes,
        });
      }
      
      print('Returning ${newItems.length} new items');
      
      // Return ONLY the NEW items to the previous screen
      Navigator.pop(context, newItems);
      
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Failed to fetch size details'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    print('Error fetching size details: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error fetching size details: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _isLoadingDetails = false);
  }
}
  void _filterItems(String searchText) {
    if (searchText.isEmpty) {
      setState(() {
        _filteredItems = List.from(_poItems);
      });
      return;
    }

    final lowerSearchText = searchText.toLowerCase();

    setState(() {
      _filteredItems = _poItems.where((item) {
        final poNo = item['PONo']?.toString().toLowerCase() ?? '';
        if (poNo.contains(lowerSearchText)) return true;

        final grnNo = item['GRNNo']?.toString().toLowerCase() ?? '';
        if (grnNo.contains(lowerSearchText)) return true;

        final itemName = item['Item_Name']?.toString().toLowerCase() ?? '';
        if (itemName.contains(lowerSearchText)) return true;

        return false;
      }).toList();
    });
  }

  void _toggleSearch() {
    setState(() {
      if (_isSearching) {
        _isSearching = false;
        _searchController.clear();
        _filteredItems = List.from(_poItems);
      } else {
        _isSearching = true;
      }
    });
  }

  AppBar _buildNormalAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: _onCancel,
      ),
      title: const Text(
        'Purchase Orders for Return',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: _toggleSearch,
        ),
      ],
    );
  }

  AppBar _buildSearchAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: _toggleSearch,
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: const InputDecoration(
          hintText: 'Search by PO No, GRN No, Item...',
          hintStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        onChanged: _filterItems,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: () {
            _searchController.clear();
            _filterItems('');
          },
        ),
      ],
    );
  }

  void _toggleSelection(dynamic item) {
    final int docDtlId = item['DocDtl_Id'] as int;

    setState(() {
      if (_selectedDocDtlIds.contains(docDtlId)) {
        _selectedDocDtlIds.remove(docDtlId);
        _selectedItemsMap.remove(docDtlId);
      } else {
        _selectedDocDtlIds.add(docDtlId);
        _selectedItemsMap[docDtlId] = {
          'DocDtl_Id': docDtlId,
          'PONo': item['PONo'],
          'GRNNo': item['GRNNo'],
          'Item_Name': item['Item_Name'],
          'Style_Code': item['Style_Code'],
          'Shade_Name': item['Shade_Name'],
          'Brand_Name': item['Brand_Name'],
          'Type_Name': item['Type_Name'],
          'Unit_Name': item['Unit_Name'],
          'ActQty': item['ActQty'],
          'ChlnQty': item['ChlnQty'],
          'PurRate': item['PurRate'],
        };
      }
    });
  }

  void _onCancel() {
    Navigator.pop(context, null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _isSearching ? _buildSearchAppBar() : _buildNormalAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _poItems.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No purchase orders found for return',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : _filteredItems.isEmpty && _searchController.text.isNotEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No matching items found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final int docDtlId = item['DocDtl_Id'] as int;
                        final bool isSelected = _selectedDocDtlIds.contains(docDtlId);
                        return _buildItemCard(item, isSelected, docDtlId);
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
                    icon: const Icon(Icons.close, size: 18, color: Colors.white),
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
                    onPressed: _selectedDocDtlIds.isEmpty || _isLoadingDetails
                        ? null
                        : _fetchSizeDetailsAndAdd,
                    icon: _isLoadingDetails
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.add_shopping_cart,
                            size: 18,
                            color: Colors.white,
                          ),
                    label: Text(
                      _isLoadingDetails
                          ? 'LOADING...'
                          : 'ADD (${_selectedDocDtlIds.length})',
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

  Widget _buildItemCard(dynamic item, bool isSelected, int docDtlId) {
    final statusColor = isSelected ? AppColors.primaryColor : Colors.grey;
    final statusBgColor = isSelected
        ? AppColors.primaryColor.withOpacity(0.1)
        : Colors.grey.shade50;

    final String poNo = item['PONo']?.toString() ?? 'N/A';
    final String grnNo = item['GRNNo']?.toString() ?? 'N/A';
    final String itemName = item['Item_Name']?.toString() ?? 'N/A';
    final String styleCode = item['Style_Code']?.toString() ?? 'N/A';
    final String shadeName = item['Shade_Name']?.toString() ?? 'N/A';
    final double actQty = (item['ActQty'] as num?)?.toDouble() ?? 0;
    final double chlnQty = (item['ChlnQty'] as num?)?.toDouble() ?? 0;
    final double purRate = (item['PurRate'] as num?)?.toDouble() ?? 0;
    final String unit = item['Unit_Name']?.toString() ?? 'PCS';

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
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            childrenPadding: EdgeInsets.zero,
            leading: GestureDetector(
              onTap: () => _toggleSelection(item),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: statusColor,
                  size: 20,
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PO: $poNo',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'GRN: $grnNo',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Shade: $shadeName | Qty: $actQty $unit',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '₹${(actQty * purRate).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.green.shade700 : Colors.grey.shade600,
                ),
              ),
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.code,
                            label: 'Style Code',
                            value: styleCode,
                          ),
                        ),
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.palette,
                            label: 'Shade',
                            value: shadeName,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.category,
                            label: 'Type',
                            value: item['Type_Name']?.toString() ?? 'N/A',
                          ),
                        ),
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.branding_watermark,
                            label: 'Brand',
                            value: item['Brand_Name']?.toString() ?? 'N/A',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.inventory,
                            label: 'Act Qty',
                            value: '$actQty $unit',
                          ),
                        ),
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.checklist,
                            label: 'Chln Qty',
                            value: '$chlnQty $unit',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.currency_rupee,
                            label: 'Purchase Rate',
                            value: '₹${purRate.toStringAsFixed(2)}',
                            valueColor: Colors.green.shade700,
                          ),
                        ),
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.calculate,
                            label: 'Total Value',
                            value: '₹${(actQty * purRate).toStringAsFixed(2)}',
                            valueColor: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Selected for purchase return',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty || value == 'N/A' ? 'N/A' : value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? const Color(0xFF2C3E50),
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