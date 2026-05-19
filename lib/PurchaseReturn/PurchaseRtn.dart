import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;
import 'package:vrs_erp/PurchaseReturn/Detail.dart';
import 'package:vrs_erp/PurchaseReturn/POForPurRtnList.dart';
import 'dart:convert';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/services/production_services.dart';

class PurchaseReturnMainPage extends StatefulWidget {
  final String? returnId;
  final Map<String, dynamic>? returnData;

  const PurchaseReturnMainPage({Key? key, this.returnId, this.returnData})
    : super(key: key);

  @override
  _PurchaseReturnMainPageState createState() => _PurchaseReturnMainPageState();
}

class _PurchaseReturnMainPageState extends State<PurchaseReturnMainPage> {
  // ==================== VARIABLES ====================
  bool _isUpdateMode = false;

  // Basic Details Controllers
  final TextEditingController _seriesCtrl = TextEditingController(text: '');
  final TextEditingController _lastCdCtrl = TextEditingController(text: '');
  final TextEditingController _docNoCtrl = TextEditingController(text: '');
  final TextEditingController docDtController = TextEditingController();
  final TextEditingController _refNoCtrl = TextEditingController(text: '');
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _remarkCtrl = TextEditingController(text: '');
  final TextEditingController _discPercentCtrl = TextEditingController(
    text: '0',
  );
  // Dropdown values
  String? selectedSupplierKey;
  String? selectedSupplierName;
  String? selectedStationKey;
  String? selectedStationName;
  String? selectedType; // Excess or Redo
  double? selectedDiscPercent;

  // Dropdown data lists from API
  List<KeyName> supplierList = [];
  List<KeyName> stationList = [];

  // Type options
  final List<String> typeOptions = ['Excess', 'Redo'];

  // List to store added items
  List<Map<String, dynamic>> addedItems = [];
  List<Map<String, dynamic>> selectedPOReturns = [];

  // Totals
  double grossAmt = 0.0;
  double disc = 0.0;
  double taxAmt = 0.0;
  double otherChrgs = 0.0;
  double amount = 0.0;
  double netAmt = 0.0;
  bool rdOff = false;
  bool _isSaving = false;
  bool isLoading = true;
  final _formKey = GlobalKey<FormState>();

  // API Session
  final String coBrId = UserSession.coBrId ?? '';
  final String fcYrId = UserSession.userFcYr ?? '';
  final String userId = UserSession.userName ?? '';

  // Store selected PO/GRN document IDs
  List<int> _selectedDocDtlIds = [];

  @override
  void initState() {
    super.initState();
    _isUpdateMode = widget.returnId != null && widget.returnId!.isNotEmpty;
    docDtController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _dateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _initializeData();
  }

  @override
  void dispose() {
    _seriesCtrl.dispose();
    _lastCdCtrl.dispose();
    _docNoCtrl.dispose();
    docDtController.dispose();
    _refNoCtrl.dispose();
    _dateCtrl.dispose();
    _remarkCtrl.dispose();
    _discPercentCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);

    try {
      await Future.wait([_fetchSuppliers(), _fetchStations()]);

      if (_isUpdateMode && widget.returnId != null) {
        await _loadReturnData(widget.returnId!);
      } else {
        await Future.wait([_loadSeries(), _loadDocNo()]);
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
    final seriesData = await ProductionService.getSeries('03');
    if (seriesData.isNotEmpty) {
      setState(() {
        _seriesCtrl.text = seriesData['Sr_Code'] ?? '';
      });
    }
  }

  Future<void> _loadDocNo() async {
    final docNoData = await ApiService.getPurRtnDocNo();
    setState(() {
      _lastCdCtrl.text = docNoData['LastCd'] ?? '';
      _docNoCtrl.text = docNoData['DocNo'] ?? '';
    });
  }

  Future<void> _fetchSuppliers() async {
    try {
      final response = await ApiService.fetchLedgers(
        ledCat: 'V',
        coBrId: coBrId,
      );

      if (response['statusCode'] == 200 && response['result'] != null) {
        final List<dynamic> data = response['result'];
        final List<KeyName> result =
            data.map((item) {
              return KeyName(
                key: item['ledKey'].toString(),
                name: item['ledName'].toString(),
                extra: item,
              );
            }).toList();

        setState(() {
          supplierList = result;
        });
      }
    } catch (e) {
      print('Error fetching suppliers: $e');
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

  Future<void> _loadReturnData(String returnId) async {
    try {
      final response = await ApiService.fetchPurchaseReturnForEdit(returnId);

      print('Response received: $response');

      // Check if response has header and details directly (without status field)
      if (response.containsKey('header') && response.containsKey('details')) {
        final header = response['header'];
        final details = response['details'];

        print('Header: $header');
        print('Details count: ${details.length}');

        setState(() {
          // Header data
          _seriesCtrl.text = header['Doc_Sr']?.toString() ?? '';
          _docNoCtrl.text = header['Doc_No']?.toString() ?? '';
          if (header['Doc_Dt'] != null) {
            String dateStr = header['Doc_Dt'].toString();
            if (dateStr.contains('T')) {
              dateStr = dateStr.split('T')[0];
            }
            docDtController.text = dateStr;
            _dateCtrl.text = dateStr;
          }
          selectedSupplierKey = header['Supl_Key']?.toString();
          // Get supplier name from supplier list
          if (selectedSupplierKey != null && supplierList.isNotEmpty) {
            final supplier = supplierList.firstWhere(
              (s) => s.key == selectedSupplierKey,
              orElse: () => KeyName(key: '', name: ''),
            );
            selectedSupplierName =
                supplier.name.isNotEmpty ? supplier.name : selectedSupplierKey;
          }
          selectedStationKey = header['Stn_Key']?.toString();
          // Get station name from station list
          if (selectedStationKey != null && stationList.isNotEmpty) {
            final station = stationList.firstWhere(
              (s) => s.key == selectedStationKey,
              orElse: () => KeyName(key: '', name: ''),
            );
            selectedStationName =
                station.name.isNotEmpty ? station.name : selectedStationKey;
          }
          _refNoCtrl.text = header['OurRef_No']?.toString() ?? '';

          // Process items data
          addedItems.clear();
          selectedPOReturns.clear();
          _selectedDocDtlIds.clear();

          for (var detail in details) {
            // Parse sizes from the detail
            List<dynamic> sizes = detail['sizes'] ?? [];

            // Calculate total quantity from sizes
            double totalQty = 0;
            List<Map<String, dynamic>> transformedSizes = [];

            for (var size in sizes) {
              double sizeQty = (size['Qty'] as num?)?.toDouble() ?? 0;
              totalQty += sizeQty;

              transformedSizes.add({
                'Size_Name': size['Size_Name']?.toString() ?? '',
                'Qty': sizeQty,
                'ClQty': (size['ClQty'] as num?)?.toDouble() ?? 0,
                'PurRate': (detail['SuplRate'] as num?)?.toDouble() ?? 0,
                'NettRate': (detail['SuplRate'] as num?)?.toDouble() ?? 0,
                'DocDtlSz_Id': size['DocDtlSz_Id'] as int? ?? 0,
                'DocDtl_Id': detail['DocDtl_Id'] as int? ?? 0,
              });
            }

            // If no sizes found, use the main Qty
            if (totalQty == 0) {
              totalQty = (detail['Qty'] as num?)?.toDouble() ?? 0;
            }

            double rate = (detail['SuplRate'] as num?)?.toDouble() ?? 0;
            double amount = totalQty * rate;
            double discAmt = (detail['DiscAmt'] as num?)?.toDouble() ?? 0;
            double netAmt = (detail['NetAmt'] as num?)?.toDouble() ?? amount;

            // Create item object matching the expected format
            Map<String, dynamic> item = {
              'docDtlId': detail['DocDtl_Id'] as int? ?? 0,
              'PONo': '', // Not available in this response
              'GRNNo': '', // Not available in this response
              'Product': detail['Item_Name']?.toString() ?? 'N/A',
              'Style_Code': detail['Style_Code']?.toString() ?? 'N/A',
              'Shade_Name': detail['Shade_Name']?.toString() ?? 'N/A',
              'Brand_Name': detail['Brand_Name']?.toString() ?? 'N/A',
              'Type_Name': detail['Type_Name']?.toString() ?? 'N/A',
              'Unit_Name': detail['ConvUnitName']?.toString() ?? 'PCS',
              'ActQty': (detail['StockQty'] as num?)?.toDouble() ?? totalQty,
              'ChlnQty': (detail['ClQty'] as num?)?.toDouble() ?? totalQty,
              'Rate': rate,
              'Qty': totalQty,
              'Disc': discAmt,
              'Amount': amount,
              'NetAmt': netAmt,
              'sizes': transformedSizes,
            };

            print(
              'Adding item: ${item['Product']}, Qty: ${item['Qty']}, Amount: ${item['Amount']}',
            );

            addedItems.add(item);
            selectedPOReturns.add(item);
            _selectedDocDtlIds.add(detail['DocDtl_Id'] as int);
          }

          print('Total items loaded: ${addedItems.length}');
          _calculateTotals();
        });
      } else if (response['status'] == 'success' &&
          response['header'] != null) {
        // Alternative response format with status field
        final header = response['header'];
        final details = response['details'] ?? response['items'] ?? [];

        setState(() {
          _docNoCtrl.text = header['Doc_No']?.toString() ?? '';
          if (header['Doc_Dt'] != null) {
            String dateStr = header['Doc_Dt'].toString();
            if (dateStr.contains('T')) dateStr = dateStr.split('T')[0];
            docDtController.text = dateStr;
            _dateCtrl.text = dateStr;
          }
          selectedSupplierKey = header['Supl_Key']?.toString();
          selectedStationKey = header['Stn_Key']?.toString();
          _refNoCtrl.text = header['OurRef_No']?.toString() ?? '';

          addedItems.clear();
          selectedPOReturns.clear();
          _selectedDocDtlIds.clear();

          for (var detail in details) {
            List<dynamic> sizes = detail['sizes'] ?? [];
            double totalQty = 0;
            List<Map<String, dynamic>> transformedSizes = [];

            for (var size in sizes) {
              double sizeQty = (size['Qty'] as num?)?.toDouble() ?? 0;
              totalQty += sizeQty;
              transformedSizes.add({
                'Size_Name': size['Size_Name']?.toString() ?? '',
                'Qty': sizeQty,
                'ClQty': (size['ClQty'] as num?)?.toDouble() ?? 0,
                'PurRate': (detail['SuplRate'] as num?)?.toDouble() ?? 0,
                'NettRate': (detail['SuplRate'] as num?)?.toDouble() ?? 0,
                'DocDtlSz_Id': size['DocDtlSz_Id'] as int? ?? 0,
                'DocDtl_Id': detail['DocDtl_Id'] as int? ?? 0,
              });
            }

            if (totalQty == 0) {
              totalQty = (detail['Qty'] as num?)?.toDouble() ?? 0;
            }

            double rate = (detail['SuplRate'] as num?)?.toDouble() ?? 0;
            double amount = totalQty * rate;

            Map<String, dynamic> item = {
              'docDtlId': detail['DocDtl_Id'] as int? ?? 0,
              'PONo': '',
              'GRNNo': '',
              'Product': detail['Item_Name']?.toString() ?? 'N/A',
              'Style_Code': detail['Style_Code']?.toString() ?? 'N/A',
              'Shade_Name': detail['Shade_Name']?.toString() ?? 'N/A',
              'Brand_Name': detail['Brand_Name']?.toString() ?? 'N/A',
              'Type_Name': detail['Type_Name']?.toString() ?? 'N/A',
              'Unit_Name': detail['ConvUnitName']?.toString() ?? 'PCS',
              'ActQty': (detail['StockQty'] as num?)?.toDouble() ?? totalQty,
              'ChlnQty': (detail['ClQty'] as num?)?.toDouble() ?? totalQty,
              'Rate': rate,
              'Qty': totalQty,
              'Disc': (detail['DiscAmt'] as num?)?.toDouble() ?? 0,
              'Amount': amount,
              'NetAmt': (detail['NetAmt'] as num?)?.toDouble() ?? amount,
              'sizes': transformedSizes,
            };

            addedItems.add(item);
            selectedPOReturns.add(item);
            _selectedDocDtlIds.add(detail['DocDtl_Id'] as int);
          }

          _calculateTotals();
        });
      } else {
        print('Invalid response format: $response');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to load return data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error loading return data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading return: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _calculateTotals() {
    double calculatedGrossAmt = 0.0;

    for (var item in addedItems) {
      final List<dynamic> sizes = item['sizes'] ?? [];

      if (sizes.isNotEmpty) {
        for (var size in sizes) {
          double sizeQty = (size['Qty'] as num?)?.toDouble() ?? 0;
          double sizePurRate = (size['PurRate'] as num?)?.toDouble() ?? 0;
          calculatedGrossAmt += sizeQty * sizePurRate;
        }
      } else {
        double qty = item['Qty'] as double? ?? 0;
        double rate = item['Rate'] as double? ?? 0;
        calculatedGrossAmt += qty * rate;
      }
    }

    setState(() {
      grossAmt = calculatedGrossAmt;
      disc = grossAmt * (selectedDiscPercent ?? 0) / 100;
      taxAmt = 0.0;
      amount = grossAmt - disc;
      double calculatedNet = amount + otherChrgs;
      netAmt = rdOff ? calculatedNet.roundToDouble() : calculatedNet;
    });
  }

  void _openPOReturnList() async {
    if (selectedSupplierKey == null || selectedSupplierKey!.isEmpty) {
      _showValidationDialog(
        'Supplier Selection Required',
        'Please select a supplier before viewing Purchase Orders.',
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => POReturnListScreen(
              supplierKey: selectedSupplierKey!,
              existingSelectedItems: selectedPOReturns,
            ),
      ),
    );

    if (result != null && result is List && result.isNotEmpty) {
      setState(() {
        selectedPOReturns.addAll(result.cast<Map<String, dynamic>>());
        addedItems.addAll(result.cast<Map<String, dynamic>>());

        _selectedDocDtlIds =
            selectedPOReturns
                .map<int>((item) => item['docDtlId'] as int)
                .where((id) => id != 0)
                .toList();
        _selectedDocDtlIds = _selectedDocDtlIds.toSet().toList();

        _calculateTotals();
      });
    }
  }

  void _handleSupplierSelection(String? val, String? key) async {
    if (key == null) return;

    String? extractedStation;

    if (val != null && val.contains('-->')) {
      final parts = val.split('-->');
      extractedStation = parts.last.trim();
    }

    setState(() {
      selectedSupplierName = val;
      selectedSupplierKey = key;

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

  void _openDetailsDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PurchaseReturnDetailsPage(
              supplierKey: selectedSupplierKey,
              supplierName: selectedSupplierName,
              supplierStation: selectedStationName,
              selectedItems: selectedPOReturns,
            ),
      ),
    );

    if (result != null) {
      print('Details saved: $result');
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

  Future<void> _saveReturn() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    if (addedItems.isEmpty) {
      _showValidationDialog(
        'Validation Error',
        'Please add at least one item to save purchase return.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Calculate totals
      double calculatedGrossAmt = 0.0;

      for (var item in addedItems) {
        final List<dynamic> sizes = item['sizes'] ?? [];

        if (sizes.isNotEmpty) {
          for (var size in sizes) {
            double sizeQty = (size['Qty'] as num?)?.toDouble() ?? 0;
            double sizePurRate = (size['PurRate'] as num?)?.toDouble() ?? 0;
            calculatedGrossAmt += sizeQty * sizePurRate;
          }
        } else {
          double qty = item['Qty'] as double? ?? 0;
          double rate = item['Rate'] as double? ?? 0;
          calculatedGrossAmt += qty * rate;
        }
      }

      double calculatedDisc =
          calculatedGrossAmt * (selectedDiscPercent ?? 0) / 100;
      double calculatedAmount = calculatedGrossAmt - calculatedDisc;
      double calculatedNetAmt =
          rdOff ? calculatedAmount.roundToDouble() : calculatedAmount;

      // Prepare items array
      List<Map<String, dynamic>> itemsArray = [];

      for (var item in addedItems) {
        final String styleCode = item['Style_Code'] ?? '';
        final String shadeName = item['Shade_Name'] ?? '';
        final List<dynamic> sizes = item['sizes'] ?? [];

        final double totalQty = item['Qty'] as double? ?? 0;

        if (sizes.isNotEmpty) {
          for (var size in sizes) {
            final String sizeName = size['Size_Name']?.toString() ?? '';
            final double sizeQty = (size['Qty'] as num?)?.toDouble() ?? 0;
            final double mrp = size['MRP'] as double? ?? 0;
            final double wsp =
                size['NettRate'] as double? ?? size['PurRate'] as double? ?? 0;

            if (sizeQty > 0) {
              itemsArray.add({
                "designcode": styleCode,
                "color": shadeName,
                "size": sizeName,
                "Qty": sizeQty,
                "TotQty": totalQty,
                "mrp": mrp,
                "WSP": wsp,
                "barcode": "",
                "Note": item['Note'] ?? "",
              });
            }
          }
        }
      }

      if (itemsArray.isEmpty) {
        _showValidationDialog(
          'No Items',
          'Please add at least one item with quantity.',
        );
        setState(() => _isSaving = false);
        return;
      }

      // Prepare data object
      final Map<String, dynamic> dataObject = {
        "orderdate":
            "${docDtController.text} ${DateFormat('HH:mm:ss').format(DateTime.now())}",
        "consignee": selectedStationKey ?? '',
        "salesman": "001",
        "customer": selectedSupplierKey ?? '',
      };

      // Prepare data2 as JSON string
      final Map<String, dynamic> data2Map = {
        "Purchasedate":
            "${docDtController.text} ${DateFormat('HH:mm:ss').format(DateTime.now())}",
        "customer": selectedSupplierKey ?? '',
        "broker": "",
        "comission": "0.0",
        "transporter": "",
        "delivaryday": "0",
        "delivarydate": docDtController.text,
        "remark": _remarkCtrl.text,
        "consignee": "",
        "station": selectedStationKey ?? '',
        "paymentterms": "",
        "paymentdays": "0",
        "duedate": docDtController.text,
        "refno": _refNoCtrl.text,
        "date": "${docDtController.text} 00:00:00.000",
        "bookingtype": "",
        "salesman": "",
        "usertype": "A",
        "grossAmount": calculatedGrossAmt.toStringAsFixed(0),
        "roundOff": rdOff,
        "roundOffAmount":
            rdOff
                ? (calculatedNetAmt - calculatedAmount).abs().toStringAsFixed(0)
                : "0",
        "netAmount": calculatedNetAmt.toStringAsFixed(0),
        "packType": "0",
        "doc_id": _isUpdateMode ? widget.returnId : "-1",
      };

      // Final payload
      final payload = {
        "doc_id": _isUpdateMode ? int.parse(widget.returnId!) : 0,
        "login_id": userId,
        "coBr_id": coBrId,
        "fcYr_id": fcYrId,
        "userId": userId,
        "coBrId": coBrId,
        "fcYrId": fcYrId,
        "data": dataObject,
        "data2": jsonEncode(data2Map),
        "items": itemsArray,
      };

      print('Payload: ${jsonEncode(payload)}');

      Map<String, dynamic> response;

      if (_isUpdateMode) {
        response = await ApiService.updatePurchaseReturn(payload);
      } else {
        response = await ApiService.insertPurchaseReturn(payload);
      }

      if (response['status'] == 'success') {
        String docNo =
            _isUpdateMode
                ? widget.returnId!
                : response['docNo'] ?? _docNoCtrl.text;
        _showSuccessDialog(docNo);
      } else {
        _showErrorSnackBar(
          response['message'] ?? 'Failed to save purchase return',
        );
      }
    } catch (e) {
      print('Error: $e');
      _showErrorSnackBar('Error: $e');
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
                                text:
                                    _isUpdateMode
                                        ? 'Purchase Return '
                                        : 'Purchase Return ',
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

  List<Map<String, String>> _getSupplierList() {
    return supplierList
        .map((e) => {'ledKey': e.key, 'ledName': e.name})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    bool isSupplierSelected =
        selectedSupplierKey != null && selectedSupplierKey!.isNotEmpty;
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
        title: Text(
          _isUpdateMode ? 'Update Purchase Return' : 'Purchase Return',
          style: const TextStyle(
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
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField('Ref No', _refNoCtrl),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDateField('Date', _dateCtrl),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDropdown(
                              "Supplier Name",
                              selectedSupplierName,
                              (val, key) => _handleSupplierSelection(val, key),
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
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDropdownField(
                                    "Type",
                                    typeOptions,
                                    selectedType,
                                    (value) =>
                                        setState(() => selectedType = value),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: _buildDiscountTextField()),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTextField('Remark', _remarkCtrl, maxLines: 2),
                            const SizedBox(height: 24),

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
              width: 100,
              height: 55,
              child: FloatingActionButton(
                heroTag: 'rtn',
                onPressed: isSupplierSelected ? _openPOReturnList : null,
                backgroundColor:
                    isSupplierSelected ? Colors.orange : Colors.grey,
                child: const Text(
                  'RTN',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                        selectedPOReturns.clear();
                        _selectedDocDtlIds.clear();
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

  Widget _buildSelectedItemCard(Map<String, dynamic> item, int index) {
    final List<dynamic> sizes = item['sizes'] ?? [];
    final int docDtlId = item['docDtlId'] as int;

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
                    'PO: ${item['PONo'] ?? 'N/A'}',
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
                    'GRN: ${item['GRNNo'] ?? 'N/A'}',
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
              'Shade: ${item['Shade_Name']} | Qty: ${item['Qty']} | Amount: ₹${item['Amount']}',
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
              onPressed: () => _deleteItem(docDtlId),
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
                        'Style Code',
                        item['Style_Code'] ?? 'N/A',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Shade',
                        item['Shade_Name'] ?? 'N/A',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Brand',
                        item['Brand_Name'] ?? 'N/A',
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
                        item['Type_Name'] ?? 'N/A',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Unit',
                        item['Unit_Name'] ?? 'PCS',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Act Qty',
                        item['ActQty']?.toString() ?? '0',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Chln Qty',
                        item['ChlnQty']?.toString() ?? '0',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyFieldCompact(
                        'Rate',
                        '₹${item['Rate']}',
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
                        'Amount',
                        '₹${item['Amount']}',
                      ),
                    ),
                  ],
                ),
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
                          0: FixedColumnWidth(60),
                          1: FixedColumnWidth(60),
                          2: FixedColumnWidth(80),
                          3: FixedColumnWidth(80),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                            ),
                            children: [
                              _buildTableHeaderCell('Size'),
                              _buildTableHeaderCell('Qty'),
                              _buildTableHeaderCell('Cl Qty'),
                              _buildTableHeaderCell('Pur Rate'),
                            ],
                          ),
                          ...sizes.map(
                            (size) => TableRow(
                              children: [
                                _buildTableCell(size['Size_Name'] ?? 'N/A'),
                                _buildTableCell((size['Qty'] ?? 0).toString()),
                                _buildTableCell(
                                  (size['ClQty'] ?? 0).toString(),
                                ),
                                _buildTableCell(
                                  '₹${(size['PurRate'] ?? 0).toStringAsFixed(2)}',
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

  void _deleteItem(int docDtlId) {
    setState(() {
      addedItems.removeWhere((item) => item['docDtlId'] == docDtlId);
      selectedPOReturns.removeWhere((item) => item['docDtlId'] == docDtlId);
      _selectedDocDtlIds =
          selectedPOReturns
              .map<int>((item) => item['docDtlId'] as int)
              .toList();
      _calculateTotals();
    });
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
        items: _getSupplierList().map((e) => e['ledName']!).toList(),
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
            isEnabled ? (val) => onChanged(val, _getKeyFromValue(val)) : null,
        enabled: isEnabled,
      ),
    );
  }

  Widget _buildDiscountTextField() {
    return TextFormField(
      controller: _discPercentCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Disc %',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(6),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        isDense: true,
        suffixText: '%',
        suffixStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
      onChanged: (value) {
        double? newDiscPercent = double.tryParse(value);
        if (newDiscPercent != null) {
          setState(() {
            selectedDiscPercent = newDiscPercent;
            _calculateTotals();
          });
        } else if (value.isEmpty) {
          setState(() {
            selectedDiscPercent = 0;
            _calculateTotals();
          });
        }
      },
    );
  }

  String? _getKeyFromValue(String? value) {
    final list = _getSupplierList();
    return list.firstWhere(
      (e) => e['ledName'] == value,
      orElse: () => {'ledKey': ''},
    )['ledKey'];
  }

  Widget _buildBottomButtons(bool hasItems) {
    // Determine button text based on mode
    String buttonText = _isUpdateMode ? "UPDATE" : "SAVE";
    String savingText = _isUpdateMode ? "Updating..." : "Saving...";

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
                  onPressed: (hasItems && !_isSaving) ? _saveReturn : null,
                  icon:
                      _isSaving
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Icon(Icons.save, size: 20, color: Colors.white),
                  label:
                      _isSaving
                          ? Text(
                            savingText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            buttonText,
                            style: const TextStyle(
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
      maxLines: maxLines,
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
        fillColor: Colors.white,
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

  Widget _buildDropdownField(
    String label,
    List<String> items,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    return DropdownSearch<String>(
      items: items,
      selectedItem: selectedValue,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: AppColors.primaryColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          isDense: true,
        ),
      ),
      onChanged: onChanged,
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: "Search $label",
            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
