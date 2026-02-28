import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:vrs_erp/catalog/imagezoom.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/constants/constants.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:vrs_erp/screens/home_screen.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/viewOrder/Pdf_viewer_screen.dart';
import 'package:vrs_erp/viewOrder/add_more_info.dart';
import 'package:vrs_erp/viewOrder/customer_master.dart';
import 'package:vrs_erp/models/consignee.dart';
import 'package:vrs_erp/models/PytTermDisc.dart';
import 'package:vrs_erp/models/item.dart';
import 'package:vrs_erp/models/catalog.dart';
import 'package:vrs_erp/models/OrderMatrix.dart';
import 'package:vrs_erp/models/CatalogOrderData.dart';

enum ActiveTab { transaction, customerDetails }

class ViewOrderScreenBarcode extends StatefulWidget {
  @override
  _ViewOrderScreenBarcodeState createState() => _ViewOrderScreenBarcodeState();
}

class _ViewOrderScreenBarcodeState extends State<ViewOrderScreenBarcode> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _additionalInfo = {};
  bool _showForm = false;
  final _orderControllers = _OrderControllers();
  final _dropdownData = _DropdownData();
  final _styleManager = _StyleManager();
  List<Consignee> consignees = [];
  List<PytTermDisc> paymentTerms = [];
  List<Item> _bookingTypes = [];
  bool isLoading = true;
  bool barcodeMode = false;
  ActiveTab _activeTab = ActiveTab.transaction;
  Map<String, Map<String, Map<String, int>>> quantities = {};
  Map<String, Set<String>> selectedColors = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey(Constants.barcode)) {
        barcodeMode = args[Constants.barcode] as bool;
      }
      _initializeData();
      _setInitialDates();
      fetchAndPrintSalesOrderNumber();
      _styleManager.updateTotalsCallback = _updateTotals;
      _loadBookingTypes();
    });
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    try {
      await _saveOrderLocally();
    } catch (e) {
      print('Save error: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  double _calculateTotalAmount() {
    double total = 0.0;
    _styleManager.controllers.forEach((style, shades) {
      final itemsForStyle = _styleManager.groupedItems[style] ?? [];
      shades.forEach((shade, sizes) {
        sizes.forEach((size, controller) {
          final qty = int.tryParse(controller.text) ?? 0;
          final item = itemsForStyle.firstWhere(
            (item) =>
                (item['shadeName']?.toString() ?? '') == shade &&
                (item['sizeName']?.toString() ?? '') == size,
            orElse: () => {},
          );
          if (item.isNotEmpty) {
            final mrp = (item['mrp'] as num?)?.toDouble() ?? 0.0;
            total += qty * mrp;
          }
        });
      });
    });
    return total;
  }

  int _calculateTotalItems() {
    return _styleManager.groupedItems.length;
  }

  int _calculateTotalQuantity() {
    int total = 0;
    _styleManager.controllers.forEach((style, shades) {
      shades.forEach((shade, sizes) {
        sizes.forEach((size, controller) {
          total += int.tryParse(controller.text) ?? 0;
        });
      });
    });
    return total;
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
      } else {
        print('API Error: ${response.statusCode}');
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

      if (responseMap['statusCode'] == 200) {
        if (responseMap['result'] is List) {
          setState(() {
            consignees = responseMap['result'];
          });
        }
      } else {
        print('API Error: ${responseMap['statusCode']}');
      }
    } catch (e) {
      print('Error fetching consignees: $e');
    }
  }

  Future<void> fetchAndPrintSalesOrderNumber() async {
    Map<String, dynamic> salesOrderData = await ApiService.getSalesOrderData(
      coBrId: UserSession.coBrId ?? '',
      userId: UserSession.userName ?? '',
      fcYrId: UserSession.userFcYr ?? '',
      barcode: "true",
    );

    if (salesOrderData.isNotEmpty &&
        salesOrderData.containsKey('salesOrderNo')) {
      String salesOrderNo = salesOrderData['salesOrderNo'];
      _orderControllers.orderNo.text = salesOrderNo;
      print('Sales Order Number: $salesOrderNo');
    } else {
      print('Sales Order Number not found');
    }
  }

  Future<String> insertFinalSalesOrder(String orderDataJson) async {
    final Map<String, dynamic> body = {
      'userId': UserSession.userName ?? '',
      'coBrId': UserSession.coBrId ?? '',
      'fcYrId': UserSession.userFcYr ?? '',
      'data2': orderDataJson,
      'barcode': barcodeMode.toString(),
    };

    try {
      final response = await http.post(
        Uri.parse(
          '${AppConstants.BASE_URL}/orderBooking/InsertFinalsalesorder',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print("rrrrrrrrrresponse body:${response.body}");
      if (response.statusCode == 200) {
        print('Success: ${response.body}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Order saved successfully')));
         return response.body;
      } else {
        print('Error: ${response.statusCode}');
        print('Response Body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save order: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving order: $e')));
    }
    return "fail";
  }

  void _setInitialDates() {
    final today = DateTime.now();
    _orderControllers.date.text = _OrderControllers.formatDate(today);
    _orderControllers.deliveryDate.text = _OrderControllers.formatDate(today);
    _orderControllers.deliveryDays.text = '0';
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _styleManager.fetchOrderItems(barcode: barcodeMode),
      _dropdownData.loadAllDropdownData(),
      fetchPaymentTerms(),
    ]);
    _initializeQuantitiesAndColors();
    _updateTotals();
    setState(() {
      isLoading = false;
    });
  }

  void _initializeQuantitiesAndColors() {
    quantities.clear();
    selectedColors.clear();
    for (var entry in _styleManager.groupedItems.entries) {
      final styleKey = entry.key;
      final items = entry.value;
      final shades = _styleManager._getSortedUniqueValues(items, 'shadeName');
      final sizes = _styleManager._getSortedUniqueValues(items, 'sizeName');

      selectedColors[styleKey] = shades.toSet();
      quantities[styleKey] = {};

      for (var shade in shades) {
        quantities[styleKey]![shade] = {};
        for (var size in sizes) {
          final item = items.firstWhere(
            (i) =>
                (i['shadeName']?.toString() ?? '') == shade &&
                (i['sizeName']?.toString() ?? '') == size,
            orElse: () => {'clqty': '0'},
          );
          quantities[styleKey]![shade]![size] =
              int.tryParse(item['clqty']?.toString() ?? '0') ?? 0;
        }
      }
    }
  }

  String formatDate(String date, bool time) {
    try {
      DateTime parsedDate = DateFormat("yyyy-MM-dd").parse(date);
      String formattedDate = DateFormat("yyyy-MM-dd").format(parsedDate);
      if (time) {
        String currentTime = DateFormat("HH:mm:ss").format(DateTime.now());
        return "$formattedDate $currentTime";
      } else {
        return formattedDate;
      }
    } catch (e) {
      print("Error parsing date: $e");
      return DateFormat("yyyy-MM-dd").format(DateTime.now());
    }
  }

  String calculateFutureDateFromString(String daysString) {
    final int? days = int.tryParse(daysString);
    if (days == null) {
      return "";
    }
    final DateTime futureDate = DateTime.now().add(Duration(days: days));
    return DateFormat('yyyy-MM-dd').format(futureDate);
  }

    String getTodayWithZeroTime() {
    final now = DateTime.now();
    final zeroTime = DateTime(now.year, now.month, now.day);
    return DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(zeroTime);
  }


  String calculateDueDate() {
    final paymentDays = _additionalInfo['paymentdays'];
    if (paymentDays != null &&
        paymentDays is String &&
        int.tryParse(paymentDays) != null) {
      return calculateFutureDateFromString(paymentDays);
    }
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return today;
  }

  Future<void> _saveOrderLocally() async {
    if (!_formKey.currentState!.validate()) return;

    String? consigneeLedKey = '';
    String? stationStnKey = '';
    final selectedConsigneeName = _additionalInfo['consignee']?.toString();
    if (selectedConsigneeName != null && selectedConsigneeName.isNotEmpty) {
      final selectedConsignee = consignees.firstWhere(
        (consignee) => consignee.ledName == selectedConsigneeName,
        orElse: () => Consignee(
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

    final orderData = {
      "saleorderno": _orderControllers.orderNo.text,
      "orderdate": formatDate(_orderControllers.date.text, true),
      "customer": _orderControllers.selectedPartyKey ?? '',
      "broker": _orderControllers.selectedBrokerKey ?? '',
      "comission": _orderControllers.comm.text,
      "transporter": _orderControllers.selectedTransporterKey ?? '',
      "delivaryday": _orderControllers.deliveryDays.text,
      "delivarydate": formatDate(_orderControllers.deliveryDate.text, false),
      "totitem": _orderControllers.totalItem.text,
      "totqty": _orderControllers.totalQty.text,
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
          _additionalInfo['salesman'] ?? _orderControllers.salesPersonKey ?? '',
    };

    final orderDataJson = jsonEncode(orderData);
    print("Saved Order Data:");
    print(orderDataJson);

    try {
      final orderNumber = await insertFinalSalesOrder(orderDataJson);
      if (orderNumber != null) {
        final formattedOrderNo = "SO$orderNumber";
        print("formattedOrderNo: ${formattedOrderNo}");
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Order Saved'),
            content: Text(
              'Order $formattedOrderNo saved successfully',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfViewerScreen(
                        rptName: 'SalesOrder',
                        orderNo: formattedOrderNo,
                        whatsappNo: _orderControllers.whatsAppMobileNo,
                        partyName: _orderControllers.selectedPartyName ?? '', 
                        orderDate: _orderControllers.date.text,
                      ),
                    ),
                  );
                },
                child: Text('View PDF'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
                child: Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error during order saving: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving order: $e')));
    }
  }

  void _updateTotals() {
    int totalQty = 0;
    double totalAmt = 0.0;

    _styleManager.controllers.forEach((style, shades) {
      final itemsForStyle = _styleManager.groupedItems[style] ?? [];

      shades.forEach((shade, sizes) {
        sizes.forEach((size, controller) {
          final qty = int.tryParse(controller.text) ?? 0;
          totalQty += qty;

          final item = itemsForStyle.firstWhere(
            (item) =>
                (item['shadeName']?.toString() ?? '') == shade &&
                (item['sizeName']?.toString() ?? '') == size,
            orElse: () => {},
          );

          if (item.isNotEmpty) {
            final mrp = (item['mrp'] as num?)?.toDouble() ?? 0.0;
            totalAmt += qty * mrp;
          }
        });
      });
    });

    _orderControllers.totalQty.text = totalQty.toString();
    _orderControllers.totalItem.text =
        _styleManager.groupedItems.length.toString();
    _orderControllers.totalAmt.text = totalAmt.toStringAsFixed(2);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2196F3);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: DrawerScreen(),
      appBar: AppBar(
        title: const Text(
          'View Order Barcode',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryBlue,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            color: primaryBlue,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Total: ₹${_calculateTotalAmount().toStringAsFixed(2)}',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 12,
                    ),
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
                    'Items: ${_calculateTotalItems()}',
                    style: GoogleFonts.roboto(color: Colors.white, fontSize: 12),
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
                    style: GoogleFonts.roboto(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child:
                      _showForm
                          ? _OrderForm(
                            controllers: _orderControllers,
                            dropdownData: _dropdownData,
                            onPartySelected: _handlePartySelection,
                            updateTotals: _updateTotals,
                            saveOrder: _handleSave,
                            additionalInfo: _additionalInfo,
                            consignees: consignees,
                            paymentTerms: paymentTerms,
                            bookingTypes: _bookingTypes,
                            onAdditionalInfoUpdated: (newInfo) {
                              setState(() {
                                _additionalInfo = newInfo;
                              });
                            },
                            isSaving: _isSaving,
                          )
                          : _StyleCardsView(
                            styleManager: _styleManager,
                            updateTotals: _updateTotals,
                            getColor: _getColorCode,
                            onUpdate: () async {
                              await _styleManager.refreshOrderItems(
                                barcode: barcodeMode,
                              );
                              _initializeQuantitiesAndColors();
                              _updateTotals();
                            },
                            quantities: quantities,
                            selectedColors: selectedColors,
                          ),
                ),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final Color primaryBlue = const Color(0xFF2196F3);

    return Container(
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeTab = ActiveTab.transaction;
                  _showForm = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          _activeTab == ActiveTab.transaction
                              ? primaryBlue
                              : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Transaction',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        _activeTab == ActiveTab.transaction
                            ? primaryBlue
                            : Colors.grey,
                    fontWeight:
                        _activeTab == ActiveTab.transaction
                            ? FontWeight.bold
                            : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeTab = ActiveTab.customerDetails;
                  _showForm = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          _activeTab == ActiveTab.customerDetails
                              ? primaryBlue
                              : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Customer Details',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        _activeTab == ActiveTab.customerDetails
                            ? primaryBlue
                            : Colors.grey,
                    fontWeight:
                        _activeTab == ActiveTab.customerDetails
                            ? FontWeight.bold
                            : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    final Color primaryBlue = const Color(0xFF2196F3);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
                child: const Text(
                  "CANCEL",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  if (_activeTab == ActiveTab.transaction) {
                    setState(() {
                      _activeTab = ActiveTab.customerDetails;
                      _showForm = true;
                    });
                  } else {
                    setState(() {
                      _activeTab = ActiveTab.transaction;
                      _showForm = false;
                    });
                  }
                },
                icon: Icon(
                  _activeTab == ActiveTab.transaction
                      ? Icons.chevron_right
                      : Icons.chevron_left,
                  size: 18,
                  color: primaryBlue,
                ),
                label: Text(
                  _activeTab == ActiveTab.transaction ? "NEXT" : "BACK",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handlePartySelection(String? val, String? key) async {
    if (key == null) return;
    setState(() {
      _orderControllers.selectedParty = val;
      _orderControllers.selectedPartyKey = key;
      _orderControllers.selectedPartyName = val;
    });

    _orderControllers.selectedPartyKey = key;
    UserSession.userLedKey = key;
    try {
      await fetchAndMapConsignees(key: key, CoBrId: UserSession.coBrId ?? '');
      final details = await _dropdownData.fetchLedgerDetails(key);
      _dropdownData.updateDependentFields(
        details,
        _orderControllers.selectedBrokerKey,
        _orderControllers.selectedTransporterKey,
      );
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
      print('Error fetching party details: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load party details')));
    }
  }

  Color _getColorCode(String color) {
    switch (color.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow[800]!;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}

class _OrderControllers {
  String? pytTermDiscKey;
  String? salesPersonKey;
  int? creditPeriod;
  String? salesLedKey;
  String? ledgerName;
  String? whatsAppMobileNo;

  final orderNo = TextEditingController();
  final date = TextEditingController();
  final comm = TextEditingController();
  final deliveryDays = TextEditingController();
  final deliveryDate = TextEditingController();
  final remark = TextEditingController();
  final totalItem = TextEditingController(text: '0');
  final totalQty = TextEditingController(text: '0');
  final totalAmt = TextEditingController(text: '0');

  String? selectedParty;
  String? selectedPartyKey;
  String? selectedPartyName;
  String? selectedTransporter;
  String? selectedTransporterKey;
  String? selectedBroker;
  String? selectedBrokerKey;

  static String formatDate(DateTime date) {
    return DateFormat("yyyy-MM-dd").format(date);
  }

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
    selectedPartyName = selectedPartyName ?? details['ledgerName']?.toString(); 
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

class _DropdownData {
  List<Map<String, String>> partyList = [];
  List<Map<String, String>> brokerList = [];
  List<Map<String, String>> transporterList = [];
  List<Map<String, String>> salesPersonList = [];

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
    return response.statusCode == 200
        ? jsonDecode(response.body)
        : throw Exception('Failed to load details');
  }

  void updateDependentFields(
    Map<String, dynamic> details,
    String? currentBrokerKey,
    String? currentTransporterKey,
  ) {}

  Future<List<Map<String, String>>> _fetchLedgers(String ledCat) async {
    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/users/getLedger'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"ledCat": ledCat, "coBrId": UserSession.coBrId ?? ''}),
    );
    return response.statusCode == 200
        ? (jsonDecode(response.body) as List)
            .map(
              (e) => {
                'ledKey': e['ledKey'].toString(),
                'ledName': e['ledName'].toString(),
              },
            )
            .toList()
        : throw Exception("Failed to load ledgers");
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

class _StyleManager {
  List<dynamic> _orderItems = [];
  final Set<String> removedStyles = {};
  final Map<String, Map<String, Map<String, TextEditingController>>>
  controllers = {};
  VoidCallback? updateTotalsCallback;
  bool isOrderItemsLoaded = false;

  Map<String, List<dynamic>> get groupedItems {
    final map = <String, List<dynamic>>{};
    for (final item in _orderItems) {
      final styleCode = item['styleCode']?.toString() ?? 'No Style Code';
      if (removedStyles.contains(styleCode)) continue;
      map.putIfAbsent(styleCode, () => []).add(item);
    }
    return map;
  }

  Future<void> fetchOrderItems({required bool barcode}) async {
    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/orderBooking/GetViewOrder'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "coBrId": UserSession.coBrId ?? '',
        "userId": UserSession.userName ?? '',
        "fcYrId": UserSession.userFcYr ?? '',
        "barcode": barcode ? "true" : "false",
      }),
    );

    if (response.statusCode == 200) {
      _orderItems = json.decode(response.body);
      _initializeControllers();
      isOrderItemsLoaded = true;
    }
  }

  Future<void> refreshOrderItems({required bool barcode}) async {
    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/orderBooking/GetViewOrder'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "coBrId": UserSession.coBrId ?? '',
        "userId": UserSession.userName ?? '',
        "fcYrId": UserSession.userFcYr ?? '',
        "barcode": barcode ? "true" : "false",
      }),
    );

    if (response.statusCode == 200) {
      final newItems = json.decode(response.body);
      _orderItems = newItems;
      _updateControllers();
    }
  }

  void copyStyle(String styleKey) {
    final items = groupedItems[styleKey];
    if (items != null) {
      final newStyleKey =
          "${styleKey}_${DateTime.now().millisecondsSinceEpoch}";
      _orderItems.addAll(
        items.map((item) => {...item, 'styleCode': newStyleKey}),
      );
      _initializeControllers();
      updateTotalsCallback?.call();
    }
  }

  void removeStyle(String styleKey) {
    removedStyles.add(styleKey);
    controllers.remove(styleKey);
    updateTotalsCallback?.call();
  }

  void _initializeControllers() {
    controllers.clear();
    for (final entry in groupedItems.entries) {
      final items = entry.value;
      final sizes = _getSortedUniqueValues(items, 'sizeName');
      final shades = _getSortedUniqueValues(items, 'shadeName');

      controllers[entry.key] = {};
      for (final shade in shades) {
        controllers[entry.key]![shade] = {};
        for (final size in sizes) {
          final item = items.firstWhere(
            (i) =>
                (i['shadeName']?.toString() ?? '') == shade &&
                (i['sizeName']?.toString() ?? '') == size,
            orElse: () => {'clqty': '0'},
          );
          final controller = TextEditingController(
            text: item['clqty']?.toString() ?? '0',
          )..addListener(() => updateTotalsCallback?.call());
          controllers[entry.key]![shade]![size] = controller;
        }
      }
    }
  }

  void _updateControllers() {
    final currentControllers =
        Map<String, Map<String, Map<String, TextEditingController>>>.from(
          controllers,
        );
    controllers.clear();
    for (final entry in groupedItems.entries) {
      final items = entry.value;
      final sizes = _getSortedUniqueValues(items, 'sizeName');
      final shades = _getSortedUniqueValues(items, 'shadeName');

      controllers[entry.key] = {};
      for (final shade in shades) {
        controllers[entry.key]![shade] = {};
        for (final size in sizes) {
          final item = items.firstWhere(
            (i) =>
                (i['shadeName']?.toString() ?? '') == shade &&
                (i['sizeName']?.toString() ?? '') == size,
            orElse: () => {'clqty': '0'},
          );
          final existingController =
              currentControllers[entry.key]?[shade]?[size];
          final controller =
              existingController ??
                    TextEditingController(
                      text: item['clqty']?.toString() ?? '0',
                    )
                ..addListener(() => updateTotalsCallback?.call());
          controllers[entry.key]![shade]![size] = controller;
        }
      }
    }
  }

  List<String> _getSortedUniqueValues(List<dynamic> items, String field) =>
      items.map((e) => e[field]?.toString() ?? '').toSet().toList()..sort();
}

class _StyleCardsView extends StatelessWidget {
  final _StyleManager styleManager;
  final VoidCallback updateTotals;
  final Color Function(String) getColor;
  final VoidCallback onUpdate;
  final Map<String, Map<String, Map<String, int>>> quantities;
  final Map<String, Set<String>> selectedColors;

  const _StyleCardsView({
    required this.styleManager,
    required this.updateTotals,
    required this.getColor,
    required this.onUpdate,
    required this.quantities,
    required this.selectedColors,
  });

  @override
  Widget build(BuildContext context) {
    if (!styleManager.isOrderItemsLoaded) {
      return const Center(child: CircularProgressIndicator());
    } else if (styleManager.groupedItems.isEmpty) {
      return const Center(
        child: Text(
          'No item added',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    } else {
      return Column(
        children:
            styleManager.groupedItems.entries.map((entry) {
              final catalogOrder = _convertToCatalogOrderData(
                entry.key,
                entry.value,
              );
              return StyleCard(
                styleCode: entry.key,
                items: entry.value,
                catalogOrder: catalogOrder,
                quantities: quantities[entry.key] ?? {},
                selectedColors: selectedColors[entry.key] ?? {},
                getColor: getColor,
                onUpdate: onUpdate,
                styleManager: styleManager,
              );
            }).toList(),
      );
    }
  }

  CatalogOrderData _convertToCatalogOrderData(
    String styleKey,
    List<dynamic> items,
  ) {
    final shades =
        items.map((i) => i['shadeName']?.toString() ?? '').toSet().toList();
    final sizes =
        items.map((i) => i['sizeName']?.toString() ?? '').toSet().toList();
    final firstItem = items.first;

    final matrix = List.generate(shades.length, (shadeIndex) {
      return List.generate(sizes.length, (sizeIndex) {
        final item = items.firstWhere(
          (i) =>
              (i['shadeName']?.toString() ?? '') == shades[shadeIndex] &&
              (i['sizeName']?.toString() ?? '') == sizes[sizeIndex],
          orElse: () => {},
        );
        final mrp = item['mrp']?.toString() ?? '0';
        final wsp = item['wsp']?.toString() ?? '0';
        final qty = item['data2']?.toString() ?? '0';
        return '$mrp,$wsp,$qty';
      });
    });

    return CatalogOrderData(
      catalog: Catalog(
        itemSubGrpKey: '',
        itemSubGrpName: '',
        itemKey: '',
        itemName: firstItem['itemName']?.toString() ?? 'Unknown',
        brandKey: '',
        brandName: '',
        styleKey: styleKey,
        styleCode: firstItem['styleCode']?.toString() ?? styleKey,
        shadeKey: '',
        shadeName: shades.join(','),
        styleSizeId: '',
        sizeName: sizes.join(','),
        mrp: double.tryParse(firstItem['mrp']?.toString() ?? '0') ?? 0.0,
        wsp: double.tryParse(firstItem['wsp']?.toString() ?? '0') ?? 0.0,
        onlyMRP: double.tryParse(firstItem['mrp']?.toString() ?? '0') ?? 0.0,
        clqty: int.tryParse(firstItem['clqty']?.toString() ?? '0') ?? 0,
        total: items.fold(
          0,
          (sum, i) => sum + (int.tryParse(i['clqty']?.toString() ?? '0') ?? 0),
        ),
        fullImagePath: firstItem['imagePath']?.toString() ?? '/NoImage.jpg',
        remark: firstItem['remark']?.toString() ?? '',
        imageId: '',
        sizeDetails: sizes
            .map((s) => '$s (${firstItem['mrp']},${firstItem['wsp']})')
            .join(','),
        sizeDetailsWithoutWSp: sizes
            .map((s) => '$s (${firstItem['mrp']})')
            .join(','),
        sizeWithMrp: sizes.map((s) => '$s (${firstItem['mrp']})').join(','),
        styleCodeWithcount: styleKey,
        onlySizes: sizes.join(','),
        sizeWithWsp: sizes.map((s) => '$s (${firstItem['wsp']})').join(','),
        createdDate: '',
        shadeImages: '',
        upcoming_Stk: firstItem['upcoming_Stk']?.toString() ?? '',

      ),
      orderMatrix: OrderMatrix(shades: shades, sizes: sizes, matrix: matrix),
    );
  }
}

class StyleCard extends StatefulWidget {
  final String styleCode;
  final List<dynamic> items;
  final CatalogOrderData catalogOrder;
  final Map<String, Map<String, int>> quantities;
  final Set<String> selectedColors;
  final Color Function(String) getColor;
  final VoidCallback onUpdate;
  final _StyleManager styleManager;

  const StyleCard({
    Key? key,
    required this.styleCode,
    required this.items,
    required this.catalogOrder,
    required this.quantities,
    required this.selectedColors,
    required this.getColor,
    required this.onUpdate,
    required this.styleManager,
  }) : super(key: key);

  @override
  _StyleCardState createState() => _StyleCardState();
}

class _StyleCardState extends State<StyleCard> {
  bool _hasQuantityChanged = false;
  bool _isUpdated = false;
  bool _isLoading = false;
  Map<String, Map<String, int>> _lastSavedQuantities = {};

  @override
  void initState() {
    super.initState();
    _lastSavedQuantities = widget.quantities.map((shade, sizes) => MapEntry(
          shade,
          Map<String, int>.from(sizes),
        ));
  }

  Widget buildOrderItem(CatalogOrderData catalogOrder, BuildContext context) {
    final catalog = catalogOrder.catalog;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: GestureDetector(
                      onDoubleTap: () {
                        final imageUrl = catalog.fullImagePath.contains("http")
                            ? catalog.fullImagePath
                            : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageZoomScreen(
                              imageUrls: [imageUrl],
                              initialIndex: 0,
                            ),
                          ),
                        );
                      },
                      child: Image.network(
                        catalog.fullImagePath.contains("http")
                            ? catalog.fullImagePath
                            : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.error, size: 60),
                      ),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            catalog.styleCode,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: Colors.red.shade900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      catalog.shadeName,
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    Table(
                      columnWidths: const {
                        0: FixedColumnWidth(100),
                        1: FixedColumnWidth(10),
                        2: FlexColumnWidth(100),
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.top,
                      children: [
                        _buildTableRow('Remark', ''),
                        _buildTableRow(
                          'Stk Type',
                          catalog.upcoming_Stk == '1' ? 'Upcoming' : 'Ready',
                        ),
                        _buildTableRow(
                          'Stock Qty',
                          _calculateStockQuantity().toString(),
                          valueColor: Colors.green[700],
                        ),
                        _buildTableRow(
                          'Order Qty',
                          _calculateCatalogQuantity().toString(),
                          valueColor: Colors.orange[800],
                        ),
                        _buildTableRow(
                          'Order Amount',
                          _calculateCatalogPrice().toStringAsFixed(2),
                          valueColor: Colors.purple[800],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
      
        ...widget.selectedColors.map(
          (color) => Column(
            children: [
              _buildColorSection(widget.catalogOrder, color),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _isLoading ? null : () => _submitDelete(context),
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
                      icon: Icon(Icons.delete, color: Colors.red.shade600),
                      label: Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading || !_hasQuantityChanged
                          ? null
                          : () => _submitUpdate(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 10.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(
                          color: _hasQuantityChanged
                              ? Colors.blue
                              : Colors.grey.shade400,
                        ),
                        backgroundColor: _hasQuantityChanged
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Updating...',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.save,
                                  color: _hasQuantityChanged
                                      ? Colors.blue
                                      : Colors.grey.shade400,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Update',
                                  style: TextStyle(
                                    color: _hasQuantityChanged
                                        ? Colors.blue
                                        : Colors.grey.shade400,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildTableRow(String label, String value, {Color? valueColor}) {
    return TableRow(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Text(label, style: GoogleFonts.roboto(fontSize: 14)),
        ),
        Align(
          alignment: Alignment.center,
          child: const Text(":", style: TextStyle(fontSize: 14)),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  int _calculateCatalogQuantity() {
    int total = 0;
    widget.quantities.forEach((shade, sizes) {
      sizes.forEach((size, qty) {
        total += qty;
      });
    });
    return total;
  }

  int _calculateStockQuantity() {
    int total = 0;
    final matrix = widget.catalogOrder.orderMatrix;
    for (var shadeIndex = 0; shadeIndex < matrix.shades.length; shadeIndex++) {
      for (var sizeIndex = 0; sizeIndex < matrix.sizes.length; sizeIndex++) {
        final matrixData = matrix.matrix[shadeIndex][sizeIndex].split(',');
        final stock =
            int.tryParse(matrixData.length > 2 ? matrixData[2] : '0') ?? 0;
        total += stock;
      }
    }
    return total;
  }

  double _calculateCatalogPrice() {
    double total = 0;
    final matrix = widget.catalogOrder.orderMatrix;
    for (var shade in widget.quantities.keys) {
      final shadeIndex = matrix.shades.indexOf(shade.trim());
      if (shadeIndex == -1) continue;
      for (var size in widget.quantities[shade]!.keys) {
        final sizeIndex = matrix.sizes.indexOf(size.trim());
        if (sizeIndex == -1) continue;
        final rate =
            double.tryParse(matrix.matrix[shadeIndex][sizeIndex].split(',')[0]) ??
            0;
        final quantity = widget.quantities[shade]![size]!;
        total += rate * quantity;
      }
    }
    return total;
  }

  Widget _buildColorSection(CatalogOrderData catalogOrder, String shade) {
    final sizes = catalogOrder.orderMatrix.sizes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Divider(height: 1, color: Colors.grey.shade300),
              Row(
                children: [
                  _buildHeader("Size", 1),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        "Qty",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lora(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ),
                  ),
                  _buildHeader("MRP", 1),
                  _buildHeader("WSP", 1),
                  _buildHeader("Stock", 1),
                ],
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              for (var size in sizes) ...[
                _buildSizeRow(catalogOrder, shade, size),
                Divider(height: 1, color: Colors.grey.shade300),
              ],
            ],
          ),
        ),
      ],
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
    CatalogOrderData catalogOrder,
    String shade,
    String size,
  ) {
    final matrix = catalogOrder.orderMatrix;
    final shadeIndex = matrix.shades.indexOf(shade.trim());
    final sizeIndex = matrix.sizes.indexOf(size.trim());

    String rate = '';
    String stock = '0';
    String wsp = '0';
    TextEditingController? controller;

    if (shadeIndex != -1 && sizeIndex != -1) {
      final matrixData = matrix.matrix[shadeIndex][sizeIndex].split(',');
      rate = matrixData[0];
      wsp = matrixData.length > 1 ? matrixData[1] : '0';
      stock = matrixData[2] ?? '0';
      controller = widget.styleManager.controllers[widget.styleCode]?[shade]?[size];
    }

    final quantity = widget.quantities[shade]?[size] ?? 0;

    return Row(
      children: [
        _buildCell(size, 1),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: SizedBox(
              width: 60,
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintText: stock,
                  hintStyle: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
                style: GoogleFonts.roboto(fontSize: 14),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: (value) {
                  final newQuantity = int.tryParse(value.isEmpty ? '0' : value) ?? 0;
                  if (widget.quantities[shade] != null) {
                    setState(() {
                      widget.quantities[shade]![size] = newQuantity;
                      _hasQuantityChanged = _checkQuantityChanged();
                    });
                  }
                },
              ),
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

  bool _checkQuantityChanged() {
    for (var shade in widget.quantities.keys) {
      for (var size in widget.quantities[shade]!.keys) {
        final currentQty = widget.quantities[shade]![size]!;
        final lastQty = _lastSavedQuantities[shade]?[size] ?? 0;
        if (currentQty != lastQty) {
          return true;
        }
      }
    }
    return false;
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: const Text("Are you sure you want to delete this style?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    String sCode = widget.styleCode;
    String bCode = "";
    if (sCode.contains('---')) {
      final parts = widget.styleCode.split('---');
      sCode = parts[0];
      bCode = parts.length > 1 ? parts[1] : "";
    }

    final payload = {
      "userId": UserSession.userName ?? '',
      "coBrId": UserSession.coBrId ?? '',
      "fcYrId": UserSession.userFcYr ?? '',
      "data": {
        "designcode": sCode,
        "mrp": '0',
        "WSP": '0',
        "size": '',
        "TotQty": '0',
        "Note": '',
        "color": "",
        "Qty": "",
        "cobrid": UserSession.coBrId ?? '',
        "user": "admin",
        "barcode": bCode,
      },
      "typ": 2,
    };

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        widget.styleManager.removeStyle(widget.styleCode);
        widget.onUpdate();
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Success"),
              content: const Text("Style deleted successfully"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      } else {
        _showErrorDialog(context, "Failed to delete style: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(context, "Error deleting style: $e");
    }
  }

  Future<void> _submitUpdate(BuildContext context) async {
    int totalQty = _calculateCatalogQuantity();
    if (totalQty <= 0) {
      _showErrorDialog(context, "Total quantity must be greater than zero.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String sCode = widget.styleCode;
    String bCode = "";
    if (sCode.contains('---')) {
      final parts = widget.styleCode.split('---');
      sCode = parts[0];
      bCode = parts.length > 1 ? parts[1] : "";
    }

    final initialPayload = {
      "userId": UserSession.userName ?? '',
      "coBrId": UserSession.coBrId ?? '',
      "fcYrId": UserSession.userFcYr ?? '',
      "data": {
        "designcode": sCode,
        "mrp": widget.catalogOrder.catalog.mrp.toString(),
        "WSP": widget.catalogOrder.catalog.wsp.toString(),
        "size": widget.catalogOrder.catalog.sizeName,
        "TotQty": totalQty.toString(),
        "Note": widget.catalogOrder.catalog.remark,
        "color": widget.catalogOrder.catalog.shadeName,
        "cobrid": UserSession.coBrId ?? '',
        "user": "admin",
        "barcode": bCode,
      },
      "typ": 1,
    };

    try {
      final initialResponse = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(initialPayload),
      );

      if (initialResponse.statusCode != 200) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(
          context,
          "Failed to update style (initial request): ${initialResponse.statusCode} - ${initialResponse.body}",
        );
        return;
      }

      if (widget.quantities.isNotEmpty) {
        final shadeMap = widget.quantities;
        List<Future<http.Response>> requests = [];

        for (final shade in shadeMap.keys) {
          final sizeMap = shadeMap[shade]!;
          for (final size in sizeMap.keys) {
            final qty = sizeMap[size]!;
            if (qty <= 0) continue;

            final payload = {
              "userId": UserSession.userName ?? '',
              "coBrId": UserSession.coBrId ?? '',
              "fcYrId": UserSession.userFcYr ?? '',
              "data": {
                "designcode": sCode,
                "mrp": widget.catalogOrder.catalog.mrp.toString(),
                "WSP": widget.catalogOrder.catalog.wsp.toString(),
                "size": size,
                "TotQty": totalQty.toString(),
                "Note": widget.catalogOrder.catalog.remark,
                "color": shade,
                "Qty": qty.toString(),
                "cobrid": UserSession.coBrId ?? '',
                "user": "admin",
                "barcode": bCode,
              },
              "typ": 0,
            };

            requests.add(http.post(
              Uri.parse('${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            ));
          }
        }

        final responses = await Future.wait(requests);

        bool allSuccessful = true;
        for (var i = 0; i < responses.length; i++) {
          final response = responses[i];
          if (response.statusCode != 200) {
            allSuccessful = false;
            print(
              'Failed to update shade/size, status: ${response.statusCode}, body: ${response.body}',
            );
          }
        }

        setState(() {
          _isLoading = false;
        });

        if (allSuccessful) {
          setState(() {
            _isUpdated = false;
            _hasQuantityChanged = false;
            _lastSavedQuantities = widget.quantities.map((shade, sizes) => MapEntry(
                  shade,
                  Map<String, int>.from(sizes),
                ));
          });
          widget.onUpdate();
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Success"),
                content: const Text("Style updated successfully"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              );
            },
          );
        } else {
          _showErrorDialog(
            context,
            "Some shade/size updates failed. Check logs for details.",
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(context, "No quantities found for style: ${widget.styleCode}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error updating style: $e');
      _showErrorDialog(context, "Error updating style: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        buildOrderItem(widget.catalogOrder, context),
        
        if (_isLoading)
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withOpacity(0.4),
          ),
        if (_isLoading)
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Updating...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
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
    required this.initialIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Image.network(
          imageUrls[initialIndex],
          fit: BoxFit.contain,
          errorBuilder:
              (context, error, stackTrace) => const Icon(Icons.error, size: 60),
        ),
      ),
    );
  }
}

class _OrderForm extends StatefulWidget {
  final _OrderControllers controllers;
  final _DropdownData dropdownData;
  final Function(String?, String?) onPartySelected;
  final VoidCallback updateTotals;
  final Future<void> Function() saveOrder;
  final Map<String, dynamic> additionalInfo;
  final List<Consignee> consignees;
  final List<PytTermDisc> paymentTerms;
  final List<Item> bookingTypes;
  final Function(Map<String, dynamic>) onAdditionalInfoUpdated;
  final bool isSaving;

  const _OrderForm({
    required this.controllers,
    required this.dropdownData,
    required this.onPartySelected,
    required this.updateTotals,
    required this.saveOrder,
    required this.additionalInfo,
    required this.consignees,
    required this.paymentTerms,
    required this.bookingTypes,
    required this.onAdditionalInfoUpdated,
    required this.isSaving,
  });

  @override
  _OrderFormState createState() => _OrderFormState();
}

class _OrderFormState extends State<_OrderForm> {
  final Color primaryBlue = const Color(0xFF2196F3);
  final Color slate600 = const Color(0xFF64748B);
  final Color slateBorder = const Color(0xFFCBD5E1);

  @override
  void initState() {
    super.initState();
    if (UserSession.userType == 'C' &&
        widget.controllers.selectedParty == null) {
      final party = widget.dropdownData.partyList.firstWhere(
        (e) => e['ledKey'] == UserSession.userLedKey,
        orElse: () => {'ledKey': '', 'ledName': ''},
      );
      if (party['ledKey']!.isNotEmpty) {
        widget.controllers.selectedParty = party['ledName'];
        widget.controllers.selectedPartyKey = party['ledKey'];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onPartySelected(party['ledName'], party['ledKey']);
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No party found for userLedKey')),
          );
        });
      }
    }
    if (UserSession.userType == 'S' &&
        widget.controllers.salesPersonKey == null) {
      final salesman = widget.dropdownData.salesPersonList.firstWhere(
        (e) => e['ledKey'] == UserSession.userLedKey,
        orElse: () => {'ledKey': '', 'ledName': ''},
      );
      if (salesman['ledKey']!.isNotEmpty) {
        widget.controllers.salesPersonKey = salesman['ledKey'];
        widget.additionalInfo['salesman'] = salesman['ledKey'];
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No salesman found for userLedKey')),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildTextField(
          context,
          "Select Date",
          widget.controllers.date,
          isDate: true,
          onTap: () => _selectDate(context, widget.controllers.date),
        ),

        _buildPartyDropdownRow(context),
        _buildDropdown(
          "Broker",
          "B",
          widget.controllers.selectedBroker,
          (val, key) async {
            widget.controllers.selectedBrokerKey = key;
            if (key != null) {
              final commission = await widget.dropdownData
                  .fetchCommissionPercentage(key);
              widget.controllers.comm.text = commission;
            }
          },
          isEnabled: UserSession.userType != 'C',
        ),
        buildTextField(context, "Comm (%)", widget.controllers.comm),
        _buildDropdown(
          "Transporter",
          "T",
          widget.controllers.selectedTransporter,
          (val, key) => widget.controllers.selectedTransporterKey = key,
        ),
        _buildResponsiveRow(
          context,
          buildTextField(
            context,
            "Delivery Days",
            widget.controllers.deliveryDays,
            readOnly: true,
          ),
          buildTextField(
            context,
            "Delivery Date",
            widget.controllers.deliveryDate,
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
                final difference = picked.difference(today).inDays;
                widget
                    .controllers
                    .deliveryDate
                    .text = _OrderControllers.formatDate(picked);
                widget.controllers.deliveryDays.text = difference.toString();
              }
            },
          ),
        ),
        buildFullField(context, "Remark", widget.controllers.remark, true),
        _buildResponsiveRow(
          context,
          buildTextField(
            context,
            "Total Item",
            widget.controllers.totalItem,
            readOnly: true,
          ),
          buildTextField(
            context,
            "Total Quantity",
            widget.controllers.totalQty,
            readOnly: true,
          ),
        ),
        buildTextField(
          context,
          "Total Amount (₹)",
          widget.controllers.totalAmt,
          readOnly: true,
        ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  if (UserSession.userType == 'S' &&
                      (widget.controllers.selectedPartyKey == null ||
                          widget.controllers.selectedPartyKey!.isEmpty)) {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text('Party Selection Required'),
                            content: Text(
                              'Please select a party before adding more information.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('OK'),
                              ),
                            ],
                          ),
                    );
                    return;
                  }
                  final salesPersonList = widget.dropdownData.salesPersonList;
                  final partyLedKey = widget.controllers.selectedPartyKey;
                  final result = await showDialog(
                    context: context,
                    builder:
                        (context) => AddMoreInfoDialog(
                          salesPersonList: salesPersonList,
                          partyLedKey: partyLedKey,
                          pytTermDiscKey: widget.controllers.pytTermDiscKey,
                          salesPersonKey: widget.controllers.salesPersonKey,
                          creditPeriod: widget.controllers.creditPeriod,
                          salesLedKey: widget.controllers.salesLedKey,
                          ledgerName: widget.controllers.ledgerName,
                          additionalInfo: widget.additionalInfo,
                          consignees: widget.consignees,
                          paymentTerms: widget.paymentTerms,
                          bookingTypes: widget.bookingTypes,
                          onValueChanged: (newInfo) {
                            widget.onAdditionalInfoUpdated(newInfo);
                          },
                          isSalesmanDropdownEnabled:
                              UserSession.userType != 'S',
                        ),
                  );
                  if (result != null) {
                    widget.onAdditionalInfoUpdated(result);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue.withOpacity(0.1),
                  foregroundColor: primaryBlue,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Add More Info',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.isSaving ? null : widget.saveOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: widget.isSaving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Saving...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPartyDropdownRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDropdown(
            "Party Name",
            "w",
            widget.controllers.selectedParty,
            widget.onPartySelected,
            isEnabled: UserSession.userType != 'C',
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            color: primaryBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed:
                UserSession.userType == 'C'
                    ? null
                    : () => showDialog(
                      context: context,
                      builder: (_) => CustomerMasterDialog(),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String ledCat,
    String? selectedValue,
    Function(String?, String?) onChanged, {
    bool isEnabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownSearch<String>(
        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: _getSearchHint(label),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            labelStyle: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        dropdownBuilder: (context, selectedItem) {
          return Text(
            selectedItem ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16),
          );
        },
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
        return widget.dropdownData.partyList;
      case 'B':
        return widget.dropdownData.brokerList;
      case 'T':
        return widget.dropdownData.transporterList;
      default:
        return [];
    }
  }

  String? _getKeyFromValue(String ledCat, String? value) =>
      _getLedgerList(ledCat).firstWhere(
        (e) => e['ledName'] == value,
        orElse: () => {'ledKey': ''},
      )['ledKey'];

  String _getSearchHint(String label) {
    switch (label.toLowerCase()) {
      case 'party name':
        return 'Search party...';
      case 'broker':
        return 'Search broker...';
      case 'transporter':
        return 'Search transporter...';
      default:
        return 'Search...';
    }
  }

  Widget _buildResponsiveRow(
    BuildContext context,
    Widget first,
    Widget second,
  ) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    return isWideScreen
        ? Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 10),
            Expanded(child: second),
          ],
        )
        : Column(children: [first, second]);
  }
}

Widget buildTextField(
  BuildContext context,
  String label,
  TextEditingController controller, {
  bool isDate = false,
  bool readOnly = false,
  VoidCallback? onTap,
  bool isText = false,
}) {
  final Color primaryBlue = const Color(0xFF2196F3);
  final Color slateBorder = const Color(0xFFCBD5E1);

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      controller: controller,
      readOnly: readOnly || isDate,
      keyboardType: isText ? TextInputType.text : TextInputType.number,
      onTap: onTap ?? (isDate ? () => _selectDate(context, controller) : null),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        suffixIcon:
            isDate
                ? Icon(Icons.calendar_today, size: 20, color: Colors.grey)
                : null,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: slateBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryBlue, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}

Future<void> _selectDate(
  BuildContext context,
  TextEditingController controller,
) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  if (picked != null) {
    controller.text = _OrderControllers.formatDate(picked);
  }
}

Widget buildFullField(
  BuildContext context,
  String label,
  TextEditingController controller,
  bool? isText,
) {
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: buildTextField(context, label, controller, isText: isText ?? false),
  );
}

class AddMoreInfoDialog extends StatefulWidget {
  final List<Map<String, String>> salesPersonList;
  final String? partyLedKey;
  final String? pytTermDiscKey;
  final String? salesPersonKey;
  final int? creditPeriod;
  final String? salesLedKey;
  final String? ledgerName;
  final Map<String, dynamic> additionalInfo;
  final List<Consignee> consignees;
  final List<PytTermDisc> paymentTerms;
  final List<Item> bookingTypes;
  final Function(Map<String, dynamic>) onValueChanged;
  final bool isSalesmanDropdownEnabled;

  const AddMoreInfoDialog({
    required this.salesPersonList,
    required this.partyLedKey,
    required this.pytTermDiscKey,
    required this.salesPersonKey,
    required this.creditPeriod,
    required this.salesLedKey,
    required this.ledgerName,
    required this.additionalInfo,
    required this.consignees,
    required this.paymentTerms,
    required this.bookingTypes,
    required this.onValueChanged,
    required this.isSalesmanDropdownEnabled,
  });

  @override
  _AddMoreInfoDialogState createState() => _AddMoreInfoDialogState();
}

class _AddMoreInfoDialogState extends State<AddMoreInfoDialog> {
  late TextEditingController _refNoController;
  late TextEditingController _stationController;
  late TextEditingController _paymentDaysController;
  String? _selectedSalesman;
  String? _selectedSalesmanKey;
  String? _selectedConsignee;
  String? _selectedPaymentTerm;
  String? _selectedBookingType;

  @override
  void initState() {
    super.initState();
    _refNoController = TextEditingController(
      text: widget.additionalInfo['refno'] ?? '',
    );
    _stationController = TextEditingController(
      text: widget.additionalInfo['station'] ?? '',
    );
    _paymentDaysController = TextEditingController(
      text: widget.additionalInfo['paymentdays'] ?? widget.creditPeriod?.toString() ?? '',
    );
    _selectedSalesman =
        widget.salesPersonList.firstWhere(
          (e) =>
              e['ledKey'] ==
              (widget.additionalInfo['salesman'] ?? widget.salesPersonKey),
          orElse: () => {'ledName': ''},
        )['ledName'];
    _selectedSalesmanKey =
        widget.additionalInfo['salesman'] ?? widget.salesPersonKey;
    _selectedConsignee = widget.additionalInfo['consignee'];
    _selectedPaymentTerm =
        widget.additionalInfo['paymentterms'] ?? widget.pytTermDiscKey;
    _selectedBookingType = widget.additionalInfo['bookingtype'];
  }

  @override
  void dispose() {
    _refNoController.dispose();
    _stationController.dispose();
    _paymentDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2196F3);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Additional Information",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBlue),
                  ),
                  const SizedBox(height: 4),
                  Divider(color: Colors.grey.shade300, height: 1),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDropdown(
                      "Salesman",
                      widget.salesPersonList.map((e) => e['ledName']!).toList(),
                      _selectedSalesman,
                      widget.isSalesmanDropdownEnabled,
                      (val) {
                        setState(() {
                          _selectedSalesman = val;
                          _selectedSalesmanKey =
                              widget.salesPersonList.firstWhere(
                                (e) => e['ledName'] == val,
                                orElse: () => {'ledKey': ''},
                              )['ledKey'];
                        });
                      },
                    ),
                    
                    _buildDropdown(
                      "Consignee",
                      widget.consignees.map((e) => e.ledName).toList(),
                      _selectedConsignee,
                      true,
                      (val) => setState(() => _selectedConsignee = val),
                    ),
                    
                    _buildDropdown(
                      "Payment Terms",
                      widget.paymentTerms.map((e) => e.name).toList(),
                      _selectedPaymentTerm,
                      true,
                      (val) => setState(() => _selectedPaymentTerm = val),
                    ),
                    
                    _buildDropdown(
                      "Booking Type",
                      widget.bookingTypes.map((e) => e.itemName).toList(),
                      _selectedBookingType,
                      true,
                      (val) => setState(() => _selectedBookingType = val),
                    ),
                    
                    _buildTextField("Reference No", _refNoController),
                    
                    _buildTextField("Station", _stationController),
                    
                    _buildTextField(
                      "Payment Days", 
                      _paymentDaysController,
                      keyboardType: TextInputType.number,
                    ),
                    
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: const Color(0xFF2196F3), width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
          labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? selectedValue,
    bool enabled,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: DropdownSearch<String>(
        enabled: enabled,
        items: items,
        selectedItem: selectedValue,
        onChanged: onChanged,
        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search $label",
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              isDense: true,
            ),
          ),
          itemBuilder: (context, item, isSelected) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(item, style: const TextStyle(fontSize: 13)),
            );
          },
          constraints: const BoxConstraints(maxHeight: 300),
        ),
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: label,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(6),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFF2196F3), width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        dropdownButtonProps: const DropdownButtonProps(icon: Icon(Icons.keyboard_arrow_down)),
        dropdownBuilder: (context, selectedItem) {
          if (selectedItem == null || selectedItem.isEmpty) {
            return Text("Select $label", style: const TextStyle(fontSize: 13, color: Colors.grey));
          }
          return Text(selectedItem, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis);
        },
        filterFn: (item, filter) {
          if (filter.isEmpty) return true;
          return item.toLowerCase().contains(filter.toLowerCase());
        },
      ),
    );
  }

  void _onSave() {
    final newInfo = {
      'salesman': _selectedSalesmanKey,
      'consignee': _selectedConsignee,
      'paymentterms': _selectedPaymentTerm,
      'bookingtype': _selectedBookingType,
      'refno': _refNoController.text,
      'station': _stationController.text,
      'paymentdays': _paymentDaysController.text,
    };
    widget.onValueChanged(newInfo);
    Navigator.pop(context, newInfo);
  }
}