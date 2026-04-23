// packing_list_without_so_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_search/dropdown_search.dart';
import 'package:vrs_erp/OrderBooking/order_booking.dart';
import 'package:vrs_erp/catalog/imagezoom.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/constants/constants.dart';
import 'package:vrs_erp/models/CatalogOrderData.dart';
import 'package:vrs_erp/models/OrderMatrix.dart';
import 'package:vrs_erp/models/PytTermDisc.dart';
import 'package:vrs_erp/models/catalog.dart';
import 'package:vrs_erp/models/consignee.dart';
import 'package:vrs_erp/models/item.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_data.dart';
import 'package:vrs_erp/viewOrder/view_order_screen2.dart';
// packing_list_without_so_screen.dart

class PackingListWithoutSOScreen extends StatefulWidget {
  final int? docId;
  final List<Catalog>? catalogs;
  final Map<String, dynamic>? routeArguments;

  const PackingListWithoutSOScreen({
    Key? key,
    this.docId,
    this.catalogs,
    this.routeArguments,
  }) : super(key: key);

  @override
  _PackingListWithoutSOScreenState createState() =>
      _PackingListWithoutSOScreenState();
}

class _PackingListWithoutSOScreenState
    extends State<PackingListWithoutSOScreen> {
  // ==================== FORM & CONTROLLERS ====================
  final _formKey = GlobalKey<FormState>();
  final _orderControllers = _PackingListControllers();
  final _dropdownData = _PackingListDropdownData();

  // ==================== DATA LISTS ====================
  List<Consignee> consignees = [];
  List<PytTermDisc> paymentTerms = [];
  List<Item> _bookingTypes = [];

  // ==================== STATE FLAGS ====================
  bool isLoading = true;
  bool _isSaving = false;
  bool _isMatrixLoading = false;
  bool _isEditMode = false;

  // ==================== ADDITIONAL INFO ====================
  Map<String, dynamic> _additionalInfo = {};

  // ==================== MATRIX DATA ====================
  List<CatalogOrderData> catalogOrderList = [];
  Map<String, Set<String>> selectedColors2 = {};
  Map<String, Map<String, Map<String, int>>> quantities = {};
  final Map<String, TextEditingController> _controllers = {};

  // ==================== SELECTED ITEMS (BUILT FROM MATRIX) ====================
  List<Map<String, dynamic>> _selectedItems = [];

  // ==================== AMOUNT CALCULATION ====================
  bool _roundOff = false;
  double _roundOffAmount = 0.0;

  // ==================== LIFECYCLE ====================
  @override
  void initState() {
    super.initState();
    _isEditMode = EditOrderData.doc_id.isNotEmpty;

    if (!_isEditMode) {
      EditOrderData.clear();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _controllers.forEach((_, ctrl) => ctrl.dispose());
    super.dispose();
  }

  // ==================== INITIALIZATION ====================
  Future<void> _initializeData() async {
    setState(() => isLoading = true);

    await _dropdownData.loadAllDropdownData();
    await _loadBookingTypes();
    await _loadPaymentTerms();

    // Store dropdown lists in EditOrderData for persistence
    EditOrderData.brokerList = _dropdownData.brokerList;
    EditOrderData.transporterList = _dropdownData.transporterList;

    if (_isEditMode) {
      await _loadEditData();
    } else {
      _setDefaultDates();
      if (widget.catalogs != null && widget.catalogs!.isNotEmpty) {
        await _loadCatalogOrderDetails(widget.catalogs!);
      }
    }

    setState(() => isLoading = false);
  }

  Future<void> _loadPaymentTerms() async {
    final response = await ApiService.fetchPayTerms(
      coBrId: UserSession.coBrId ?? '',
    );
    if (response['result'] != null && response['result'] is List) {
      setState(() {
        paymentTerms =
            (response['result'] as List)
                .map((e) => PytTermDisc(key: e.key, name: e.name))
                .toList();
      });
    }
  }

  Future<void> _loadBookingTypes() async {
    try {
      final rawData = await ApiService.fetchBookingTypes(
        coBrId: UserSession.coBrId ?? '',
      );
      setState(() {
        _bookingTypes =
            (rawData as List)
                .map(
                  (json) => Item(
                    itemKey: json['key'],
                    itemName: json['name'],
                    itemSubGrpKey: '',
                  ),
                )
                .toList();
      });
    } catch (e) {
      print('Failed to load booking types: $e');
    }
  }

  void _setDefaultDates() {
    final today = DateTime.now();
    _orderControllers.date.text = _PackingListControllers.formatDate(today);
    _orderControllers.deliveryDate.text = _PackingListControllers.formatDate(
      today,
    );
    _orderControllers.deliveryDays.text = '0';
  }

  // ==================== EDIT MODE: LOAD FROM EditOrderData ====================
  Future<void> _loadEditData() async {
    setState(() {
      _orderControllers.date.text =
          EditOrderData.deliveryDate.isNotEmpty
              ? EditOrderData.deliveryDate
              : _PackingListControllers.formatDate(DateTime.now());
      _orderControllers.selectedParty = EditOrderData.partyName;
      _orderControllers.selectedPartyKey = EditOrderData.partyKey;
      _orderControllers.selectedPartyName = EditOrderData.partyName;
      _orderControllers.selectedBroker = EditOrderData.brokerName;
      _orderControllers.selectedBrokerKey = EditOrderData.brokerKey;
      _orderControllers.selectedTransporter = EditOrderData.transporterName;
      _orderControllers.selectedTransporterKey = EditOrderData.transporterKey;
      _orderControllers.comm.text = EditOrderData.commission;
      _orderControllers.deliveryDays.text = EditOrderData.deliveryDays;
      _orderControllers.deliveryDate.text = EditOrderData.deliveryDate;
      _orderControllers.remark.text = EditOrderData.remark;
    });

    if (EditOrderData.partyKey.isNotEmpty) {
      await fetchAndMapConsignees(key: EditOrderData.partyKey);
    }
    setState(() {
      consignees = EditOrderData.consignees;
    });

    setState(() {
      catalogOrderList = EditOrderData.data;
    });
    _rebuildMatrixFromCatalogOrderData();
    _restoreQuantitiesFromEditOrderData();

    if (EditOrderData.detailsForEdit.isNotEmpty) {
      try {
        final stored = jsonDecode(EditOrderData.detailsForEdit);
        if (stored['additionalInfo'] != null) {
          _additionalInfo = Map<String, dynamic>.from(stored['additionalInfo']);
        }
      } catch (_) {}
    }

    _dropdownData.brokerList = EditOrderData.brokerList;
    _dropdownData.transporterList = EditOrderData.transporterList;
  }

  void _rebuildMatrixFromCatalogOrderData() {
    selectedColors2.clear();
    quantities.clear();
    for (var order in catalogOrderList) {
      final styleKey = order.catalog.styleKey;
      selectedColors2[styleKey] =
          order.catalog.shadeName.split(',').map((e) => e.trim()).toSet();
      quantities[styleKey] = {};
      for (var shade in selectedColors2[styleKey]!) {
        quantities[styleKey]![shade] = {};
      }
    }
  }

  // ==================== LOAD CATALOG MATRIX ====================
  Future<void> _loadCatalogOrderDetails(
    List<Catalog> catalogs, {
    bool append = false,
  }) async {
    if (!append) {
      setState(() {
        catalogOrderList.clear();
        selectedColors2.clear();
        quantities.clear();
        _controllers.clear();
      });
    }

    setState(() => _isMatrixLoading = true);
    final List<CatalogOrderData> newItems = [];

    for (var item in catalogs) {
      final payload = {
        "itemSubGrpKey": item.itemSubGrpKey,
        "itemKey": item.itemKey,
        "styleKey": item.styleKey,
        "userId": UserSession.userName ?? '',
        "coBrId": UserSession.coBrId ?? '',
        "fcYrId": UserSession.userFcYr ?? '',
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
          final catalogOrder = CatalogOrderData(
            catalog: item,
            orderMatrix: orderMatrix,
          );
          newItems.add(catalogOrder);

          selectedColors2[item.styleKey] =
              item.shadeName.split(',').map((e) => e.trim()).toSet();

          quantities[item.styleKey] = {};
          for (var shade in selectedColors2[item.styleKey]!) {
            quantities[item.styleKey]![shade] = {};
          }
        } else {
          debugPrint(
            'Failed to fetch order details for ${item.styleKey}: ${response.statusCode}',
          );
          _showErrorSnackBar('Failed to load details for ${item.styleCode}');
        }
      } catch (e) {
        debugPrint('Error fetching order details for ${item.styleKey}: $e');
        _showErrorSnackBar('Error loading ${item.styleCode}');
      }
    }

    setState(() {
      if (append) {
        catalogOrderList.addAll(newItems);
      } else {
        catalogOrderList = newItems;
      }
      _isMatrixLoading = false;
    });

    EditOrderData.data = catalogOrderList;
    _persistQuantitiesToEditOrderData();
  }

  // ==================== QUANTITY PERSISTENCE ====================
  void _persistQuantitiesToEditOrderData() {
    Map<String, dynamic> qtyJson = {};
    quantities.forEach((styleKey, shadeMap) {
      qtyJson[styleKey] = {};
      shadeMap.forEach((shade, sizeMap) {
        qtyJson[styleKey][shade] = sizeMap;
      });
    });
    EditOrderData.detailsForEdit = jsonEncode({
      'quantities': qtyJson,
      'additionalInfo': _additionalInfo,
    });
  }

  void _restoreQuantitiesFromEditOrderData() {
    if (EditOrderData.detailsForEdit.isNotEmpty) {
      try {
        final stored = jsonDecode(EditOrderData.detailsForEdit);
        if (stored['quantities'] != null) {
          final qtyJson = stored['quantities'] as Map<String, dynamic>;
          quantities.clear();
          qtyJson.forEach((styleKey, shadeMap) {
            quantities[styleKey] = {};
            (shadeMap as Map<String, dynamic>).forEach((shade, sizeMap) {
              quantities[styleKey]![shade] = Map<String, int>.from(sizeMap);
            });
          });
          // Update controllers
          _controllers.clear();
          quantities.forEach((styleKey, shadeMap) {
            shadeMap.forEach((shade, sizeMap) {
              sizeMap.forEach((size, qty) {
                final key = '$styleKey-$shade-$size';
                _controllers[key] = TextEditingController(text: qty.toString());
              });
            });
          });
        }
        if (stored['additionalInfo'] != null) {
          _additionalInfo = Map<String, dynamic>.from(stored['additionalInfo']);
        }
      } catch (e) {
        print('Error restoring quantities: $e');
      }
    }
  }

  // ==================== MATRIX QUANTITY HELPERS ====================
  int _getQuantity(String styleKey, String shade, String size) {
    return quantities[styleKey]?[shade]?[size] ?? 0;
  }

  void _setQuantity(String styleKey, String shade, String size, int value) {
    setState(() {
      quantities.putIfAbsent(styleKey, () => {});
      quantities[styleKey]!.putIfAbsent(shade, () => {});
      quantities[styleKey]![shade]![size] = value.clamp(0, 9999);
    });
    _persistQuantitiesToEditOrderData();
  }

  // ==================== BUILD ITEMS FROM MATRIX ====================
  List<Map<String, dynamic>> _buildItemsFromMatrix() {
    List<Map<String, dynamic>> items = [];

    for (var catalogOrder in catalogOrderList) {
      final catalog = catalogOrder.catalog;
      final matrix = catalogOrder.orderMatrix;
      final styleKey = catalog.styleKey;

      final quantityMap = quantities[styleKey];
      if (quantityMap == null) continue;

      for (var shade in quantityMap.keys) {
        final shadeIndex = matrix.shades.indexOf(shade.trim());
        if (shadeIndex == -1) continue;

        List<Map<String, dynamic>> sizes = [];
        int totalQty = 0;
        double totalAmt = 0.0;

        for (var size in quantityMap[shade]!.keys) {
          final sizeIndex = matrix.sizes.indexOf(size.trim());
          if (sizeIndex == -1) continue;

          final quantity = quantityMap[shade]![size]!;
          if (quantity > 0) {
            final matrixData = matrix.matrix[shadeIndex][sizeIndex].split(',');
            final mrp = double.tryParse(matrixData[0]) ?? 0.0;
            final rate = double.tryParse(matrixData[1]) ?? 0.0;
            final stock = int.tryParse(matrixData[2]) ?? 0;

            sizes.add({
              'size': size,
              'qty': quantity,
              'mrp': mrp,
              'rate': rate,
              'stock': stock,
              'netRate': rate,
              'ordQty': 0,
              'stkId': 0,
              'docDtlSzId': 0,
            });

            totalQty += quantity;
            totalAmt += rate * quantity;
          }
        }

        if (totalQty > 0) {
          items.add({
            'docId': 0,
            'docNo': 'Direct',
            'docDt': DateTime.now().toIso8601String(),
            'docDtlId': 0,
            'itemName': catalog.itemName,
            'styleCode': catalog.styleCode,
            'shadeName': shade,
            'brandName': catalog.brandName,
            'typeName': '',
            'unitName': '',
            'mrp': sizes.isNotEmpty ? sizes.first['mrp'] : 0.0,
            'rate': totalQty > 0 ? totalAmt / totalQty : 0.0,
            'selectedQty': totalQty.toDouble(),
            'itemAmt': totalAmt,
            'balQty': 0,
            'discPercent': 0.0,
            'discAmt': 0.0,
            'amtRemark': '',
            'sizes': sizes,
          });
        }
      }
    }
    return items;
  }

  // ==================== AMOUNT CALCULATIONS ====================
  double _calculateGrossAmount() {
    double total = 0.0;
    for (var item in _selectedItems) {
      total += (item['selectedQty'] * item['rate']);
    }
    return total;
  }

  void _updateRoundOff() {
    setState(() {
      if (_roundOff) {
        double gross = _calculateGrossAmount();
        _roundOffAmount = gross - gross.roundToDouble();
      } else {
        _roundOffAmount = 0.0;
      }
    });
  }

  double _calculateNetAmount() {
    double gross = _calculateGrossAmount();
    return _roundOff ? gross.roundToDouble() : gross - _roundOffAmount;
  }

  // ==================== PARTY HANDLING ====================
  Future<void> fetchAndMapConsignees({required String key}) async {
    try {
      Map<String, dynamic> responseMap = await ApiService.fetchConsinees(
        key: key,
        CoBrId: UserSession.coBrId ?? '',
      );
      if (responseMap['statusCode'] == 200 && responseMap['result'] is List) {
        setState(() {
          consignees = responseMap['result'];
          EditOrderData.consignees = consignees;
        });
      }
    } catch (e) {
      print('Error fetching consignees: $e');
    }
  }

  void _handlePartySelection(String? val, String? key) async {
    if (key == null) return;

    setState(() {
      _orderControllers.selectedParty = val;
      _orderControllers.selectedPartyKey = key;
      _orderControllers.selectedPartyName = val;
    });

    EditOrderData.partyKey = key;
    EditOrderData.partyName = val ?? '';

    try {
      await fetchAndMapConsignees(key: key);
      final details = await _dropdownData.fetchLedgerDetails(key);

      _orderControllers.pytTermDiscKey = details['pytTermDiscKey'];
      _orderControllers.salesPersonKey = details['salesPersonKey'];
      _orderControllers.creditPeriod = details['creditPeriod'];
      _orderControllers.selectedTransporterKey = details['trspKey'];
      _orderControllers.whatsAppMobileNo = details['whatsAppMobileNo'];

      final commission = await _dropdownData.fetchCommissionPercentage(key);

      setState(() {
        _orderControllers.updateFromPartyDetails(
          details,
          _dropdownData.brokerList,
          _dropdownData.transporterList,
        );
        _orderControllers.comm.text = commission;
        EditOrderData.commission = commission;
      });
    } catch (e) {
      _showValidationDialog('Error', 'Failed to load party details');
    }
  }

  // ==================== DIALOGS ====================
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

  Future<void> _showAddMoreInfoDialog() async {
    if (UserSession.userType == 'S' &&
        (_orderControllers.selectedPartyKey?.isEmpty ?? true)) {
      _showValidationDialog(
        'Party Selection Required',
        'Please select a party before adding more information.',
      );
      return;
    }

    final result = await showDialog(
      context: context,
      builder:
          (context) => AddMoreInfoDialog2(
            salesPersonList: _dropdownData.salesPersonList,
            partyLedKey: _orderControllers.selectedPartyKey,
            pytTermDiscKey: _orderControllers.pytTermDiscKey,
            salesPersonKey: _orderControllers.salesPersonKey,
            creditPeriod: _orderControllers.creditPeriod,
            salesLedKey: _orderControllers.salesLedKey,
            ledgerName: _orderControllers.ledgerName,
            additionalInfo: _additionalInfo,
            consignees: consignees,
            paymentTerms: paymentTerms,
            bookingTypes: _bookingTypes,
            onValueChanged: (newInfo) {
              setState(() => _additionalInfo = newInfo);
              _persistQuantitiesToEditOrderData();
            },
            isSalesmanDropdownEnabled: UserSession.userType == 'A',
            isPaymentTermEnable: UserSession.userType != 'C',
            isConsigneeEnabled: UserSession.userType != 'C',
            isBookingTypeEnabled:
                UserSession.userType == 'A' || UserSession.userType == 'S',
          ),
    );

    if (result != null) {
      setState(() => _additionalInfo = result);
      _persistQuantitiesToEditOrderData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Additional information saved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ==================== SAVE PACKING ====================
  Future<void> _savePackingList() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    // Build items from matrix first
    final items = _buildItemsFromMatrix();
    if (items.isEmpty) {
      _showValidationDialog('No Items', 'Please enter at least one quantity.');
      return;
    }
    setState(() {
      _selectedItems = items;
    });

    setState(() => _isSaving = true);

    try {
      String? consigneeLedKey = '', stationStnKey = '';
      final selectedConsigneeName = _additionalInfo['consignee']?.toString();

      if (selectedConsigneeName != null && selectedConsigneeName.isNotEmpty) {
        final selectedConsignee = consignees.firstWhere(
          (c) => c.ledName == selectedConsigneeName,
          orElse:
              () => Consignee(
                ledKey: '',
                ledName: '',
                stnKey: '',
                stnName: '',
                paymentTermsKey: '',
                paymentTermsName: '',
                pytTermDiscdays: '0',
              ),
        );
        consigneeLedKey = selectedConsignee.ledKey;
        stationStnKey = selectedConsignee.stnKey;
      }

      final Map<String, dynamic> data2 = {
        "packingdate": formatDate(_orderControllers.date.text, true),
        "customer": _orderControllers.selectedPartyKey ?? '',
        "broker": _orderControllers.selectedBrokerKey ?? '',
        "comission": _orderControllers.comm.text,
        "transporter": _orderControllers.selectedTransporterKey ?? '',
        "delivaryday": _orderControllers.deliveryDays.text,
        "delivarydate": formatDate(_orderControllers.deliveryDate.text, false),
        "remark": _orderControllers.remark.text,
        "consignee": consigneeLedKey,
        "station": stationStnKey,
        "paymentterms":
            _additionalInfo['paymentterms'] ??
            _orderControllers.pytTermDiscKey ??
            '',
        "paymentdays":
            _additionalInfo['paymentdays'] ??
            _orderControllers.creditPeriod?.toString() ??
            '0',
        "duedate": calculateDueDate(),
        "refno": _additionalInfo['refno'] ?? '',
        "date": getTodayWithZeroTime(),
        "bookingtype": _additionalInfo['bookingtype'] ?? '',
        "salesman":
            _additionalInfo['salesman'] ??
            _orderControllers.salesPersonKey ??
            '',
        "usertype": UserSession.userType,
        "grossAmount": _calculateGrossAmount().toInt().toString(),
        "roundOff": _roundOff,
        "roundOffAmount": _roundOffAmount.toInt().toString(),
        "netAmount": _calculateNetAmount().toInt().toString(),
      };

      List<Map<String, dynamic>> dataArray = [];

      for (var item in _selectedItems) {
        final List<Map<String, dynamic>> sizes =
            List<Map<String, dynamic>>.from(item['sizes'] ?? []);

        if (sizes.isNotEmpty) {
          for (var size in sizes) {
            final int qty = size['qty'] as int? ?? 0;
            if (qty > 0) {
              dataArray.add({
                "designcode": item['styleCode']?.toString() ?? '',
                "soDocId": 0,
                "soDocDtlId": 0,
                "soDocDtlSzId": 0,
                "stkId": 0,
                "mrp": (size['mrp'] as double? ?? 0).toInt().toString(),
                "WSP": (size['rate'] as double? ?? 0).toInt().toString(),
                "size": size['size']?.toString() ?? '',
                "TotQty":
                    ((item['selectedQty'] as double? ?? 0).toInt()).toString(),
                "Note": item['amtRemark']?.toString() ?? '',
                "color": item['shadeName']?.toString() ?? '',
                "Qty": qty.toString(),
                "cobrid": UserSession.coBrId ?? '',
                "user": UserSession.userName ?? '',
                "barcode": "",
              });
            }
          }
        } else {
          final int qty = (item['selectedQty'] as double? ?? 0).toInt();
          if (qty > 0) {
            dataArray.add({
              "designcode": item['styleCode']?.toString() ?? '',
              "soDocId": 0,
              "soDocDtlId": 0,
              "soDocDtlSzId": 0,
              "stkId": 0,
              "mrp": (item['mrp'] as double? ?? 0).toInt().toString(),
              "WSP": (item['rate'] as double? ?? 0).toInt().toString(),
              "size": "",
              "TotQty": qty.toString(),
              "Note": item['amtRemark']?.toString() ?? '',
              "color": item['shadeName']?.toString() ?? '',
              "Qty": qty.toString(),
              "cobrid": UserSession.coBrId ?? '',
              "user": UserSession.userName ?? '',
              "barcode": "",
            });
          }
        }
      }

      if (dataArray.isEmpty) {
        _showValidationDialog('No Items', 'Please add at least one item.');
        setState(() => _isSaving = false);
        return;
      }

      _showLoadingDialog();

      final payload = {
        "userId": UserSession.userName ?? '',
        "coBrId": UserSession.coBrId ?? '',
        "fcYrId": UserSession.userFcYr ?? '',
        "typ": _isEditMode ? 1 : 0,
        "docId": _isEditMode ? int.tryParse(EditOrderData.doc_id) ?? 0 : 0,
        "data": dataArray,
        "data2": jsonEncode(data2),
        "barcode": "false",
      };

      // final response = _isEditMode
      //     ? await ApiService.updatePacking(payload)
      //     : await ApiService.insertPacking(payload);
      try {
        final response = await http.post(
          // Uri.parse('${AppConstants.BASE_URL}/orderBooking/insertPacking'),
          Uri.parse('https://webhook.site/bb5b85c8-d2f1-44dc-8e0a-ca7c61382caf'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          print('Error inserting packing: ${response.body}');
        }
      } catch (e) {
        print('Error inserting packing: $e');
      }
      ;

      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      // if (response['status'] == 'success') {
      //   EditOrderData.clear();
      //   _showSuccessDialog(response['docNo'] ?? '', isUpdate: _isEditMode);
      // } else {
      //   // _showErrorSnackBar(response['message'] ?? 'Failed to save packing');
      // }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showErrorSnackBar('Error saving packing: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Saving Packing List...',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ),
    );
  }

  void _showSuccessDialog(String docNo, {bool isUpdate = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
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
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Packing $docNo ${isUpdate ? 'updated' : 'saved'} successfully',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context, true);
                    },
                    child: const Text('Done'),
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

  // ==================== DATE HELPERS ====================
  String formatDate(String date, bool time) {
    try {
      DateTime parsed = DateFormat("yyyy-MM-dd").parse(date);
      String formatted = DateFormat("yyyy-MM-dd").format(parsed);
      return time
          ? "$formatted ${DateFormat("HH:mm:ss").format(DateTime.now())}"
          : formatted;
    } catch (_) {
      return DateFormat("yyyy-MM-dd").format(DateTime.now());
    }
  }

  String calculateFutureDateFromString(String days) {
    final int? d = int.tryParse(days);
    if (d == null) return "";
    return DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().add(Duration(days: d)));
  }

  String getTodayWithZeroTime() {
    final now = DateTime.now();
    return DateFormat(
      'yyyy-MM-dd HH:mm:ss.SSS',
    ).format(DateTime(now.year, now.month, now.day));
  }

  String calculateDueDate() {
    final paymentDays = _additionalInfo['paymentdays'];
    if (paymentDays != null &&
        paymentDays is String &&
        int.tryParse(paymentDays) != null) {
      return calculateFutureDateFromString(paymentDays);
    }
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = _PackingListControllers.formatDate(picked);
      if (controller == _orderControllers.deliveryDate) {
        EditOrderData.deliveryDate = controller.text;
      }
    }
  }

  // ==================== UI BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(),
      bottomNavigationBar: _buildBottomButtons(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryColor,
      elevation: 4,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        _isEditMode ? 'Edit Packing List' : 'Add Packing List',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    "Packing Date",
                    _orderControllers.date,
                    isDate: true,
                    onTap: () => _selectDate(_orderControllers.date),
                    isRequired: true,
                  ),
                  _buildPartyDropdownRow(),
                  _buildDropdown(
                    "Broker",
                    "B",
                    _orderControllers.selectedBroker,
                    (val, key) async {
                      setState(() {
                        _orderControllers.selectedBrokerKey = key;
                        _orderControllers.selectedBroker = val;
                      });
                      EditOrderData.brokerKey = key ?? '';
                      EditOrderData.brokerName = val ?? '';
                      if (key != null) {
                        final commission = await _dropdownData
                            .fetchCommissionPercentage(key);
                        _orderControllers.comm.text = commission;
                        EditOrderData.commission = commission;
                      }
                    },
                    isEnabled: UserSession.userType != 'C',
                  ),
                  if (UserSession.userType == 'A')
                    _buildTextField(
                      "Comm (%)",
                      _orderControllers.comm,
                      onChanged: (val) => EditOrderData.commission = val,
                    ),
                  _buildDropdown(
                    "Transporter",
                    "T",
                    _orderControllers.selectedTransporter,
                    (val, key) {
                      setState(() {
                        _orderControllers.selectedTransporterKey = key;
                        _orderControllers.selectedTransporter = val;
                      });
                      EditOrderData.transporterKey = key ?? '';
                      EditOrderData.transporterName = val ?? '';
                    },
                  ),
                  _buildResponsiveRow(
                    _buildTextField(
                      "Delivery Days",
                      _orderControllers.deliveryDays,
                      readOnly: true,
                    ),
                    _buildTextField(
                      "Delivery Date",
                      _orderControllers.deliveryDate,
                      isDate: true,
                      onTap: () async {
                        final today = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: today,
                          firstDate: today,
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          _orderControllers.deliveryDate.text =
                              _PackingListControllers.formatDate(picked);
                          _orderControllers.deliveryDays.text =
                              picked.difference(today).inDays.toString();
                          EditOrderData.deliveryDate =
                              _orderControllers.deliveryDate.text;
                          EditOrderData.deliveryDays =
                              _orderControllers.deliveryDays.text;
                        }
                      },
                    ),
                  ),
                  _buildTextField(
                    "Remark",
                    _orderControllers.remark,
                    isText: true,
                    onChanged: (val) => EditOrderData.remark = val,
                  ),
                  const SizedBox(height: 20),

                  // Matrix Section with Sticky Headers
                  if (_isMatrixLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (catalogOrderList.isNotEmpty)
                    _buildMatrixWithStickyHeaders(),
                  const SizedBox(height: 20),

                  // Amount Summary (shown after building items)
                  if (_selectedItems.isNotEmpty) ...[
                    _buildAmountSummaryCard(),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatrixWithStickyHeaders() {
    return CustomScrollView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      slivers:
          catalogOrderList.map((order) => _buildStickySection(order)).toList(),
    );
  }

  Widget _buildStickySection(CatalogOrderData catalogOrder) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _CardHeaderDelegate(
            child: buildOrderCardOnly(catalogOrder),
            height: 140,
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final shade = selectedColors2[catalogOrder.catalog.styleKey]!
                  .elementAt(index);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildColorSection(catalogOrder, shade),
              );
            },
            childCount:
                selectedColors2[catalogOrder.catalog.styleKey]?.length ?? 0,
          ),
        ),
      ],
    );
  }

  Widget buildOrderCardOnly(CatalogOrderData catalogOrder) {
    final catalog = catalogOrder.catalog;
    final imageUrl =
        catalog.fullImagePath.contains("http")
            ? catalog.fullImagePath
            : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                AppColors.primaryColor.withOpacity(0.03),
                AppColors.primaryColor.withOpacity(0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ImageZoomScreen(
                              imageUrls: [imageUrl],
                              initialIndex: 0,
                            ),
                      ),
                    );
                  },
                  child: Container(
                    width: 70,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (_, __, ___) =>
                                const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryColor.withOpacity(0.15),
                              AppColors.primaryColor.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          catalog.styleCode,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
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
                              Icons.shopping_bag,
                              'Qty',
                              '${_calculateCatalogQuantity(catalog.styleKey)}',
                              Colors.green,
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.grey.shade300,
                            ),
                            _buildStatItem(
                              Icons.pending,
                              'Pending',
                              '0',
                              Colors.orange,
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.grey.shade300,
                            ),
                            _buildStatItem(
                              Icons.inventory,
                              'WIP',
                              '0',
                              Colors.blue,
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

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: 9, color: Colors.grey)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateCatalogQuantity(String styleKey) {
    int total = 0;
    for (var shade in quantities[styleKey]?.keys ?? []) {
      for (var size in quantities[styleKey]![shade]!.keys) {
        total += quantities[styleKey]![shade]![size]!;
      }
    }
    return total;
  }

  Widget _buildColorSection(CatalogOrderData catalogOrder, String shade) {
    final sizes = catalogOrder.orderMatrix.sizes;
    final styleKey = catalogOrder.catalog.styleKey;
    final matrix = catalogOrder.orderMatrix;
    final shadeIndex = matrix.shades.indexOf(shade.trim());

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "SHADE",
                          style: GoogleFonts.lora(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildHeader("QUANTITY", 1),
                _buildHeader("AMOUNT", 1),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      shade,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _getColorCode(shade),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      _calculateShadeQuantity(styleKey, shade).toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: Text(
                      '₹${_calculateShadePrice(catalogOrder, shade).toStringAsFixed(0)}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _buildHeader("SIZE", 1),
                _buildHeader("QTY", 2),
                _buildHeader("MRP", 1),
                _buildHeader("WSP", 1),
                _buildHeader("STOCK", 1),
              ],
            ),
          ),
          const Divider(height: 1),
          for (var size in sizes) ...[
            _buildSizeRow(catalogOrder, shade, size),
            if (size != sizes.last) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(String text, int flex) => Expanded(
    flex: flex,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    ),
  );

  int _calculateShadeQuantity(String styleKey, String shade) {
    int total = 0;
    for (var size in quantities[styleKey]?[shade]?.keys ?? []) {
      total += quantities[styleKey]![shade]![size]!;
    }
    return total;
  }

  double _calculateShadePrice(CatalogOrderData catalogOrder, String shade) {
    double total = 0;
    final styleKey = catalogOrder.catalog.styleKey;
    final matrix = catalogOrder.orderMatrix;
    final shadeIndex = matrix.shades.indexOf(shade.trim());
    if (shadeIndex == -1) return total;
    for (var size in quantities[styleKey]?[shade]?.keys ?? []) {
      final sizeIndex = matrix.sizes.indexOf(size.toString().trim());
      if (sizeIndex == -1) continue;
      final rate =
          double.tryParse(matrix.matrix[shadeIndex][sizeIndex].split(',')[1]) ??
          0;
      final quantity = quantities[styleKey]![shade]![size]!;
      total += rate * quantity;
    }
    return total;
  }

  Widget _buildSizeRow(
    CatalogOrderData catalogOrder,
    String shade,
    String size,
  ) {
    final matrix = catalogOrder.orderMatrix;
    final shadeIndex = matrix.shades.indexOf(shade.trim());
    final sizeIndex = matrix.sizes.indexOf(size.trim());
    final styleKey = catalogOrder.catalog.styleKey;

    String mrp = '0', wsp = '0', stock = '0';
    if (shadeIndex != -1 && sizeIndex != -1) {
      final parts = matrix.matrix[shadeIndex][sizeIndex].split(',');
      mrp = parts[0];
      wsp = parts[1];
      stock = parts.length > 2 ? parts[2] : '0';
    }

    final quantity = _getQuantity(styleKey, shade, size);
    final controllerKey = '$styleKey-$shade-$size';
    final controller = _controllers.putIfAbsent(
      controllerKey,
      () => TextEditingController(text: quantity.toString()),
    );
    if (controller.text != quantity.toString()) {
      controller.text = quantity.toString();
    }

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
                IconButton(
                  icon: const Icon(Icons.remove, size: 20),
                  onPressed: () {
                    _setQuantity(styleKey, shade, size, quantity - 1);
                    controller.text =
                        _getQuantity(styleKey, shade, size).toString();
                  },
                ),
                SizedBox(
                  width: 22,
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: GoogleFonts.roboto(fontSize: 14),
                    onChanged: (val) {
                      final newQty = int.tryParse(val) ?? 0;
                      _setQuantity(styleKey, shade, size, newQty);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () {
                    _setQuantity(styleKey, shade, size, quantity + 1);
                    controller.text =
                        _getQuantity(styleKey, shade, size).toString();
                  },
                ),
              ],
            ),
          ),
        ),
        _buildCell(mrp, 1),
        _buildCell(wsp, 1),
        _buildCell(stock, 1),
      ],
    );
  }

  Widget _buildCell(String text, int flex) => Expanded(
    flex: flex,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

  Color _getColorCode(String shade) {
    final color = shade.toLowerCase();
    if (color.contains('red')) return Colors.red;
    if (color.contains('blue')) return Colors.blue;
    if (color.contains('green')) return Colors.green;
    if (color.contains('black')) return Colors.black;
    return Colors.grey.shade800;
  }

  Widget _buildAmountSummaryCard() {
    final gross = _calculateGrossAmount();
    final net = _calculateNetAmount();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amount Summary',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primaryColor,
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gross Amount'),
              Text(
                '₹ ${gross.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _roundOff,
                    onChanged: (v) {
                      setState(() {
                        _roundOff = v ?? false;
                        _updateRoundOff();
                      });
                    },
                    activeColor: AppColors.primaryColor,
                  ),
                  const Text('Round Off'),
                ],
              ),
              Text(
                _roundOff
                    ? '₹ ${_roundOffAmount.toStringAsFixed(2)}'
                    : '₹ 0.00',
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Net Amount',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '₹ ${net.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return SafeArea(
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showAddMoreInfoDialog,
                icon: const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  "Add More Info",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _savePackingList,
                icon:
                    _isSaving
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.save, size: 18, color: Colors.white),
                label: Text(
                  _isSaving ? "Saving..." : "Save",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== FLOATING ACTION BUTTON ====================
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _openCatalogSelection,
      icon: const Icon(Icons.add_shopping_cart),
      label: const Text('Add Items'),
      backgroundColor: AppColors.primaryColor,
    );
  }

  void _openCatalogSelection() async {
    // Persist current state before navigating
    _persistQuantitiesToEditOrderData();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => OrderBookingScreen(
              editMode: true,
              editModeType: Constants.PACKING,
            ),
      ),
    );

    if (result != null && result is List<Catalog>) {
      final existingStyleKeys =
          catalogOrderList.map((e) => e.catalog.styleKey).toSet();
      final newCatalogs =
          result.where((c) => !existingStyleKeys.contains(c.styleKey)).toList();

      if (newCatalogs.isNotEmpty) {
        await _loadCatalogOrderDetails(newCatalogs, append: true);
        // Restore quantities for existing items (they remain unchanged)
        _restoreQuantitiesFromEditOrderData();
      }
    }
  }

  // ==================== FORM FIELD WIDGETS ====================
  Widget _buildPartyDropdownRow() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: _buildDropdown(
      "Party Name",
      "w",
      _orderControllers.selectedParty,
      _handlePartySelection,
      isEnabled: UserSession.userType != 'C',
      isRequired: true,
    ),
  );

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
            (v) =>
                isRequired && (v == null || v.isEmpty)
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
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
            ),
            labelStyle: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        onChanged:
            isEnabled
                ? (val) => onChanged(val, _getKeyFromValue(ledCat, val))
                : null,
        enabled: isEnabled,
      ),
    );
  }

  List<Map<String, String>> _getLedgerList(String ledCat) {
    switch (ledCat) {
      case 'w':
        return _dropdownData.partyList;
      case 'B':
        return _dropdownData.brokerList;
      case 'T':
        return _dropdownData.transporterList;
      default:
        return [];
    }
  }

  String? _getKeyFromValue(String ledCat, String? value) =>
      _getLedgerList(ledCat).firstWhere(
        (e) => e['ledName'] == value,
        orElse: () => {'ledKey': ''},
      )['ledKey'];

  Widget _buildResponsiveRow(Widget first, Widget second) =>
      MediaQuery.of(context).size.width > 600
          ? Row(
            children: [
              Expanded(child: first),
              const SizedBox(width: 10),
              Expanded(child: second),
            ],
          )
          : Column(children: [first, second]);

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isDate = false,
    bool readOnly = false,
    VoidCallback? onTap,
    bool isText = false,
    bool isRequired = false,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly || isDate,
        keyboardType: isText ? TextInputType.text : TextInputType.number,
        onTap: onTap ?? (isDate ? () => _selectDate(controller) : null),
        onChanged: onChanged,
        validator:
            isRequired
                ? (v) => v == null || v.isEmpty ? '$label is required' : null
                : null,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          isDense: true,
          suffixIcon:
              isDate
                  ? Icon(Icons.calendar_today, size: 18, color: Colors.grey)
                  : null,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
          ),
          labelStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ==================== STICKY HEADER DELEGATE ====================
class _CardHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _CardHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: child);
  }

  @override
  bool shouldRebuild(covariant _CardHeaderDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}

// ==================== CONTROLLER CLASSES ====================
class _PackingListControllers {
  String? pytTermDiscKey,
      salesPersonKey,
      salesLedKey,
      ledgerName,
      whatsAppMobileNo;
  int? creditPeriod;

  final date = TextEditingController();
  final comm = TextEditingController();
  final deliveryDays = TextEditingController();
  final deliveryDate = TextEditingController();
  final remark = TextEditingController();

  String? selectedParty, selectedPartyKey, selectedPartyName;
  String? selectedTransporter, selectedTransporterKey;
  String? selectedBroker, selectedBrokerKey;

  static String formatDate(DateTime date) =>
      DateFormat("yyyy-MM-dd").format(date);

  void updateFromPartyDetails(
    Map<String, dynamic> details,
    List<Map<String, String>> brokers,
    List<Map<String, String>> transporters,
  ) {
    pytTermDiscKey = details['pytTermDiscKey']?.toString();
    salesPersonKey = details['salesPersonKey']?.toString();
    creditPeriod = details['creditPeriod'] as int?;
    salesLedKey = details['salesLedKey']?.toString();
    ledgerName = details['ledgerName']?.toString();
    selectedPartyName ??= details['ledgerName']?.toString();

    final partyBrokerKey = details['brokerKey']?.toString() ?? '';
    if (partyBrokerKey.isNotEmpty) {
      final broker = brokers.firstWhere(
        (e) => e['ledKey'] == partyBrokerKey,
        orElse: () => {'ledName': ''},
      );
      selectedBroker = broker['ledName'];
      selectedBrokerKey = partyBrokerKey;
    }

    final partyTrspKey = details['trspKey']?.toString() ?? '';
    if (partyTrspKey.isNotEmpty) {
      final transporter = transporters.firstWhere(
        (e) => e['ledKey'] == partyTrspKey,
        orElse: () => {'ledName': ''},
      );
      selectedTransporter = transporter['ledName'];
      selectedTransporterKey = partyTrspKey;
    }
  }
}

class _PackingListDropdownData {
  List<Map<String, String>> partyList = [],
      brokerList = [],
      transporterList = [],
      salesPersonList = [];

  Future<void> loadAllDropdownData() async {
    final results = await Future.wait([
      _fetchLedgers("w"),
      _fetchLedgers("B"),
      _fetchLedgers("T"),
      _fetchLedgers("S"),
    ]);
    partyList = results[0];
    brokerList = results[1];
    transporterList = results[2];
    salesPersonList = results[3];
  }

  Future<Map<String, dynamic>> fetchLedgerDetails(String ledKey) async {
    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/users/getLedgerDetails'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"ledKey": ledKey}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load details');
  }

  Future<List<Map<String, String>>> _fetchLedgers(String ledCat) async {
    try {
      final response = await ApiService.fetchLedgers(
        ledCat: ledCat,
        coBrId: UserSession.coBrId ?? '',
      );
      if (response['statusCode'] == 200 && response['result'] != null) {
        return (response['result'] as List<KeyName>)
            .map((e) => {'ledKey': e.key, 'ledName': e.name})
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<String> fetchCommissionPercentage(String ledKey) async {
    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/users/getCommPerc'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"ledKey": ledKey}),
    );
    return response.statusCode == 200 ? response.body : '0';
  }
}
