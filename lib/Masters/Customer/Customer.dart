// lib/widgets/customer_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/services/app_services.dart';

class CustomerForm extends StatefulWidget {
  final String? editItemId;
  final VoidCallback? onSuccess;
  final VoidCallback? onClose;

  const CustomerForm({Key? key, this.editItemId, this.onSuccess, this.onClose})
    : super(key: key);

  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  final _formKey = GlobalKey<FormState>();

  bool _isEditMode = false;
  bool _isLoading = false;
  bool _isSaving = false;

  // Section expansion states
  bool _basicInfoExpanded = true;
  bool _officeAddressExpanded = false;
  bool _bankDetailsExpanded = false;
  bool _taxInfoExpanded = false;
  bool _discountExpanded = false;

  // Text Editing Controllers
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _printNameController = TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _gstNoController = TextEditingController();
  final TextEditingController _mobile1Controller = TextEditingController();
  final TextEditingController _mobile2Controller = TextEditingController();
  final TextEditingController _brokerCommController = TextEditingController();
  final TextEditingController _spcommPercController = TextEditingController();
  final TextEditingController _splMkDownController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _phone1Controller = TextEditingController();
  final TextEditingController _phone2Controller = TextEditingController();
  final TextEditingController _email1Controller = TextEditingController();
  final TextEditingController _email2Controller = TextEditingController();
  final TextEditingController _faxController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _creditLimitController = TextEditingController();
  final TextEditingController _creditDaysController = TextEditingController();
  final TextEditingController _intPercController = TextEditingController();
  final TextEditingController _billLimitController = TextEditingController();
  final TextEditingController _panNoController = TextEditingController();
  final TextEditingController _tanNoController = TextEditingController();
  final TextEditingController _aadharNoController = TextEditingController();
  final TextEditingController _udyamNoController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _dispatchOrderController =
      TextEditingController();
  final TextEditingController _stopDispatchController = TextEditingController();

  // Dropdown selected values
  KeyName? _selectedStation;
  KeyName? _selectedBrand;
  KeyName? _selectedAccountGroup;
  KeyName? _selectedCardType;
  KeyName? _selectedBroker;
  KeyName? _selectedSalesPerson;
  KeyName? _selectedCurrency;
  KeyName? _selectedTransporter;
  KeyName? _selectedDiscTerm;
  KeyName? _selectedExecuted;
  KeyName? _selectedSalesType;

  // Simple dropdown values
  String _selectedCategory = 'Customer';
  String _selectedRoundOff = 'None';
  String _selectedCreditLimitExceeds = '';
  String _selectedBillLimitExc = '';
  String _selectedUdyamType = '';
  String _selectedPriceList = 'common';
  bool _isActive = true;

  bool _showSuccessDialog = false;
  bool _showErrorDialog = false;
  String _successMessage = '';
  String _errorMessage = '';

  // Dropdown data lists
  List<KeyName> _stations = [];
  List<KeyName> _brands = [];
  List<KeyName> _accountGroups = [];
  List<KeyName> _cardTypes = [];
  List<KeyName> _brokers = [];
  List<KeyName> _salesPersons = [];
  List<KeyName> _currencies = [];
  List<KeyName> _transporters = [];
  List<KeyName> _discountTerms = [];
  List<KeyName> _executedOptions = [];
  List<KeyName> _discountNameOptions = [];
  List<KeyName> _salesTypes = [];

  // Discounts list
  List<Map<String, dynamic>> _discounts = [];
  KeyName? _selectedDiscountName;
  final TextEditingController _discountPercentController =
      TextEditingController();

  // Options
  final List<Map<String, String>> _categoryOptions = [
    {'display': 'Customer', 'value': 'Customer'},
    {'display': 'Consignee', 'value': 'Consignee'},
    {'display': 'Branch', 'value': 'Branch'},
    {'display': 'All', 'value': 'All'},
    {'display': 'Franchisee', 'value': 'Franchisee'},
  ];

  final List<Map<String, String>> _priceListOptions = [
    {'display': 'Common', 'value': 'common'},
    {'display': 'Premium', 'value': 'premium'},
    {'display': 'Wholesale', 'value': 'wholesale'},
  ];

  final List<Map<String, String>> _creditLimitOptions = [
    {'display': 'None', 'value': 'R'},
    {'display': 'Indicate', 'value': 'I'},
    {'display': 'Stop Billing', 'value': 'S'},
  ];

  final List<Map<String, String>> _udyamTypeOptions = [
    {'display': 'Micro', 'value': 'M'},
    {'display': 'Small', 'value': 'S'},
    {'display': 'Medium', 'value': 'D'},
    {'display': 'Large', 'value': 'L'},
    {'display': 'Unregistered', 'value': 'U'},
  ];

  @override
  void initState() {
    super.initState();
    _setupFieldListeners();
    _fetchAllData().then((_) {
      if (widget.editItemId != null && widget.editItemId!.isNotEmpty) {
        _isEditMode = true;
        _fetchCustomerData(widget.editItemId!);
      }
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _printNameController.dispose();
    _contactPersonController.dispose();
    _codeController.dispose();
    _gstNoController.dispose();
    _mobile1Controller.dispose();
    _mobile2Controller.dispose();
    _brokerCommController.dispose();
    _spcommPercController.dispose();
    _splMkDownController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _pinController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _email1Controller.dispose();
    _email2Controller.dispose();
    _faxController.dispose();
    _websiteController.dispose();
    _creditLimitController.dispose();
    _creditDaysController.dispose();
    _intPercController.dispose();
    _billLimitController.dispose();
    _panNoController.dispose();
    _tanNoController.dispose();
    _aadharNoController.dispose();
    _udyamNoController.dispose();
    _remarkController.dispose();
    _dispatchOrderController.dispose();
    _stopDispatchController.dispose();
    _discountPercentController.dispose();
    super.dispose();
  }

  void _setupFieldListeners() {
    _customerNameController.addListener(() {
      _printNameController.text = _customerNameController.text;
    });
  }

  void _showErrorDialogBox() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: AppColors.red,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.slate600,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _errorMessage = '';
                        _showErrorDialog = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialogBox() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.accentColor,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Success!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _successMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.slate600,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog only
                      widget.onSuccess?.call();
                      widget.onClose?.call(); // This should close the form
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchCustomerData(String ledKey) async {
    setState(() => _isLoading = true);
    try {
      final customerData = await ApiService.getLedgerByLedKey(ledKey);

      if (customerData.isNotEmpty) {
        // Set text controllers
        _customerNameController.text = customerData['Led_Name'] ?? '';
        _printNameController.text = customerData['Abbr'] ?? '';
        _contactPersonController.text = customerData['Co_Name'] ?? '';
        _codeController.text = customerData['Alt_Code'] ?? '';
        _gstNoController.text = customerData['GSTNo'] ?? '';
        _mobile1Controller.text = customerData['Mobile1'] ?? '';
        _mobile2Controller.text = customerData['Mobile2'] ?? '';
        _brokerCommController.text =
            customerData['Comm_Perc']?.toString() ?? '';
        _spcommPercController.text =
            customerData['Spcomm_Perc']?.toString() ?? '';
        _splMkDownController.text = customerData['SplMkDown']?.toString() ?? '';
        _addressController.text = customerData['OAddr'] ?? '';
        _areaController.text = customerData['OPlace'] ?? '';
        _pinController.text = customerData['OPin'] ?? '';
        _phone1Controller.text = customerData['OTel1'] ?? '';
        _phone2Controller.text = customerData['OTel2'] ?? '';
        _email1Controller.text = customerData['OEmail'] ?? '';
        _email2Controller.text = customerData['OAltEMail'] ?? '';
        _faxController.text = customerData['OFax'] ?? '';
        _websiteController.text = customerData['OWebsite'] ?? '';
        _creditLimitController.text =
            customerData['Credit_Limit']?.toString() ?? '';
        _creditDaysController.text =
            customerData['Credit_Period']?.toString() ?? '';
        _intPercController.text = customerData['Int_Perc']?.toString() ?? '';
        _billLimitController.text = customerData['BillLimit']?.toString() ?? '';
        _panNoController.text = customerData['PANNo'] ?? '';
        _tanNoController.text = customerData['TANNo'] ?? '';
        _aadharNoController.text = customerData['AdharNo'] ?? '';
        _udyamNoController.text = customerData['UdyamNo'] ?? '';
        _remarkController.text = customerData['Remark'] ?? '';
        _dispatchOrderController.text = customerData['DispatchOrder'] ?? '';
        _stopDispatchController.text = customerData['StopDispatch'] ?? '';

        // Set dropdown values
        _selectedCategory =
            customerData['Led_Type'] == 'R'
                ? 'Customer'
                : customerData['Led_Type'] == 'C'
                ? 'Consignee'
                : 'Customer';
        _selectedRoundOff = customerData['RdOff'] == '1' ? 'RS' : 'None';
        _isActive = customerData['Status'] == '1';
        _selectedCreditLimitExceeds = customerData['CreditLimitExceeds'] ?? '';
        _selectedBillLimitExc = customerData['BillLimitExc'] ?? '';
        _selectedUdyamType = customerData['UdyamType'] ?? '';
        _selectedPriceList = customerData['Price_List'] ?? 'common';

        // Find and set selected dropdowns from lists - Set to null if not found

        // Station
        if (customerData['OStn_Key'] != null &&
            customerData['OStn_Key'].toString().isNotEmpty) {
          final station = _stations.firstWhere(
            (station) => station.key == customerData['OStn_Key'],
            orElse: () => KeyName(key: '', name: ''),
          );
          _selectedStation = station.key.isNotEmpty ? station : null;
        } else {
          _selectedStation = null;
        }

        // Brand
        if (customerData['CustBrand_key'] != null &&
            customerData['CustBrand_key'].toString().isNotEmpty) {
          final brand = _brands.firstWhere(
            (brand) => brand.key == customerData['CustBrand_key'],
            orElse: () => KeyName(key: '', name: ''),
          );
          _selectedBrand = brand.key.isNotEmpty ? brand : null;
        } else {
          _selectedBrand = null;
        }

        // Account Group
        if (customerData['AccLGrp_Key'] != null &&
            customerData['AccLGrp_Key'].toString().isNotEmpty) {
          final accountGroup = _accountGroups.firstWhere(
            (group) => group.key == customerData['AccLGrp_Key'],
            orElse: () => KeyName(key: '', name: ''),
          );
          _selectedAccountGroup =
              accountGroup.key.isNotEmpty ? accountGroup : null;
        } else {
          _selectedAccountGroup = null;
        }

        // Card Type
        if (customerData['CardType_Key'] != null &&
            customerData['CardType_Key'].toString().isNotEmpty) {
          final cardType = _cardTypes.firstWhere(
            (card) => card.key == customerData['CardType_Key'],
            orElse: () => KeyName(key: '', name: ''),
          );
          _selectedCardType = cardType.key.isNotEmpty ? cardType : null;
        } else {
          _selectedCardType = null;
        }

        // Broker
        if (customerData['Broker_Key'] != null &&
            customerData['Broker_Key'].toString().isNotEmpty) {
          final broker = _brokers.firstWhere(
            (broker) => broker.key == customerData['Broker_Key'],
            orElse: () => KeyName(key: '', name: ''),
          );
          _selectedBroker = broker.key.isNotEmpty ? broker : null;
        } else {
          _selectedBroker = null;
        }

        // Sales Person
        if (customerData['SalesPerson_Key'] != null &&
            customerData['SalesPerson_Key'].toString().isNotEmpty) {
          final salesPerson = _salesPersons.firstWhere(
            (person) => person.key == customerData['SalesPerson_Key'],
            orElse: () => KeyName(key: '', name: ''),
          );
          _selectedSalesPerson =
              salesPerson.key.isNotEmpty ? salesPerson : null;
        } else {
          _selectedSalesPerson = null;
        }

        // Currency
        if (customerData['Currn_key'] != null &&
            customerData['Currn_key'].toString().isNotEmpty) {
          final currency = _currencies.firstWhere(
            (currency) => currency.key == customerData['Currn_key'],
            orElse: () => KeyName(key: '', name: ''),
          );
          _selectedCurrency = currency.key.isNotEmpty ? currency : null;
        } else {
          _selectedCurrency = null;
        }

        // Transporter
        if (customerData['Trsp_Key'] != null &&
            customerData['Trsp_Key'].toString().isNotEmpty) {
          final transporter = _transporters.firstWhere(
            (trans) => trans.key == customerData['Trsp_Key'],
            orElse: () => KeyName(key: '', name: ''),
          );
          _selectedTransporter =
              transporter.key.isNotEmpty ? transporter : null;
        } else {
          _selectedTransporter = null;
        }

        // Discount Term
        if (customerData['PytTermDisc_Key'] != null &&
            customerData['PytTermDisc_Key'].toString().isNotEmpty) {
          final discTerm = _discountTerms.firstWhere(
            (term) => term.key == customerData['PytTermDisc_Key'],
            orElse: () => KeyName(key: '', name: ''),
          );
          _selectedDiscTerm = discTerm.key.isNotEmpty ? discTerm : null;
        } else {
          _selectedDiscTerm = null;
        }

        // Executed
        if (customerData['Exec_key'] != null &&
            customerData['Exec_key'].toString().isNotEmpty) {
          final executed = _executedOptions.firstWhere(
            (exec) => exec.key == customerData['Exec_key'],
            orElse: () => KeyName(key: '', name: ''),
          );
          _selectedExecuted = executed.key.isNotEmpty ? executed : null;
        } else {
          _selectedExecuted = null;
        }

        // Sales Type
        if (customerData['sales_Led_Key'] != null &&
            customerData['sales_Led_Key'].toString().isNotEmpty) {
          final salesType = _salesTypes.firstWhere(
            (type) => type.key == customerData['sales_Led_Key'],
            orElse: () => KeyName(key: '', name: ''),
          );
          _selectedSalesType = salesType.key.isNotEmpty ? salesType : null;
        } else {
          _selectedSalesType = null;
        }

        // Load discounts if any
        if (customerData['Discounts'] != null &&
            customerData['Discounts'] is List) {
          _discounts = List<Map<String, dynamic>>.from(
            customerData['Discounts'],
          );
        }
      }
    } catch (e) {
      print('Error fetching customer data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading customer data: $e'),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      final stationsResponse = await ApiService.fetchStations(
        coBrId: UserSession.coBrId ?? '',
      );
      if (stationsResponse['statusCode'] == 200 &&
          stationsResponse['result'] is List) {
        _stations = List<KeyName>.from(stationsResponse['result']);
        if (_stations.isNotEmpty) {
          _selectedStation = _stations[0];
          _areaController.text = _selectedStation!.name;
        }
      }

      try {
        final brandsResponse = await ApiService.getBrandForCust();
        if (brandsResponse is List && brandsResponse.isNotEmpty) {
          _brands =
              brandsResponse
                  .map(
                    (item) => KeyName(
                      key: item['Brand_Key']?.toString() ?? '',
                      name: item['Brand_Name']?.toString() ?? '',
                    ),
                  )
                  .toList();
        }
      } catch (e) {
        _brands = [];
      }

      try {
        final accountGroupsResponse = await ApiService.getAccountSubGroups();
        if (accountGroupsResponse is List && accountGroupsResponse.isNotEmpty) {
          _accountGroups =
              accountGroupsResponse
                  .map(
                    (item) => KeyName(
                      key: item['AccLGrp_Key']?.toString() ?? '',
                      name: item['AccLGrp_Name']?.toString() ?? '',
                    ),
                  )
                  .toList();
          if (_accountGroups.isNotEmpty && _selectedAccountGroup == null)
            _selectedAccountGroup = _accountGroups[0];
        }
      } catch (e) {
        _accountGroups = [];
      }

      try {
        final cardTypesResponse = await ApiService.getCardType();
        if (cardTypesResponse is List && cardTypesResponse.isNotEmpty) {
          _cardTypes =
              cardTypesResponse
                  .map(
                    (item) => KeyName(
                      key: item['CardType_Key']?.toString() ?? '',
                      name: item['CardType_Name']?.toString() ?? '',
                    ),
                  )
                  .toList();
          if (_cardTypes.isNotEmpty && _selectedCardType == null)
            _selectedCardType = _cardTypes[0];
        }
      } catch (e) {
        _cardTypes = [];
      }

      try {
        final brokersResponse = await ApiService.fetchLedgers(
          ledCat: 'B',
          coBrId: UserSession.coBrId ?? '',
        );
        if (brokersResponse['statusCode'] == 200 &&
            brokersResponse['result'] is List) {
          _brokers = List<KeyName>.from(brokersResponse['result']);
        }
      } catch (e) {
        _brokers = [];
      }

      try {
        final salesPersonsResponse = await ApiService.fetchLedgers(
          ledCat: 'S',
          coBrId: UserSession.coBrId ?? '',
        );
        if (salesPersonsResponse['statusCode'] == 200 &&
            salesPersonsResponse['result'] is List) {
          _salesPersons = List<KeyName>.from(salesPersonsResponse['result']);
        }
      } catch (e) {
        _salesPersons = [];
      }

      try {
        final currenciesResponse = await ApiService.getCurrency();
        if (currenciesResponse is List && currenciesResponse.isNotEmpty) {
          _currencies =
              currenciesResponse
                  .map(
                    (item) => KeyName(
                      key: item['Currn_Key']?.toString() ?? '',
                      name: item['Currn_Name']?.toString() ?? '',
                    ),
                  )
                  .toList();
          if (_currencies.isNotEmpty && _selectedCurrency == null)
            _selectedCurrency = _currencies[0];
        }
      } catch (e) {
        _currencies = [];
      }

      try {
        final transportersResponse = await ApiService.fetchLedgers(
          ledCat: 'T',
          coBrId: UserSession.coBrId ?? '',
        );
        if (transportersResponse['statusCode'] == 200 &&
            transportersResponse['result'] is List) {
          _transporters = List<KeyName>.from(transportersResponse['result']);
        }
      } catch (e) {
        _transporters = [];
      }

      // Fetch sales types (ledCat: 'L')
      try {
        final salesTypesResponse = await ApiService.fetchLedgers(
          ledCat: 'L',
          coBrId: UserSession.coBrId ?? '',
        );
        if (salesTypesResponse['statusCode'] == 200 &&
            salesTypesResponse['result'] is List) {
          _salesTypes = List<KeyName>.from(salesTypesResponse['result']);
          if (_salesTypes.isNotEmpty && _selectedSalesType == null) {
            _selectedSalesType = _salesTypes[0];
          }
        }
      } catch (e) {
        print('Sales Types API failed: $e');
        _salesTypes = [];
      }

      try {
        final paymentDiscountResponse = await ApiService.getPaymentDiscount();
        if (paymentDiscountResponse is List &&
            paymentDiscountResponse.isNotEmpty) {
          _discountTerms =
              paymentDiscountResponse
                  .map(
                    (item) => KeyName(
                      key: item['PytTermDisc_Key']?.toString() ?? '',
                      name: item['PytTermDisc_Name']?.toString() ?? '',
                      extra: item,
                    ),
                  )
                  .toList();
        }
      } catch (e) {
        _discountTerms = [];
      }

      try {
        final qualityResponse = await ApiService.getQuality();
        if (qualityResponse is List && qualityResponse.isNotEmpty) {
          _executedOptions =
              qualityResponse
                  .map(
                    (item) => KeyName(
                      key: item['Qlty_Key']?.toString() ?? '',
                      name: item['Qlty_Name']?.toString() ?? '',
                    ),
                  )
                  .toList();
        }
      } catch (e) {
        _executedOptions = [];
      }

      try {
        final termsResponse = await ApiService.getTerms();
        if (termsResponse is List && termsResponse.isNotEmpty) {
          _discountNameOptions =
              termsResponse
                  .map(
                    (item) => KeyName(
                      key: item['TxTmTDS_Key']?.toString() ?? '',
                      name: item['TxTmTDS_Name']?.toString() ?? '',
                      extra: item,
                    ),
                  )
                  .toList();
        }
      } catch (e) {
        _discountNameOptions = [];
      }

      setState(() {});
    } catch (e) {
      print('Error in _fetchAllData: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    // Validate form
    if (_customerNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Customer Name is required.';
        _showErrorDialog = true;
      });
      _showErrorDialogBox();
      return;
    }

    setState(() => _isSaving = true);

    try {
      final getLedType = () {
        switch (_selectedCategory) {
          case 'Customer':
            return 'R';
          case 'Consignee':
            return 'C';
          default:
            return 'R';
        }
      };

      final basePayload = {
        "CoBr_Id": UserSession.coBrId ?? "",
        "Led_Name": _customerNameController.text,
        "Abbr": _printNameController.text,
        "Co_Name": _contactPersonController.text,
        "Led_Type": getLedType(),
        "Alt_Code": _codeController.text,
        "GSTLed_Type": "R",
        "Led_Cat": "W",
        "OAddr": _addressController.text,
        "OStn_Key": _selectedStation?.key ?? "",
        "OPlace": _areaController.text,
        "OPin": _pinController.text,
        "OTel1": _phone1Controller.text,
        "OTel2": _phone2Controller.text,
        "OEmail": _email1Controller.text,
        "OAltEMail": _email2Controller.text,
        "RStn_Key": _selectedStation?.key ?? "",
        "RPlace": _areaController.text,
        "RPin": _pinController.text,
        "Mobile1": _mobile1Controller.text,
        "Spcomm_Perc": _spcommPercController.text,
        "Mobile2": _mobile2Controller.text,
        "Credit_Limit": double.tryParse(_creditLimitController.text) ?? 0.0,
        "Credit_Period": int.tryParse(_creditDaysController.text) ?? 0,
        "Int_Perc": double.tryParse(_intPercController.text) ?? 0.0,
        "CreditLimitExceeds": _selectedCreditLimitExceeds,
        "BillLimitExc": _selectedBillLimitExc,
        "PANNo": _panNoController.text,
        "TANNo": _tanNoController.text,
        "GSTNo": _gstNoController.text,
        "Bill_Disc_Perc": 0.0,
        "PartyGrp_Key": "",
        "AccLGrp_Key": _selectedAccountGroup?.key ?? "",
        "CardType_Key": _selectedCardType?.key ?? "",
        "CardNo": "",
        "RdOff": _selectedRoundOff == "RS" ? "1" : "0",
        "BillWise_Dtl": "1",
        "AskRate": "0",
        "Status": _isActive ? "1" : "0",
        "Created_By": 1,
        "Updated_By": 1,
        "RateCat_Id": 1,
        "Loc_Key": "",
        "sales_Led_Key": _selectedSalesType?.key ?? "",
        "Price_List": _selectedPriceList,
        "Broker_Key": _selectedBroker?.key ?? "",
        "Comm_Perc": double.tryParse(_brokerCommController.text) ?? 0.0,
        "SalesPerson_Key": _selectedSalesPerson?.key ?? "",
        "Currn_key": _selectedCurrency?.key ?? "",
        "Trsp_Key": _selectedTransporter?.key ?? "",
        "SplMkDown": double.tryParse(_splMkDownController.text) ?? 0.0,
        "AdharNo": _aadharNoController.text,
        "UdyamType": _selectedUdyamType,
        "UdyamNo": _udyamNoController.text,
        "PytTermDisc_Key": _selectedDiscTerm?.key ?? "",
        "Exec_key": _selectedExecuted?.key ?? "",
        "PortOfDisc": "",
        "DispatchOrder":
            _dispatchOrderController.text.isEmpty
                ? null
                : _dispatchOrderController.text,
        "StopDispatch":
            _stopDispatchController.text.isEmpty
                ? null
                : _stopDispatchController.text,
        "Remark": _remarkController.text,
        "Delivery": "",
        "OFax": _faxController.text,
        "OWebsite": _websiteController.text,
        "BillLimit": double.tryParse(_billLimitController.text) ?? 0.0,
        "Discounts":
            _discounts
                .map(
                  (d) => {
                    'srNo': d['srNo'],
                    'name': d['name'],
                    'percent': d['percent'],
                  },
                )
                .toList(),
        "CustBrand_key": _selectedBrand?.key ?? "",
      };

      if (_isEditMode && widget.editItemId != null) {
        // Update existing customer
        final updatePayload = {
          ...basePayload,
          "Led_Key": widget.editItemId,
          "Updated_By": 1,
        };
        await ApiService.updateLedger(updatePayload);
        _successMessage = "Customer updated successfully";
      } else {
        // Create new customer
        await ApiService.createLedger(basePayload);
        _successMessage = "Customer saved successfully";
      }

      if (mounted) {
        setState(() {
          _showSuccessDialog = true;
        });
        _showSuccessDialogBox();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString().replaceAll('Exception:', '').trim();
          _showErrorDialog = true;
        });
        _showErrorDialogBox();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _handleClear() {
    _customerNameController.clear();
    _printNameController.clear();
    _contactPersonController.clear();
    _codeController.clear();
    _gstNoController.clear();
    _mobile1Controller.clear();
    _mobile2Controller.clear();
    _brokerCommController.clear();
    _spcommPercController.clear();
    _splMkDownController.clear();
    _addressController.clear();
    _areaController.clear();
    _pinController.clear();
    _phone1Controller.clear();
    _phone2Controller.clear();
    _email1Controller.clear();
    _email2Controller.clear();
    _faxController.clear();
    _websiteController.clear();
    _creditLimitController.clear();
    _creditDaysController.clear();
    _intPercController.clear();
    _billLimitController.clear();
    _panNoController.clear();
    _tanNoController.clear();
    _aadharNoController.clear();
    _udyamNoController.clear();
    _remarkController.clear();
    _dispatchOrderController.clear();
    _stopDispatchController.clear();
    _discountPercentController.clear();

    setState(() {
      _selectedCategory = 'Customer';
      _selectedCreditLimitExceeds = '';
      _selectedBillLimitExc = '';
      _selectedUdyamType = '';
      _selectedRoundOff = 'None';
      _selectedPriceList = 'common';
      _isActive = true;
      _discounts = [];
      _selectedDiscountName = null;
      _selectedBrand = null;
      _selectedBroker = null;
      _selectedSalesPerson = null;
      _selectedTransporter = null;
      _selectedDiscTerm = null;
      _selectedExecuted = null;
      _selectedSalesType = null;

      if (_stations.isNotEmpty) {
        _selectedStation = _stations[0];
        _areaController.text = _selectedStation!.name;
      }
      if (_accountGroups.isNotEmpty) _selectedAccountGroup = _accountGroups[0];
      if (_cardTypes.isNotEmpty) _selectedCardType = _cardTypes[0];
      if (_currencies.isNotEmpty) _selectedCurrency = _currencies[0];
    });
  }

  void _handleAddDiscount() {
    if (_selectedDiscountName != null &&
        _discountPercentController.text.isNotEmpty) {
      setState(() {
        _discounts.add({
          'srNo': _discounts.length + 1,
          'name': _selectedDiscountName!.name,
          'percent': double.parse(_discountPercentController.text),
        });
        _selectedDiscountName = null;
        _discountPercentController.clear();
      });
    }
  }

  void _handleRemoveDiscount(int index) {
    setState(() {
      _discounts.removeAt(index);
      for (int i = 0; i < _discounts.length; i++) {
        _discounts[i]['srNo'] = i + 1;
      }
    });
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : keyboardType,
        inputFormatters:
            isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AppColors.primaryColor,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          isDense: true,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (pickedDate != null) {
            controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
          }
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AppColors.primaryColor,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          suffixIcon: const Icon(
            Icons.calendar_today,
            size: 18,
            color: AppColors.slate600,
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<KeyName> items,
    required KeyName? selectedValue,
    required Function(KeyName?) onChanged,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          DropdownSearch<KeyName>(
            key: ValueKey(selectedValue?.key),
            items: items,
            selectedItem: selectedValue,

            itemAsString: (item) => item.name,

            onChanged: (val) {
              setState(() {
                onChanged(val);
              });
            },

            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: isRequired ? '$label *' : label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),

                // 👇 extra right padding for spacing
                contentPadding: const EdgeInsets.fromLTRB(12, 10, 55, 10),
              ),
            ),

            popupProps: PopupProps.menu(showSearchBox: true),

            dropdownBuilder: (context, selectedItem) {
              if (selectedItem == null) {
                return Text(
                  'Select $label',
                  style: const TextStyle(color: Colors.grey),
                );
              }
              return Text(selectedItem.name);
            },

            compareFn: (item, selectedItem) => item.key == selectedItem?.key,
          ),

          // ✅ CLEAR ICON (styled)
          if (selectedValue != null)
            Positioned(
              right: 35, // 👈 spacing from arrow
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    onChanged(null);
                  });
                },
                child: const Icon(
                  Icons.clear,
                  size: 14, // 🔥 smaller size
                  color: Colors.red, // 🔥 red color
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSimpleDropdown({
    required String label,
    required List<Map<String, String>> items,
    required String selectedValue,
    required Function(String) onChanged,
    bool isRequired = false,
  }) {
    String getDisplayText(String value) {
      final item = items.firstWhere(
        (e) => e['value'] == value,
        orElse: () => {'display': value},
      );
      return item['display']!;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          DropdownSearch<String>(
            key: ValueKey(selectedValue),

            items: items.map((e) => e['display']!).toList(),
            selectedItem:
                selectedValue.isEmpty ? null : getDisplayText(selectedValue),

            onChanged: (displayText) {
              if (displayText != null) {
                final item = items.firstWhere(
                  (e) => e['display'] == displayText,
                  orElse: () => {'value': selectedValue},
                );
                setState(() {
                  onChanged(item['value']!);
                });
              }
            },

            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: isRequired ? '$label *' : label,
                labelStyle: const TextStyle(fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 1.5,
                  ),
                ),

                // 👇 space for clear icon
                contentPadding: const EdgeInsets.fromLTRB(12, 10, 55, 10),

                isDense: true,
              ),
            ),

            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: 'Search $label',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            dropdownBuilder: (context, selectedDisplayText) {
              if (selectedDisplayText == null || selectedDisplayText.isEmpty) {
                return Text(
                  'Select $label',
                  style: const TextStyle(color: Colors.grey),
                );
              }
              return Text(selectedDisplayText);
            },
          ),

          // ✅ CLEAR ICON
          if (selectedValue.isNotEmpty)
            Positioned(
              right: 35,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    onChanged(''); // clear value
                  });
                },
                child: const Icon(Icons.clear, size: 14, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              _isEditMode ? 'Edit Customer' : 'Add Customer',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            // Section 1: Basic Information
                            _buildSectionHeader(
                              title: 'Basic Information',
                              icon: Icons.person,
                              isExpanded: _basicInfoExpanded,
                              onTap:
                                  () => setState(
                                    () =>
                                        _basicInfoExpanded =
                                            !_basicInfoExpanded,
                                  ),
                              color: AppColors.primaryColor,
                            ),
                            if (_basicInfoExpanded)
                              Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      _buildTextField(
                                        label: 'Customer Name *',
                                        controller: _customerNameController,
                                        validator:
                                            (v) =>
                                                v?.isEmpty == true
                                                    ? 'Required'
                                                    : null,
                                      ),
                                      _buildTextField(
                                        label: 'Print Name',
                                        controller: _printNameController,
                                      ),
                                      _buildTextField(
                                        label: 'Contact Person',
                                        controller: _contactPersonController,
                                      ),
                                      _buildTextField(
                                        label: 'Code',
                                        controller: _codeController,
                                      ),
                                      _buildSimpleDropdown(
                                        label: 'Category',
                                        items: _categoryOptions,
                                        selectedValue: _selectedCategory,
                                        onChanged:
                                            (v) => setState(
                                              () => _selectedCategory = v,
                                            ),
                                      ),
                                      _buildDropdown(
                                        label: 'Sales Type',
                                        items: _salesTypes,
                                        selectedValue: _selectedSalesType,
                                        onChanged:
                                            (v) => setState(
                                              () => _selectedSalesType = v,
                                            ),
                                      ),
                                      _buildDropdown(
                                        label: 'Account Group',
                                        items: _accountGroups,
                                        selectedValue: _selectedAccountGroup,
                                        onChanged:
                                            (v) => setState(
                                              () => _selectedAccountGroup = v,
                                            ),
                                      ),
                                      _buildTextField(
                                        label: 'GST No',
                                        controller: _gstNoController,
                                      ),
                                      _buildDropdown(
                                        label: 'Brand',
                                        items: _brands,
                                        selectedValue: _selectedBrand,
                                        onChanged:
                                            (v) => setState(
                                              () => _selectedBrand = v,
                                            ),
                                      ),
                                      _buildSimpleDropdown(
                                        label: 'Price List',
                                        items: _priceListOptions,
                                        selectedValue: _selectedPriceList,
                                        onChanged:
                                            (v) => setState(
                                              () => _selectedPriceList = v,
                                            ),
                                      ),
                                      _buildTextField(
                                        label: 'Mobile 1',
                                        controller: _mobile1Controller,
                                        isNumber: true,
                                      ),
                                      _buildTextField(
                                        label: 'Mobile 2',
                                        controller: _mobile2Controller,
                                        isNumber: true,
                                      ),
                                      _buildDropdown(
                                        label: 'Broker',
                                        items: _brokers,
                                        selectedValue: _selectedBroker,
                                        onChanged:
                                            (v) => setState(
                                              () => _selectedBroker = v,
                                            ),
                                      ),
                                      _buildTextField(
                                        label: 'Broker Commission (%)',
                                        controller: _brokerCommController,
                                        isNumber: true,
                                      ),
                                      _buildDropdown(
                                        label: 'Sales Person',
                                        items: _salesPersons,
                                        selectedValue: _selectedSalesPerson,
                                        onChanged:
                                            (v) => setState(
                                              () => _selectedSalesPerson = v,
                                            ),
                                      ),
                                      _buildTextField(
                                        label: 'Sales Person Commission (%)',
                                        controller: _spcommPercController,
                                        isNumber: true,
                                      ),
                                      _buildDropdown(
                                        label: 'Currency',
                                        items: _currencies,
                                        selectedValue: _selectedCurrency,
                                        onChanged:
                                            (v) => setState(
                                              () => _selectedCurrency = v,
                                            ),
                                      ),
                                      _buildDropdown(
                                        label: 'Transporter',
                                        items: _transporters,
                                        selectedValue: _selectedTransporter,
                                        onChanged:
                                            (v) => setState(
                                              () => _selectedTransporter = v,
                                            ),
                                      ),
                                      _buildDropdown(
                                        label: 'Discount Term',
                                        items: _discountTerms,
                                        selectedValue: _selectedDiscTerm,
                                        onChanged:
                                            (v) => setState(
                                              () => _selectedDiscTerm = v,
                                            ),
                                      ),
                                      _buildTextField(
                                        label: 'Spl Markdown (%)',
                                        controller: _splMkDownController,
                                        isNumber: true,
                                      ),
                                      _buildDropdown(
                                        label: 'Executed',
                                        items: _executedOptions,
                                        selectedValue: _selectedExecuted,
                                        onChanged:
                                            (v) => setState(
                                              () => _selectedExecuted = v,
                                            ),
                                      ),
                                      _buildDateField(
                                        label: 'Dispatch Order',
                                        controller: _dispatchOrderController,
                                      ),
                                      _buildDateField(
                                        label: 'Stop Dispatch',
                                        controller: _stopDispatchController,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Section 2: Office Address
                            _buildSectionHeader(
                              title: 'Office Address',
                              icon: Icons.location_on,
                              isExpanded: _officeAddressExpanded,
                              onTap:
                                  () => setState(
                                    () =>
                                        _officeAddressExpanded =
                                            !_officeAddressExpanded,
                                  ),
                              color: AppColors.primaryColor.shade400,
                            ),
                            if (_officeAddressExpanded)
                              Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      _buildTextField(
                                        label: 'Address',
                                        controller: _addressController,
                                        maxLines: 2,
                                      ),
                                      _buildDropdown(
                                        label: 'Station',
                                        items: _stations,
                                        selectedValue: _selectedStation,
                                        onChanged: (v) {
                                          setState(() {
                                            _selectedStation = v;
                                            if (v != null)
                                              _areaController.text = v.name;
                                          });
                                        },
                                        isRequired: true,
                                      ),
                                      _buildTextField(
                                        label: 'Area',
                                        controller: _areaController,
                                      ),
                                      _buildTextField(
                                        label: 'Pin',
                                        controller: _pinController,
                                        isNumber: true,
                                      ),
                                      _buildTextField(
                                        label: 'Phone 1',
                                        controller: _phone1Controller,
                                        isNumber: true,
                                      ),
                                      _buildTextField(
                                        label: 'Phone 2',
                                        controller: _phone2Controller,
                                        isNumber: true,
                                      ),
                                      _buildTextField(
                                        label: 'Email 1',
                                        controller: _email1Controller,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                      ),
                                      _buildTextField(
                                        label: 'Email 2',
                                        controller: _email2Controller,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                      ),
                                      _buildTextField(
                                        label: 'Fax',
                                        controller: _faxController,
                                      ),
                                      _buildTextField(
                                        label: 'Website',
                                        controller: _websiteController,
                                      ),
                                      _buildTextField(
                                        label: 'Remark',
                                        controller: _remarkController,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Section 3: Bank Details
                            _buildSectionHeader(
                              title: 'Bank Details',
                              icon: Icons.account_balance,
                              isExpanded: _bankDetailsExpanded,
                              onTap:
                                  () => setState(
                                    () =>
                                        _bankDetailsExpanded =
                                            !_bankDetailsExpanded,
                                  ),
                              color: AppColors.primaryColor.shade400,
                            ),
                            if (_bankDetailsExpanded)
                              Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      _buildTextField(
                                        label: 'Credit Limit',
                                        controller: _creditLimitController,
                                        isNumber: true,
                                      ),
                                      _buildTextField(
                                        label: 'Credit Days',
                                        controller: _creditDaysController,
                                        isNumber: true,
                                      ),
                                      _buildTextField(
                                        label: 'Interest (%)',
                                        controller: _intPercController,
                                        isNumber: true,
                                      ),
                                      _buildSimpleDropdown(
                                        label: 'Credit Limit Exceeds',
                                        items: _creditLimitOptions,
                                        selectedValue:
                                            _selectedCreditLimitExceeds,
                                        onChanged:
                                            (v) => setState(
                                              () =>
                                                  _selectedCreditLimitExceeds =
                                                      v,
                                            ),
                                      ),
                                      _buildTextField(
                                        label: 'Bill Limit',
                                        controller: _billLimitController,
                                        isNumber: true,
                                      ),
                                      _buildSimpleDropdown(
                                        label: 'Bill Exceeds',
                                        items: _creditLimitOptions,
                                        selectedValue: _selectedBillLimitExc,
                                        onChanged:
                                            (v) => setState(
                                              () => _selectedBillLimitExc = v,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Section 4: Tax Info
                            _buildSectionHeader(
                              title: 'Tax Information',
                              icon: Icons.receipt,
                              isExpanded: _taxInfoExpanded,
                              onTap:
                                  () => setState(
                                    () => _taxInfoExpanded = !_taxInfoExpanded,
                                  ),
                              color: AppColors.primaryColor.shade400,
                            ),
                            if (_taxInfoExpanded)
                              Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      _buildTextField(
                                        label: 'PAN No',
                                        controller: _panNoController,
                                      ),
                                      _buildTextField(
                                        label: 'TAN No',
                                        controller: _tanNoController,
                                      ),
                                      _buildTextField(
                                        label: 'Aadhar No',
                                        controller: _aadharNoController,
                                      ),
                                      _buildSimpleDropdown(
                                        label: 'Udyam Type',
                                        items: _udyamTypeOptions,
                                        selectedValue: _selectedUdyamType,
                                        onChanged:
                                            (v) => setState(
                                              () => _selectedUdyamType = v,
                                            ),
                                      ),
                                      _buildTextField(
                                        label: 'Udyam No',
                                        controller: _udyamNoController,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Section 5: Discount
                            _buildSectionHeader(
                              title: 'Discount Details',
                              icon: Icons.local_offer,
                              isExpanded: _discountExpanded,
                              onTap:
                                  () => setState(
                                    () =>
                                        _discountExpanded = !_discountExpanded,
                                  ),
                              color: AppColors.primaryColor.shade400,
                            ),
                            if (_discountExpanded)
                              Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      _buildDropdown(
                                        label: 'Discount Name',
                                        items: _discountNameOptions,
                                        selectedValue: _selectedDiscountName,
                                        onChanged: (v) {
                                          setState(() {
                                            _selectedDiscountName = v;
                                            // Auto-fill percentage from Terms API
                                            if (v != null && v.extra != null) {
                                              double? percentage =
                                                  v.extra!['TxTmTDS_Perc']
                                                      ?.toDouble();
                                              if (percentage != null) {
                                                _discountPercentController
                                                        .text =
                                                    percentage.toString();
                                              }
                                            }
                                          });
                                        },
                                      ),
                                      _buildTextField(
                                        label: 'Discount (%)',
                                        controller: _discountPercentController,
                                        isNumber: true,
                                      ),
                                      ElevatedButton(
                                        onPressed: _handleAddDiscount,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.accentColor,
                                          foregroundColor: AppColors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          minimumSize: const Size(
                                            double.infinity,
                                            40,
                                          ),
                                        ),
                                        child: const Text('Add Discount'),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppColors.slateBorder,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color:
                                                    AppColors
                                                        .primaryColor
                                                        .shade50,
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(8),
                                                    ),
                                              ),
                                              child: const Row(
                                                children: [
                                                  SizedBox(
                                                    width: 40,
                                                    child: Text(
                                                      'Sr No',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      'Discount Name',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 80,
                                                    child: Text(
                                                      'Discount %',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 40,
                                                    child: Text(
                                                      'Action',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            _discounts.isEmpty
                                                ? const Padding(
                                                  padding: EdgeInsets.all(24),
                                                  child: Text(
                                                    'No discounts added',
                                                    style: TextStyle(
                                                      color: AppColors.slate600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                )
                                                : ListView.builder(
                                                  shrinkWrap: true,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  itemCount: _discounts.length,
                                                  itemBuilder: (
                                                    context,
                                                    index,
                                                  ) {
                                                    final discount =
                                                        _discounts[index];
                                                    return Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            10,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        border: Border(
                                                          bottom: BorderSide(
                                                            color: AppColors
                                                                .slateBorder
                                                                .withOpacity(
                                                                  0.5,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          SizedBox(
                                                            width: 40,
                                                            child: Text(
                                                              discount['srNo']
                                                                  .toString(),
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              discount['name'],
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 80,
                                                            child: Text(
                                                              '${discount['percent']}%',
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 40,
                                                            child: IconButton(
                                                              icon: const Icon(
                                                                Icons.delete,
                                                                color:
                                                                    AppColors
                                                                        .red,
                                                                size: 18,
                                                              ),
                                                              onPressed:
                                                                  () =>
                                                                      _handleRemoveDiscount(
                                                                        index,
                                                                      ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              constraints:
                                                                  const BoxConstraints(),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: _isActive,
                                        onChanged:
                                            (v) =>
                                                setState(() => _isActive = v!),
                                        activeColor: AppColors.primaryColor,
                                      ),
                                      const Text(
                                        'Active',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Round Off',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Radio(
                                            value: 'None',
                                            groupValue: _selectedRoundOff,
                                            onChanged:
                                                (v) => setState(
                                                  () => _selectedRoundOff = v!,
                                                ),
                                            activeColor: AppColors.primaryColor,
                                          ),
                                          const Text(
                                            'None',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          const SizedBox(width: 12),
                                          Radio(
                                            value: 'RS',
                                            groupValue: _selectedRoundOff,
                                            onChanged:
                                                (v) => setState(
                                                  () => _selectedRoundOff = v!,
                                                ),
                                            activeColor: AppColors.primaryColor,
                                          ),
                                          const Text(
                                            'RS',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isSaving ? null : _handleClear,
                                icon: const Icon(Icons.clear, size: 16),
                                label: const Text(
                                  'Clear',
                                  style: TextStyle(fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.lightGray,
                                  foregroundColor: AppColors.slate600,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isSaving ? null : _handleSave,
                                icon:
                                    _isSaving
                                        ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.white,
                                          ),
                                        )
                                        : const Icon(Icons.save, size: 16),
                                label:
                                    _isSaving
                                        ? const Text(
                                          'Saving...',
                                          style: TextStyle(fontSize: 13),
                                        )
                                        : Text(
                                          _isEditMode ? 'Update' : 'Save',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
