
// ==================== DETAILS PAGE ====================

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/services/app_services.dart';

class PurchaseInwardDetailsPage extends StatefulWidget {
  final String? supplierKey;
  final String? supplierName;
  final String? supplierStation;
  final List<Map<String, dynamic>> selectedItems;
  final Map<String, dynamic>? initialData;

  const PurchaseInwardDetailsPage({
    Key? key,
    this.supplierKey,
    this.supplierName,
    this.supplierStation,
    this.selectedItems = const [],
    this.initialData,
  }) : super(key: key);

  @override
  _PurchaseInwardDetailsPageState createState() => _PurchaseInwardDetailsPageState();
}

class _PurchaseInwardDetailsPageState extends State<PurchaseInwardDetailsPage> {
  // ==================== PARTY DETAILS SECTION ====================
  final TextEditingController partyController = TextEditingController();
  final TextEditingController partyStationController = TextEditingController();
  final TextEditingController partyAddressController = TextEditingController();

  // ==================== DELIVERY SCHEDULE SECTION ====================
  String? deliverySchedule; // 'Common' or 'Designwise'
  final TextEditingController deliveryDaysController = TextEditingController();
  final TextEditingController deliveryDateController = TextEditingController();
  String? selectedDiscTerms;
  final TextEditingController pytDaysController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();

  // ==================== OTHER DETAILS SECTION ====================
  String? selectedTransporter;
  final TextEditingController lrNoController = TextEditingController();
  final TextEditingController lrDateController = TextEditingController();
  String? selectedBroker;
  final TextEditingController commPercentController = TextEditingController();
  String? selectedCurrency;
  final TextEditingController eWayBillNoController = TextEditingController();

  // ==================== DROPDOWN DATA ====================
  List<KeyName> transporterList = [];
  List<KeyName> brokerList = [];
  List<KeyName> currencyList = [];
  List<KeyName> discTermsList = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    partyController.text = widget.supplierName ?? '';
    partyStationController.text = widget.supplierStation ?? '';
    lrDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    deliveryDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    dueDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    deliverySchedule = 'Common';
    
    _loadDropdownData();
    _loadInitialData();
  }

  @override
  void dispose() {
    partyController.dispose();
    partyStationController.dispose();
    partyAddressController.dispose();
    deliveryDaysController.dispose();
    deliveryDateController.dispose();
    pytDaysController.dispose();
    dueDateController.dispose();
    lrNoController.dispose();
    lrDateController.dispose();
    commPercentController.dispose();
    eWayBillNoController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    if (widget.initialData != null) {
      setState(() {
        partyAddressController.text = widget.initialData?['partyAddress'] ?? '';
        deliverySchedule = widget.initialData?['deliverySchedule'] ?? 'Common';
        deliveryDaysController.text = widget.initialData?['deliveryDays'] ?? '';
        deliveryDateController.text = widget.initialData?['deliveryDate'] ?? '';
        selectedDiscTerms = widget.initialData?['discTerms'];
        pytDaysController.text = widget.initialData?['pytDays'] ?? '';
        dueDateController.text = widget.initialData?['dueDate'] ?? '';
        selectedTransporter = widget.initialData?['transporter'];
        lrNoController.text = widget.initialData?['lrNo'] ?? '';
        lrDateController.text = widget.initialData?['lrDate'] ?? '';
        selectedBroker = widget.initialData?['broker'];
        commPercentController.text = widget.initialData?['commPercent'] ?? '';
        selectedCurrency = widget.initialData?['currency'] ?? 'INR';
        eWayBillNoController.text = widget.initialData?['eWayBillNo'] ?? '';
      });
    }
  }

  Future<void> _loadDropdownData() async {
    setState(() => isLoading = true);
    
    try {
      await Future.wait([
        _fetchLedgers('T', (data) => transporterList = data),
        _fetchLedgers('B', (data) => brokerList = data),
        _fetchDiscTerms(),
        _fetchCurrency(),
      ]);
    } catch (e) {
      print('Error loading dropdown data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchLedgers(String ledCat, Function(List<KeyName>) onSuccess) async {
    try {
      final response = await ApiService.fetchLedgers(
        ledCat: ledCat,
        coBrId: UserSession.coBrId ?? '',
      );
      if (response['statusCode'] == 200 && response['result'] != null) {
        onSuccess(response['result']);
      }
    } catch (e) {
      print('Error fetching $ledCat: $e');
    }
  }

 Future<void> _fetchDiscTerms() async {
  try {
    final List<Map<String, dynamic>> discTermsData = await ApiService.getPaymentDiscount();
    
    if (discTermsData.isNotEmpty) {
      setState(() {
        discTermsList = discTermsData.map((item) {
          return KeyName(
            key: item['PytTermDisc_Key']?.toString() ?? '',
            name: item['PytTermDisc_Name']?.toString() ?? '',
            extra: item,
          );
        }).toList();
      });
    }
  } catch (e) {
    print('Error fetching disc terms: $e');
  }
}
  Future<void> _fetchCurrency() async {
    currencyList = [
      KeyName(key: 'INR', name: 'Indian Rupee (INR)'),
      KeyName(key: 'USD', name: 'US Dollar (USD)'),
      KeyName(key: 'EUR', name: 'Euro (EUR)'),
      KeyName(key: 'GBP', name: 'British Pound (GBP)'),
      KeyName(key: 'AED', name: 'UAE Dirham (AED)'),
    ];
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Purchase Inward Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Party Details Section
                  _buildSectionHeader('Party Details'),
                  const SizedBox(height: 16),
                  _buildReadOnlyField('Party', partyController),
                  const SizedBox(height: 12),
                  _buildReadOnlyField('Station', partyStationController),
                  const SizedBox(height: 12),
                  _buildTextField('Address', partyAddressController, maxLines: 2),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Delivery Schedule Section
                  _buildSectionHeader('Delivery Schedule'),
                  const SizedBox(height: 16),
                  _buildRadioGroup(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Delivery Days', deliveryDaysController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDateField('Delivery Date', deliveryDateController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownFieldWithList(
                          'Disc Terms',
                          discTermsList,
                          selectedDiscTerms,
                          (value, key) => setState(() {
                            selectedDiscTerms = value;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Pyt Days', pytDaysController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDateField('Due Date', dueDateController),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Other Details Section
                  _buildSectionHeader('Other Details'),
                  const SizedBox(height: 16),
                  _buildDropdownFieldWithList('Transporter', transporterList, selectedTransporter, (value, key) {
                    setState(() => selectedTransporter = value);
                  }),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('LR No', lrNoController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDateField('LR Date', lrDateController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownFieldWithList('Broker', brokerList, selectedBroker, (value, key) {
                          setState(() => selectedBroker = value);
                        }),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Comm %', commPercentController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownFieldWithList('Currency', currencyList, selectedCurrency, (value, key) {
                          setState(() => selectedCurrency = value);
                        }),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('E-way Bill No', eWayBillNoController)),
                    ],
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildRadioGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Radio<String>(
              value: 'Common',
              groupValue: deliverySchedule,
              onChanged: (value) {
                setState(() {
                  deliverySchedule = value;
                });
              },
              activeColor: AppColors.primaryColor,
            ),
            const Text('Common'),
            const SizedBox(width: 24),
            Radio<String>(
              value: 'Designwise',
              groupValue: deliverySchedule,
              onChanged: (value) {
                setState(() {
                  deliverySchedule = value;
                });
              },
              activeColor: AppColors.primaryColor,
            ),
            const Text('Designwise'),
          ],
        ),
      ],
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return GestureDetector(
      onTap: () => _selectDate(controller),
      child: TextFormField(
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          suffixIcon: const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildDropdownFieldWithList(
    String label,
    List<KeyName> items,
    String? selectedValue,
    Function(String?, String?) onChanged,
  ) {
    List<String> itemStrings = items.map((e) => e.name).toList();

    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: "Search $label",
            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
        ),
      ),
      items: itemStrings,
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      dropdownBuilder: (context, selectedItem) => Text(
        selectedItem ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      onChanged: (val) {
        final selected = items.firstWhere(
          (e) => e.name == val,
          orElse: () => KeyName(key: '', name: ''),
        );
        onChanged(val, selected.key);
      },
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
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20, color: Colors.white),
                  label: const Text(
                    "Cancel",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
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
                  onPressed: () {
                    Navigator.pop(context, {
                      'partyAddress': partyAddressController.text,
                      'deliverySchedule': deliverySchedule,
                      'deliveryDays': deliveryDaysController.text,
                      'deliveryDate': deliveryDateController.text,
                      'discTerms': selectedDiscTerms,
                      'pytDays': pytDaysController.text,
                      'dueDate': dueDateController.text,
                      'transporter': selectedTransporter,
                      'lrNo': lrNoController.text,
                      'lrDate': lrDateController.text,
                      'broker': selectedBroker,
                      'commPercent': commPercentController.text,
                      'currency': selectedCurrency,
                      'eWayBillNo': eWayBillNoController.text,
                    });
                  },
                  icon: const Icon(Icons.check, size: 20, color: Colors.white),
                  label: const Text(
                    "Confirm",
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
}