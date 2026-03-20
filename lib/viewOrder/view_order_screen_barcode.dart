import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:provider/provider.dart';
import 'package:vrs_erp/OrderBooking/order_booking.dart';
import 'package:vrs_erp/catalog/imagezoom.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/constants/constants.dart';
import 'package:vrs_erp/models/CartModel.dart';
import 'package:vrs_erp/register/OrderReportViewPage%20.dart';
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
import 'package:vrs_erp/viewOrder/style_card.dart';

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
  bool isCustomerTabEnabled = false;
  bool isTransactionSaved = false;
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
          AppConstants.seprateBarcodeWiseBooking == "1"
              ? '${AppConstants.BASE_URL}/orderBooking/InsertFinalsalesorder'
              : '${AppConstants.BASE_URL}/orderBooking/InsertAllsalesorder',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print("response body:${response.body}");
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

  // Future<void> _saveOrderLocally() async {
  //   if (!_formKey.currentState!.validate()) return;

  //   String? consigneeLedKey = '';
  //   String? stationStnKey = '';
  //   final selectedConsigneeName = _additionalInfo['consignee']?.toString();
  //   if (selectedConsigneeName != null && selectedConsigneeName.isNotEmpty) {
  //     final selectedConsignee = consignees.firstWhere(
  //       (consignee) => consignee.ledName == selectedConsigneeName,
  //       orElse:
  //           () => Consignee(
  //             ledKey: '',
  //             ledName: '',
  //             stnKey: '',
  //             stnName: '',
  //             paymentTermsKey: '',
  //             paymentTermsName: '',
  //             pytTermDiscdays: '0',
  //           ),
  //     );
  //     consigneeLedKey = selectedConsignee.ledKey;
  //     stationStnKey = selectedConsignee.stnKey;
  //   }

  //   final orderData = {
  //     "saleorderno": _orderControllers.orderNo.text,
  //     "orderdate": formatDate(_orderControllers.date.text, true),
  //     "customer": _orderControllers.selectedPartyKey ?? '',
  //     "broker": _orderControllers.selectedBrokerKey ?? '',
  //     "comission": _orderControllers.comm.text,
  //     "transporter": _orderControllers.selectedTransporterKey ?? '',
  //     "delivaryday": _orderControllers.deliveryDays.text,
  //     "delivarydate": formatDate(_orderControllers.deliveryDate.text, false),
  //     "totitem": _orderControllers.totalItem.text,
  //     "totqty": _orderControllers.totalQty.text,
  //     "remark": _orderControllers.remark.text,
  //     "consignee": consigneeLedKey,
  //     "station": stationStnKey,
  //     "paymentterms":
  //         _additionalInfo['paymentterms'] ??
  //         _orderControllers.pytTermDiscKey ??
  //         '',
  //     "paymentdays":
  //         _additionalInfo['paymentdays'] ??
  //         _orderControllers.creditPeriod?.toString() ??
  //         '0',
  //     "duedate": calculateDueDate(),
  //     "refno": _additionalInfo['refno'] ?? '',
  //     "date": getTodayWithZeroTime(),
  //     "bookingtype": _additionalInfo['bookingtype'] ?? '',
  //     "salesman":
  //         _additionalInfo['salesman'] ?? _orderControllers.salesPersonKey ?? '',
  //   };

  //   final orderDataJson = jsonEncode(orderData);
  //   print("Saved Order Data:");
  //   print(orderDataJson);

  //   try {
  //     final orderNumber = await insertFinalSalesOrder(orderDataJson);
  //     if (orderNumber != null && orderNumber != "fail") {
  //       final formattedOrderNo = "SO$orderNumber";
  //       print("formattedOrderNo: ${formattedOrderNo}");

  //       showDialog(
  //         context: context,
  //         builder:
  //             (context) => AlertDialog(
  //               title: Text('Order Saved'),
  //               content: Text('Order $formattedOrderNo saved successfully'),
  //               actions: [
  //                 TextButton(
  //                   onPressed: () {
  //                     Navigator.pop(context);
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                         builder:
  //                             (context) => PdfViewerScreen(
  //                               rptName: 'SalesOrder',
  //                               orderNo: formattedOrderNo,
  //                               whatsappNo: _orderControllers.whatsAppMobileNo,
  //                               partyName:
  //                                   _orderControllers.selectedPartyName ?? '',
  //                               orderDate: _orderControllers.date.text,
  //                             ),
  //                       ),
  //                     );
  //                   },
  //                   child: Text('View PDF'),
  //                 ),
  //                 TextButton(
  //                   onPressed: () {
  //                     Navigator.pushReplacement(
  //                       context,
  //                       MaterialPageRoute(builder: (context) => HomeScreen()),
  //                     );
  //                   },
  //                   child: Text('Done'),
  //                 ),
  //               ],
  //             ),
  //       );
  //     }
  //   } catch (e) {
  //     print('Error during order saving: $e');
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Error saving order: $e')));
  //   }
  // }

  Future<void> _saveOrderLocally() async {
    if (!_formKey.currentState!.validate()) return;

    String? consigneeLedKey = '';
    String? stationStnKey = '';
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
      if (orderNumber != null && orderNumber != "fail") {
        final formattedOrderNo = "SO$orderNumber";
        print("formattedOrderNo: ${formattedOrderNo}");

        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Order Saved'),
                content: Text('Order $formattedOrderNo saved successfully'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // REPLACE PdfViewerScreen with OrderReportViewPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => OrderReportViewPage(
                                orderNo:
                                    orderNumber, // Use orderNumber directly (without "SO" prefix)
                                orderData: null,
                                showOnlyWithImage: false,
                              ),
                        ),
                      );
                    },
                    child: Text(
                      'View Report',
                    ), // Changed from 'View PDF' to 'View Report'
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderBookingScreen(),
                        ),
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
    setState(() {
      isCustomerTabEnabled = false;
      isTransactionSaved = false;
    });
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Cart'),
          content: const Text('Do you want to delete all cart items?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showFinalConfirmation();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _showFinalConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearCartApi();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearCartApi() async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/orderBooking/deleteOrderCart'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "userName": UserSession.userName,
          "barcodeFlag": true,
          "seprateBarcodeWiseBooking":
              AppConstants.seprateBarcodeWiseBooking ?? "0",
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart cleared successfully')),
        );

        // Optional: Refresh UI
        // _refreshCart();
        Provider.of<CartModel>(context, listen: false).clearAddedItems();
        _initializeData();
      } else {
        _initializeData();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to clear cart')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
  @override
  Widget build(BuildContext context) {
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
        backgroundColor: AppColors.primaryColor,
        elevation: 0, // Set to 0 to remove default shadow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
            actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'clear_cart') {
                _showClearCartDialog();
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'clear_cart',
                    child: Row(
                      children: const [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Clear Cart'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49.0),
          child: Column(
            children: [
              // White divider line
              Container(
                height: 1,
                width: double.infinity,
                color: Colors.white.withOpacity(0.3),
              ),
              // Bottom container
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                color: AppColors.maroon,
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
                        'Qty: ${_calculateTotalQuantity()}',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                  isCustomerTabEnabled = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          _activeTab == ActiveTab.transaction
                              ? AppColors.primaryColor
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
                            ? AppColors.primaryColor
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
              onTap:
                  isCustomerTabEnabled
                      ? () {
                        setState(() {
                          _activeTab = ActiveTab.customerDetails;
                          _showForm = true;
                        });
                      }
                      : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          _activeTab == ActiveTab.customerDetails
                              ? AppColors.primaryColor
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
                            ? AppColors.primaryColor
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
    // CUSTOMER DETAILS TAB
    if (_activeTab == ActiveTab.customerDetails) {
      return Container(
        color: AppColors.primaryColor,
        child: SizedBox(
          height: 45,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  color: const Color.fromARGB(255, 220, 239, 248),
                  child: TextButton(
                    onPressed: () async {
                      if (UserSession.userType == 'S' &&
                          (_orderControllers.selectedPartyKey == null ||
                              _orderControllers.selectedPartyKey!.isEmpty)) {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Party Selection Required'),
                                content: const Text(
                                  'Please select a party before adding more information.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                        );
                        return;
                      }

                      final result = await showDialog(
                        context: context,
                        builder:
                            (context) => AddMoreInfoDialog(
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
                                setState(() {
                                  _additionalInfo = newInfo;
                                });
                              },
                              isSalesmanDropdownEnabled:
                                  UserSession.userType == 'A',
                              isPaymentTermEnable:
                                  UserSession.userType !=
                                  'C', // Admin & Salesman
                              isConsigneeEnabled:
                                  UserSession.userType !=
                                  'C', // Admin & Salesman
                              isBookingTypeEnabled:
                                  UserSession.userType == 'A' ||
                                  UserSession.userType ==
                                      'S', // Admin & Salesman
                            ),
                      );

                      if (result != null) {
                        setState(() {
                          _additionalInfo = result;
                        });
                      }
                    },
                    child: const Text(
                      "Add More Info",
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: _isSaving ? null : _handleSave,
                  child:
                      _isSaving
                          ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            "Save",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.white,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // TRANSACTION TAB
    return Container(
      color: AppColors.primaryColor,
      child: SizedBox(
        height: 45,
        child: Row(
          children: [
            Expanded(
              child: Container(
                color: const Color.fromARGB(255, 220, 239, 248),
                child: TextButton(
                  onPressed: () {
                    // Navigator.pushReplacement(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder:
                    //         (context) =>
                    //             OrderBookingScreen(startWithBarcode: true),
                    //   ),
                    // );
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => OrderBookingScreen(startWithBarcode: true)),
                        (Route<dynamic> route) => false,
                      );
                  },
                  child: const Text(
                    "Add More",
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () {
                  // 👇 Check if items exist first
                  if (_styleManager.groupedItems.isEmpty) {
                    // Show message when no items
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please add items'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  // 👇 Only proceed if items exist
                  if (_activeTab == ActiveTab.transaction) {
                    if (!_formKey.currentState!.validate()) return;

                    setState(() {
                      isCustomerTabEnabled = true;
                      _activeTab = ActiveTab.customerDetails;
                      _showForm = true;
                    });
                  }
                },
                icon: Icon(
                  Icons.chevron_right,
                  size: 18,
                  // 👇 Icon color changes based on item presence
                  color:
                      _styleManager.groupedItems.isEmpty
                          ? Colors.grey[600] // Grey icon when no items
                          : AppColors.white, // White icon when items exist
                ),
                label: Text(
                  "Confirm",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    // 👇 Text color changes based on item presence
                    color:
                        _styleManager.groupedItems.isEmpty
                            ? Colors.grey[600] // Grey text when no items
                            : AppColors.white, // White text when items exist
                  ),
                ),
                // 👇 Style the button with background color changes
                style: TextButton.styleFrom(
                  backgroundColor:
                      _styleManager.groupedItems.isEmpty
                          ? Colors
                              .grey[300] // Light grey background when no items
                          : AppColors
                              .primaryColor, // Primary color when items exist
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                ),
              ),
            ),
          ],
        ),
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
      case 'brown':
        return Colors.brown;

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
      body: jsonEncode({
        "ledCat": ledCat,
        "coBrId": UserSession.coBrId ?? '',
        "ledKey": UserSession.userLedKey ?? '',
        "userType": UserSession.userType ?? '',
      }),
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
      Uri.parse(
        AppConstants.seprateBarcodeWiseBooking == "1"
            ? '${AppConstants.BASE_URL}/orderBooking/GetViewOrder'
            : '${AppConstants.BASE_URL}/orderBooking/GetAllViewOrder',
      ),
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
      Uri.parse(
        AppConstants.seprateBarcodeWiseBooking == "1"
            ? '${AppConstants.BASE_URL}/orderBooking/GetViewOrder'
            : '${AppConstants.BASE_URL}/orderBooking/GetAllViewOrder',
      ),
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
      items.map((e) => e[field]?.toString() ?? '').toSet().toList();
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

    // Create matrix with sizes as rows and shades as columns
    final matrix = List.generate(sizes.length, (sizeIndex) {
      return List.generate(shades.length, (shadeIndex) {
        final item = items.firstWhere(
          (i) =>
              (i['shadeName']?.toString() ?? '') == shades[shadeIndex] &&
              (i['sizeName']?.toString() ?? '') == sizes[sizeIndex],
          orElse: () => {},
        );
        final mrp = item['mrp']?.toString() ?? '0';
        final wsp = item['wsp']?.toString() ?? '0';
        final qty = item['clqty']?.toString() ?? '0';
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
    _lastSavedQuantities = widget.quantities.map(
      (shade, sizes) => MapEntry(shade, Map<String, int>.from(sizes)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with image and details (same as previous design)
              Padding(
                padding: const EdgeInsets.all(12),
                child: _buildHeaderSection(),
              ),

              const SizedBox(height: 4),

              // Stats row (same as previous design)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildStatsRow(),
              ),

              const SizedBox(height: 12),

              // Price Table - FULL WIDTH (enhanced design)
              ...widget.selectedColors.map(
                (color) => Column(
                  children: [
                    _buildEnhancedPriceTable(color),
                    const SizedBox(height: 5),

                    // Action buttons (enhanced design but same functionality)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: _buildActionButtons(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),

          // Loading overlay (unchanged)
          if (_isLoading)
            ModalBarrier(
              dismissible: false,
              color: Colors.black.withOpacity(0.4),
            ),
          if (_isLoading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      SizedBox(width: 16),
                      Text(
                        'Updating...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // New header section with enhanced design
  Widget _buildHeaderSection() {
    final catalog = widget.catalogOrder.catalog;
    final firstItem = widget.items.first;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image (unchanged functionality)
        _buildItemImage(catalog.fullImagePath),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Style Code with gradient background (enhanced design)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor.withOpacity(0.08),
                      Colors.white,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Style Code with badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'STYLE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.styleCode,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Divider
                    Divider(
                      color: AppColors.primaryColor.withOpacity(0.2),
                      height: 1,
                      thickness: 1,
                    ),

                    const SizedBox(height: 8),

                    // Details in wrap layout (same data, enhanced presentation)
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (firstItem['itemSubGrpName'] != null)
                          _buildCompactDetailChip(
                            'Category',
                            firstItem['itemSubGrpName'],
                          ),
                        if (firstItem['itemName'] != null)
                          _buildCompactDetailChip(
                            'Product',
                            firstItem['itemName'],
                          ),
                        if (firstItem['brandName'] != null)
                          _buildCompactDetailChip(
                            'Brand',
                            firstItem['brandName'],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method for detail chips
  Widget _buildCompactDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: TableColors.priceRowBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TableColors.borderColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // New stats row
  Widget _buildStatsRow() {
    return Row(
      children: [
        // Expanded(
        //   child: _buildStatRow(
        //     'Stock',
        //     _calculateStockQuantity().toString(),
        //     Icons.inventory,
        //     Colors.blue.shade700,
        //   ),
        // ),
        // const SizedBox(width: 6),
        Expanded(
          child: _buildStatRow(
            'Qty',
            _calculateCatalogQuantity().toString(),
            Icons.shopping_bag,
            Colors.orange.shade700,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildStatRow(
            'Amt',
            '₹${_calculateCatalogPrice().toStringAsFixed(0)}',
            Icons.currency_rupee,
            Colors.green.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced price table with full width
  Widget _buildEnhancedPriceTable(String shade) {
    final matrix = widget.catalogOrder.orderMatrix;
    final shadeIndex = matrix.shades.indexOf(shade.trim());
    if (shadeIndex == -1) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: TableColors.borderColor),
          bottom: BorderSide(color: TableColors.borderColor),
        ),
        color: Colors.white,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Table(
              border: TableBorder.all(
                color: TableColors.borderColor,
                width: 0.5,
              ),
              columnWidths: _buildColumnWidths(matrix.sizes.length),
              children: [
                // Header row with enhanced diagonal
                _buildEnhancedHeaderRow(matrix.sizes),

                // MRP row
                TableRow(
                  decoration: BoxDecoration(color: TableColors.priceRowBg),
                  children: [
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: TableColors.accentColor.withOpacity(0.1),
                        child: const Text(
                          'MRP',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: TableColors.accentColor,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    ...matrix.sizes.asMap().entries.map((entry) {
                      final sizeIndex = entry.key;
                      final matrixData = matrix.matrix[sizeIndex][shadeIndex]
                          .split(',');
                      final mrp = matrixData.isNotEmpty ? matrixData[0] : '0';
                      return TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: TableColors.borderColor,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '₹$mrp',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),

                // WSP row
                TableRow(
                  decoration: BoxDecoration(color: TableColors.priceRowBg),
                  children: [
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: TableColors.accentColor.withOpacity(0.1),
                        child: const Text(
                          'WSP',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: TableColors.accentColor,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    ...matrix.sizes.asMap().entries.map((entry) {
                      final sizeIndex = entry.key;
                      final matrixData = matrix.matrix[sizeIndex][shadeIndex]
                          .split(',');
                      final wsp = matrixData.length > 1 ? matrixData[1] : '0';
                      return TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: TableColors.borderColor,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '₹$wsp',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),

                // Shade row with quantity fields (same functionality)
                TableRow(
                  decoration: BoxDecoration(color: TableColors.evenRowBg),
                  children: [
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: TableColors.borderColor,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Copy icon (same functionality as before)
                            // Container(
                            //   margin: const EdgeInsets.only(right: 6),
                            //   child: Material(
                            //     color: Colors.transparent,
                            //     child: InkWell(
                            //       borderRadius: BorderRadius.circular(4),
                            //       onTap: () => _showShadeCopyOptions(shade),
                            //       child: Container(
                            //         padding: const EdgeInsets.all(4),
                            //         decoration: BoxDecoration(
                            //           color: TableColors.accentColor
                            //               .withOpacity(0.1),
                            //           borderRadius: BorderRadius.circular(4),
                            //         ),
                            //         child: Icon(
                            //           Icons.copy_all,
                            //           size: 14,
                            //           color: TableColors.accentColor,
                            //         ),
                            //       ),
                            //     ),
                            //   ),
                            // ),
                            Expanded(
                              child: Text(
                                shade,
                                style: TextStyle(
                                  color: widget.getColor(shade),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ...matrix.sizes.asMap().entries.map((entry) {
                      final sizeIndex = entry.key;
                      final size = entry.value;
                      final currentQty = widget.quantities[shade]?[size] ?? 0;

                      return TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: TableColors.borderColor,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: TextField(
                            controller:
                                widget.styleManager.controllers[widget
                                    .styleCode]?[shade]?[size],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              hintText: currentQty.toString(),
                              hintStyle: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                                fontStyle: FontStyle.italic,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: TableColors.accentColor,
                                  width: 1,
                                ),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            onChanged: (value) {
                              final newQuantity =
                                  int.tryParse(value.isEmpty ? '0' : value) ??
                                  0;
                              if (widget.quantities[shade] != null) {
                                setState(() {
                                  widget.quantities[shade]![size] = newQuantity;
                                  _hasQuantityChanged = _checkQuantityChanged();
                                });
                              }
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced header row with diagonal
  TableRow _buildEnhancedHeaderRow(List<String> sizes) {
    return TableRow(
      decoration: BoxDecoration(color: TableColors.headerBg),
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Container(
            height: 50,
            child: CustomPaint(
              painter: _SimpleDiagonalPainter(),
              child: const Stack(
                children: [
                  Positioned(
                    left: 12,
                    top: 22,
                    child: Text(
                      'SHADE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 14,
                    bottom: 22,
                    child: Text(
                      'SIZE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        fontSize: 14,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ...sizes.map(
          (size) => TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  size,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Map<int, TableColumnWidth> _buildColumnWidths(int sizeCount) {
    double screenWidth = MediaQuery.of(context).size.width;
    double firstColumnWidth = 140;
    double remainingWidth = screenWidth - firstColumnWidth;
    double sizeColumnWidth = remainingWidth / (sizeCount > 0 ? sizeCount : 1);

    if (sizeColumnWidth < 70) {
      sizeColumnWidth = 70;
    }

    return {
      0: FixedColumnWidth(firstColumnWidth),
      for (var i = 0; i < sizeCount; i++)
        i + 1: FixedColumnWidth(sizeColumnWidth),
    };
  }

  // Enhanced action buttons with reduced height
  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Note field (unchanged functionality)
        TextField(
          controller: TextEditingController(
            text: widget.catalogOrder.catalog.remark,
          ),
          decoration: InputDecoration(
            labelText: 'Note',
            labelStyle: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: TableColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 11),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Update Button
            Expanded(
              child: _buildCompactGradientButton(
                label: 'Update',
                icon: Icons.update,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onPressed:
                    _isLoading || !_hasQuantityChanged
                        ? null
                        : () => _submitUpdate(context),
              ),
            ),
            const SizedBox(width: 8),
            // Remove Button
            Expanded(
              child: _buildCompactGradientButton(
                label: 'Remove',
                icon: Icons.delete,
                gradient: const LinearGradient(
                  colors: [Color(0xFFf44336), Color(0xFFd32f2f)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onPressed: _isLoading ? null : () => _submitDelete(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactGradientButton({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      height: 32,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          minimumSize: const Size(double.infinity, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _showShadeCopyOptions(String shade) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Copy Options for $shade',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TableColors.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.copy_all,
                    color: TableColors.accentColor,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Copy Qty in shade only',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  'Copy first quantity to all sizes in this shade',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                onTap: () {
                  Navigator.pop(context);
                  final firstQty =
                      widget
                          .styleManager
                          .controllers[widget.styleCode]?[shade]
                          ?.values
                          .first
                          .text;
                  for (var size
                      in widget
                          .styleManager
                          .controllers[widget.styleCode]![shade]!
                          .keys) {
                    widget
                        .styleManager
                        .controllers[widget.styleCode]![shade]![size]
                        ?.text = firstQty ?? '0';
                  }
                  widget.onUpdate();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Original functionality methods (unchanged)
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
    for (var sizeIndex = 0; sizeIndex < matrix.sizes.length; sizeIndex++) {
      for (
        var shadeIndex = 0;
        shadeIndex < matrix.shades.length;
        shadeIndex++
      ) {
        final matrixData = matrix.matrix[sizeIndex][shadeIndex].split(',');
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
            double.tryParse(
              matrix.matrix[sizeIndex][shadeIndex].split(',')[0],
            ) ??
            0;
        final quantity = widget.quantities[shade]![size]!;
        total += rate * quantity;
      }
    }
    return total;
  }

  Widget _buildItemImage(String imagePath) {
    final imageUrl =
        imagePath.contains("http")
            ? imagePath
            : '${AppConstants.BASE_URL}/images$imagePath';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    ImageZoomScreen(imageUrls: [imageUrl], initialIndex: 0),
          ),
        );
      },
      child: Container(
        width: 90,
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: TableColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder:
                (context, child, loadingProgress) =>
                    loadingProgress == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
            errorBuilder:
                (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 30,
                    color: Colors.grey,
                  ),
                ),
          ),
        ),
      ),
    );
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
        Uri.parse(
          '${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails',
        ),
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
        _showErrorDialog(
          context,
          "Failed to delete style: ${response.statusCode}",
        );
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
        Uri.parse(
          '${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails',
        ),
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

            requests.add(
              http.post(
                Uri.parse(
                  '${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails',
                ),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(payload),
              ),
            );
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
            _lastSavedQuantities = widget.quantities.map(
              (shade, sizes) => MapEntry(shade, Map<String, int>.from(sizes)),
            );
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
        _showErrorDialog(
          context,
          "No quantities found for style: ${widget.styleCode}",
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error updating style: $e');
      _showErrorDialog(context, "Error updating style: $e");
    }
  }
}

// Simple diagonal painter
class _SimpleDiagonalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

        // Row(
        //   children: [
        //     Expanded(
        //       child: ElevatedButton(
        //         onPressed: () async {
        //           if (UserSession.userType == 'S' &&
        //               (widget.controllers.selectedPartyKey == null ||
        //                   widget.controllers.selectedPartyKey!.isEmpty)) {
        //             showDialog(
        //               context: context,
        //               builder:
        //                   (context) => AlertDialog(
        //                     title: Text('Party Selection Required'),
        //                     content: Text(
        //                       'Please select a party before adding more information.',
        //                     ),
        //                     actions: [
        //                       TextButton(
        //                         onPressed: () => Navigator.pop(context),
        //                         child: Text('OK'),
        //                       ),
        //                     ],
        //                   ),
        //             );
        //             return;
        //           }
        //           final salesPersonList = widget.dropdownData.salesPersonList;
        //           final partyLedKey = widget.controllers.selectedPartyKey;
        //           final result = await showDialog(
        //             context: context,
        //             builder:
        //                 (context) => AddMoreInfoDialog(
        //                   salesPersonList: salesPersonList,
        //                   partyLedKey: partyLedKey,
        //                   pytTermDiscKey: widget.controllers.pytTermDiscKey,
        //                   salesPersonKey: widget.controllers.salesPersonKey,
        //                   creditPeriod: widget.controllers.creditPeriod,
        //                   salesLedKey: widget.controllers.salesLedKey,
        //                   ledgerName: widget.controllers.ledgerName,
        //                   additionalInfo: widget.additionalInfo,
        //                   consignees: widget.consignees,
        //                   paymentTerms: widget.paymentTerms,
        //                   bookingTypes: widget.bookingTypes,
        //                   onValueChanged: (newInfo) {
        //                     widget.onAdditionalInfoUpdated(newInfo);
        //                   },
        //                   isSalesmanDropdownEnabled:
        //                       UserSession.userType != 'S',
        //                 ),
        //           );
        //           if (result != null) {
        //             widget.onAdditionalInfoUpdated(result);
        //           }
        //         },
        //         style: ElevatedButton.styleFrom(
        //           backgroundColor: AppColors.primaryColor.withOpacity(0.1),
        //           foregroundColor: AppColors.primaryColor,
        //           elevation: 0,
        //           padding: const EdgeInsets.symmetric(vertical: 16),
        //           shape: RoundedRectangleBorder(
        //             borderRadius: BorderRadius.circular(8),
        //           ),
        //         ),
        //         child: const Text(
        //           'Add More Info',
        //           style: TextStyle(fontWeight: FontWeight.bold),
        //         ),
        //       ),
        //     ),
        //     const SizedBox(width: 10),
        //     Expanded(
        //       child: ElevatedButton(
        //         onPressed: widget.isSaving ? null : widget.saveOrder,
        //         style: ElevatedButton.styleFrom(
        //           backgroundColor: AppColors.primaryColor,
        //           foregroundColor: Colors.white,
        //           padding: const EdgeInsets.symmetric(vertical: 16),
        //           shape: RoundedRectangleBorder(
        //             borderRadius: BorderRadius.circular(8),
        //           ),
        //         ),
        //         child:
        //             widget.isSaving
        //                 ? Row(
        //                   mainAxisAlignment: MainAxisAlignment.center,
        //                   mainAxisSize: MainAxisSize.min,
        //                   children: [
        //                     const Text(
        //                       'Saving...',
        //                       style: TextStyle(
        //                         fontSize: 16,
        //                         fontWeight: FontWeight.w500,
        //                         color: Colors.white,
        //                       ),
        //                     ),
        //                     const SizedBox(width: 12),
        //                     const SizedBox(
        //                       width: 20,
        //                       height: 20,
        //                       child: CircularProgressIndicator(
        //                         strokeWidth: 2.5,
        //                         color: Colors.white,
        //                       ),
        //                     ),
        //                   ],
        //                 )
        //                 : const Text(
        //                   'Save',
        //                   style: TextStyle(fontWeight: FontWeight.bold),
        //                 ),
        //       ),
        //     ),
        //   ],
        // ),
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
          isRequired: true,
        ),
      ),
      const SizedBox(width: 8),
      Container(
        height: 54,
        width: 54,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: UserSession.userType == 'C'
              ? null
              : () async {
                  // Show dialog and wait for result
                  final result = await showDialog(
                    context: context,
                    builder: (_) => CustomerMasterDialog(),
                  );

                  // Handle the result
                  if (result != null && result is Map) {
                    if (result['success'] == true) {
                      // Show loading indicator
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Refreshing party list...'),
                          duration: Duration(seconds: 1),
                        ),
                      );

                      // Refresh the dropdown data
                      await widget.dropdownData.loadAllDropdownData();

                      // Auto-select the new customer if we have the key
                      if (result['customerKey'] != null) {
                        widget.onPartySelected(
                          result['customerName'],
                          result['customerKey'],
                        );
                      }

                      // Update UI
                      setState(() {});

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Customer "${result['customerName']}" added and selected',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
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
       bool isRequired = false,
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

        /// ⭐ SEARCH ONLY BEFORE -->
        filterFn: (item, filter) {
          if (filter.isEmpty) return true;

          final namePart =
              item.contains('-->')
                  ? item.split('-->').first.trim().toLowerCase()
                  : item.toLowerCase();

          return namePart.contains(filter.toLowerCase());
        },

        selectedItem: selectedValue,

        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: label,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
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
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
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
  final bool isPaymentTermEnable;
  final bool isConsigneeEnabled; // Add this
  final bool isBookingTypeEnabled;

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
    required this.isPaymentTermEnable,
    required this.isConsigneeEnabled,
    required this.isBookingTypeEnabled,
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
  String? _selectedConsigneeKey; // Store consignee key
  String? _selectedConsigneeName; // Display consignee name
  String? _selectedPaymentTermKey; // Store payment term key
  String? _selectedPaymentTermName; // Display payment term name
  String? _selectedBookingTypeKey; // Store booking type key
  String? _selectedBookingTypeName;

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
      text:
          widget.additionalInfo['paymentdays'] ??
          widget.creditPeriod?.toString() ??
          '',
    );

    // Initialize Salesman
    _selectedSalesman =
        widget.salesPersonList.firstWhere(
          (e) =>
              e['ledKey'] ==
              (widget.additionalInfo['salesman'] ?? widget.salesPersonKey),
          orElse: () => {'ledName': ''},
        )['ledName'];
    _selectedSalesmanKey =
        widget.additionalInfo['salesman'] ?? widget.salesPersonKey;

    // Initialize Consignee - store key but get name for display
    _selectedConsigneeKey = widget.additionalInfo['consignee'];
    if (_selectedConsigneeKey != null) {
      final consignee = widget.consignees.firstWhere(
        (e) => e.ledKey == _selectedConsigneeKey,
        orElse:
            () => Consignee(
              ledKey: '',
              ledName: '',
              stnKey: '',
              stnName: '',
              paymentTermsKey: '',
              paymentTermsName: '',
              pytTermDiscdays: '',
            ),
      );
      _selectedConsigneeName =
          consignee.ledName.isNotEmpty ? consignee.ledName : null;
    }

    // Initialize Payment Term - store key but get name for display
    _selectedPaymentTermKey =
        widget.additionalInfo['paymentterms'] ?? widget.pytTermDiscKey;
    if (_selectedPaymentTermKey != null) {
      final term = widget.paymentTerms.firstWhere(
        (e) => e.key == _selectedPaymentTermKey,
        orElse: () => PytTermDisc(key: '', name: ''),
      );
      _selectedPaymentTermName = term.name.isNotEmpty ? term.name : null;
    }

    // Initialize Booking Type - store key but get name for display
    _selectedBookingTypeKey = widget.additionalInfo['bookingtype'];
    if (_selectedBookingTypeKey != null) {
      final bookingType = widget.bookingTypes.firstWhere(
        (e) => e.itemKey == _selectedBookingTypeKey,
        orElse: () => Item(itemKey: '', itemName: '', itemSubGrpKey: ''),
      );
      _selectedBookingTypeName =
          bookingType.itemName.isNotEmpty ? bookingType.itemName : null;
    }
  }

  // Helper method to get consignee name from key
  String? _getConsigneeName() {
    if (_selectedConsigneeKey != null) {
      final consignee = widget.consignees.firstWhere(
        (e) => e.ledKey == _selectedConsigneeKey,
        orElse:
            () => Consignee(
              ledKey: '',
              ledName: '',
              stnKey: '',
              stnName: '',
              paymentTermsKey: '',
              paymentTermsName: '',
              pytTermDiscdays: '',
            ),
      );
      if (consignee.ledName.isNotEmpty) return consignee.ledName;
    }
    return null;
  }

  // Helper method to get consignee key from name
  String? _getConsigneeKey(String? selectedName) {
    if (selectedName == null) return null;

    final consignee = widget.consignees.firstWhere(
      (e) => e.ledName == selectedName,
      orElse:
          () => Consignee(
            ledKey: '',
            ledName: '',
            stnKey: '',
            stnName: '',
            paymentTermsKey: '',
            paymentTermsName: '',
            pytTermDiscdays: '',
          ),
    );

    _selectedConsigneeKey =
        consignee.ledKey.isNotEmpty ? consignee.ledKey : null;
    return _selectedConsigneeKey;
  }

  // Helper method to get payment term name from key
  String? _getPaymentTermName() {
    if (_selectedPaymentTermKey != null) {
      final term = widget.paymentTerms.firstWhere(
        (e) => e.key == _selectedPaymentTermKey,
        orElse: () => PytTermDisc(key: '', name: ''),
      );
      if (term.name.isNotEmpty) return term.name;
    }
    return null;
  }

  // Helper method to get payment term key from name
  String? _getPaymentTermKey(String? selectedName) {
    if (selectedName == null) return null;

    final term = widget.paymentTerms.firstWhere(
      (e) => e.name == selectedName,
      orElse: () => PytTermDisc(key: '', name: ''),
    );

    _selectedPaymentTermKey = term.key.isNotEmpty ? term.key : null;
    return _selectedPaymentTermKey;
  }

  // Helper method to get booking type name from key
  String? _getBookingTypeName() {
    if (_selectedBookingTypeKey != null) {
      final bookingType = widget.bookingTypes.firstWhere(
        (e) => e.itemKey == _selectedBookingTypeKey,
        orElse: () => Item(itemKey: '', itemName: '', itemSubGrpKey: ''),
      );
      if (bookingType.itemName.isNotEmpty) return bookingType.itemName;
    }
    return null;
  }

  // Helper method to get booking type key from name
  String? _getBookingTypeKey(String? selectedName) {
    if (selectedName == null) return null;

    final bookingType = widget.bookingTypes.firstWhere(
      (e) => e.itemName == selectedName,
      orElse: () => Item(itemKey: '', itemName: '', itemSubGrpKey: ''),
    );

    _selectedBookingTypeKey =
        bookingType.itemKey.isNotEmpty ? bookingType.itemKey : null;
    return _selectedBookingTypeKey;
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 20.0,
      ),
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
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Divider(color: Colors.grey.shade300, height: 1),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Salesman Dropdown
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

                    // Consignee Dropdown - Updated to use key/name pattern
                    _buildDropdown(
                      "Consignee",
                      widget.consignees.map((e) => e.ledName).toList(),
                      _getConsigneeName(), // Get name from key
                      widget.isConsigneeEnabled,
                      (val) {
                        setState(() {
                          _getConsigneeKey(val); // Store key from selected name
                        });
                      },
                    ),

                    // Payment Terms Dropdown - Already updated
                    _buildDropdown(
                      "Payment Terms",
                      widget.paymentTerms.map((e) => e.name).toList(),
                      _getPaymentTermName(), // Get name from key
                      widget.isPaymentTermEnable,
                      (val) {
                        setState(() {
                          _getPaymentTermKey(
                            val,
                          ); // Store key from selected name
                        });
                      },
                    ),

                    // Booking Type Dropdown - Updated to use key/name pattern
                    _buildDropdown(
                      "Booking Type",
                      widget.bookingTypes.map((e) => e.itemName).toList(),
                      _getBookingTypeName(), // Get name from key
                      widget.isBookingTypeEnabled,
                      (val) {
                        setState(() {
                          _getBookingTypeKey(
                            val,
                          ); // Store key from selected name
                        });
                      },
                    ),

                    _buildTextField("Reference No", _refNoController),

                    // _buildTextField("Station", _stationController),

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
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        "Save",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(fontWeight: FontWeight.bold),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: const Color(0xFF2196F3), width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
          labelStyle: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
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
              color: Color(0xFF475569),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        dropdownButtonProps: const DropdownButtonProps(
          icon: Icon(Icons.keyboard_arrow_down),
        ),
        dropdownBuilder: (context, selectedItem) {
          if (selectedItem == null || selectedItem.isEmpty) {
            return Text(
              "Select $label",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            );
          }
          return Text(
            selectedItem,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          );
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
      'consignee': _selectedConsigneeKey, // Save the key
      'paymentterms': _selectedPaymentTermKey, // Save the key
      'bookingtype': _selectedBookingTypeKey,
      'refno': _refNoController.text,
      'station': _stationController.text,
      'paymentdays': _paymentDaysController.text,
    };
    widget.onValueChanged(newInfo);
    Navigator.pop(context, newInfo);
  }
}

class _DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.shade400
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
