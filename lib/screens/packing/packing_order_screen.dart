import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:vrs_erp/Masters/Customer/Customer.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/constants/constants.dart';
import 'package:vrs_erp/models/consignee.dart';
import 'package:vrs_erp/models/PytTermDisc.dart';
import 'package:vrs_erp/models/item.dart';
import 'package:vrs_erp/screens/packing/SalesOrderList.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/viewOrder/add_more_info.dart';
import 'package:vrs_erp/viewOrder/view_order_screen2.dart';

class PackingListScreen extends StatefulWidget {
  const PackingListScreen({Key? key}) : super(key: key);

  @override
  _PackingListScreenState createState() => _PackingListScreenState();
}

class _PackingListScreenState extends State<PackingListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderControllers = _PackingListControllers();
  final _dropdownData = _PackingListDropdownData();

  List<Consignee> consignees = [];
  List<PytTermDisc> paymentTerms = [];
  List<Item> _bookingTypes = [];
  bool isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _additionalInfo = {};

  String? _selectedSOOption;
  List<Map<String, dynamic>> _selectedSOItems = [];

  bool _roundOff = false;
  double _roundOffAmount = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);

    await Future.wait([
      _dropdownData.loadAllDropdownData(),
      fetchPaymentTerms(),
      _loadBookingTypes(),
    ]);

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

  Future<void> fetchPaymentTerms() async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/users/getPytTermDisc'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"coBrId": UserSession.coBrId ?? ''}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          paymentTerms =
              data
                  .map(
                    (e) => PytTermDisc(
                      key: e['pytTermDiscKey']?.toString() ?? '',
                      name: e['pytTermDiscName']?.toString() ?? '',
                    ),
                  )
                  .toList();
        });
      }
    } catch (e) {
      print('Error fetching payment terms: $e');
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
            ),
      ),
    );

    if (result != null && result is List<Map<String, dynamic>>) {
      setState(() => _selectedSOItems = result);
    }
  }

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

      final packingData = {
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
        "soOption": _selectedSOOption,
        "selectedItems": _selectedSOItems,
        "grossAmount": _calculateGrossAmount(),
        "roundOff": _roundOff,
        "roundOffAmount": _roundOffAmount,
        "netAmount": _calculateNetAmount(),
      };

      print('Packing Data: ${jsonEncode(packingData)}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Packing List saved successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving packing: $e')));
    } finally {
      setState(() => _isSaving = false);
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

  double _calculateGrossAmount() {
    double total = 0.0;
    for (var item in _selectedSOItems) {
      total += (item['selectedQty'] * item['rate']);
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

  @override
  Widget build(BuildContext context) {
    double grossAmount = _calculateGrossAmount();
    double netAmount = _calculateNetAmount();

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
          'Packing List',
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                              _buildTextField(
                                "Comm (%)",
                                _orderControllers.comm,
                              ),
                            _buildDropdown(
                              "Transporter",
                              "T",
                              _orderControllers.selectedTransporter,
                              (val, key) =>
                                  _orderControllers.selectedTransporterKey =
                                      key,
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
                                        _PackingListControllers.formatDate(
                                          picked,
                                        );
                                    _orderControllers.deliveryDays.text =
                                        picked
                                            .difference(today)
                                            .inDays
                                            .toString();
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

                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Order Type',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildRadioOption(
                                          'without_so',
                                          'Without SO',
                                          Icons.inventory,
                                          _selectedSOOption,
                                          (value) {
                                            setState(() {
                                              _selectedSOOption = value;
                                              if (value == 'without_so')
                                                _selectedSOItems.clear();
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildRadioOption(
                                          'with_so',
                                          'With SO',
                                          Icons.receipt_long,
                                          _selectedSOOption,
                                          (value) {
                                            setState(
                                              () => _selectedSOOption = value,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            if (_selectedSOItems.isNotEmpty) ...[
                              _buildSelectedItemsCard(),
                              const SizedBox(height: 16),

                              Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Gross Amount',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                              activeColor:
                                                  AppColors.primaryColor,
                                            ),
                                            const Text(
                                              'Round Off',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
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
                                                _roundOff
                                                    ? Colors.green.shade700
                                                    : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                              ),
                            ],
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildBottomButtons(),
                ],
              ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildRadioOption(
    String value,
    String title,
    IconData icon,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade400,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color:
              isSelected
                  ? AppColors.primaryColor.withOpacity(0.08)
                  : Colors.white,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: selectedValue,
              onChanged: onChanged,
              activeColor: AppColors.primaryColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primaryColor : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primaryColor : Colors.black87,
              ),
            ),
          ],
        ),
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
      totalQty += (size['qty'] as int? ?? 0);
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
              item['docNo'] ?? 'N/A',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item['itemName'] ?? 'N/A',
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
                'Qty: ${item['selectedQty']} ${item['unitName']}',
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
              onPressed: () => setState(() => _selectedSOItems.removeAt(index)),
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
                      child: _buildReadOnlyField(
                        'Product',
                        item['itemName'] ?? 'N/A',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyField(
                        'Design',
                        item['styleCode'] ?? 'N/A',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyField(
                        'Type',
                        item['typeName'] ?? 'N/A',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyField(
                        'Shade',
                        item['shadeName'] ?? 'N/A',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyField(
                        'Brand',
                        item['brandName']?.isNotEmpty == true
                            ? item['brandName']
                            : 'N/A',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyField(
                        'Order No',
                        item['docNo'] ?? 'N/A',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyField(
                        'Date',
                        item['docDt'] ?? 'N/A',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyField(
                        'Dlv Date',
                        item['dlvDate'] ?? 'N/A',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Read-only main fields (MRP, Rate, Qty - all read-only)
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
                        '${(item['selectedQty'] as double? ?? 0).toStringAsFixed(0)} ${item['unitName']}',
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
                        '${item['balQty']} ${item['unitName']}',
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
                        'Amount',
                        '₹${(((item['selectedQty'] as double? ?? 0) * (item['rate'] as double? ?? 0)) - (item['discAmt'] as double? ?? 0)).toStringAsFixed(2)}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildReadOnlyField(
                        'Amount Remark',
                        item['amtRemark'] ?? '',
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
                      'Total Qty: ${item['selectedQty']} ${item['unitName']}',
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
                // Header Row
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade50),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Text(
                        'Size',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          color: AppColors.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Text(
                        'Qty',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          color: AppColors.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Text(
                        'Ord Qty',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          color: AppColors.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Text(
                        'Stock',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          color: AppColors.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Text(
                        'Rate',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          color: AppColors.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Text(
                        'MRP',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          color: AppColors.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Text(
                        'Net Rate',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          color: AppColors.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                // Data Rows
                ...sizes.map((size) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        child: Text(
                          size['size'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 4,
                        ),
                        child: SizedBox(
                          width: 50,
                          child: TextFormField(
                            initialValue: (size['qty'] as int? ?? 0).toString(),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
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
                            style: const TextStyle(fontSize: 10),
                            onChanged: (val) {
                              final int qty = int.tryParse(val) ?? 0;
                              setState(() {
                                size['qty'] = qty;
                                int total = 0;
                                for (var s in sizes) {
                                  total += (s['qty'] as int? ?? 0);
                                }
                                item['selectedQty'] = total.toDouble();
                                item['itemAmt'] =
                                    (item['selectedQty'] as double? ?? 0) *
                                    (item['rate'] as double? ?? 0);
                              });
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        child: Text(
                          (size['ordQty'] as int? ?? 0).toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        child: Text(
                          (size['stock'] as int? ?? 0).toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        child: Text(
                          (size['rate'] as double? ?? 0).toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        child: Text(
                          (size['mrp'] as double? ?? 0).toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        child: Text(
                          (size['netRate'] as double? ?? 0).toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildFloatingActionButton() {
    // If "With SO" is selected, show single button
    if (_selectedSOOption == 'with_so') {
      return Container(
        margin: const EdgeInsets.only(bottom: 80),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFABButton(
                Icons.receipt_long,
                'View Sales Orders',
                _openOrderListPage,
              ),
            ],
          ),
        ),
      );
    }

    // If "Without SO" is selected or no selection, show Add Item | Barcode buttons
    return Container(
      margin: const EdgeInsets.only(bottom: 80),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFABButton(Icons.add, 'Add Item', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Item feature coming soon')),
              );
            }),
            Container(width: 1, height: 35, color: Colors.grey.shade300),
            _buildFABButton(Icons.qr_code_scanner, 'Barcode', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Barcode scanning feature coming soon'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFABButton(IconData icon, String label, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
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
              borderSide: BorderSide(color: const Color(0xFF2196F3), width: 2),
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
            borderSide: BorderSide(color: const Color(0xFFCBD5E1)),
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
}

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
    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/users/getLedger'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "ledCat": ledCat,
        "coBrId": UserSession.coBrId ?? '',
        "ledKey": UserSession.userLedKey ?? '',
        "userType": UserSession.userType ?? '',
      }),
    );
    if (response.statusCode == 200)
      return (jsonDecode(response.body) as List)
          .map(
            (e) => {
              'ledKey': e['ledKey'].toString(),
              'ledName': e['ledName'].toString(),
            },
          )
          .toList();
    throw Exception("Failed to load ledgers");
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
