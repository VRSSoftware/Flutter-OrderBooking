import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:vrs_erp/PurchaseInward/AddPurchaseInward.dart';

import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/services/production_services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class PurchaseInwardPage extends StatefulWidget {
  final String? inwardId;
  final Map<String, dynamic>? inwardData;

  const PurchaseInwardPage({Key? key, this.inwardId, this.inwardData})
    : super(key: key);

  @override
  _PurchaseInwardPageState createState() => _PurchaseInwardPageState();
}

class PurchaseItem {
  final String categoryKey;
  final String categoryName;
  final String itemKey;
  final String itemName;
  final List<String> styles;
  final List<String> shades;
  final List<String> sizes;
  final List<String> brands;
  final String imageUrl;
  final String styleCode;

  PurchaseItem({
    required this.categoryKey,
    required this.categoryName,
    required this.itemKey,
    required this.itemName,
    required this.styles,
    required this.shades,
    required this.sizes,
    required this.brands,
    this.imageUrl = '',
    required this.styleCode,
  });
}

class CatalogOrderData {
  final PurchaseItem catalog;
  final OrderMatrix orderMatrix;

  CatalogOrderData({required this.catalog, required this.orderMatrix});
}

class OrderMatrix {
  final List<String> shades;
  final List<String> sizes;
  final List<List<String>> matrix;

  OrderMatrix({
    required this.shades,
    required this.sizes,
    required this.matrix,
  });

  factory OrderMatrix.fromJson(Map<String, dynamic> json) {
    return OrderMatrix(
      shades: List<String>.from(json['shades']),
      sizes: List<String>.from(json['sizes']),
      matrix: List<List<String>>.from(
        json['matrix'].map((row) => List<String>.from(row)),
      ),
    );
  }
}

class _PurchaseInwardPageState extends State<PurchaseInwardPage> {
  bool _isUpdateMode = false;

  final TextEditingController _seriesCtrl = TextEditingController(text: '');
  final TextEditingController _lastCdCtrl = TextEditingController(text: '');
  final TextEditingController _docNoCtrl = TextEditingController(text: '');
  final TextEditingController docDtController = TextEditingController();
  final TextEditingController _discPercentCtrl = TextEditingController(
    text: '0',
  );
  final TextEditingController _refNoCtrl = TextEditingController(text: '');
  final TextEditingController _remarkCtrl = TextEditingController(text: '');

  String? selectedSupplierKey;
  String? selectedSupplierName;
  String? selectedStationKey;
  String? selectedStationName;
  String? selectedGrnAgainst = 'PO';

  List<KeyName> supplierList = [];
  List<KeyName> stationList = [];

  List<PurchaseItem> selectedPurchaseItems = [];
  List<CatalogOrderData> catalogOrderList = [];
  List<CatalogOrderData> filteredCatalogOrderList = [];

  Map<String, Map<String, Map<String, int>>> quantities = {};
  Map<String, Set<String>> selectedColors = {};
  Map<String, Map<String, Map<String, TextEditingController>>> controllers = {};

  double grossAmt = 0.0;
  double disc = 0.0;
  double taxAmt = 0.0;
  double otherChrgs = 0.0;
  double netAmt = 0.0;
  bool rdOff = false;
  bool _isSaving = false;
  bool isLoading = true;
  bool isLoadingDetails = false;
  final _formKey = GlobalKey<FormState>();

  final String coBrId = UserSession.coBrId ?? '';
  final String fcYrId = UserSession.userFcYr ?? '';
  final String userId = UserSession.userName ?? '';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _isUpdateMode = widget.inwardId != null && widget.inwardId!.isNotEmpty;
    docDtController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _searchController.addListener(_filterSearchResults);
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterSearchResults);
    _searchController.dispose();
    _seriesCtrl.dispose();
    _lastCdCtrl.dispose();
    _docNoCtrl.dispose();
    docDtController.dispose();
    _discPercentCtrl.dispose();
    _refNoCtrl.dispose();
    _remarkCtrl.dispose();
    for (var styleControllers in controllers.values) {
      for (var shadeControllers in styleControllers.values) {
        for (var controller in shadeControllers.values) {
          controller.dispose();
        }
      }
    }
    super.dispose();
  }

  void _filterSearchResults() {
    final searchTerm = _searchController.text.toLowerCase().trim();
    setState(() {
      if (searchTerm.isEmpty) {
        filteredCatalogOrderList = List.from(catalogOrderList);
      } else {
        filteredCatalogOrderList =
            catalogOrderList
                .where(
                  (item) =>
                      item.catalog.itemName.toLowerCase().contains(searchTerm),
                )
                .toList();
      }
    });
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);

    try {
      await Future.wait([_fetchSuppliers(), _fetchStations()]);

      if (_isUpdateMode && widget.inwardId != null) {
        await _loadInwardData(widget.inwardId!);
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
    final seriesData = await ProductionService.getSeries('1');
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
        setState(() => supplierList = result);
      }
    } catch (e) {
      print('Error fetching suppliers: $e');
    }
  }

  Future<void> _fetchStations() async {
    try {
      final response = await ApiService.fetchStations(coBrId: coBrId);
      if (response['statusCode'] == 200 && response['result'] != null) {
        setState(() => stationList = response['result']);
      }
    } catch (e) {
      print('Error fetching stations: $e');
    }
  }

  Future<void> _loadInwardData(String inwardId) async {
    try {
      final headerResponse = await ApiService.fetchPurchaseInwardHeaderForEdit(
        docId: inwardId,
        coBrId: coBrId,
      );
      if (headerResponse.isNotEmpty) {
        final docNo = headerResponse['Doc_No']?.toString();
        final docDt = headerResponse['Doc_Dt']?.toString();
        final supplierKey = headerResponse['supplier_key']?.toString();
        final stationKey = headerResponse['stn_key']?.toString();
        final supplierName = headerResponse['supplierName']?.toString();
        final discPercent = headerResponse['Disc_Percent']?.toString();
        final refNo = headerResponse['Ref_No']?.toString();
        final remark = headerResponse['Remark']?.toString();
        final grnAgainst = headerResponse['Grn_Against']?.toString();

        setState(() {
          _docNoCtrl.text = docNo ?? '';
          if (docDt != null) docDtController.text = docDt.split('T')[0];
          selectedSupplierKey = supplierKey;
          selectedSupplierName = supplierName;
          selectedStationKey = stationKey;
          _discPercentCtrl.text = discPercent ?? '0';
          _refNoCtrl.text = refNo ?? '';
          _remarkCtrl.text = remark ?? '';
          selectedGrnAgainst = grnAgainst ?? 'PO';
        });

        if (stationKey != null && stationList.isNotEmpty) {
          final station = stationList.firstWhere(
            (s) => s.key == stationKey,
            orElse: () => KeyName(key: '', name: ''),
          );
          if (station.name.isNotEmpty)
            setState(() => selectedStationName = station.name);
        }
      }
    } catch (e) {
      print('Error loading inward data: $e');
    }
  }

  Future<void> _loadOrderDetailsForItem(PurchaseItem item) async {
    setState(() => isLoadingDetails = true);

    final payload = {
      "itemSubGrpKey": item.categoryKey,
      "itemKey": item.itemKey,
      "styleKey": item.itemKey,
      "userId": userId,
      "coBrId": coBrId,
      "fcYrId": fcYrId,
    };

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/catalog/GetOrderDetails2'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final orderMatrix = OrderMatrix.fromJson(data);

        catalogOrderList.add(
          CatalogOrderData(catalog: item, orderMatrix: orderMatrix),
        );

        final styleKey = item.itemKey;
        selectedColors[styleKey] = orderMatrix.shades.toSet();

        quantities[styleKey] = {};
        controllers[styleKey] = {};
        for (var shade in selectedColors[styleKey]!) {
          quantities[styleKey]![shade] = {};
          controllers[styleKey]![shade] = {};
          for (var size in orderMatrix.sizes) {
            quantities[styleKey]![shade]![size] = 0;
            final controller = TextEditingController(text: '0');
            controllers[styleKey]![shade]![size] = controller;
          }
        }

        filteredCatalogOrderList = List.from(catalogOrderList);
        _calculateTotals();
      }
    } catch (e) {
      debugPrint('Error fetching order details for ${item.itemName}: $e');
    } finally {
      setState(() => isLoadingDetails = false);
    }
  }

  void _calculateTotals() {
    double totalGross = 0.0;
    for (var catalogData in catalogOrderList) {
      final styleKey = catalogData.catalog.itemKey;
      final styleQuantities = quantities[styleKey] ?? {};
      final orderMatrix = catalogData.orderMatrix;

      for (var shade in styleQuantities.keys) {
        final shadeQuantities = styleQuantities[shade] ?? {};
        for (var size in shadeQuantities.keys) {
          final qty = shadeQuantities[size] ?? 0;
          if (qty > 0) {
            final shadeIndex = orderMatrix.shades.indexOf(shade);
            final sizeIndex = orderMatrix.sizes.indexOf(size);
            if (shadeIndex != -1 && sizeIndex != -1) {
              final matrixData = orderMatrix.matrix[shadeIndex][sizeIndex]
                  .split(',');
              final wsp =
                  double.tryParse(
                    matrixData.length > 1 ? matrixData[1] : matrixData[0],
                  ) ??
                  0;
              totalGross += wsp * qty;
            }
          }
        }
      }
    }

    setState(() {
      grossAmt = totalGross;
      double discPercent = double.tryParse(_discPercentCtrl.text) ?? 0;
      disc = grossAmt * discPercent / 100;
      double calculatedNet = grossAmt - disc + taxAmt + otherChrgs;
      netAmt = rdOff ? calculatedNet.roundToDouble() : calculatedNet;
    });
  }

  void _handleSupplierSelection(String? val, String? key) async {
    if (key == null) return;
    setState(() {
      selectedSupplierName = val;
      selectedSupplierKey = key;
    });
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

  Future<void> _saveInward() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      Map<String, dynamic> data2Map = {
        "inwarddate": "${docDtController.text} 18:58:15",
        "supplier": selectedSupplierKey ?? '',
        "station": selectedStationKey ?? '',
        "discpercent": _discPercentCtrl.text,
        "refno": _refNoCtrl.text,
        "remark": _remarkCtrl.text,
        "grnagainst": selectedGrnAgainst ?? 'PO',
        "grossAmount": grossAmt.toStringAsFixed(2),
        "discount": disc.toStringAsFixed(2),
        "roundOff": rdOff,
        "roundOffAmount":
            rdOff
                ? (netAmt - grossAmt + disc - taxAmt - otherChrgs)
                    .abs()
                    .toStringAsFixed(2)
                : "0",
        "netAmount": netAmt.toStringAsFixed(2),
        "doc_id": _isUpdateMode ? (widget.inwardId ?? "-1") : "-1",
      };

      Map<String, dynamic> response;
      if (_isUpdateMode) {
        final int docId = int.tryParse(widget.inwardId ?? '0') ?? 0;
        final Map<String, dynamic> updateData = {
          "userId": userId,
          "login_id": userId,
          "coBr_id": coBrId,
          "coBrId": coBrId,
          "fcYr_id": fcYrId,
          "fcYrId": fcYrId,
          "docId": docId,
          "supplierKey": selectedSupplierKey ?? '',
          "data2": jsonEncode(data2Map),
        };
        response = await ApiService.updatePurchaseInward(updateData);
      } else {
        final Map<String, dynamic> saveData = {
          "userId": userId,
          "login_id": userId,
          "coBr_id": coBrId,
          "coBrId": coBrId,
          "fcYr_id": fcYrId,
          "fcYrId": fcYrId,
          "docId": 0,
          "supplierKey": selectedSupplierKey ?? '',
          "data2": jsonEncode(data2Map),
        };
        response = await ApiService.savePurchaseInward(saveData);
      }

      if (response['status'] == 'success') {
        String docNo =
            response['docNo']?.toString() ??
            response['message']?.toString() ??
            _docNoCtrl.text;
        _showSuccessDialog(docNo);
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to save inward');
      }
    } catch (e) {
      print('Error saving inward: $e');
      _showErrorSnackBar('Error saving inward: $e');
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
                                text: _isUpdateMode ? 'Inward ' : 'Inward ',
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

  void _onFloatingButtonPressed() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                AddPurchaseInwardItem(supplierKey: selectedSupplierKey),
      ),
    );

    if (result != null && result is List && result.isNotEmpty) {
      setState(() => isLoadingDetails = true);

      for (var itemData in result) {
        final categoryKey = itemData['categoryKey'] ?? '';
        final categoryName = itemData['categoryName'] ?? '';
        final itemKey = itemData['itemKey'] ?? '';
        final itemName = itemData['itemName'] ?? '';
        final styles = List<String>.from(itemData['styles'] ?? []);

        // For each selected style, make API call
        for (var styleCode in styles) {
          await _fetchAndAddItem(
            categoryKey,
            categoryName,
            itemKey,
            itemName,
            styleCode,
          );
        }
      }

      setState(() => isLoadingDetails = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item(s) added successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _fetchAndAddItem(
    String categoryKey,
    String categoryName,
    String itemKey,
    String itemName,
    String styleKey,
  ) async {
    try {
      final data = await ApiService.fetchOrderDetails(
        itemSubGrpKey: categoryKey,
        itemKey: itemKey,
        styleKey: styleKey,
        userId: userId,
        coBrId: coBrId,
        fcYrId: fcYrId,
      );

      print('API Response for $styleKey: $data'); // Debug print

      final orderMatrix = OrderMatrix.fromJson(data);

      print('Shades: ${orderMatrix.shades}'); // Debug print
      print('Sizes: ${orderMatrix.sizes}'); // Debug print

      final purchaseItem = PurchaseItem(
        categoryKey: categoryKey,
        categoryName: categoryName,
        itemKey: itemKey,
        itemName: itemName,
        styles: [styleKey],
        shades: orderMatrix.shades,
        sizes: orderMatrix.sizes,
        brands: [],
        imageUrl: '',
        styleCode: styleKey,
      );

      setState(() {
        // Add to catalog list
        catalogOrderList.add(
          CatalogOrderData(catalog: purchaseItem, orderMatrix: orderMatrix),
        );

        // IMPORTANT: Initialize selectedColors for this style
        if (!selectedColors.containsKey(styleKey)) {
          selectedColors[styleKey] = {};
        }
        // Add all shades from orderMatrix
        selectedColors[styleKey]!.addAll(orderMatrix.shades);

        // Initialize quantities and controllers
        if (!quantities.containsKey(styleKey)) {
          quantities[styleKey] = {};
        }
        if (!controllers.containsKey(styleKey)) {
          controllers[styleKey] = {};
        }

        // Initialize for each shade and size
        for (var shade in orderMatrix.shades) {
          if (!quantities[styleKey]!.containsKey(shade)) {
            quantities[styleKey]![shade] = {};
          }
          if (!controllers[styleKey]!.containsKey(shade)) {
            controllers[styleKey]![shade] = {};
          }
          for (var size in orderMatrix.sizes) {
            if (!quantities[styleKey]![shade]!.containsKey(size)) {
              quantities[styleKey]![shade]![size] = 0;
            }
            if (controllers[styleKey]![shade]![size] == null) {
              final controller = TextEditingController(text: '0');
              controllers[styleKey]![shade]![size] = controller;
            }
          }
        }

        print(
          'SelectedColors for $styleKey: ${selectedColors[styleKey]}',
        ); // Debug print
        print(
          'Quantities for $styleKey: ${quantities[styleKey]}',
        ); // Debug print

        filteredCatalogOrderList = List.from(catalogOrderList);
        _calculateTotals();
      });
    } catch (e) {
      debugPrint('Error fetching order details for $itemName - $styleKey: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load details for $itemName - $styleKey'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeItem(String styleKey) {
    setState(() {
      catalogOrderList.removeWhere(
        (catalog) => catalog.catalog.styleCode == styleKey,
      );
      filteredCatalogOrderList.removeWhere(
        (catalog) => catalog.catalog.styleCode == styleKey,
      );
      quantities.remove(styleKey);
      controllers.remove(styleKey);
      selectedColors.remove(styleKey);
      _calculateTotals();
    });
  }

  void _updateQuantity(String styleKey, String shade, String size, int newQty) {
    setState(() {
      if (quantities[styleKey] != null &&
          quantities[styleKey]![shade] != null) {
        quantities[styleKey]![shade]![size] = newQty;
        controllers[styleKey]![shade]![size]?.text = newQty.toString();
        _calculateTotals();
      }
    });
  }

  void _addShade(
    String styleKey,
    String newShade,
    CatalogOrderData catalogData,
  ) {
    setState(() {
      if (!selectedColors.containsKey(styleKey)) selectedColors[styleKey] = {};
      selectedColors[styleKey]!.add(newShade);
      if (!quantities.containsKey(styleKey)) quantities[styleKey] = {};
      if (!quantities[styleKey]!.containsKey(newShade))
        quantities[styleKey]![newShade] = {};
      if (!controllers.containsKey(styleKey)) controllers[styleKey] = {};
      if (!controllers[styleKey]!.containsKey(newShade))
        controllers[styleKey]![newShade] = {};
      for (var size in catalogData.orderMatrix.sizes) {
        quantities[styleKey]![newShade]![size] = 0;
        controllers[styleKey]![newShade]![size] = TextEditingController(
          text: '0',
        );
      }
      _calculateTotals();
    });
  }

  void _removeShade(String styleKey, String shade) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Shade'),
            content: Text('Are you sure you want to remove shade "$shade"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedColors[styleKey]?.remove(shade);
                    quantities[styleKey]?.remove(shade);
                    controllers[styleKey]?.remove(shade);
                    _calculateTotals();
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Shade "$shade" removed'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _updateItem(CatalogOrderData catalogData) async {
    final styleKey = catalogData.catalog.itemKey;
    int totalQty = 0;
    for (var shadeQuantities in (quantities[styleKey] ?? {}).values) {
      for (var qty in shadeQuantities.values) totalQty += qty;
    }
    if (totalQty <= 0) {
      _showValidationDialog(
        'Validation Error',
        'Total quantity must be greater than zero',
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await Future.delayed(Duration(seconds: 1));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  List<String> _getAvailableShades(CatalogOrderData catalogData) {
    final allShades = catalogData.orderMatrix.shades;
    // Use styleCode, NOT itemKey
    final existingShades = selectedColors[catalogData.catalog.styleCode] ?? {};
    return allShades.where((shade) => !existingShades.contains(shade)).toList();
  }

  @override
  Widget build(BuildContext context) {
    double _calculateTotalAmount() {
      double total = 0.0;
      for (var catalogData in catalogOrderList) {
        final styleKey = catalogData.catalog.itemKey;
        final styleQuantities = quantities[styleKey] ?? {};
        final orderMatrix = catalogData.orderMatrix;
        for (var shade in styleQuantities.keys) {
          final shadeQuantities = styleQuantities[shade] ?? {};
          for (var size in shadeQuantities.keys) {
            final qty = shadeQuantities[size] ?? 0;
            if (qty > 0) {
              final shadeIndex = orderMatrix.shades.indexOf(shade);
              final sizeIndex = orderMatrix.sizes.indexOf(size);
              if (shadeIndex != -1 && sizeIndex != -1) {
                final matrixData = orderMatrix.matrix[shadeIndex][sizeIndex]
                    .split(',');
                final wsp =
                    double.tryParse(
                      matrixData.length > 1 ? matrixData[1] : matrixData[0],
                    ) ??
                    0;
                total += wsp * qty;
              }
            }
          }
        }
      }
      return total;
    }

    int _calculateTotalQuantity() {
      int total = 0;
      for (var styleQuantities in quantities.values) {
        for (var shadeQuantities in styleQuantities.values) {
          for (var qty in shadeQuantities.values) total += qty;
        }
      }
      return total;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title:
            _isSearching
                ? Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryColor,
                    ),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: "Search by item name...",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      isDense: true,
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: AppColors.primaryColor,
                      ),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppColors.primaryColor,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _isSearching = false;
                                  _filterSearchResults();
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              )
                              : null,
                    ),
                  ),
                )
                : const Text(
                  'Purchase Inward',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
        actions: [
          if (!_isSearching && catalogOrderList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => setState(() => _isSearching = true),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            color: AppColors.primaryColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Total: ₹${_calculateTotalAmount().toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.white.withOpacity(0.5),
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                ),
                Flexible(
                  child: Text(
                    'Items: ${catalogOrderList.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.white.withOpacity(0.5),
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                ),
                Flexible(
                  child: Text(
                    'Qty: ${_calculateTotalQuantity()}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body:
          isLoading || isLoadingDetails
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
                              "Supplier",
                              supplierList,
                              selectedSupplierName,
                              (val, key) => _handleSupplierSelection(val, key),
                              isRequired: true,
                              isEnabled: !_isUpdateMode,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDropdown(
                                    "Station",
                                    stationList,
                                    selectedStationName,
                                    (val, key) => setState(() {
                                      selectedStationName = val;
                                      selectedStationKey = key;
                                    }),
                                    isRequired: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    'Ref No',
                                    _refNoCtrl,
                                    isRequired: false,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    'Disc %',
                                    _discPercentCtrl,
                                    isRequired: false,
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) => _calculateTotals(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: _buildGrnAgainstDropdown()),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              'Remark',
                              _remarkCtrl,
                              isRequired: false,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 24),

                            if (catalogOrderList.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ...filteredCatalogOrderList.map(
                                (catalogData) => _buildItemCard(catalogData),
                              ),
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
                                      onChanged:
                                          (value) => setState(() {
                                            rdOff = value ?? false;
                                            _calculateTotals();
                                          }),
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
                  _buildBottomButtons(),
                ],
              ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40), // move a little up
        child: FloatingActionButton(
          heroTag: 'add',
          onPressed: _onFloatingButtonPressed,
          backgroundColor: AppColors.primaryColor,
          child: const Icon(
            Icons.add,
            size: 30,
            color: Colors.white, // icon color white
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  //---

  Widget _buildItemCard(CatalogOrderData catalogData) {
    final item = catalogData.catalog;
    final styleKey = item.styleCode; // Use styleCode, NOT item.itemKey
    final shades = selectedColors[styleKey] ?? {};
    final availableShades = _getAvailableShades(catalogData);

    int totalQty = 0;
    double totalAmount = 0;
    final styleQuantities = quantities[styleKey] ?? {};
    final orderMatrix = catalogData.orderMatrix;

    for (var shade in styleQuantities.keys) {
      final shadeQuantities = styleQuantities[shade] ?? {};
      for (var size in shadeQuantities.keys) {
        final qty = shadeQuantities[size] ?? 0;
        if (qty > 0) {
          totalQty += qty;
          final shadeIndex = orderMatrix.shades.indexOf(shade);
          final sizeIndex = orderMatrix.sizes.indexOf(size);
          if (shadeIndex != -1 && sizeIndex != -1) {
            final matrixData = orderMatrix.matrix[shadeIndex][sizeIndex].split(
              ',',
            );
            final wsp =
                double.tryParse(
                  matrixData.length > 1 ? matrixData[1] : matrixData[0],
                ) ??
                0;
            totalAmount += wsp * qty;
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: GestureDetector(
                      onTap: () {
                        final imageUrl = item.imageUrl;
                        if (imageUrl.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ImageZoomScreen(
                                    imageUrls: [imageUrl],
                                    initialIndex: 0,
                                  ),
                            ),
                          );
                        }
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          item.imageUrl.isNotEmpty
                              ? Image.network(
                                item.imageUrl,
                                fit: BoxFit.contain,
                                loadingBuilder:
                                    (context, child, loadingProgress) =>
                                        loadingProgress == null
                                            ? child
                                            : Container(
                                              color: Colors.grey.shade100,
                                              child: Center(
                                                child: SizedBox(
                                                  width: 25,
                                                  height: 25,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(
                                                          AppColors
                                                              .primaryColor,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      color: Colors.grey.shade100,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.broken_image,
                                              size: 25,
                                              color: Colors.grey.shade400,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'No Image',
                                              style: TextStyle(
                                                fontSize: 8,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              )
                              : Container(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.zoom_in,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.itemName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.red.shade900,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Style: ${item.styleCode}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap:
                                () =>
                                    _removeItem(styleKey), // Use styleKey here
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              Icons.inventory,
                              'Type',
                              'Ready',
                              Colors.blue,
                            ),
                            _buildDivider(),
                            _buildStatItem(
                              Icons.storage,
                              'Stock',
                              '0',
                              Colors.green,
                            ),
                            _buildDivider(),
                            _buildStatItem(
                              Icons.shopping_bag,
                              'Order',
                              totalQty.toString(),
                              Colors.orange,
                            ),
                            _buildDivider(),
                            _buildStatItem(
                              Icons.currency_rupee,
                              'Amount',
                              '₹${totalAmount.toStringAsFixed(0)}',
                              Colors.purple,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                ...shades.map(
                  (shade) => _buildShadeSection(catalogData, shade),
                ),
                if (availableShades.isNotEmpty)
                  _buildAddShadeButton(catalogData, availableShades),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    MaterialColor color,
  ) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: color.shade700),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: Colors.grey.shade300);
  }

  Widget _buildShadeSection(CatalogOrderData catalogData, String shade) {
    final orderMatrix = catalogData.orderMatrix;
    final styleKey = catalogData.catalog.styleCode;
    final sizes = orderMatrix.sizes;
    final Color shadeColor = _getColorFromShade(shade);

    int shadeTotalQty = 0;
    double shadeTotalPrice = 0;
    final styleQuantities = quantities[styleKey] ?? {};
    final shadeQuantities = styleQuantities[shade] ?? {};

    for (var size in sizes) {
      final qty = shadeQuantities[size] ?? 0;
      if (qty > 0) {
        shadeTotalQty += qty;
        final shadeIndex = orderMatrix.shades.indexOf(shade);
        final sizeIndex = orderMatrix.sizes.indexOf(size);
        if (shadeIndex != -1 && sizeIndex != -1) {
          final matrixData = orderMatrix.matrix[shadeIndex][sizeIndex].split(
            ',',
          );
          final wsp =
              double.tryParse(
                matrixData.length > 1 ? matrixData[1] : matrixData[0],
              ) ??
              0;
          shadeTotalPrice += wsp * qty;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // First header row: Shade, Quantity, Price
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 8.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Text(
                    "Shade",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Text(
                    "Quantity",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Amount",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 1, color: Colors.grey.shade300),

          // Second row: Shade name with its total quantity and price
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 8.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Text(
                    shade,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: shadeColor,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Text(
                    shadeTotalQty.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(fontSize: 14),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    '${shadeTotalPrice.toStringAsFixed(2)}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 1, color: Colors.grey.shade300),

          // Third header row: Size, Qty, Rate, WSP, Stock
          Row(
            children: [
              _buildHeader("Size", 1),
              _buildHeader("Qty", 2),
              _buildHeader("Rate", 1),
              _buildHeader("WSP", 1),
              _buildHeader("Stock", 1),
            ],
          ),
          Divider(height: 1, color: Colors.grey.shade300),

          // Size rows
          for (var size in sizes) ...[
            _buildSizeRow(catalogData, shade, size),
            if (size != sizes.last)
              Divider(height: 1, color: Colors.grey.shade300),
          ],

          Divider(height: 1, color: Colors.grey.shade300),

          // Delete and Update buttons BELOW the table (at the bottom of the shade section)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _removeShade(styleKey, shade),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: Colors.red.shade600),
                    ),
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red.shade600,
                      size: 18,
                    ),
                    label: Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _updateItem(catalogData),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: AppColors.primaryColor),
                      backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                    ),
                    icon: Icon(
                      Icons.save,
                      color: AppColors.primaryColor,
                      size: 18,
                    ),
                    label: Text(
                      'Update',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.lora(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.red.shade900,
          ),
        ),
      ),
    );
  }

  Widget _buildSizeRow(
    CatalogOrderData catalogData,
    String shade,
    String size,
  ) {
    final orderMatrix = catalogData.orderMatrix;
    final styleKey = catalogData.catalog.styleCode;
    final shadeIndex = orderMatrix.shades.indexOf(shade);
    final sizeIndex = orderMatrix.sizes.indexOf(size);

    String rate = '';
    String wsp = '';
    String stock = '0';
    TextEditingController? controller;

    if (shadeIndex != -1 && sizeIndex != -1) {
      final matrixData = orderMatrix.matrix[shadeIndex][sizeIndex].split(',');
      rate = matrixData[0];
      wsp = matrixData.length > 1 ? matrixData[1] : '0';
      stock = matrixData.length > 2 ? matrixData[2] : '0';
      controller = controllers[styleKey]?[shade]?[size];
    }

    final quantity = quantities[styleKey]?[shade]?[size] ?? 0;

    return Row(
      children: [
        _buildCell(size, 1),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    final newQuantity = (quantity - 1).clamp(0, 9999);
                    if (quantities[styleKey] != null &&
                        quantities[styleKey]![shade] != null) {
                      setState(() {
                        quantities[styleKey]![shade]![size] = newQuantity;
                        controller?.text = newQuantity.toString();
                      });
                      _calculateTotals();
                    }
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    child: const Icon(Icons.remove, size: 16),
                  ),
                ),
                SizedBox(
                  width: 45,
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 2,
                      ),
                    ),
                    style: GoogleFonts.roboto(fontSize: 12),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    onChanged: (value) {
                      final newQuantity =
                          int.tryParse(value.isEmpty ? '0' : value) ?? 0;
                      if (quantities[styleKey] != null &&
                          quantities[styleKey]![shade] != null) {
                        setState(() {
                          quantities[styleKey]![shade]![size] = newQuantity
                              .clamp(0, 999);
                        });
                        _calculateTotals();
                      }
                    },
                  ),
                ),
                InkWell(
                  onTap: () {
                    final newQuantity = (quantity + 1).clamp(0, 9999);
                    if (quantities[styleKey] != null &&
                        quantities[styleKey]![shade] != null) {
                      setState(() {
                        quantities[styleKey]![shade]![size] = newQuantity;
                        controller?.text = newQuantity.toString();
                      });
                      _calculateTotals();
                    }
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    child: const Icon(Icons.add, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildCell(rate, 1),
        _buildCell(wsp, 1),
        _buildCell(stock, 1),
      ],
    );
  }

  Widget _buildCell(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildAddShadeButton(
    CatalogOrderData catalogData,
    List<String> availableShades,
  ) {
    final styleKey =
        catalogData.catalog.styleCode; // Use styleCode, not itemKey
    final styleQuantities = quantities[styleKey] ?? {};

    final Map<String, bool> shadeHasQuantity = {};
    for (var shade in catalogData.orderMatrix.shades) {
      final hasQty =
          styleQuantities[shade]?.values.any((qty) => qty > 0) ?? false;
      shadeHasQuantity[shade] = hasQty;
    }

    return Container(
      width: double.infinity,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.9),
            AppColors.primaryColor,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              () => _showAddShadeDialog(
                catalogData,
                availableShades,
                shadeHasQuantity,
              ),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Add Shade',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.7),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddShadeDialog(
    CatalogOrderData catalogData,
    List<String> availableShades,
    Map<String, bool> shadeHasQuantity,
  ) {
    final styleKey = catalogData.catalog.styleCode;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              Set<String> selectedShades = {};

              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  constraints: const BoxConstraints(
                    maxWidth: 380,
                    maxHeight: 480,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.color_lens,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Add Shades',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    catalogData.catalog.itemName,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            Text(
                              'Select shades to add',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: availableShades.length,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemBuilder: (context, index) {
                              final shade = availableShades[index];
                              final hasQuantity =
                                  shadeHasQuantity[shade] ?? false;
                              // Calculate isSelected INSIDE the itemBuilder so it updates
                              final isSelected = selectedShades.contains(shade);

                              return Opacity(
                                opacity: hasQuantity ? 0.6 : 1.0,
                                child: AbsorbPointer(
                                  absorbing: hasQuantity,
                                  child: Material(
                                    color:
                                        isSelected && !hasQuantity
                                            ? AppColors.primaryColor
                                                .withOpacity(0.05)
                                            : Colors.transparent,
                                    child: InkWell(
                                      onTap:
                                          hasQuantity
                                              ? null
                                              : () {
                                                setDialogState(() {
                                                  if (selectedShades.contains(
                                                    shade,
                                                  )) {
                                                    selectedShades.remove(
                                                      shade,
                                                    );
                                                  } else {
                                                    selectedShades.add(shade);
                                                  }
                                                });
                                              },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color:
                                                    hasQuantity
                                                        ? Colors.green
                                                            .withOpacity(0.1)
                                                        : (isSelected
                                                            ? AppColors
                                                                .primaryColor
                                                            : Colors
                                                                .transparent),
                                                border: Border.all(
                                                  color:
                                                      hasQuantity
                                                          ? Colors
                                                              .green
                                                              .shade300
                                                          : (isSelected
                                                              ? Colors
                                                                  .transparent
                                                              : Colors
                                                                  .grey
                                                                  .shade400),
                                                  width: 1.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              child:
                                                  hasQuantity
                                                      ? Icon(
                                                        Icons.check,
                                                        color:
                                                            Colors
                                                                .green
                                                                .shade600,
                                                        size: 14,
                                                      )
                                                      : (isSelected
                                                          ? const Icon(
                                                            Icons.check,
                                                            color: Colors.white,
                                                            size: 14,
                                                          )
                                                          : null),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                shade,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      isSelected && !hasQuantity
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                  color:
                                                      hasQuantity
                                                          ? Colors.grey.shade500
                                                          : _getColorFromShade(
                                                            shade,
                                                          ),
                                                ),
                                              ),
                                            ),
                                            if (hasQuantity)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'Added',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        Colors.green.shade700,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    selectedShades.isEmpty
                                        ? null
                                        : () {
                                          for (var shade in selectedShades) {
                                            _addShade(
                                              styleKey,
                                              shade,
                                              catalogData,
                                            );
                                          }
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${selectedShades.length} shade(s) added',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  selectedShades.isEmpty
                                      ? 'Add Shades'
                                      : 'Add (${selectedShades.length})',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color:
                                        selectedShades.isEmpty
                                            ? Colors.grey.shade600
                                            : Colors.white,
                                  ),
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
            },
          ),
    );
  }

  Color _getColorFromShade(String shade) {
    switch (shade.toLowerCase()) {
      case 'red':
        return Colors.red.shade700;
      case 'green':
        return Colors.green.shade700;
      case 'blue':
        return Colors.blue.shade700;
      case 'yellow':
        return Colors.amber.shade800;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.grey.shade700;
      case 'purple':
        return Colors.purple.shade700;
      case 'orange':
        return Colors.orange.shade700;
      case 'pink':
        return Colors.pink.shade700;
      case 'brown':
        return Colors.brown.shade700;
      default:
        return AppColors.primaryColor;
    }
  }

  Widget _buildDropdown(
    String label,
    List<KeyName> items,
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
        items: items.map((e) => e.name).toList(),
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
                  if (val != null) {
                    final selectedKey =
                        items
                            .firstWhere(
                              (e) => e.name == val,
                              orElse: () => KeyName(key: '', name: ''),
                            )
                            .key;
                    onChanged(val, selectedKey);
                  }
                }
                : null,
        enabled: isEnabled,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator:
            (value) =>
                isRequired && (value == null || value.isEmpty)
                    ? "$label is required"
                    : null,
        onChanged: onChanged,
        decoration: InputDecoration(
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
        ),
      ),
    );
  }

  Widget _buildGrnAgainstDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownSearch<String>(
        items: ['PO', 'GRN'],
        selectedItem: selectedGrnAgainst,
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: 'GRN Against',
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
          ),
        ),
        onChanged: (value) => setState(() => selectedGrnAgainst = value),
      ),
    );
  }

  Widget _buildBottomButtons() {
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
                  onPressed: () {},
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
                  onPressed: !_isSaving ? _saveInward : null,
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
                    backgroundColor: AppColors.primaryColor,
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
        if (pickedDate != null)
          setState(
            () => controller.text = DateFormat('yyyy-MM-dd').format(pickedDate),
          );
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

class ImageZoomScreen extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageZoomScreen({
    Key? key,
    required this.imageUrls,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: PageView.builder(
          controller: PageController(initialPage: initialIndex),
          itemCount: imageUrls.length,
          itemBuilder: (context, index) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.contain,
                errorBuilder:
                    (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
              ),
            );
          },
        ),
      ),
    );
  }
}
