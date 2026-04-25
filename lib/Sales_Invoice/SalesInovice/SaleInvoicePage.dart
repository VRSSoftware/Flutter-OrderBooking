import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vrs_erp/Sales_Invoice/InvoiceDetailsPage.dart';
import 'package:vrs_erp/Sales_Invoice/SalesInovice/AddItemPage.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/models/keyName.dart';

class SaleInvoicePage extends StatefulWidget {
  final String? invoiceId;
  final Map<String, dynamic>? invoiceData;

  const SaleInvoicePage({Key? key, this.invoiceId, this.invoiceData})
    : super(key: key);

  @override
  _SaleInvoicePageState createState() => _SaleInvoicePageState();
}

class _SaleInvoicePageState extends State<SaleInvoicePage> {
  // ==================== VARIABLES ====================
  bool _isUpdateMode = false;

  // Basic Details Controllers
  final TextEditingController seriesController = TextEditingController();
  final TextEditingController lastCdController = TextEditingController();
  final TextEditingController docNoController = TextEditingController();
  final TextEditingController docDtController = TextEditingController();

  // Dropdown values
  String? selectedPartyKey;
  String? selectedPartyName;
  String? selectedSalesLedgerKey;
  String? selectedSalesLedgerName;
  String? selectedStationKey;
  String? selectedStationName;

  // Invoice Details Data
  Map<String, dynamic> invoiceDetails = {};

  // Dropdown data lists from API
  List<KeyName> salesLedgerList = [];
  List<KeyName> partyList = [];
  List<KeyName> stationList = [];

  // List to store added items
  List<Map<String, dynamic>> addedItems = [];

  // Totals
  double grossAmt = 0.0;
  double disc = 0.0;
  double taxAmt = 0.0;
  double otherChrgs = 0.0;
  double netAmt = 0.0;
  bool rdOff = false;
  bool _isSaving = false;
  bool isLoading = true;
  final _formKey = GlobalKey<FormState>();

  // API Session
  final String coBrId = UserSession.coBrId ?? '';
  final String fcYrId = UserSession.userFcYr ?? '';
  final String userId = UserSession.userName ?? '';

  @override
  void initState() {
    super.initState();
    _isUpdateMode = widget.invoiceId != null && widget.invoiceId!.isNotEmpty;
    docDtController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _initializeData();
  }

  @override
  void dispose() {
    seriesController.dispose();
    lastCdController.dispose();
    docNoController.dispose();
    docDtController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);

    try {
      await Future.wait([
        _fetchDocNumbers(),
        _fetchLedgers('L'),
        _fetchLedgers('W'),
        _fetchStations(),
      ]);

      if (_isUpdateMode) {
        await _loadInvoiceData(widget.invoiceId!);
      }
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchDocNumbers() async {
    try {
      final response = await ApiService.getDocNumbers(
        docType: 'SINV',
        coBrId: coBrId,
        fcYrId: fcYrId,
      );

      if (response['status'] == 'success') {
        setState(() {
          seriesController.text = response['series']?.toString() ?? 'INV';
          lastCdController.text = response['lastCd']?.toString() ?? '';
          docNoController.text = response['docNo']?.toString() ?? '1';
        });
      }
    } catch (e) {
      seriesController.text = 'INV';
      lastCdController.text = 'INV-001';
      docNoController.text = '1';
    }
  }

  Future<void> _fetchLedgers(String ledCat) async {
    try {
      final response = await ApiService.fetchLedgers(
        ledCat: ledCat,
        coBrId: coBrId,
      );

      if (response['statusCode'] == 200 && response['result'] != null) {
        final List<KeyName> result = response['result'];

        setState(() {
          if (ledCat == 'L') {
            salesLedgerList = result;
          } else if (ledCat == 'W') {
            partyList = result;
          }
        });
      }
    } catch (e) {
      print('Error fetching ledgers for $ledCat: $e');
    }
  }

  Future<void> _fetchStations() async {
    try {
      final response = await ApiService.fetchStations(coBrId: coBrId);
      if (response['statusCode'] == 200 && response['result'] != null) {
        setState(() {
          stationList = response['result'];
        });
      }
    } catch (e) {
      print('Error fetching stations: $e');
    }
  }

  Future<void> _loadInvoiceData(String invoiceId) async {
    try {
      final response = await ApiService.fetchInvoiceById(
        docId: invoiceId,
        coBrId: coBrId,
      );

      if (response['status'] == 'success') {
        setState(() {
          seriesController.text =
              response['series']?.toString() ?? seriesController.text;
          lastCdController.text =
              response['lastCd']?.toString() ?? lastCdController.text;
          docNoController.text =
              response['docNo']?.toString() ?? docNoController.text;
          docDtController.text =
              response['docDt']?.toString() ??
              DateFormat('yyyy-MM-dd').format(DateTime.now());

          selectedSalesLedgerKey = response['salesLedgerKey'];
          selectedSalesLedgerName = response['salesLedger'];
          selectedPartyKey = response['partyKey'];
          selectedPartyName = response['party'];
          selectedStationKey = response['stationKey'];
          selectedStationName = response['station'];

          if (response['items'] != null && response['items'] is List) {
            addedItems = List<Map<String, dynamic>>.from(response['items']);
          }

          otherChrgs =
              double.tryParse(response['otherChrgs']?.toString() ?? '0') ?? 0.0;
          rdOff = response['rdOff'] ?? false;
          
          // Load invoice details if exists
          if (response['invoiceDetails'] != null) {
            invoiceDetails = response['invoiceDetails'];
          }
          
          _calculateTotals();
        });
      }
    } catch (e) {
      print('Error loading invoice data: $e');
    }
  }

  void _calculateTotals() {
    grossAmt = addedItems.fold(
      0.0,
      (sum, item) => sum + (item['Amount'] ?? 0.0),
    );
    disc = addedItems.fold(0.0, (sum, item) => sum + (item['Disc'] ?? 0.0));
    taxAmt = 0.0;
    double calculatedNet = grossAmt - disc + taxAmt + otherChrgs;
    setState(() {
      netAmt = rdOff ? calculatedNet.roundToDouble() : calculatedNet;
    });
  }

  void _openAddItemPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddItemPage()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        addedItems.add(result);
        _calculateTotals();
      });
    }
  }

  void _handlePartySelection(String? val, String? key) async {
    if (key == null) return;

    String? extractedStation;
    if (val != null && val.contains('-->')) {
      final parts = val.split('-->');
      extractedStation = parts.last.trim();
    }

    setState(() {
      selectedPartyName = val;
      selectedPartyKey = key;

      if (extractedStation != null && extractedStation.isNotEmpty) {
        selectedStationName = extractedStation;
        for (var station in stationList) {
          if (station.name == extractedStation) {
            selectedStationKey = station.key;
            break;
          }
        }
      }
    });
  }

  void _openInvoiceDetails() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailsPage(
          partyKey: selectedPartyKey,
          partyName: selectedPartyName,
          partyStation: selectedStationName,
          selectedDespatches: [], // No despatches for regular invoice
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        invoiceDetails = result;
      });
      print('Invoice Details saved: $result');
    }
  }

  void _showValidationDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _saveInvoice() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    if (addedItems.isEmpty) {
      _showValidationDialog(
        'Validation Error',
        'Please add at least one item to save invoice.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> invoiceData = {
        'series': seriesController.text,
        'lastCd': lastCdController.text,
        'docNo': docNoController.text,
        'docDt': docDtController.text,
        'salesLedgerKey': selectedSalesLedgerKey,
        'salesLedger': selectedSalesLedgerName,
        'partyKey': selectedPartyKey,
        'party': selectedPartyName,
        'stationKey': selectedStationKey,
        'station': selectedStationName,
        'items': addedItems,
        'invoiceDetails': invoiceDetails,
        'grossAmt': grossAmt,
        'disc': disc,
        'taxAmt': taxAmt,
        'otherChrgs': otherChrgs,
        'netAmt': netAmt,
        'rdOff': rdOff,
        'coBrId': coBrId,
        'fcYrId': fcYrId,
        'userId': userId,
        'typ': _isUpdateMode ? 1 : 0,
        'docId': widget.invoiceId ?? '',
      };

      final response = await ApiService.saveInvoice(invoiceData);

      if (response['status'] == 'success') {
        _showSuccessDialog(response['docNo']?.toString() ?? 'Invoice');
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to save invoice');
      }
    } catch (e) {
      _showErrorSnackBar('Error saving invoice: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccessDialog(String docNo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.green.shade100),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade800,
                            ),
                            children: [
                              TextSpan(
                                text: _isUpdateMode ? 'Invoice ' : 'Invoice ',
                              ),
                              TextSpan(
                                text: docNo,
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(
                                text:
                                    _isUpdateMode
                                        ? ' updated successfully'
                                        : ' saved successfully',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context, true);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryColor,
                            side: BorderSide(color: AppColors.primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  List<Map<String, String>> _getLedgerList(String ledCat) {
    switch (ledCat) {
      case 'W':
        return partyList
            .map((e) => {'ledKey': e.key, 'ledName': e.name})
            .toList();
      case 'L':
        return salesLedgerList
            .map((e) => {'ledKey': e.key, 'ledName': e.name})
            .toList();
      default:
        return [];
    }
  }

  String? _getKeyFromValue(String ledCat, String? value) {
    final list = _getLedgerList(ledCat);
    return list.firstWhere(
      (e) => e['ledName'] == value,
      orElse: () => {'ledKey': ''},
    )['ledKey'];
  }

  @override
  Widget build(BuildContext context) {
    bool isPartySelected =
        selectedPartyKey != null && selectedPartyKey!.isNotEmpty;
    bool hasItems = addedItems.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Sale Invoice',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildReadOnlyField(
                                    'Series',
                                    seriesController,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildReadOnlyField(
                                    'Last CD',
                                    lastCdController,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildReadOnlyField(
                                    'Doc No',
                                    docNoController,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDateField(
                                    'Doc Dt',
                                    docDtController,
                                    isRequired: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDropdown(
                              "Sales Ledger",
                              "L",
                              selectedSalesLedgerName,
                              (val, key) {
                                setState(() {
                                  selectedSalesLedgerName = val;
                                  selectedSalesLedgerKey = key;
                                });
                              },
                              isRequired: true,
                              isEnabled: true,
                            ),
                            const SizedBox(height: 12),
                            _buildDropdown(
                              "Party Name",
                              "W",
                              selectedPartyName,
                              (val, key) => _handlePartySelection(val, key),
                              isRequired: true,
                              isEnabled: !_isUpdateMode,
                            ),
                            const SizedBox(height: 12),
                            _buildReadOnlyField(
                              'Station',
                              TextEditingController(
                                text: selectedStationName ?? '',
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Only show items section if items exist
                            if (addedItems.isNotEmpty) ...[
                              _buildSelectedItemsCard(),
                              const SizedBox(height: 16),
                            ],

                            const Divider(),
                            const SizedBox(height: 16),
                            const Text(
                              'Amount Summary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSummaryRow('Gross Amt', grossAmt),
                            const SizedBox(height: 8),
                            _buildSummaryRow('Disc', disc),
                            const SizedBox(height: 8),
                            _buildSummaryRow('Tax Amt (0.00)', taxAmt),
                            const SizedBox(height: 8),
                            _buildSummaryRowWithTextField(
                              'Other Chrgs',
                              otherChrgs,
                              (value) {
                                setState(() {
                                  otherChrgs = double.tryParse(value) ?? 0.0;
                                  _calculateTotals();
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: rdOff,
                                      onChanged: (value) {
                                        setState(() {
                                          rdOff = value ?? false;
                                          _calculateTotals();
                                        });
                                      },
                                      activeColor: AppColors.primaryColor,
                                    ),
                                    const Text('Rd Off'),
                                  ],
                                ),
                                Text(
                                  '₹ ${(netAmt - grossAmt + disc - taxAmt - otherChrgs).abs().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        rdOff
                                            ? Colors.green.shade700
                                            : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            const SizedBox(height: 8),
                            _buildSummaryRow('Net Amt', netAmt, isBold: true),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildBottomButtons(hasItems),
                ],
              ),
  

          floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 55,
              height: 55,
              child: FloatingActionButton(
                heroTag: 'addItem',
                onPressed: isPartySelected ? _openAddItemPage : null,
                backgroundColor: isPartySelected ? Colors.orange : Colors.grey,
                child: const Icon(Icons.local_shipping, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Selected Items Card
  Widget _buildSelectedItemsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_cart,
                  size: 18,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Items (${addedItems.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed:
                      () => setState(() {
                        addedItems.clear();
                        _calculateTotals();
                      }),
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: addedItems.length,
            itemBuilder:
                (context, index) =>
                    _buildSelectedItemCard(addedItems[index], index),
          ),
        ],
      ),
    );
  }

  // Selected Item Card
  Widget _buildSelectedItemCard(Map<String, dynamic> item, int index) {
    final List<dynamic> sizes = item['sizes'] ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.inventory,
            color: AppColors.primaryColor,
            size: 20,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['Product'] ?? 'N/A',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Qty: ${item['Qty']} | Amount: ₹${item['Amount']}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '₹${item['Amount']}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  addedItems.removeAt(index);
                  _calculateTotals();
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                // Product Details Rows
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Product',
                        item['Product'] ?? 'N/A',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Design',
                        item['Design'] ?? 'N/A',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Type',
                        item['Type'] ?? 'N/A',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Shade',
                        item['Shade'] ?? 'N/A',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Brand',
                        item['Brand'] ?? 'N/A',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Rate',
                        '₹${item['Rate']}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'MRP',
                        '₹${item['MRP']}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Qty',
                        item['Qty'].toString(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Avg Rt',
                        '₹${item['Avg Rt']}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Item Amt',
                        '₹${item['Item Amt']}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Disc',
                        '₹${item['Disc']}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Disc (%)',
                        '${item['Disc (%)']}%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Amount',
                        '₹${item['Amount']}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Description',
                        item['Description'] ?? 'N/A',
                      ),
                    ),
                  ],
                ),

                // Size-wise Details Table
                if (sizes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Size-wise Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Table(
                        border: TableBorder(
                          horizontalInside: BorderSide(
                            color: Colors.grey.shade100,
                          ),
                          verticalInside: BorderSide(
                            color: Colors.grey.shade200,
                            width: 0.5,
                          ),
                        ),
                        columnWidths: const {
                          0: FixedColumnWidth(50),
                          1: FixedColumnWidth(50),
                          2: FixedColumnWidth(90),
                          3: FixedColumnWidth(90),
                          4: FixedColumnWidth(90),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                            ),
                            children: [
                              _buildTableHeaderCell('Size'),
                              _buildTableHeaderCell('Qty'),
                              _buildTableHeaderCell('MRP'),
                              _buildTableHeaderCell('Rate'),
                              _buildTableHeaderCell('Net Rate'),
                            ],
                          ),
                          ...sizes.map(
                            (size) => TableRow(
                              children: [
                                _buildTableCell(
                                  size['Size_Name'] ?? size['size'] ?? 'N/A',
                                ),
                                _buildTableCell((size['Qty'] ?? 0).toString()),
                                _buildTableCell(
                                  '₹${(size['MRP'] ?? size['mrp'] ?? 0).toStringAsFixed(2)}',
                                ),
                                _buildTableCell(
                                  '₹${(size['Rate'] ?? 0).toStringAsFixed(2)}',
                                ),
                                _buildTableCell(
                                  '₹${(size['NettRate'] ?? 0).toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Total Qty: ${item['Qty']} ${item['Unit_Name'] ?? 'PCS'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyFieldCompact(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: AppColors.primaryColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Colors.black87),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String ledCat,
    String? selectedValue,
    Function(String?, String?) onChanged, {
    bool isEnabled = true,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownSearch<String>(
        validator:
            (value) =>
                isRequired && (value == null || value.isEmpty)
                    ? "$label is required"
                    : null,
        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search $label",
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.grey,
                size: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              isDense: true,
            ),
          ),
        ),
        items: _getLedgerList(ledCat).map((e) => e['ledName']!).toList(),
        filterFn:
            (item, filter) =>
                filter.isEmpty
                    ? true
                    : item
                        .split('-->')
                        .first
                        .trim()
                        .toLowerCase()
                        .contains(filter.toLowerCase()),
        selectedItem: selectedValue,
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: label,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(6),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            labelStyle: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        dropdownBuilder:
            (context, selectedItem) => Text(
              selectedItem ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
        onChanged:
            isEnabled
                ? (val) => onChanged(val, _getKeyFromValue(ledCat, val))
                : null,
        enabled: isEnabled,
      ),
    );
  }

  Widget _buildBottomButtons(bool hasItems) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _openInvoiceDetails,
                  icon: const Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Details",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: (hasItems && !_isSaving) ? _saveInvoice : null,
                  icon:
                      _isSaving
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(
                            Icons.save,
                            size: 20,
                            color: Colors.white,
                          ),
                  label:
                      _isSaving
                          ? const Text(
                            "Saving...",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            "Save",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        hasItems ? AppColors.primaryColor : Colors.grey,
                    foregroundColor: Colors.white,
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
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDateField(
    String label,
    TextEditingController controller, {
    bool isRequired = false,
  }) {
    return GestureDetector(
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          setState(() {
            controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
          });
        }
      },
      child: TextFormField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
        validator:
            isRequired
                ? (value) =>
                    value == null || value.isEmpty ? '$label is required' : null
                : null,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: AppColors.primaryColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          isDense: true,
          filled: true,
          fillColor: Colors.grey.shade50,
          suffixIcon: const Icon(
            Icons.calendar_today,
            size: 18,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.primaryColor : Colors.black87,
          ),
        ),
        Text(
          '₹ ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.primaryColor : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRowWithTextField(
    String label,
    double value,
    Function(String) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        SizedBox(
          width: 120,
          child: TextFormField(
            initialValue: value.toString(),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              isDense: true,
              prefixText: '₹ ',
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}