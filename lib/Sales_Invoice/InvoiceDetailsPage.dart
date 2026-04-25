import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/models/keyName.dart';

class InvoiceDetailsPage extends StatefulWidget {
  final String? partyKey;
  final String? partyName;
  final String? partyStation;
  final List<Map<String, dynamic>> selectedDespatches;

  const InvoiceDetailsPage({
    Key? key,
    this.partyKey,
    this.partyName,
    this.partyStation,
    this.selectedDespatches = const [],
  }) : super(key: key);

  @override
  _InvoiceDetailsPageState createState() => _InvoiceDetailsPageState();
}

class _InvoiceDetailsPageState extends State<InvoiceDetailsPage> {
  // ==================== DISPATCH SECTION ====================
  String? selectedPackingNo;
  Map<String, dynamic>? selectedPackingData;
  List<Map<String, dynamic>> packingList = [];
  final TextEditingController packingDateController = TextEditingController();
  final TextEditingController orderNoController = TextEditingController();
  final TextEditingController orderDateController = TextEditingController();
  String? selectedTransporter;
  final TextEditingController lrNoController = TextEditingController();
  final TextEditingController lrDateController = TextEditingController();
  String? selectedDiscTerm;
  final TextEditingController dueDtController = TextEditingController();
  final TextEditingController vehicleNoController = TextEditingController();
  String? selectedConcPerson;
  final TextEditingController pytDaysController = TextEditingController();
  final TextEditingController ourOrderNoController = TextEditingController();

  // ==================== PARTY DETAILS SECTION ====================
  final TextEditingController partyController = TextEditingController();
  final TextEditingController partyStationController = TextEditingController();
  final TextEditingController partyAddressController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController deliveryModeController = TextEditingController();
  String? selectedConsignee;
  final TextEditingController stationController = TextEditingController();
  final TextEditingController refNoController = TextEditingController();
  final TextEditingController consigneeAddressController = TextEditingController();
  final TextEditingController consigneeConPersonController = TextEditingController();

  // ==================== OTHER DETAILS SECTION ====================
  String? selectedSalesPerson;
  final TextEditingController commPercentController = TextEditingController();
  String? selectedBroker;
  final TextEditingController brokerCommPercentController = TextEditingController();
  final TextEditingController cartonNoController = TextEditingController();
  final TextEditingController grossWgtController = TextEditingController();
  String? selectedCurrency;
  final TextEditingController nettWgtController = TextEditingController();
  final TextEditingController votWgtController = TextEditingController();
  final TextEditingController eWayBillNoController = TextEditingController();
  String? selectedFormType;
  final TextEditingController freightController = TextEditingController();
  String? selectedTrspMode;
  final TextEditingController rtgsDetailsController = TextEditingController();
  final TextEditingController portOfDiscController = TextEditingController();

  // ==================== DROPDOWN DATA ====================
  List<KeyName> transporterList = [];
  List<KeyName> discTermList = [];
  List<KeyName> concPersonList = [];
  List<KeyName> consigneeList = [];
  List<KeyName> salesPersonList = [];
  List<KeyName> brokerList = [];
  List<KeyName> currencyList = [];

  bool isLoading = true;

  // Form type options
  final List<String> formTypeOptions = [
    'No Form',
    'C-Form',
    'F-Form',
    'H-Form',
    'I-Form'
  ];

  // Transport mode options
  final List<String> trspModeOptions = [
    'By Road',
    'By Rail',
    'By Ship',
    'By Air'
  ];

  @override
  void initState() {
    super.initState();
    partyController.text = widget.partyName ?? '';
    partyStationController.text = widget.partyStation ?? '';
    stationController.text = widget.partyStation ?? '';
    packingDateController.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
    lrDateController.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
    orderDateController.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
    dueDtController.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
    
    _loadPackingList();
    _loadDropdownData();
  }

  Future<void> _loadPackingList() async {
    if (widget.selectedDespatches.isEmpty) return;
    
    List<int> docIds = widget.selectedDespatches.map((d) => d['Doc_Id'] as int).toList();
    
    try {
      final response = await ApiService.fetchPackingDetailsForBill(docIds: docIds);
      
      if (response['status'] == 'success' && response['data'] != null) {
        final List<dynamic> data = response['data'];
        Map<String, Map<String, dynamic>> uniquePackings = {};
        
        for (var item in data) {
          String docNo = item['Doc_No'].toString();
          if (!uniquePackings.containsKey(docNo)) {
            uniquePackings[docNo] = {
              'Doc_Id': item['Doc_Id'],
              'Doc_No': docNo,
              'Doc_Dt': item['Doc_Dt'],
            };
          }
        }
        
        setState(() {
          packingList = uniquePackings.values.toList();
        });
      }
    } catch (e) {
      print('Error loading packing list: $e');
    }
  }

  Future<void> _loadDropdownData() async {
    setState(() => isLoading = true);
    
    try {
      await Future.wait([
        _fetchLedgers('T', (data) => transporterList = data),
        _fetchLedgers('S', (data) => salesPersonList = data),
        _fetchLedgers('B', (data) => brokerList = data),
        _fetchConsignees(),
        _fetchCurrency(),
        _fetchDiscTerm(),
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

  Future<void> _fetchConsignees() async {
    if (widget.partyKey == null) return;
    try {
      final response = await ApiService.fetchConsinees(
        key: widget.partyKey!,
        CoBrId: UserSession.coBrId ?? '',
      );
      if (response['statusCode'] == 200 && response['result'] != null) {
        setState(() {
          consigneeList = response['result'];
        });
      }
    } catch (e) {
      print('Error fetching consignees: $e');
    }
  }

  Future<void> _fetchCurrency() async {
    // Add your currency API call here
    currencyList = [
      KeyName(key: 'INR', name: 'INR'),
      KeyName(key: 'USD', name: 'USD'),
      KeyName(key: 'EUR', name: 'EUR'),
    ];
  }

  Future<void> _fetchDiscTerm() async {
    // Add your discount term API call here
    discTermList = [
      KeyName(key: '1', name: 'No Discount'),
      KeyName(key: '2', name: 'Cash Discount'),
      KeyName(key: '3', name: 'Trade Discount'),
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

  void _onPackingNoChange(String? docNo) {
    if (docNo == null) return;
    setState(() {
      selectedPackingNo = docNo;
      selectedPackingData = packingList.firstWhere(
        (p) => p['Doc_No'] == docNo,
        orElse: () => {},
      );
      if (selectedPackingData != null && selectedPackingData!['Doc_Dt'] != null) {
        try {
          DateTime date = DateTime.parse(selectedPackingData!['Doc_Dt']);
          packingDateController.text = DateFormat('dd-MM-yyyy').format(date);
        } catch (e) {}
      }
    });
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
          'Invoice Details',
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
                  // Dispatch Section
                  _buildSectionHeader('Dispatch Section'),
                  const SizedBox(height: 16),
                  _buildDropdownField('Packing No', packingList, selectedPackingNo, _onPackingNoChange),
                  const SizedBox(height: 12),
                  _buildDateField('Date', packingDateController),
                  const SizedBox(height: 12),
                  _buildTextField('Order No', orderNoController),
                  const SizedBox(height: 12),
                  _buildDateField('Order Date', orderDateController),
                  const SizedBox(height: 12),
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
                  _buildDropdownField('Disc Term', discTermList, selectedDiscTerm, (value) {
                    setState(() => selectedDiscTerm = value);
                  }),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildDateField('Due Dt', dueDtController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Vehicle No', vehicleNoController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownField('Conc Person', concPersonList, selectedConcPerson, (value) {
                    setState(() => selectedConcPerson = value);
                  }),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Pyt Days', pytDaysController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Our Order No', ourOrderNoController)),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Party Details Section
                  _buildSectionHeader('Party Details'),
                  const SizedBox(height: 16),
                  _buildReadOnlyField('Party', partyController),
                  const SizedBox(height: 12),
                  _buildReadOnlyField('Party Station', partyStationController),
                  const SizedBox(height: 12),
                  _buildTextField('Party Address', partyAddressController, maxLines: 2),
                  const SizedBox(height: 12),
                  _buildTextField('Destination', destinationController),
                  const SizedBox(height: 12),
                  _buildTextField('Delivery Module', deliveryModeController),
                  const SizedBox(height: 12),
                  _buildDropdownField('Consignee', consigneeList, selectedConsignee, (value) {
                    setState(() => selectedConsignee = value);
                  }),
                  const SizedBox(height: 12),
                  _buildReadOnlyField('Station', stationController),
                  const SizedBox(height: 12),
                  _buildTextField('Ref No', refNoController),
                  const SizedBox(height: 12),
                  _buildTextField('Address', consigneeAddressController, maxLines: 2),
                  const SizedBox(height: 12),
                  _buildTextField('Consignee Con. Person', consigneeConPersonController),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Other Details Section
                  _buildSectionHeader('Other Details'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildDropdownField('Salesperson', salesPersonList, selectedSalesPerson, (value) {
                        setState(() => selectedSalesPerson = value);
                      })),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Comm %', commPercentController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildDropdownField('Broker', brokerList, selectedBroker, (value) {
                        setState(() => selectedBroker = value);
                      })),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Broker Comm %', brokerCommPercentController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Carton No', cartonNoController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Gross Wgt', grossWgtController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildDropdownField('Currency', currencyList, selectedCurrency, (value) {
                        setState(() => selectedCurrency = value);
                      })),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Nett Wgt', nettWgtController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Vot Wgt', votWgtController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('E-Way Bill No', eWayBillNoController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownField('Form Type', formTypeOptions, selectedFormType, (value) {
                    setState(() => selectedFormType = value);
                  }),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Freight', freightController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDropdownField('Trsp Mode', trspModeOptions, selectedTrspMode, (value) {
                        setState(() => selectedTrspMode = value);
                      })),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField('RTGS Details', rtgsDetailsController, maxLines: 2),
                  const SizedBox(height: 12),
                  _buildTextField('Port of Disc', portOfDiscController),

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
    List<dynamic> items,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    List<String> itemStrings = items.map((e) {
      if (e is KeyName) return e.name;
      return e.toString();
    }).toList();

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
                      'dispatch': {
                        'packingNo': selectedPackingNo,
                        'date': packingDateController.text,
                        'orderNo': orderNoController.text,
                        'orderDate': orderDateController.text,
                        'transporter': selectedTransporter,
                        'lrNo': lrNoController.text,
                        'lrDate': lrDateController.text,
                        'discTerm': selectedDiscTerm,
                        'dueDt': dueDtController.text,
                        'vehicleNo': vehicleNoController.text,
                        'concPerson': selectedConcPerson,
                        'pytDays': pytDaysController.text,
                        'ourOrderNo': ourOrderNoController.text,
                      },
                      'party': {
                        'address': partyAddressController.text,
                        'destination': destinationController.text,
                        'deliveryMode': deliveryModeController.text,
                        'consignee': selectedConsignee,
                        'refNo': refNoController.text,
                        'consigneeAddress': consigneeAddressController.text,
                        'consigneePerson': consigneeConPersonController.text,
                      },
                      'other': {
                        'salesPerson': selectedSalesPerson,
                        'commPercent': commPercentController.text,
                        'broker': selectedBroker,
                        'brokerComm': brokerCommPercentController.text,
                        'cartonNo': cartonNoController.text,
                        'grossWgt': grossWgtController.text,
                        'currency': selectedCurrency,
                        'nettWgt': nettWgtController.text,
                        'votWgt': votWgtController.text,
                        'eWayBillNo': eWayBillNoController.text,
                        'formType': selectedFormType,
                        'freight': freightController.text,
                        'trspMode': selectedTrspMode,
                        'rtgsDetails': rtgsDetailsController.text,
                        'portOfDisc': portOfDiscController.text,
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