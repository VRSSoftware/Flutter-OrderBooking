import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vrs_erp/Sales_Invoice/SalesInovice/AddItemPage.dart';
import 'package:vrs_erp/Sales_Invoice/SalesInvoiceWithPO/DespatchListScreen.dart';
import 'package:vrs_erp/Sales_Invoice/InvoiceDetailsPage.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/services/production_services.dart';

class SaleInvoiceWithPO extends StatefulWidget {
  final String? invoiceId;
  final Map<String, dynamic>? invoiceData;

  const SaleInvoiceWithPO({Key? key, this.invoiceId, this.invoiceData})
    : super(key: key);

  @override
  _SaleInvoiceWithPOState createState() => _SaleInvoiceWithPOState();
}

class _SaleInvoiceWithPOState extends State<SaleInvoiceWithPO> {
  // ==================== VARIABLES ====================
  bool _isUpdateMode = false;

  // Basic Details Controllers
  final TextEditingController _seriesCtrl = TextEditingController(text: '');
  final TextEditingController _lastCdCtrl = TextEditingController(text: '');
  final TextEditingController _docNoCtrl = TextEditingController(text: '');
  final TextEditingController docDtController = TextEditingController();

  // Dropdown values
  String? selectedPartyKey;
  String? selectedPartyName;
  String? selectedSalesLedgerKey;
  String? selectedSalesLedgerName;
  String? selectedStationKey;
  String? selectedStationName;

  // Dropdown data lists from API
  List<KeyName> salesLedgerList = [];
  List<KeyName> partyList = [];
  List<KeyName> stationList = [];

  // List to store added items
  List<Map<String, dynamic>> addedItems = [];
  List<Map<String, dynamic>> selectedDespatches = [];

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

  // Add this variable at the top with other variables
  List<int> _packingDocIds = [];

  @override
  void initState() {
    super.initState();
    _isUpdateMode = widget.invoiceId != null && widget.invoiceId!.isNotEmpty;
    docDtController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _initializeData();
  }

  @override
  void dispose() {
    _seriesCtrl.dispose();
    _lastCdCtrl.dispose();
    _docNoCtrl.dispose();
    docDtController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);

    try {
      // Load Sales Ledger FIRST (changed order)
      await _fetchLedgers('L');

      // Then load everything else in parallel
      await Future.wait([
        _loadSeries(),
        _loadDocNo(),
        _fetchLedgers('W'), // Now Party list loads after Sales Ledger
        _fetchStations(),
      ]);

      if (_isUpdateMode && widget.invoiceId != null) {
        await _loadInvoiceData(widget.invoiceId!);
      }
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadSeries() async {
    final seriesData = await ProductionService.getSeries('21');
    if (seriesData.isNotEmpty) {
      setState(() {
        _seriesCtrl.text = seriesData['Sr_Code'] ?? '';
      });
    }
  }

  Future<void> _loadDocNo() async {
    final docNoData = await ApiService.getDocNo();
    setState(() {
      _lastCdCtrl.text = docNoData['LastCd'] ?? '';
      _docNoCtrl.text = docNoData['DocNo'] ?? '';
    });
  }

  Future<void> _fetchLedgers(String ledCat) async {
    try {
      Map<String, dynamic> response;

      if (ledCat == 'L') {
        response = await ApiService.fetchLedgers(
          ledCat: ledCat,
          coBrId: coBrId,
          accLGrpKey: '0121',
        );
      } else {
        response = await ApiService.fetchLedgers(
          ledCat: ledCat,
          coBrId: coBrId,
        );
      }

      if (response['statusCode'] == 200 && response['result'] != null) {
        final List<dynamic> data = response['result'];

        // Convert to KeyName objects with extra data
        final List<KeyName> result =
            data.map((item) {
              return KeyName(
                key: item['ledKey'].toString(),
                name: item['ledName'].toString(),
                extra: item, // Store the entire item as extra data
              );
            }).toList();

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

      print('Load invoice response type: ${response.runtimeType}');
      print('Load invoice response: $response');

      // Get header information from widget.invoiceData if available
      if (widget.invoiceData != null) {
        print('Invoice Data from register: ${widget.invoiceData}');

        setState(() {
          _docNoCtrl.text =
              widget.invoiceData!['docNo']?.toString() ?? _docNoCtrl.text;
          selectedPartyName = widget.invoiceData!['partyName']?.toString();

          // FIX: Set the party key from invoiceData
          if (widget.invoiceData!.containsKey('partyKey') &&
              widget.invoiceData!['partyKey'] != null) {
            selectedPartyKey = widget.invoiceData!['partyKey'].toString();
            print('Set selectedPartyKey from invoiceData: $selectedPartyKey');
          } else if (widget.invoiceData!.containsKey('custKey') &&
              widget.invoiceData!['custKey'] != null) {
            selectedPartyKey = widget.invoiceData!['custKey'].toString();
            print('Set selectedPartyKey from custKey: $selectedPartyKey');
          }
        });
      }

      // Response is a List of packing details
      if (response is List && response.isNotEmpty) {
        setState(() {
          addedItems.clear();
          selectedDespatches.clear();

          Set<int> uniquePackDocIds = {};

          for (var item in response) {
            final packDocId = item['packDocId'] as int?;
            if (packDocId != null) {
              uniquePackDocIds.add(packDocId);
            }

            double qty = (item['Qty'] as num?)?.toDouble() ?? 0;
            double rate = (item['Rate'] as num?)?.toDouble() ?? 0;
            double amount =
                (item['Amount'] as num?)?.toDouble() ?? (qty * rate);
            double discAmt = (item['DiscAmt'] as num?)?.toDouble() ?? 0;
            double netAmt = (item['NetAmt'] as num?)?.toDouble() ?? amount;
            double avgRt = (item['Avrg_RT'] as num?)?.toDouble() ?? rate;

            Map<String, dynamic> transformedItem = {
              'Doc_Id': packDocId,
              'packDocId': packDocId,
              'SaleBillDtlID': item['SaleBillDtlID'],
              'PackDocNo': item['PackDocNo'] ?? '',
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
            };

            addedItems.add(transformedItem);
            selectedDespatches.add(transformedItem);
          }

          _packingDocIds = uniquePackDocIds.toList();

          _calculateTotals();
        });
      } else {
        print('No items found in invoice or invalid response format');
      }
    } catch (e) {
      print('Error loading invoice data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

  void _openDespatchDetails() async {
    if (selectedPartyKey == null || selectedPartyKey!.isEmpty) {
      _showValidationDialog(
        'Party Selection Required',
        'Please select a party before viewing Despatches.',
      );
      return;
    }

    print('Opening despatch screen for party: $selectedPartyKey');
    print('Existing selected despatches: ${selectedDespatches.length}');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => DespatchListScreen(
              custKey: selectedPartyKey!,
              existingSelectedDespatches:
                  selectedDespatches, // Pass existing selections
              onDespatchesSelected: (newDespatches) {
                print('Callback received ${newDespatches.length} despatches');
              },
            ),
      ),
    );

    print('Result from pop: $result');
    print('Result type: ${result.runtimeType}');

    if (result != null && result is List && result.isNotEmpty) {
      print('Received ${result.length} despatches from selection');

      setState(() {
        // Clear and add all selected despatches (this replaces the old ones)
        selectedDespatches.clear();
        addedItems.clear();
        selectedDespatches.addAll(result.cast<Map<String, dynamic>>());
        addedItems.addAll(result.cast<Map<String, dynamic>>());

        // Update packingDocIds for saving
        _packingDocIds =
            selectedDespatches
                .map<int>((item) {
                  return item['Doc_Id'] ?? item['packDocId'] ?? 0;
                })
                .where((id) => id != 0)
                .toList();
        _packingDocIds = _packingDocIds.toSet().toList();

        _calculateTotals();
      });

      print('Added items count: ${addedItems.length}');
      print('Packing Doc IDs: $_packingDocIds');
    } else {
      print('No despatches selected or result is null/empty');
    }
  }

  void _handlePartySelection(String? val, String? key) async {
    if (key == null) return;

    String? extractedStation;

    if (val != null && val.contains('-->')) {
      final parts = val.split('-->');
      extractedStation = parts.last.trim();
    }

    // Find the selected party from partyList
    final selectedParty = partyList.firstWhere(
      (party) => party.key == key,
      orElse: () => KeyName(key: '', name: ''),
    );

    // Get salesLedKey from extra data
    String? salesLedKeyFromParty = selectedParty.salesLedKey;

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

    // Auto-select Sales Ledger after state update
    if (salesLedKeyFromParty != null && salesLedKeyFromParty.isNotEmpty) {
      // Wait a bit for sales ledger list to load if needed
      if (salesLedgerList.isEmpty) {
        // If sales ledger list is empty, wait for it to load
        await Future.delayed(Duration(milliseconds: 500));
        // Or better: retry a few times
        for (int i = 0; i < 5; i++) {
          if (salesLedgerList.isNotEmpty) break;
          await Future.delayed(Duration(milliseconds: 200));
        }
      }
      _autoSelectSalesLedger(salesLedKeyFromParty);
    }
  }

  void _autoSelectSalesLedger(String salesLedKey) {
    if (!mounted) return;

    // Find matching sales ledger by key
    final matchingLedger = salesLedgerList.firstWhere(
      (ledger) => ledger.key == salesLedKey,
      orElse: () => KeyName(key: '', name: ''),
    );

    if (matchingLedger.key.isNotEmpty) {
      // Found matching sales ledger - auto-select it
      setState(() {
        selectedSalesLedgerKey = matchingLedger.key;
        selectedSalesLedgerName = matchingLedger.name;
      });
      print(
        'Auto-selected Sales Ledger: ${matchingLedger.name} (${matchingLedger.key})',
      );
    } else {
      // Sales ledger not found - show key in the field but not in dropdown
      print('Sales Ledger with key $salesLedKey not found in list');

      setState(() {
        // Set the selected value to show the missing key in the field
        selectedSalesLedgerKey = salesLedKey;
        selectedSalesLedgerName = '$salesLedKey';
      });

      // Show message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sales Ledger ID: $salesLedKey not available. Please select from dropdown.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _openDetailsDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => InvoiceDetailsPage(
              partyKey: selectedPartyKey,
              partyName: selectedPartyName,
              partyStation: selectedStationName,
              selectedDespatches: selectedDespatches,
            ),
      ),
    );

    if (result != null) {
      print('Details saved: $result');
      // Handle the saved details if needed
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.normal)),
        ],
      ),
    );
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
      // Extract packing document IDs
      List<int> packingDocIds;

      if (_isUpdateMode) {
        // In update mode, use the stored packingDocIds from loaded data
        packingDocIds = _packingDocIds;
      } else {
        // In create mode, extract from addedItems
        packingDocIds =
            addedItems
                .map<int>((item) {
                  if (item['Doc_Id'] != null) {
                    return int.tryParse(item['Doc_Id'].toString()) ?? 0;
                  }
                  return 0;
                })
                .where((id) => id != 0)
                .toList();
        // Remove duplicates
        packingDocIds = packingDocIds.toSet().toList();
      }

      print('Extracted Packing Doc IDs: $packingDocIds');

      if (packingDocIds.isEmpty) {
        _showValidationDialog(
          'Validation Error',
          'No valid packing document IDs found.',
        );
        setState(() => _isSaving = false);
        return;
      }

      // Prepare data2 JSON string
      Map<String, dynamic> data2Map = {
        "packingdate": "${docDtController.text} 18:58:15",
        "customer": selectedPartyKey ?? '',
        "broker": "",
        "comission": "0.0",
        "transporter": "",
        "delivaryday": "",
        "delivarydate": docDtController.text,
        "remark": "",
        "consignee": "",
        "station": selectedStationKey ?? '',
        "paymentterms": "",
        "paymentdays": "0",
        "duedate": docDtController.text,
        "refno": "",
        "date": "${docDtController.text} 00:00:00.000",
        "bookingtype": "",
        "salesman": selectedSalesLedgerKey ?? '',
        "usertype": "A",
        "grossAmount": grossAmt.toStringAsFixed(2),
        "roundOff": rdOff,
        "roundOffAmount":
            rdOff
                ? (netAmt - grossAmt + disc - taxAmt - otherChrgs)
                    .abs()
                    .toStringAsFixed(2)
                : "0",
        "netAmount": netAmt.toStringAsFixed(2),
        "packType": "0",
        "doc_id": _isUpdateMode ? (widget.invoiceId ?? "-1") : "-1",
      };

      Map<String, dynamic> response;

      if (_isUpdateMode) {
        // Use update endpoint for update mode
        final int docId = int.tryParse(widget.invoiceId ?? '0') ?? 0;

        final Map<String, dynamic> updateData = {
          "userId": UserSession.userName ?? '',
          "login_id": UserSession.userName ?? '',
          "coBr_id": coBrId,
          "coBrId": coBrId,
          "fcYr_id": fcYrId,
          "fcYrId": fcYrId,
          "docId": docId,
          "custKey": selectedPartyKey ?? '',
          "packingDocIds": packingDocIds, // Note: newPackingDocIds for update
          "data2": jsonEncode(data2Map),
        };

        print('Updating invoice payload: ${jsonEncode(updateData)}');
        print('Updating with newPackingDocIds: $packingDocIds');

        response = await ApiService.updateSaleBillForPacking(updateData);
      } else {
        // Use create endpoint for new invoice
        final Map<String, dynamic> saveData = {
          "userId": UserSession.userName ?? '',
          "login_id": UserSession.userName ?? '',
          "coBr_id": coBrId,
          "coBrId": coBrId,
          "fcYr_id": fcYrId,
          "fcYrId": fcYrId,
          "docId": 0,
          "custKey": selectedPartyKey ?? '',
          "packingDocIds": packingDocIds,
          "data2": jsonEncode(data2Map),
        };

        print('Saving invoice payload: ${jsonEncode(saveData)}');
        print('PackingDocIds: $packingDocIds');

        response = await ApiService.saveInvoiceForPacking(saveData);
      }

      print('Response: $response');

      if (response['status'] == 'success') {
        String docNo =
            response['docNo']?.toString() ??
            response['message']?.toString() ??
            _docNoCtrl.text;
        _showSuccessDialog(docNo);
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to save invoice');
      }
    } catch (e) {
      print('Error saving invoice: $e');
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
            .map(
              (e) => {
                'ledKey': e.key,
                'ledName': e.name,
                if (e.salesLedKey != null) 'salesLedKey': e.salesLedKey!,
              },
            )
            .toList();
      case 'L':
        // Filter out any missing entries from the dropdown list
        return salesLedgerList
            .where(
              (e) => !e.isMissing,
            ) // Don't show missing entries in dropdown
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
        _isUpdateMode
            ? (selectedPartyKey != null && selectedPartyKey!.isNotEmpty)
            : (selectedPartyKey != null && selectedPartyKey!.isNotEmpty);

    bool hasItems = addedItems.isNotEmpty;

    print('Build - Is Update Mode: $_isUpdateMode');
    print('Build - Selected Party Key: $selectedPartyKey');
    print('Build - Is Party Selected: $isPartySelected');

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
                                    _seriesCtrl,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildReadOnlyField(
                                    'Last CD',
                                    _lastCdCtrl,
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
                                    _docNoCtrl,
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
                              "Party Name",
                              "W",
                              selectedPartyName,
                              (val, key) => _handlePartySelection(val, key),
                              isRequired: true,
                              isEnabled: !_isUpdateMode,
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
                            _buildReadOnlyField(
                              'Station',
                              TextEditingController(
                                text: selectedStationName ?? '',
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Only show items section if items exist (like PackingListAgainstSO)
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
                heroTag: 'despatch',
                onPressed: isPartySelected ? _openDespatchDetails : null,
                backgroundColor: isPartySelected ? Colors.orange : Colors.grey,
                child: const Icon(Icons.local_shipping, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Selected Items Card (Same design as PackingListAgainstSO)
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

  // Selected Item Card (Same design as PackingListAgainstSO)
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Doc: ${item['PackDocNo'] ?? item['Doc_No'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Unit: ${item['Unit_Name'] ?? 'PCS'}',
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
                // Product Details Row 1
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
                // Row 2
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
                // Row 3
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
                // Row 4
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
                        '${item['Qty']} ${item['Unit_Name'] ?? 'PCS'}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 5
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
                // Row 6 - Discount
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
                // Row 7 - Tax Details
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Tax Amt',
                        '₹${item['Tax Amt'] ?? 0}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Tax %',
                        '${item['TaxPerc'] ?? 5}%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 8 - Tax Breakup
                if (item['Tax1_Amt'] != null || item['Tax2_Amt'] != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tax Breakup',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'CGST: ₹${item['Tax1_Amt'] ?? 0}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'SGST: ₹${item['Tax2_Amt'] ?? 0}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            if (item['Tax3_Amt'] != null &&
                                item['Tax3_Amt'] != 0)
                              Expanded(
                                child: Text(
                                  'Other: ₹${item['Tax3_Amt']}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                // Row 9 - Net Amount
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildReadOnlyFieldCompact(
                          'Net Amount',
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
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Unit: ${item['Unit_Name'] ?? 'PCS'}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryColor,
                          ),
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
                          2: FixedColumnWidth(80),
                          3: FixedColumnWidth(80),
                          4: FixedColumnWidth(80),
                        },
                        children: [
                          // Header Row
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
                          // Data Rows
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
                ? (val) {
                  if (ledCat == 'L' && val != null) {
                    final selectedKey = _getKeyFromValue(ledCat, val);
                    final selectedLedger = salesLedgerList.firstWhere(
                      (l) => l.key == selectedKey,
                      orElse: () => KeyName(key: '', name: ''),
                    );

                    // If selecting a valid ledger (not missing), update normally
                    if (!selectedLedger.isMissing) {
                      onChanged(val, selectedKey);
                    } else {
                      // If selecting missing item, prompt to select valid one
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please select a valid Sales Ledger'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    onChanged(val, _getKeyFromValue(ledCat, val));
                  }
                }
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
                  onPressed: _openDetailsDialog,
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
