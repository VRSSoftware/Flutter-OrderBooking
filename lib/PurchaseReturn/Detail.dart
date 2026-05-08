import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/models/keyName.dart';

class PurchaseReturnDetailsPage extends StatefulWidget {
  final String? supplierKey;
  final String? supplierName;
  final String? supplierStation;
  final List<Map<String, dynamic>> selectedItems;

  const PurchaseReturnDetailsPage({
    Key? key,
    this.supplierKey,
    this.supplierName,
    this.supplierStation,
    this.selectedItems = const [],
  }) : super(key: key);

  @override
  _PurchaseReturnDetailsPageState createState() => _PurchaseReturnDetailsPageState();
}

class _PurchaseReturnDetailsPageState extends State<PurchaseReturnDetailsPage> {
  // ==================== PARTY DETAILS SECTION ====================
  final TextEditingController partyController = TextEditingController();
  final TextEditingController partyStationController = TextEditingController();
  final TextEditingController partyAddressController = TextEditingController();

  // ==================== OTHER DETAILS SECTION ====================
  String? selectedTransporter;
  final TextEditingController lrNoController = TextEditingController();
  final TextEditingController lrDateController = TextEditingController();
  String? selectedBroker;
  final TextEditingController commPercentController = TextEditingController();
  String? selectedCurrency;

  // ==================== DROPDOWN DATA ====================
  List<KeyName> transporterList = [];
  List<KeyName> brokerList = [];
  List<KeyName> currencyList = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    partyController.text = widget.supplierName ?? '';
    partyStationController.text = widget.supplierStation ?? '';
    lrDateController.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
    
    _loadDropdownData();
  }

  @override
  void dispose() {
    partyController.dispose();
    partyStationController.dispose();
    partyAddressController.dispose();
    lrNoController.dispose();
    lrDateController.dispose();
    commPercentController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    setState(() => isLoading = true);
    
    try {
      await Future.wait([
        _fetchLedgers('T', (data) => transporterList = data),
        _fetchLedgers('B', (data) => brokerList = data),
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

  Future<void> _fetchCurrency() async {
    // Currency options
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
        controller.text = DateFormat('dd-MM-yyyy').format(picked);
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
          'Purchase Return Details',
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

                  // Other Details Section
                  _buildSectionHeader('Other Details'),
                  const SizedBox(height: 16),
                  _buildDropdownField('Transporter', transporterList, selectedTransporter, (value) {
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
                      Expanded(child: _buildDropdownField('Broker', brokerList, selectedBroker, (value) {
                        setState(() => selectedBroker = value);
                      })),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Comm %', commPercentController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownField('Currency', currencyList, selectedCurrency, (value) {
                    setState(() => selectedCurrency = value);
                  }),

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

  Widget _buildDropdownField(
    String label,
    List<KeyName> items,
    String? selectedValue,
    Function(String?) onChanged,
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
      onChanged: onChanged,
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
                    // Save details and return
                    Navigator.pop(context, {
                      'party': {
                        'address': partyAddressController.text,
                      },
                      'other': {
                        'transporter': selectedTransporter,
                        'lrNo': lrNoController.text,
                        'lrDate': lrDateController.text,
                        'broker': selectedBroker,
                        'commPercent': commPercentController.text,
                        'currency': selectedCurrency,
                      },
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