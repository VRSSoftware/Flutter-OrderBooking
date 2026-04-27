import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/services/app_services.dart';

class DespatchListScreen extends StatefulWidget {
  final String custKey;
  final List<Map<String, dynamic>> existingSelectedDespatches;
  final Function(List<Map<String, dynamic>>) onDespatchesSelected;

  const DespatchListScreen({
    Key? key,
    required this.custKey,
    this.existingSelectedDespatches = const [],
    required this.onDespatchesSelected,
  }) : super(key: key);

  @override
  _DespatchListScreenState createState() => _DespatchListScreenState();
}

class _DespatchListScreenState extends State<DespatchListScreen> {
  List<dynamic> _despatches = [];
  List<dynamic> _filteredDespatches = [];
  bool _isLoading = true;
  bool _isLoadingDetails = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Set<String> _selectedDespatchIds = {};
  Map<String, Map<String, dynamic>> _selectedDespatchesMap = {};

@override
void initState() {
  super.initState();
  // DON'T add existing despatches to selected IDs
  // Only use them to know what's already in the invoice
  // _selectedDespatchIds should start empty for NEW selections
  _selectedDespatchIds.clear();
  _selectedDespatchesMap.clear();
  
  _fetchDespatches();
}


 Future<void> _fetchDespatches() async {
  setState(() => _isLoading = true);

  try {
    final response = await ApiService.fetchPendingDespatches(
      custKey: widget.custKey,
      fcYrId: UserSession.userFcYr ?? '',
      coBrId: UserSession.coBrId ?? '',
    );

    print('Response: $response');

    if (response['status'] == 'success' && response['data'] != null && response['data'] is List) {
      List<dynamic> allDespatches = response['data'];
      
      // Get IDs of already selected despatches from existing invoice
      Set<String> existingSelectedIds = {};
      for (var item in widget.existingSelectedDespatches) {
        final docId = item['Doc_Id']?.toString() ?? item['packDocId']?.toString();
        if (docId != null) {
          existingSelectedIds.add(docId);
        }
      }
      
      print('Existing despatch IDs in invoice: $existingSelectedIds');
      
      // Filter out despatches that are already in the invoice
      List<dynamic> pendingDespatches = allDespatches.where((despatch) {
        final despatchId = despatch['Doc_Id']?.toString();
        return !existingSelectedIds.contains(despatchId);
      }).toList();
      
      print('Total despatches: ${allDespatches.length}');
      print('Already in invoice: ${existingSelectedIds.length}');
      print('Available to add: ${pendingDespatches.length}');
      
      setState(() {
        _despatches = pendingDespatches;
        _filteredDespatches = pendingDespatches;
      });
    } else {
      setState(() {
        _despatches = [];
        _filteredDespatches = [];
      });
    }
  } catch (e) {
    print('Error fetching despatches: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error fetching despatches: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}


Future<void> _fetchPackingDetailsAndAdd() async {
  if (_selectedDespatchIds.isEmpty) return;

  setState(() => _isLoadingDetails = true);

  try {
    // Get IDs of already selected despatches from existing invoice
    Set<String> existingSelectedIds = {};
    for (var item in widget.existingSelectedDespatches) {
      final docId = item['Doc_Id']?.toString() ?? item['packDocId']?.toString();
      if (docId != null) {
        existingSelectedIds.add(docId);
      }
    }
    
    // Only get NEWLY selected despatch IDs (not already in invoice)
    List<int> newDocIds = _selectedDespatchIds
        .where((id) => !existingSelectedIds.contains(id))
        .map((id) => int.parse(id))
        .toList();
    
    print('All selected IDs: $_selectedDespatchIds');
    print('Existing IDs in invoice: $existingSelectedIds');
    print('New Doc IDs to add: $newDocIds');
    
    if (newDocIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No new despatches to add'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => _isLoadingDetails = false);
      return;
    }
    
    final response = await ApiService.fetchPackingDetailsForBill(docIds: newDocIds);

    print('Packing Details Response: $response');

    if (response['status'] == 'success' && response['data'] != null && response['data'] is List) {
      final List<Map<String, dynamic>> packingDetails = 
          List<Map<String, dynamic>>.from(response['data']);
      
      // Transform packing details to match the expected format
      List<Map<String, dynamic>> newItems = [];
      
      for (var item in packingDetails) {
        double qty = (item['Qty'] as num?)?.toDouble() ?? 0;
        double rate = (item['Rate'] as num?)?.toDouble() ?? 0;
        double amount = (item['Amount'] as num?)?.toDouble() ?? (qty * rate);
        double discAmt = (item['DiscAmt'] as num?)?.toDouble() ?? 0;
        double netAmt = (item['NetAmt'] as num?)?.toDouble() ?? amount;
        double avgRt = (item['Avrg_RT'] as num?)?.toDouble() ?? rate;
        
        newItems.add({
          'Doc_Id': item['Doc_Id'],
          'packDocId': item['Doc_Id'],
          'DocDtl_Id': item['DocDtl_Id'],
          'Doc_No': item['Doc_No'],
          'Product': item['Item_Name'] ?? 'N/A',
          'Design': item['Style_Code'] ?? 'N/A',
          'Type': item['Type_Name'] ?? 'N/A',
          'Shade': item['Shade_Name'] ?? 'N/A',
          'Brand': item['Brand_Name'] ?? 'N/A',
          'Rate': rate,
          'MRP': (item['MRP'] as num?)?.toDouble() ?? 0,
          'Qty': qty,
          'Avg Rt': avgRt,
          'Item Amt': amount,
          'Disc': discAmt,
          'Disc (%)': (item['billDiscPerc'] as num?)?.toDouble() ?? 0,
          'Amount': netAmt,
          'Tax Amt': (item['Tax_Amt'] as num?)?.toDouble() ?? 0,
          'TaxPerc': (item['TaxPerc'] as num?)?.toDouble() ?? 0,
          'Tax1_Amt': (item['Tax1_Amt'] as num?)?.toDouble() ?? 0,
          'Tax2_Amt': (item['Tax2_Amt'] as num?)?.toDouble() ?? 0,
          'Tax3_Amt': (item['Tax3_Amt'] as num?)?.toDouble() ?? 0,
          'sizes': item['sizes'] ?? [],
          'Unit_Name': item['Unit_Name'] ?? 'PCS',
        });
      }
      
      print('Returning ${newItems.length} new items');
      
      // Return ONLY the NEW items to the previous screen
      Navigator.pop(context, newItems);
      
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch packing details'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    print('Error fetching packing details: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error fetching packing details: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _isLoadingDetails = false);
  }
}
 
  void _filterDespatches(String searchText) {
    if (searchText.isEmpty) {
      setState(() {
        _filteredDespatches = List.from(_despatches);
      });
      return;
    }

    final lowerSearchText = searchText.toLowerCase();

    setState(() {
      _filteredDespatches = _despatches.where((despatch) {
        final docNo = despatch['Doc_No']?.toString().toLowerCase() ?? '';
        if (docNo.contains(lowerSearchText)) return true;

        final dlvPlace = despatch['DlvPlace']?.toString().toLowerCase() ?? '';
        if (dlvPlace.contains(lowerSearchText)) return true;

        final transporter = despatch['transporter']?.toString().toLowerCase() ?? '';
        if (transporter.contains(lowerSearchText)) return true;

        final lrNo = despatch['LrNo']?.toString().toLowerCase() ?? '';
        if (lrNo.contains(lowerSearchText)) return true;

        return false;
      }).toList();
    });
  }

  void _toggleSearch() {
    setState(() {
      if (_isSearching) {
        _isSearching = false;
        _searchController.clear();
        _filteredDespatches = List.from(_despatches);
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
        'Pending Despatches',
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
          hintText: 'Search by Doc No, Dlv Place, Transporter...',
          hintStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        onChanged: _filterDespatches,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: () {
            _searchController.clear();
            _filterDespatches('');
          },
        ),
      ],
    );
  }

  void _toggleSelection(dynamic item) {
    final String uniqueId = item['Doc_Id'].toString();

    setState(() {
      if (_selectedDespatchIds.contains(uniqueId)) {
        _selectedDespatchIds.remove(uniqueId);
        _selectedDespatchesMap.remove(uniqueId);
      } else {
        _selectedDespatchIds.add(uniqueId);
        _selectedDespatchesMap[uniqueId] = {
          'Doc_Id': item['Doc_Id'],
          'Doc_No': item['Doc_No'],
          'Doc_Dt': item['Doc_Dt'],
          'TotQty': item['TotQty'],
          'Net_Amt': item['Net_Amt'],
          'DlvPlace': item['DlvPlace'],
          'Trsp_Key': item['Trsp_Key'] ?? '',
          'transporter': item['transporter'] ?? '',
          'LrNo': item['LrNo'] ?? '',
          'LrDt': item['LrDt'],
          'Gross_Wt': item['Gross_Wt'] ?? 0,
          'Packets': item['Packets'] ?? '',
          'Carton_no': item['Carton_no'] ?? '',
        };
      }
    });
  }

void _onCancel() {
  Navigator.pop(context, null); // Return null when cancelled
}

  String formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _isSearching ? _buildSearchAppBar() : _buildNormalAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _despatches.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No pending despatches found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : _filteredDespatches.isEmpty && _searchController.text.isNotEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No matching despatches found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _filteredDespatches.length,
                      itemBuilder: (context, index) {
                        final item = _filteredDespatches[index];
                        final String uniqueId = item['Doc_Id'].toString();
                        final bool isSelected = _selectedDespatchIds.contains(uniqueId);
                        return _buildDespatchCard(item, isSelected, uniqueId);
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
                    onPressed: _selectedDespatchIds.isEmpty || _isLoadingDetails
                        ? null 
                        : _fetchPackingDetailsAndAdd,
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
                          : 'ADD PO(${_selectedDespatchIds.length})',
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

  Widget _buildDespatchCard(dynamic item, bool isSelected, String uniqueId) {
    final statusColor = isSelected ? AppColors.primaryColor : Colors.grey;
    final statusBgColor = isSelected
        ? AppColors.primaryColor.withOpacity(0.1)
        : Colors.grey.shade50;

    final String docNo = item['Doc_No']?.toString() ?? 'N/A';
    final String docDate = formatDate(item['Doc_Dt']);
    final double totQty = (item['TotQty'] as num?)?.toDouble() ?? 0;
    final double netAmt = (item['Net_Amt'] as num?)?.toDouble() ?? 0;
    final String dlvPlace = item['DlvPlace']?.toString() ?? 'N/A';
    final String transporter = item['transporter']?.toString() ?? 'N/A';
    final String lrNo = item['LrNo']?.toString() ?? 'N/A';
    final String packets = item['Packets']?.toString() ?? 'N/A';
    final String cartonNo = item['Carton_no']?.toString() ?? 'N/A';
    final double grossWt = (item['Gross_Wt'] as num?)?.toDouble() ?? 0;

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
                  docNo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Date: $docDate | Place: $dlvPlace',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
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
                '₹${netAmt.toStringAsFixed(2)}',
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
                            icon: Icons.location_on,
                            label: 'Dlv Place',
                            value: dlvPlace,
                          ),
                        ),
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.local_shipping,
                            label: 'Transporter',
                            value: transporter,
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
                            label: 'Total Qty',
                            value: '${totQty.toStringAsFixed(0)} PCS',
                          ),
                        ),
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.currency_rupee,
                            label: 'Net Amount',
                            value: '₹${netAmt.toStringAsFixed(2)}',
                            valueColor: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.qr_code,
                            label: 'LR No',
                            value: lrNo,
                          ),
                        ),
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.category,
                            label: 'Packets',
                            value: packets,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.inventory_2,
                            label: 'Carton No',
                            value: cartonNo,
                          ),
                        ),
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.monitor_weight,
                            label: 'Gross Wt',
                            value: '${grossWt.toStringAsFixed(2)} KG',
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
                                'Selected for invoice',
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