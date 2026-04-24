import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/consignee.dart';
import 'package:vrs_erp/models/PytTermDisc.dart';
import 'package:vrs_erp/models/item.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/packing/SalesOrderList.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/viewOrder/view_order_screen2.dart';

class PackingListAgainstSO extends StatefulWidget {
  final String? orderId;
  final Map<String, dynamic>? orderData;

  const PackingListAgainstSO({Key? key, this.orderId, this.orderData})
    : super(key: key);

  @override
  _PackingListAgainstSOState createState() => _PackingListAgainstSOState();
}

class _PackingListAgainstSOState extends State<PackingListAgainstSO> {
  // ==================== VARIABLES ====================
  bool _isUpdateMode = false;

  // Form & Controllers
  final _formKey = GlobalKey<FormState>();
  final _orderControllers = _PackingListControllers();
  final _dropdownData = _PackingListDropdownData();

  // Data Lists
  List<Consignee> consignees = [];
  List<PytTermDisc> paymentTerms = [];
  List<Item> _bookingTypes = [];

  // State Flags
  bool isLoading = true;
  bool _isSaving = false;

  // Data Maps
  Map<String, dynamic> _additionalInfo = {};

  // Order Selection
  List<Map<String, dynamic>> _selectedSOItems = [];

  // Amount Calculation
  bool _roundOff = false;
  double _roundOffAmount = 0.0;

  // ==================== LIFECYCLE METHODS ====================
  @override
  void initState() {
    super.initState();
    _isUpdateMode = widget.orderId != null && widget.orderId!.isNotEmpty;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isUpdateMode) {
        _loadPackingData(widget.orderId!);
      } else {
        _initializeData();
      }
    });
  }

  // ==================== INITIALIZATION METHODS ====================
  Future<void> _initializeData() async {
    setState(() => isLoading = true);

    final payTermsResponse = await ApiService.fetchPayTerms(
      coBrId: UserSession.coBrId ?? '',
    );

    await Future.wait([
      _dropdownData.loadAllDropdownData(),
      _loadBookingTypes(),
    ]);

    setState(() {
      if (payTermsResponse['result'] != null &&
          payTermsResponse['result'] is List) {
        paymentTerms =
            (payTermsResponse['result'] as List)
                .map(
                  (keyName) =>
                      PytTermDisc(key: keyName.key, name: keyName.name),
                )
                .toList();
      }
    });

    final today = DateTime.now();
    _orderControllers.date.text = _PackingListControllers.formatDate(today);
    _orderControllers.deliveryDate.text = _PackingListControllers.formatDate(
      today,
    );
    _orderControllers.deliveryDays.text = '0';

    setState(() => isLoading = false);
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

  // ==================== API METHODS ====================
  Future<void> _loadPackingData(String orderId) async {
    setState(() => isLoading = true);

    try {
      final response = await ApiService.fetchPackingById(
        docId: orderId,
        coBrId: UserSession.coBrId ?? '',
      );

      print('Response: $response');

      if (response['status'] == 'success') {
        setState(() {
          _orderControllers.date.text =
              response['packingdate']?.split(' ')[0] ??
              DateFormat('yyyy-MM-dd').format(DateTime.now());

          _orderControllers.selectedPartyKey = response['customer'];
          _orderControllers.selectedPartyName = response['customerName'];
          _orderControllers.selectedParty = response['customerName'];

          _orderControllers.selectedBrokerKey = response['broker'];
          _orderControllers.comm.text =
              response['comission']?.toString() ?? '0';
          _orderControllers.selectedTransporterKey = response['transporter'];
          _orderControllers.deliveryDays.text =
              response['delivaryday']?.toString() ?? '0';
          _orderControllers.deliveryDate.text = response['delivarydate'] ?? '';
          _orderControllers.remark.text = response['remark'] ?? '';
          _roundOff = response['roundOff'] ?? false;

          if (response['items'] != null && response['items'] is List) {
            List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(
              response['items'],
            );
            String packingDate = response['packingdate'] ?? '';

            for (var item in items) {
              if (item['docNo'] == null || item['docNo'].toString().isEmpty) {
                item['docNo'] = response['docNo'] ?? 'N/A';
              }
              item['docDt'] = packingDate;
            }
            _selectedSOItems = items;
          }

          _updateRoundOff();
        });

        if (_orderControllers.selectedPartyKey != null &&
            _orderControllers.selectedPartyKey!.isNotEmpty) {
          await fetchAndMapConsignees(
            key: _orderControllers.selectedPartyKey!,
            CoBrId: UserSession.coBrId ?? '',
          );

          final details = await _dropdownData.fetchLedgerDetails(
            _orderControllers.selectedPartyKey!,
          );
          _orderControllers.updateFromPartyDetails(
            details,
            _dropdownData.brokerList,
            _dropdownData.transporterList,
          );
        }
      } else {
        _showValidationDialog(
          'Error',
          response['message'] ?? 'Failed to load packing data',
        );
      }
    } catch (e) {
      print('Error loading packing data: $e');
      _showValidationDialog('Error', 'Failed to load packing data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchAndMapConsignees({
    required String key,
    required String CoBrId,
  }) async {
    try {
      Map<String, dynamic> responseMap = await ApiService.fetchConsinees(
        key: key,
        CoBrId: CoBrId,
      );
      if (responseMap['statusCode'] == 200 && responseMap['result'] is List) {
        setState(() => consignees = responseMap['result']);
      }
    } catch (e) {
      print('Error fetching consignees: $e');
    }
  }

  // ==================== HELPER METHODS ====================
  String formatDate(String date, bool time) {
    try {
      DateTime parsedDate = DateFormat("yyyy-MM-dd").parse(date);
      String formattedDate = DateFormat("yyyy-MM-dd").format(parsedDate);
      if (time) {
        return "$formattedDate ${DateFormat("HH:mm:ss").format(DateTime.now())}";
      }
      return formattedDate;
    } catch (e) {
      return DateFormat("yyyy-MM-dd").format(DateTime.now());
    }
  }

  String calculateFutureDateFromString(String daysString) {
    final int? days = int.tryParse(daysString);
    if (days == null) return "";
    return DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().add(Duration(days: days)));
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

  double _calculateGrossAmount() {
    double total = 0.0;
    for (var item in _selectedSOItems) {
      // Use netAmt if available from the order, otherwise calculate
      if (item['netAmt'] != null && item['netAmt'] > 0) {
        total += item['netAmt'] as double;
      } else {
        total += (item['selectedQty'] * item['rate']);
      }
    }
    return total;
  }

  void _updateRoundOff() {
    setState(() {
      if (_roundOff) {
        double grossAmount = _calculateGrossAmount();
        _roundOffAmount = grossAmount - grossAmount.roundToDouble();
      } else {
        _roundOffAmount = 0.0;
      }
    });
  }

  double _calculateNetAmount() {
    double grossAmount = _calculateGrossAmount();
    if (_roundOff) {
      return grossAmount.roundToDouble();
    }
    return grossAmount - _roundOffAmount;
  }

  // ==================== UI HELPER METHODS ====================
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

  // ==================== DIALOG METHODS ====================
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

  // ==================== BUSINESS LOGIC METHODS ====================
  void _openOrderListPage() async {
    if (_orderControllers.selectedPartyKey?.isEmpty ?? true) {
      _showValidationDialog(
        'Party Selection Required',
        'Please select a party before viewing Sales Orders.',
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SalesOrderListScreen(
              custKey: _orderControllers.selectedPartyKey!,
              existingSelectedItems: _selectedSOItems,
              isEditMode: _isUpdateMode,
              currentPackingId: _isUpdateMode ? widget.orderId : null,
            ),
      ),
    );

    if (result != null && result is List<Map<String, dynamic>>) {
      setState(() {
        _selectedSOItems.addAll(result);
      });

      print('After merge - total items: ${_selectedSOItems.length}');
      for (var item in _selectedSOItems) {
        print(
          'Item: ${item['itemName']}, docDtlId: ${item['docDtlId']}, selectedQty: ${item['selectedQty']}, sizes count: ${item['sizes']?.length ?? 0}',
        );
      }
    }
  }

  void _handlePartySelection(String? val, String? key) async {
    if (key == null) return;

    setState(() {
      _orderControllers.selectedParty = val;
      _orderControllers.selectedPartyKey = key;
      _orderControllers.selectedPartyName = val;
    });

    try {
      await fetchAndMapConsignees(key: key, CoBrId: UserSession.coBrId ?? '');
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
      });
    } catch (e) {
      _showValidationDialog('Error', 'Failed to load party details');
    }
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
            onValueChanged:
                (newInfo) => setState(() => _additionalInfo = newInfo),
            isSalesmanDropdownEnabled: UserSession.userType == 'A',
            isPaymentTermEnable: UserSession.userType != 'C',
            isConsigneeEnabled: UserSession.userType != 'C',
            isBookingTypeEnabled:
                UserSession.userType == 'A' || UserSession.userType == 'S',
          ),
    );

    if (result != null) {
      setState(() => _additionalInfo = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Additional information saved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _savePackingList() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? consigneeLedKey = '', stationStnKey = '';
      final selectedConsigneeName = _additionalInfo['consignee']?.toString();

      if (selectedConsigneeName != null && selectedConsigneeName.isNotEmpty) {
        final selectedConsignee = consignees.firstWhere(
          (consignee) => consignee.ledName == selectedConsigneeName,
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

      Set<String> uniqueOrderNos = {};
      for (var item in _selectedSOItems) {
        String? docNo = item['docNo']?.toString();
        if (docNo != null && docNo.isNotEmpty && docNo != 'N/A') {
          uniqueOrderNos.add(docNo);
        }
      }
      String ourOrderNo = uniqueOrderNos.join(',');
      print('DEBUG: Final ourOrderNo = "$ourOrderNo"');

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
        "ourOrderNo": ourOrderNo,
        "packType": "1",
      };

      List<Map<String, dynamic>> dataArray = [];

      for (var item in _selectedSOItems) {
        print(
          'Saving item: ${item['itemName']}, docId: ${item['docId']}, docDtlId: ${item['docDtlId']}, selectedQty: ${item['selectedQty']}',
        );

        final List<Map<String, dynamic>> sizes =
            List<Map<String, dynamic>>.from(item['sizes'] ?? []);

        int soDocId = 0;
        var docIdValue = item['docId'];
        if (docIdValue is int) {
          soDocId = docIdValue;
        } else if (docIdValue is String) {
          soDocId = int.tryParse(docIdValue) ?? 0;
        }

        int soDocDtlId = 0;
        var docDtlIdValue = item['docDtlId'];
        if (docDtlIdValue is int) {
          soDocDtlId = docDtlIdValue;
        } else if (docDtlIdValue is String) {
          soDocDtlId = int.tryParse(docDtlIdValue) ?? 0;
        }

        if (sizes.isNotEmpty) {
          for (var size in sizes) {
            final int qty = size['qty'] as int? ?? 0;
            if (qty > 0) {
              int soDocDtlSzId = 0;
              var szIdValue = size['docDtlSzId'];
              if (szIdValue is int) {
                soDocDtlSzId = szIdValue;
              } else if (szIdValue is String) {
                soDocDtlSzId = int.tryParse(szIdValue) ?? 0;
              }

              int stkId = 0;
              var stkIdValue = size['stkId'];
              if (stkIdValue is int) {
                stkId = stkIdValue;
              } else if (stkIdValue is String) {
                stkId = int.tryParse(stkIdValue) ?? 0;
              }

              dataArray.add({
                "designcode": item['styleCode']?.toString() ?? '',
                "soDocId": soDocId,
                "soDocDtlId": soDocDtlId,
                "soDocDtlSzId": soDocDtlSzId,
                "stkId": stkId,
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
              "soDocId": soDocId,
              "soDocDtlId": soDocDtlId,
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
        _showValidationDialog(
          'No Items',
          'Please add at least one item to save.',
        );
        setState(() => _isSaving = false);
        return;
      }

      _showLoadingDialog();

      int packingDocId = int.tryParse(widget.orderId ?? '0') ?? 0;

      final Map<String, dynamic> payload = {
        "userId": UserSession.userName ?? '',
        "coBrId": UserSession.coBrId ?? '',
        "fcYrId": UserSession.userFcYr ?? '',
        "typ": _isUpdateMode ? 1 : 0,
        "docId": packingDocId,
        "data": dataArray,
        "data2": jsonEncode(data2),
        "barcode": "false",
      };

      print('Total dataArray length: ${dataArray.length}');
      print('Payload docId: $packingDocId');

      final response =
          _isUpdateMode
              ? await ApiService.updatePacking(payload)
              : await ApiService.insertPacking(payload);

      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (response['status'] == 'success') {
        _showSuccessDialog(response['docNo'] ?? '', isUpdate: _isUpdateMode);
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to save packing');
      }
    } catch (e) {
      print('Error: $e');
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
                                text: isUpdate ? 'Packing ' : 'Packing ',
                              ),
                              TextSpan(
                                text: docNo,
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.blue.shade300,
                                  decorationThickness: 2,
                                ),
                              ),
                              TextSpan(
                                text:
                                    isUpdate
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

  Future<void> _selectDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null)
      controller.text = _PackingListControllers.formatDate(picked);
  }

  // ==================== WIDGET BUILD METHODS ====================
  @override
  Widget build(BuildContext context) {
    double grossAmount = _calculateGrossAmount();
    double netAmount = _calculateNetAmount();
    bool isPartySelected =
        _orderControllers.selectedPartyKey != null &&
        _orderControllers.selectedPartyKey!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(grossAmount, netAmount, isPartySelected),
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
      title: const Text(
        'Packing List(Against SO)',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildBody(
    double grossAmount,
    double netAmount,
    bool isPartySelected,
  ) {
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
                      _orderControllers.selectedBrokerKey = key;
                      if (key != null) {
                        final commission = await _dropdownData
                            .fetchCommissionPercentage(key);
                        _orderControllers.comm.text = commission;
                      }
                    },
                    isEnabled: UserSession.userType != 'C',
                  ),
                  if (UserSession.userType == 'A')
                    _buildTextField("Comm (%)", _orderControllers.comm),
                  _buildDropdown(
                    "Transporter",
                    "T",
                    _orderControllers.selectedTransporter,
                    (val, key) =>
                        _orderControllers.selectedTransporterKey = key,
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
                        }
                      },
                    ),
                  ),
                  _buildTextField(
                    "Remark",
                    _orderControllers.remark,
                    isText: true,
                  ),
                  const SizedBox(height: 16),

                  // View Sales Orders Button
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ElevatedButton.icon(
                      onPressed: isPartySelected ? _openOrderListPage : null,
                      icon: Icon(
                        Icons.receipt_long,
                        size: 20,
                        color:
                            isPartySelected
                                ? Colors.white
                                : Colors.grey.shade400,
                      ),
                      label: Text(
                        'View Sales Orders',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color:
                              isPartySelected
                                  ? Colors.white
                                  : Colors.grey.shade400,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isPartySelected
                                ? AppColors.primaryColor
                                : Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),

                  if (_selectedSOItems.isNotEmpty) ...[
                    _buildSelectedItemsCard(),
                    const SizedBox(height: 16),
                    _buildAmountSummaryCard(grossAmount, netAmount),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
        _buildBottomButtons(),
      ],
    );
  }

  Widget _buildAmountSummaryCard(double grossAmount, double netAmount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gross Amount',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                '₹ ${grossAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
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
                    onChanged: (value) {
                      setState(() {
                        _roundOff = value ?? false;
                        _updateRoundOff();
                      });
                    },
                    activeColor: AppColors.primaryColor,
                  ),
                  const Text(
                    'Round Off',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Text(
                _roundOff
                    ? '₹ ${_roundOffAmount.toStringAsFixed(2)}'
                    : '₹ 0.00',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      _roundOff ? Colors.green.shade700 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Net Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              Text(
                '₹ ${netAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedItemsCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
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
                  'Selected Items (${_selectedSOItems.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _selectedSOItems.clear()),
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
            itemCount: _selectedSOItems.length,
            itemBuilder:
                (context, index) =>
                    _buildSelectedItemCard(_selectedSOItems[index], index),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedItemCard(Map<String, dynamic> item, int index) {
    final List<Map<String, dynamic>> sizes = List<Map<String, dynamic>>.from(
      item['sizes'] ?? [],
    );

    int totalQty = 0;
    for (var size in sizes) {
      int qty = size['qty'] as int? ?? 0;
      totalQty += qty;
    }

    if (totalQty != (item['selectedQty'] as double? ?? 0)) {
      item['selectedQty'] = totalQty.toDouble();
      item['itemAmt'] =
          (item['selectedQty'] as double? ?? 0) *
          (item['rate'] as double? ?? 0);
    }

    double avgRate = 0.0;
    if (totalQty > 0) {
      double totalValue = 0.0;
      for (var size in sizes) {
        totalValue +=
            (size['qty'] as int? ?? 0) * (size['rate'] as double? ?? 0);
      }
      avgRate = totalValue / totalQty;
    }

    String displayDocNo = item['docNo']?.toString() ?? 'N/A';
    String displayItemName = item['itemName']?.toString() ?? 'N/A';
    String displayStyleCode = item['styleCode']?.toString() ?? 'N/A';
    String displayShadeName = item['shadeName']?.toString() ?? 'N/A';
    String displayBrandName = item['brandName']?.toString() ?? 'N/A';
    String displayTypeName = item['typeName']?.toString() ?? 'N/A';
    String displayUnitName = item['unitName']?.toString() ?? 'PCS';
    String displayDocDate = '';
    if (item['docDt'] != null && item['docDt'].toString().isNotEmpty) {
      String dateStr = item['docDt'].toString().split(' ')[0];
      displayDocDate = dateStr;
    }

    String displayDlvDate = item['dlvDate']?.toString() ?? '';
    String displayAmtRemark = item['amtRemark']?.toString() ?? '';

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
              displayDocNo,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              displayItemName,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
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
                'Qty: ${item['selectedQty']} $displayUnitName',
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
                // Dispose all controllers and focus nodes for sizes in this item
                final sizesToDispose = item['sizes'] as List? ?? [];
                for (var sizeToDispose in sizesToDispose) {
                  if (sizeToDispose['controller'] != null) {
                    sizeToDispose['controller'].dispose();
                  }
                  if (sizeToDispose['focusNode'] != null) {
                    sizeToDispose['focusNode'].dispose();
                  }
                }
                setState(() => _selectedSOItems.removeAt(index));
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
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyField('Product', displayItemName),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyField('Design', displayStyleCode),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyField('Type', displayTypeName),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyField('Shade', displayShadeName),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyField('Brand', displayBrandName),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyField('Order No', displayDocNo),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyField('Date', displayDocDate),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyField('Dlv Date', displayDlvDate),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyField(
                        'MRP',
                        '₹${(item['mrp'] as double? ?? 0).toStringAsFixed(2)}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyField(
                        'Rate',
                        '₹${(item['rate'] as double? ?? 0).toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyField(
                        'Qty',
                        '${(item['selectedQty'] as double? ?? 0).toStringAsFixed(0)} $displayUnitName',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyField(
                        'Avg Rt',
                        avgRate.toStringAsFixed(2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyField(
                        'Item Amt',
                        '₹${(item['itemAmt'] as double? ?? 0).toStringAsFixed(2)}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyField(
                        'Ord Qty',
                        '${item['balQty'] ?? 0} $displayUnitName',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyField(
                        'Disc (%)',
                        '${(item['discPercent'] as double? ?? 0).toStringAsFixed(2)}%',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyField(
                        'Disc Amt',
                        '₹${(item['discAmt'] as double? ?? 0).toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyField(
                        'Total Qty',
                        '${item['totQty']?.toStringAsFixed(0) ?? 'N/A'} ${displayUnitName}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyField(
                        'Net Amount',
                        '₹${item['netAmt']?.toStringAsFixed(2) ?? '0.00'}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyField(
                        'Amount',
                        '₹${(((item['selectedQty'] as double? ?? 0) * (item['rate'] as double? ?? 0)) - (item['discAmt'] as double? ?? 0)).toStringAsFixed(2)}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyField(
                        'Amount Remark',
                        displayAmtRemark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                if (sizes.isNotEmpty)
                  _buildSizeWiseTable(item, sizes)
                else
                  const Text(
                    'No size details available',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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
                      'Total Qty: ${item['selectedQty']} $displayUnitName',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
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

  Widget _buildSizeWiseTable(
    Map<String, dynamic> item,
    List<Map<String, dynamic>> sizes,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Size-wise Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
                horizontalInside: BorderSide(color: Colors.grey.shade100),
                verticalInside: BorderSide(
                  color: Colors.grey.shade200,
                  width: 0.5,
                ),
              ),
              columnWidths: const {
                0: FixedColumnWidth(50),
                1: FixedColumnWidth(55),
                2: FixedColumnWidth(55),
                3: FixedColumnWidth(50),
                4: FixedColumnWidth(60),
                5: FixedColumnWidth(60),
                6: FixedColumnWidth(60),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade50),
                  children: [
                    _buildTableHeaderCell('Size'),
                    _buildTableHeaderCell('Qty'),
                    _buildTableHeaderCell('Ord Qty'),
                    _buildTableHeaderCell('Stock'),
                    _buildTableHeaderCell('Rate'),
                    _buildTableHeaderCell('MRP'),
                    _buildTableHeaderCell('Net Rate'),
                  ],
                ),
                ...sizes.map((size) => _buildTableRow(size, sizes, item)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 10,
          color: AppColors.primaryColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  TableRow _buildTableRow(
    Map<String, dynamic> size,
    List<Map<String, dynamic>> sizes,
    Map<String, dynamic> item,
  ) {
    // Get stock quantity
    int stockQty = size['stock'] as int? ?? 0;
    int currentQty = size['qty'] as int? ?? 0;
    int ordQty = size['ordQty'] as int? ?? 0;
    int sizeBalQty = size['balQty'] as int? ?? 0;

    // Get varPerc from the item
    final double varPerc = item['varPerc'] as double? ?? 0;
    final bool hasVarPerc = varPerc > 0;

    // Calculate varQty and total allowed quantity ONLY if varPerc > 0
    final double varQty =
        hasVarPerc ? _calculateVarQty(sizeBalQty.toDouble(), varPerc) : 0;
    final double totalAllowedQty =
        hasVarPerc ? (sizeBalQty + varQty) : double.infinity;

    // Create a controller for this size if not exists
    if (size['controller'] == null) {
      size['controller'] = TextEditingController(text: currentQty.toString());
      size['lastValidQty'] = currentQty;
      size['isError'] = false;
    }

    // Create focus node for this field
    if (size['focusNode'] == null) {
      size['focusNode'] = FocusNode();

      size['focusNode'].addListener(() {
        if (!size['focusNode'].hasFocus) {
          _validateAndUpdateQuantity(size, sizes, item, stockQty);
        }
      });
    }

    // Store necessary values
    size['ordQty'] = ordQty;
    size['balQty'] = sizeBalQty;
    size['totalAllowedQty'] = totalAllowedQty;
    size['varPerc'] = varPerc;

    // Check if current quantity is valid
    bool isValidStock = (size['qty'] as int? ?? 0) <= stockQty;
    bool isValidOrder =
        !hasVarPerc || (size['qty'] as int? ?? 0) <= totalAllowedQty;
    bool isValid = isValidStock && isValidOrder;

    return TableRow(
      children: [
        _buildTableCell(size['size'] ?? 'N/A'),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: BoxDecoration(color: Colors.yellow.shade50),
          child: SizedBox(
            width: 50,
            child: TextFormField(
              controller: size['controller'],
              focusNode: size['focusNode'],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color:
                    !isValid && (size['qty'] as int? ?? 0) > 0
                        ? Colors.red
                        : Colors.black,
                fontWeight:
                    !isValid && (size['qty'] as int? ?? 0) > 0
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onChanged: (value) {
                final int enteredQty = int.tryParse(value) ?? 0;
                setState(() {
                  size['tempQty'] = enteredQty;
                  bool exceedsStock = enteredQty > stockQty && stockQty > 0;
                  bool exceedsOrder =
                      hasVarPerc && enteredQty > totalAllowedQty;
                  size['isError'] = exceedsStock || exceedsOrder;
                });
              },
              onEditingComplete: () {
                _validateAndUpdateQuantity(size, sizes, item, stockQty);
                size['focusNode'].unfocus();
              },
              onTapOutside: (event) {
                _validateAndUpdateQuantity(size, sizes, item, stockQty);
              },
            ),
          ),
        ),
        _buildTableCell(ordQty.toString()),
        _buildTableCell(
          stockQty.toString(),
          textColor: stockQty == 0 ? Colors.red : Colors.black87,
          fontWeight: stockQty == 0 ? FontWeight.bold : FontWeight.normal,
        ),
        _buildTableCell((size['rate'] as double? ?? 0).toStringAsFixed(2)),
        _buildTableCell((size['mrp'] as double? ?? 0).toStringAsFixed(2)),
        _buildTableCell((size['netRate'] as double? ?? 0).toStringAsFixed(2)),
      ],
    );
  }

  void _validateAndUpdateQuantity(
    Map<String, dynamic> size,
    List<Map<String, dynamic>> sizes,
    Map<String, dynamic> item,
    int stockQty,
  ) {
    final String textValue = size['controller'].text;
    final int enteredQty = int.tryParse(textValue) ?? 0;

    // Get size-specific balance quantity from the size object
    final int sizeBalQty = size['balQty'] as int? ?? 0;

    // Get varPerc from the item
    final double varPerc = item['varPerc'] as double? ?? 0;

    // Calculate total allowed quantity ONLY if varPerc > 0
    final bool hasVarPerc = varPerc > 0;
    final double varQty =
        hasVarPerc ? _calculateVarQty(sizeBalQty.toDouble(), varPerc) : 0;
    final double totalAllowedQty =
        hasVarPerc ? (sizeBalQty + varQty) : double.infinity;

    // Check if entered quantity exceeds total allowed quantity (only if varPerc exists)
    if (hasVarPerc && enteredQty > totalAllowedQty) {
      _showStockErrorDialogForSize(
        'Quantity cannot be greater than Order Qty (${totalAllowedQty.toStringAsFixed(0)} ) for size ${size['size']}',
        size,
        sizes,
        item,
        totalAllowedQty.toInt(),
      );
    }
    // Check if entered quantity exceeds stock (always apply)
    else if (enteredQty > stockQty && stockQty > 0) {
      _showStockErrorDialogForSize(
        'Quantity cannot be greater than Ready stock for size ${size['size']}.\nAvailable stock: $stockQty',
        size,
        sizes,
        item,
        stockQty,
      );
    } else if (enteredQty >= 0 &&
        (!hasVarPerc || enteredQty <= totalAllowedQty) &&
        (stockQty == 0 || enteredQty <= stockQty)) {
      // Valid quantity - update everything
      setState(() {
        size['qty'] = enteredQty;
        size['lastValidQty'] = enteredQty;
        size['controller'].text = enteredQty.toString();
        size['isError'] = false;

        // Recalculate total quantity from all sizes
        int totalQty = 0;
        for (var s in sizes) {
          totalQty += (s['qty'] as int? ?? 0);
        }
        item['selectedQty'] = totalQty.toDouble();
        item['itemAmt'] = totalQty * (item['rate'] as double);

        _updateRoundOff();
      });
    }
  }

  // Add this new method for order limit error dialog
  void _showOrderLimitErrorDialog(
    String message,
    Map<String, dynamic> size,
    List<Map<String, dynamic>> sizes,
    Map<String, dynamic> item,
    int resetQty,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            titlePadding: EdgeInsets.zero,
            contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            actionsPadding: const EdgeInsets.only(bottom: 12),
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Order Limit Exceeded',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            content: Text(message, style: const TextStyle(fontSize: 14)),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);

                        setState(() {
                          // Reset to total allowed quantity
                          size['qty'] = resetQty;
                          size['lastValidQty'] = resetQty;
                          size['isError'] = false;

                          // Reset the controller text
                          if (size['controller'] != null) {
                            size['controller'].text = resetQty.toString();
                          }

                          // Recalculate total quantity from all sizes
                          int totalQty = 0;
                          for (var s in sizes) {
                            totalQty += (s['qty'] as int? ?? 0);
                          }

                          item['selectedQty'] = totalQty.toDouble();
                          item['itemAmt'] = totalQty * (item['rate'] as double);

                          // Update round off
                          _updateRoundOff();
                        });
                      },
                      icon: const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'OK',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  // Add the calculate methods
  double _calculateVarQty(double balQty, double varPerc) {
    if (varPerc <= 0) return 0;
    return (balQty * varPerc) / 100;
  }

  double _calculateTotalAllowedQty(double balQty, double varPerc) {
    double varQty = _calculateVarQty(balQty, varPerc);
    return balQty + varQty;
  }

  void _showStockErrorDialogForSize(
    String message,
    Map<String, dynamic> size,
    List<Map<String, dynamic>> sizes,
    Map<String, dynamic> item,
    int stockQty,
  ) {
    // Store the stock quantity (this is what we want to reset to)
    final int resetQty = stockQty;

    // Store the current invalid text for display
    final String invalidText = size['controller']?.text ?? '0';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            titlePadding: EdgeInsets.zero,
            contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            actionsPadding: const EdgeInsets.only(bottom: 12),
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Stock Limit Exceeded',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            content: Text(message, style: const TextStyle(fontSize: 14)),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);

                        setState(() {
                          // Reset to STOCK VALUE
                          size['qty'] = resetQty;
                          size['lastValidQty'] = resetQty;
                          size['isError'] = false;

                          // Reset the controller text to stock value
                          if (size['controller'] != null) {
                            size['controller'].text = resetQty.toString();
                          }

                          // Recalculate total quantity from all sizes
                          int totalQty = 0;
                          for (var s in sizes) {
                            totalQty += (s['qty'] as int? ?? 0);
                          }

                          item['selectedQty'] = totalQty.toDouble();
                          item['itemAmt'] = totalQty * (item['rate'] as double);

                          // Update round off
                          _updateRoundOff();
                        });
                      },
                      icon: const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'OK',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  static Widget _buildTableCell(
    String text, {
    Color textColor = Colors.black87,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: fontWeight,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      width: double.infinity,
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
                  onPressed: _showAddMoreInfoDialog,
                  icon: const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Add More Info",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
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
                  onPressed: _isSaving ? null : _savePackingList,
                  icon:
                      _isSaving
                          ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(
                            Icons.save,
                            size: 18,
                            color: Colors.white,
                          ),
                  label:
                      _isSaving
                          ? const Text(
                            "Saving...",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            "Save",
                            style: TextStyle(
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
    );
  }

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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly || isDate,
        keyboardType: isText ? TextInputType.text : TextInputType.number,
        onTap: onTap ?? (isDate ? () => _selectDate(controller) : null),
        validator:
            isRequired
                ? (value) =>
                    value == null || value.isEmpty ? '$label is required' : null
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
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
            borderRadius: BorderRadius.circular(6),
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

  String? selectedParty,
      selectedPartyKey,
      selectedPartyName,
      selectedTransporter,
      selectedTransporterKey,
      selectedBroker,
      selectedBrokerKey;

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
    try {
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
    } catch (e) {
      print('Error loading dropdown data: $e');
    }
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
        final List<KeyName> result = response['result'];
        return result
            .map((keyName) => {'ledKey': keyName.key, 'ledName': keyName.name})
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching ledgers for $ledCat: $e');
      return [];
    }
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
