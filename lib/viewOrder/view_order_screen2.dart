import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:vrs_erp/OrderBooking/order_booking.dart';
import 'package:vrs_erp/OrderBooking/orderbooking_booknow.dart';
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
import 'package:vrs_erp/viewOrder/style_card.dart';
import 'package:vrs_erp/models/consignee.dart';
import 'package:vrs_erp/models/PytTermDisc.dart';
import 'package:vrs_erp/models/item.dart';
import 'package:vrs_erp/models/catalog.dart';
import 'package:vrs_erp/models/OrderMatrix.dart';
import 'package:vrs_erp/models/CatalogOrderData.dart';
import 'package:vrs_erp/catalog/imagezoom.dart';
import 'package:google_fonts/google_fonts.dart';

enum ActiveTab { transaction, customerDetails }

class ViewOrderScreen2 extends StatefulWidget {
  @override
  _ViewOrderScreen2State createState() => _ViewOrderScreen2State();
}

class _ViewOrderScreen2State extends State<ViewOrderScreen2> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _additionalInfo = {};
  bool _showForm = false;
  final _orderControllers = _OrderControllers2();
  final _dropdownData = _DropdownData2();
  final _styleManager = _StyleManager2();
  List<Consignee> consignees = [];
  List<PytTermDisc> paymentTerms = [];
  List<Item> _bookingTypes = [];
  bool isLoading = true;
  bool barcodeMode = false;
  ActiveTab _activeTab = ActiveTab.transaction;
  bool isCustomerTabEnabled = false;
  bool _isSaving = false;

  // For table design
  Map<String, Map<String, Map<String, int>>> quantities = {};
  Map<String, Set<String>> selectedColors = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        if (args.containsKey(Constants.barcode)) {
          barcodeMode = args[Constants.barcode] as bool;
        }
      }
      _initializeData();
      _setInitialDates();
      fetchAndPrintSalesOrderNumber();
      _styleManager.updateTotalsCallback = _updateTotals;
      _loadBookingTypes();
    });
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
      barcode: "false",
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
      'data2': orderDataJson.toString(),
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
    _orderControllers.date.text = _OrderControllers2.formatDate(today);
    _orderControllers.deliveryDate.text = _OrderControllers2.formatDate(today);
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
      final allShades = _getSortedUniqueValues(items, 'shadeName');
      final sizes = _getSortedUniqueValues(items, 'sizeName');

      // Initialize quantities for all shades first
      quantities[styleKey] = {};
      for (var shade in allShades) {
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

      // FIX: Only add shades to selectedColors if they have quantity > 0
      selectedColors[styleKey] = {};
      for (var shade in allShades) {
        bool hasQuantity = false;
        for (var size in sizes) {
          if ((quantities[styleKey]![shade]?[size] ?? 0) > 0) {
            hasQuantity = true;
            break;
          }
        }
        if (hasQuantity) {
          selectedColors[styleKey]!.add(shade);
        }
      }
    }
  }

  List<String> _getSortedUniqueValues(List<dynamic> items, String field) =>
      items.map((e) => e[field]?.toString() ?? '').toSet().toList();

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
  //   if (_isSaving) return;

  //   setState(() => _isSaving = true);

  //   try {
  //     if (!_formKey.currentState!.validate()) {
  //       setState(() => _isSaving = false);
  //       return;
  //     }

  //     String? consigneeLedKey = '';
  //     String? stationStnKey = '';
  //     final selectedConsigneeName = _additionalInfo['consignee']?.toString();
  //     if (selectedConsigneeName != null && selectedConsigneeName.isNotEmpty) {
  //       final selectedConsignee = consignees.firstWhere(
  //         (consignee) => consignee.ledName == selectedConsigneeName,
  //         orElse:
  //             () => Consignee(
  //               ledKey: '',
  //               ledName: '',
  //               stnKey: '',
  //               stnName: '',
  //               paymentTermsKey: '',
  //               paymentTermsName: '',
  //               pytTermDiscdays: '0',
  //             ),
  //       );
  //       consigneeLedKey = selectedConsignee.ledKey;
  //       stationStnKey = selectedConsignee.stnKey;
  //     }

  //     final orderData = {
  //       "saleorderno": _orderControllers.orderNo.text,
  //       "orderdate": formatDate(_orderControllers.date.text, true),
  //       "customer": _orderControllers.selectedPartyKey ?? '',
  //       "broker": _orderControllers.selectedBrokerKey ?? '',
  //       "comission": _orderControllers.comm.text,
  //       "transporter": _orderControllers.selectedTransporterKey ?? '',
  //       "delivaryday": _orderControllers.deliveryDays.text,
  //       "delivarydate": formatDate(_orderControllers.deliveryDate.text, false),
  //       "totitem": _orderControllers.totalItem.text,
  //       "totqty": _orderControllers.totalQty.text,
  //       "remark": _orderControllers.remark.text,
  //       "consignee": consigneeLedKey,
  //       "station": stationStnKey,
  //       "paymentterms":
  //           _additionalInfo['paymentterms'] ??
  //           _orderControllers.pytTermDiscKey ??
  //           '',
  //       "paymentdays":
  //           _additionalInfo['paymentdays'] ??
  //           _orderControllers.creditPeriod?.toString() ??
  //           '0',
  //       "duedate": calculateDueDate(),
  //       "refno": _additionalInfo['refno'] ?? '',
  //       "date": getTodayWithZeroTime(),
  //       "bookingtype": _additionalInfo['bookingtype'] ?? '',
  //       "salesman":
  //           _additionalInfo['salesman'] ??
  //           _orderControllers.salesPersonKey ??
  //           '',
  //     };
  //     final orderDataJson = jsonEncode(orderData);
  //     print("Saved Order Data:");
  //     print(orderDataJson);

  //     final response = await insertFinalSalesOrder(orderDataJson);
  //     if (response != null && response != "fail") {
  //       Provider.of<CartModel>(context, listen: false).clearAddedItems();
  //       final formattedOrderNo = "SO$response";

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
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Failed to save order. Please try again.')),
  //       );
  //     }
  //   } catch (e) {
  //     print('Error during order saving: $e');
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Error saving order: $e')));
  //   } finally {
  //     setState(() => _isSaving = false);
  //   }
  // }

  Future<void> _saveOrderLocally() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      if (!_formKey.currentState!.validate()) {
        setState(() => _isSaving = false);
        return;
      }

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
            _additionalInfo['salesman'] ??
            _orderControllers.salesPersonKey ??
            '',
      };
      final orderDataJson = jsonEncode(orderData);
      print("Saved Order Data:");
      print(orderDataJson);

      final response = await insertFinalSalesOrder(orderDataJson);
      if (response != null && response != "fail") {
        Provider.of<CartModel>(context, listen: false).clearAddedItems();
        final formattedOrderNo = "SO$response";

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
                                    response, // Use the response which is the order number
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save order. Please try again.')),
        );
      }
    } catch (e) {
      print('Error during order saving: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving order: $e')));
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
    });
  }

  void _updateQuantitiesFromRefreshedItems() {
    for (var entry in _styleManager.groupedItems.entries) {
      final styleKey = entry.key;
      final items = entry.value;
      final sizes = _getSortedUniqueValues(items, 'sizeName');
      final allShades = _getSortedUniqueValues(items, 'shadeName');

      // Ensure quantities map exists
      if (!quantities.containsKey(styleKey)) {
        quantities[styleKey] = {};
      }

      // Update quantities for all shades (including newly added ones)
      for (var shade in allShades) {
        if (!quantities[styleKey]!.containsKey(shade)) {
          quantities[styleKey]![shade] = {};
        }

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

      // Ensure selectedColors has all shades with quantity > 0
      // But PRESERVE any manually added shades (even with 0 quantity)
      if (!selectedColors.containsKey(styleKey)) {
        selectedColors[styleKey] = {};
      }

      // Add shades with quantity > 0
      for (var shade in allShades) {
        bool hasQuantity = false;
        for (var size in sizes) {
          if ((quantities[styleKey]![shade]?[size] ?? 0) > 0) {
            hasQuantity = true;
            break;
          }
        }
        if (hasQuantity) {
          selectedColors[styleKey]!.add(shade);
        }
      }
    }
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
          "barcodeFlag": false,
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
          'View Order',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 4,
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
                    'Items: ${_calculateTotalItems()}',
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
                          ? _OrderForm2(
                            controllers: _orderControllers,
                            dropdownData: _dropdownData,
                            onPartySelected: _handlePartySelection,
                            updateTotals: _updateTotals,
                            saveOrder: _saveOrderLocally,
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
                          : _StyleCardsView2(
                            styleManager: _styleManager,
                            updateTotals: _updateTotals,
                            getColor: _getColorCode,
                            onUpdate: () async {
                              // Don't re-initialize everything, just refresh the order items
                              await _styleManager.refreshOrderItems(
                                barcode: barcodeMode,
                              );

                              // Instead of re-initializing everything, just update quantities
                              // from the refreshed items while preserving selectedColors
                              _updateQuantitiesFromRefreshedItems();

                              _updateTotals();

                              // Force a rebuild
                              setState(() {});
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
                  onPressed: _isSaving ? null : _saveOrderLocally,
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
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderBookingScreen(),
                      ),
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
                  if (_styleManager.groupedItems.isEmpty) {
                    // Show message when no items
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please add items'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

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
                  color:
                      _styleManager.groupedItems.isEmpty
                          ? Colors.grey[400]
                          : AppColors.white,
                ),
                label: Text(
                  "Confirm",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color:
                        _styleManager.groupedItems.isEmpty
                            ? Colors.grey[400]
                            : AppColors.white,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor:
                      _styleManager.groupedItems.isEmpty
                          ? Colors.grey[300]
                          : AppColors.primaryColor,
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
}

class _OrderControllers2 {
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

class _DropdownData2 {
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

class _StyleManager2 {
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

  void removeStyle(String styleKey) {
    removedStyles.add(styleKey);
    controllers.remove(styleKey);
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
            orElse: () => {'clqty': 0},
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
            orElse: () => {'clqty': 0},
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

class _StyleCardsView2 extends StatelessWidget {
  final _StyleManager2 styleManager;
  final VoidCallback updateTotals;
  final Color Function(String) getColor;
  final VoidCallback onUpdate;
  final Map<String, Map<String, Map<String, int>>> quantities;
  final Map<String, Set<String>> selectedColors;

  const _StyleCardsView2({
    required this.styleManager,
    required this.updateTotals,
    required this.getColor,
    required this.onUpdate,
    required this.quantities,
    required this.selectedColors,
  });

  List<String> _getAllShadesForStyle(String styleKey) {
    final items = styleManager.groupedItems[styleKey] ?? [];
    return items
        .map((item) => item['shadeName']?.toString() ?? '')
        .toSet()
        .toList();
  }

  List<String> _getAllSizesForStyle(String styleKey) {
    final items = styleManager.groupedItems[styleKey] ?? [];
    return items
        .map((item) => item['sizeName']?.toString() ?? '')
        .toSet()
        .toList();
  }

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

              // Get the actual Set reference, don't create a new one
              final styleSelectedColors = selectedColors[entry.key];
              if (styleSelectedColors == null) {
                // This shouldn't happen, but if it does, initialize it
                selectedColors[entry.key] = {};
              }

              return StyleCard2(
                styleCode: entry.key,
                items: entry.value,
                catalogOrder: catalogOrder,
                quantities: quantities[entry.key] ?? {},
                selectedColors:
                    selectedColors[entry.key]!, // Use ! since we know it exists
                getColor: getColor,
                onUpdate: onUpdate,
                styleManager: styleManager,
                controllers: styleManager.controllers[entry.key]!,
                allShades: _getAllShadesForStyle(entry.key),
                allSizes: _getAllSizesForStyle(entry.key),
                onShadeAdded: (shade) {
                  // Just call onUpdate which will refresh the parent
                  onUpdate();
                },
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

class StyleCard2 extends StatefulWidget {
  final String styleCode;
  final List<dynamic> items;
  final CatalogOrderData catalogOrder;
  final Map<String, Map<String, int>> quantities;
  final Set<String> selectedColors;
  final Color Function(String) getColor;
  final VoidCallback onUpdate;
  final _StyleManager2 styleManager;
  final Map<String, Map<String, TextEditingController>> controllers;
  final List<String> allShades;
  final List<String> allSizes;
  final Function(String)? onShadeAdded;

  const StyleCard2({
    Key? key,
    required this.styleCode,
    required this.items,
    required this.catalogOrder,
    required this.quantities,
    required this.selectedColors,
    required this.getColor,
    required this.onUpdate,
    required this.styleManager,
    required this.controllers,
    required this.allShades,
    required this.allSizes,
    this.onShadeAdded,
  }) : super(key: key);

  @override
  _StyleCard2State createState() => _StyleCard2State();
}

class _StyleCard2State extends State<StyleCard2> {
  bool _hasQuantityChanged = false;
  bool _isLoading = false;
  Map<String, Map<String, int>> _lastSavedQuantities = {};

  @override
  void initState() {
    super.initState();
    _lastSavedQuantities = widget.quantities.map(
      (shade, sizes) => MapEntry(shade, Map<String, int>.from(sizes)),
    );
  }

  List<String> _getAvailableShades() {
    final allShades = widget.catalogOrder.orderMatrix.shades;
    // Get shades that are already in selectedColors (regardless of quantity)
    final existingShades = widget.selectedColors;

    return allShades.where((shade) => !existingShades.contains(shade)).toList();
  }

  // ADD THIS METHOD
  Future<void> _showAddShadeDialog() async {
    final allShades = widget.catalogOrder.orderMatrix.shades;

    // Create a map to track which shades have quantity
    final Map<String, bool> shadeHasQuantity = {};
    for (var shade in allShades) {
      // Check if shade has any quantity > 0
      final hasQty =
          widget.quantities[shade]?.values.any((qty) => qty > 0) ?? false;
      shadeHasQuantity[shade] = hasQty;
    }

    final selectedShades = await showDialog<List<String>>(
      context: context,
      builder:
          (context) => AddShadeDialog2(
            styleCode: widget.styleCode,
            allShades: allShades,
            shadeHasQuantity: shadeHasQuantity,
          ),
    );

    if (selectedShades != null && selectedShades.isNotEmpty) {
      // Use batch update for better performance
      _addMultipleShades(selectedShades);
    }
  }

  void _addMultipleShades(List<String> shades) {
    print('Adding multiple shades: $shades');

    // Call parent callback for each shade
    if (widget.onShadeAdded != null) {
      for (var shade in shades) {
        widget.onShadeAdded!(shade);
      }
    }

    // Batch update local state
    setState(() {
      for (var shade in shades) {
        // Add to selectedColors
        widget.selectedColors.add(shade);

        // Initialize quantities for all sizes to 0
        widget.quantities[shade] = {};

        // Initialize controllers for all sizes
        if (!widget.controllers.containsKey(shade)) {
          widget.controllers[shade] = {};
        }

        for (var size in widget.catalogOrder.orderMatrix.sizes) {
          // Set quantity to 0
          widget.quantities[shade]![size] = 0;

          // Create or update controller
          if (widget.controllers[shade]![size] == null) {
            widget.controllers[shade]![size] = TextEditingController(text: '0')
              ..addListener(() {
                // Update quantity when text changes
                final value =
                    int.tryParse(widget.controllers[shade]![size]!.text) ?? 0;
                if (widget.quantities[shade]?[size] != value) {
                  setState(() {
                    widget.quantities[shade]![size] = value;
                    _hasQuantityChanged = true;
                  });
                }
              });
          } else {
            widget.controllers[shade]![size]!.text = '0';
          }
        }
      }

      _hasQuantityChanged = true;
    });

    print('Multiple shades added successfully');
  }

  // Future<void> _removeShadeLocally(String shadeToRemove) async {
  //   // Show confirmation dialog
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text("Remove Shade"),
  //         content: Text(
  //           "Are you sure you want to remove shade '$shadeToRemove'?",
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context, false),
  //             child: const Text("Cancel"),
  //           ),
  //           TextButton(
  //             onPressed: () => Navigator.pop(context, true),
  //             child: const Text("Remove", style: TextStyle(color: Colors.red)),
  //           ),
  //         ],
  //       );
  //     },
  //   );

  //   if (confirmed != true) return;

  //   // Show loading indicator
  //   setState(() {
  //     _isLoading = true;
  //   });

  //   try {
  //     // Extract base style code (without barcode suffix if any)
  //     String styleCode = widget.styleCode;
  //     if (styleCode.contains('---')) {
  //       styleCode = styleCode.split('---')[0];
  //     }

  //     // Prepare API payload
  //     final Map<String, dynamic> payload = {
  //       "userName": UserSession.userName ?? '',
  //       "styleCode": styleCode,
  //       "shade": shadeToRemove,
  //     };

  //     print('Deleting shade with payload: $payload');

  //     // Call API
  //     final response = await http.post(
  //       Uri.parse('${AppConstants.BASE_URL}/orderBooking/deleteShade'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(payload),
  //     );

  //     print('Delete shade response: ${response.statusCode} - ${response.body}');

  //     if (response.statusCode == 200) {
  //       // Success - update local state
  //       setState(() {
  //         // Set all quantities for this shade to 0
  //         if (widget.quantities.containsKey(shadeToRemove)) {
  //           for (var size in widget.quantities[shadeToRemove]!.keys) {
  //             widget.quantities[shadeToRemove]![size] = 0;

  //             // Also update controller text to 0
  //             if (widget.controllers.containsKey(shadeToRemove) &&
  //                 widget.controllers[shadeToRemove]!.containsKey(size)) {
  //               widget.controllers[shadeToRemove]![size]!.text = '0';
  //             }
  //           }
  //         }
  //         // final cartModel = Provider.of<CartModel>(context, listen: false);
  //         //         cartModel.removeItem(widget.styleCode);
  //         // Remove from selectedColors (this will hide it from UI)
  //         widget.selectedColors.remove(shadeToRemove);

  //         _hasQuantityChanged = true;
  //         _isLoading = false;
  //       });

  //       // Update parent
  //       widget.onUpdate();

  //       // Show success message
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Shade removed successfully'),
  //           backgroundColor: Colors.green,
  //           duration: Duration(seconds: 2),
  //         ),
  //       );
  //     } else {
  //       // API error
  //       setState(() {
  //         _isLoading = false;
  //       });

  //       String errorMessage = 'Failed to remove shade';
  //       try {
  //         final responseData = jsonDecode(response.body);
  //         if (responseData is Map && responseData.containsKey('message')) {
  //           errorMessage = responseData['message'];
  //         }
  //       } catch (_) {}

  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(errorMessage),
  //           backgroundColor: Colors.red,
  //           duration: Duration(seconds: 3),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     // Network or other error
  //     setState(() {
  //       _isLoading = false;
  //     });

  //     print('Error removing shade: $e');

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Error: ${e.toString()}'),
  //         backgroundColor: Colors.red,
  //         duration: Duration(seconds: 3),
  //       ),
  //     );
  //   }
  // }

  Future<void> _removeShadeLocally(String shadeToRemove) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Remove Shade"),
          content: Text(
            "Are you sure you want to remove shade '$shadeToRemove'?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Remove", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // ─── API call to remove shade ────────────────────────────────
      String styleCode = widget.styleCode.split('---')[0];
      final payload = {
        "userName": UserSession.userName ?? '',
        "styleCode": styleCode,
        "shade": shadeToRemove,
      };

      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/orderBooking/deleteShade'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        // handle error
        setState(() => _isLoading = false);
        return;
      }

      // ─── Update local state ──────────────────────────────────────
      setState(() {
        // Zero out this shade
        final shadeMap = widget.quantities[shadeToRemove];
        if (shadeMap != null) {
          for (final size in shadeMap.keys.toList()) {
            shadeMap[size] = 0;
            widget.controllers[shadeToRemove]?[size]?.text = '0';
          }
        }

        // Remove from visible shades
        widget.selectedColors.remove(shadeToRemove);

        _hasQuantityChanged = true;
        _isLoading = false;
      });

      // ─── Decide whether to remove whole style ─────────────────────
      final cart = Provider.of<CartModel>(context, listen: false);

      if (_isStyleCompletelyEmpty()) {
        // Style is now completely empty → safe to remove from cart & manager
        cart.removeItem(widget.styleCode);
        widget.styleManager.removeStyle(widget.styleCode);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Style ${widget.styleCode} removed (all quantities zero)',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Still has some quantity somewhere → just notify / refresh
        cart.notifyListeners(); // if your cart shows totals
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shade $shadeToRemove removed'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onUpdate();
    } catch (e) {
      setState(() => _isLoading = false);
      // error snackbar...
    }
  }

  bool _isStyleCompletelyEmpty() {
    // Use the quantities map that was passed via widget
    final styleQuantities = widget.quantities;

    if (styleQuantities.isEmpty) return true;

    for (final shadeMap in styleQuantities.values) {
      for (final qty in shadeMap.values) {
        if (qty > 0) {
          return false;
        }
      }
    }
    return true;
  }

  Widget buildOrderItem(CatalogOrderData catalogOrder, BuildContext context) {
    final catalog = catalogOrder.catalog;

    // Show ALL shades in selectedColors (including newly added ones with 0 quantity)
    final activeShades = widget.selectedColors.toList();

    print(
      'Building order item with shades: $activeShades',
    ); // Add this debug line

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.1, vertical: 5.0),
          child: Container(
            width: 800, // Ensures card takes full width
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      AppColors.primaryColor.withOpacity(0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row with image and details
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image with reduced height
                          Container(
                            width: 80, // Reduced width
                            height:
                                60, // Fixed height - reduced from dynamic height
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
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
                                  final imageUrl =
                                      catalog.fullImagePath.contains("http")
                                          ? catalog.fullImagePath
                                          : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}';
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
                                },
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      catalog.fullImagePath.contains("http")
                                          ? catalog.fullImagePath
                                          : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}',
                                      fit: BoxFit.contain,
                                      loadingBuilder: (
                                        context,
                                        child,
                                        loadingProgress,
                                      ) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
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
                                                    >(AppColors.primaryColor),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (
                                            context,
                                            error,
                                            stackTrace,
                                          ) => Container(
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
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                    ),
                                    // Image overlay on tap hint
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

                          // Details Section - Expanded to take remaining width
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Style Code with border
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    catalog.styleCode,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.red.shade900,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // Shade Name with border
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor.withOpacity(
                                      0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: AppColors.primaryColor.withOpacity(
                                        0.2,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    catalog.shadeName,
                                    style: GoogleFonts.roboto(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                      color: AppColors.primaryColor.shade900,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap:
                                () => _submitDelete(
                                  context,
                                ), // Calls the existing method for full style deletion
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

                      // Stats row below the image - all in one line
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Stock Type
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.inventory,
                                      size: 12,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'Type',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    catalog.upcoming_Stk == '1'
                                        ? 'Upcoming'
                                        : 'Ready',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Vertical Divider
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.grey.shade300,
                            ),

                            // Stock Qty
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.storage,
                                      size: 12,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'Stock',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    _calculateStockQuantity().toString(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Vertical Divider
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.grey.shade300,
                            ),

                            // Order Qty
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.shopping_bag,
                                      size: 12,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'Order',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    _calculateCatalogQuantity().toString(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Vertical Divider
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.grey.shade300,
                            ),

                            // Amount
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.currency_rupee,
                                      size: 12,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'Amount',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    '₹${_calculateCatalogPrice().toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple.shade700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
          ),
        ),
        const SizedBox(height: 15),

        // Show all shades in selectedColors
        ...activeShades.map(
          (color) => Column(
            children: [
              _buildColorSection(widget.catalogOrder, color),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed:
                          _isLoading ? null : () => _removeShadeLocally(color),
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
                      onPressed:
                          _isLoading || !_hasQuantityChanged
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
                          color:
                              _hasQuantityChanged
                                  ? AppColors.primaryColor
                                  : Colors.grey.shade400,
                        ),
                        backgroundColor:
                            _hasQuantityChanged
                                ? AppColors.primaryColor.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                      ),
                      child:
                          _isLoading
                              ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Updating...',
                                    style: TextStyle(
                                      color: AppColors.primaryColor,
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
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ],
                              )
                              : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.save,
                                    color:
                                        _hasQuantityChanged
                                            ? AppColors.primaryColor
                                            : Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Update',
                                    style: TextStyle(
                                      color:
                                          _hasQuantityChanged
                                              ? AppColors.primaryColor
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
            double.tryParse(
              matrix.matrix[shadeIndex][sizeIndex].split(',')[0],
            ) ??
            0;
        final quantity = widget.quantities[shade]![size]!;
        total += rate * quantity;
      }
    }
    return total;
  }

  int _calculateShadeQuantity(String shade) {
    int total = 0;
    for (var size in widget.quantities[shade]?.keys ?? []) {
      total += widget.quantities[shade]![size]!;
    }
    return total;
  }

  double _calculateShadePrice(CatalogOrderData catalogOrder, String shade) {
    double total = 0;
    final matrix = catalogOrder.orderMatrix;
    final shadeIndex = matrix.shades.indexOf(shade.trim());
    if (shadeIndex == -1) return total;

    for (var size in widget.quantities[shade]?.keys ?? []) {
      final sizeIndex = matrix.sizes.indexOf(size.toString().trim());
      if (sizeIndex == -1) continue;
      final rate =
          double.tryParse(matrix.matrix[shadeIndex][sizeIndex].split(',')[0]) ??
          0;
      final quantity = widget.quantities[shade]![size]!;
      total += rate * quantity;
    }
    return total;
  }

  Widget _buildColorSection(CatalogOrderData catalogOrder, String shade) {
    final sizes = catalogOrder.orderMatrix.sizes;
    final Color shadeColor = widget.getColor(shade);
    final styleKey = catalogOrder.catalog.styleKey;

    // Calculate total quantity and price for this shade
    int shadeTotalQty = _calculateShadeQuantity(shade);
    double shadeTotalPrice = _calculateShadePrice(catalogOrder, shade);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
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
                        vertical: 1.0,
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
                        vertical: 4.0,
                        horizontal: 8.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        shade,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: shadeColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0,
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
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
                _buildSizeRow(
                  catalogOrder,
                  shade,
                  size,
                ), // This should use widget.controllers and widget.quantities
                if (size != sizes.last)
                  Divider(height: 1, color: Colors.grey.shade300),
              ],
            ],
          ),
        ),
        const SizedBox(height: 15),
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
      stock = matrixData.length > 2 ? matrixData[2] : '0';

      // Get controller from widget.controllers
      if (widget.controllers.containsKey(shade) &&
          widget.controllers[shade]!.containsKey(size)) {
        controller = widget.controllers[shade]![size];
      }
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    final newQuantity = (quantity - 1).clamp(0, 9999);
                    if (widget.quantities[shade] != null) {
                      setState(() {
                        widget.quantities[shade]![size] = newQuantity;
                        controller?.text = newQuantity.toString();
                        _hasQuantityChanged = _checkQuantityChanged();
                      });
                    }
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    child: const Icon(Icons.remove, size: 16),
                  ),
                ),
                SizedBox(
                  width: 35,
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
                      if (widget.quantities[shade] != null) {
                        setState(() {
                          widget.quantities[shade]![size] = newQuantity.clamp(
                            0,
                            999,
                          );
                          _hasQuantityChanged = _checkQuantityChanged();
                        });
                      }
                    },
                  ),
                ),
                InkWell(
                  onTap: () {
                    final newQuantity = (quantity + 1).clamp(0, 9999);
                    if (widget.quantities[shade] != null) {
                      setState(() {
                        widget.quantities[shade]![size] = newQuantity;
                        controller?.text = newQuantity.toString();
                        _hasQuantityChanged = _checkQuantityChanged();
                      });
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
        // Remove from CartModel
        if (!mounted) return;

        // Get the cart model and remove this item
        final cartModel = Provider.of<CartModel>(context, listen: false);
        cartModel.removeItem(widget.styleCode);

        // Also remove from style manager
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Add a key that changes when selectedColors changes
            buildOrderItem(
              widget.catalogOrder,
              context,
            ), // This already includes all shades
            const SizedBox(height: 15),

            // Add Shade Button - only show if there are available shades
            if (_getAvailableShades().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton.icon(
                  onPressed: _showAddShadeDialog,
                  icon: const Icon(Icons.add),
                  label: Text('Add Shade'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ),
          ],
        ),

        // Loading overlay
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

class AddShadeDialog extends StatelessWidget {
  final String styleCode;
  final List<String> availableShades;

  const AddShadeDialog({
    Key? key,
    required this.styleCode,
    required this.availableShades,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Shade - $styleCode'),
      content: Container(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: availableShades.length,
          itemBuilder: (context, index) {
            final shade = availableShades[index];
            return ListTile(
              title: Text(shade),
              onTap: () => Navigator.pop(context, shade),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
      ],
    );
  }
}

class AddShadeDialog2 extends StatefulWidget {
  final String styleCode;
  final List<String> allShades;
  final Map<String, bool> shadeHasQuantity;

  const AddShadeDialog2({
    Key? key,
    required this.styleCode,
    required this.allShades,
    required this.shadeHasQuantity,
  }) : super(key: key);

  @override
  _AddShadeDialog2State createState() => _AddShadeDialog2State();
}

class _AddShadeDialog2State extends State<AddShadeDialog2> {
  final Set<String> _selectedShades = {};

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
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
                          widget.styleCode,
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

            // Subheader
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

            // Shades List
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.allShades.length,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  separatorBuilder:
                      (context, index) => Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Colors.grey.shade100,
                      ),
                  itemBuilder: (context, index) {
                    final shade = widget.allShades[index];
                    final hasQuantity = widget.shadeHasQuantity[shade] ?? false;
                    final isSelected = _selectedShades.contains(shade);

                    return Opacity(
                      opacity: hasQuantity ? 0.6 : 1.0,
                      child: AbsorbPointer(
                        absorbing: hasQuantity, // Disable if has quantity
                        child: Material(
                          color:
                              isSelected && !hasQuantity
                                  ? AppColors.primaryColor.withOpacity(0.05)
                                  : Colors.transparent,
                          child: InkWell(
                            onTap:
                                hasQuantity
                                    ? null
                                    : () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedShades.remove(shade);
                                        } else {
                                          _selectedShades.add(shade);
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
                                  // Checkbox or disabled indicator
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color:
                                          hasQuantity
                                              ? Colors.green.withOpacity(0.1)
                                              : (isSelected
                                                  ? AppColors.primaryColor
                                                  : Colors.transparent),
                                      border: Border.all(
                                        color:
                                            hasQuantity
                                                ? Colors.green.shade300
                                                : (isSelected
                                                    ? Colors.transparent
                                                    : Colors.grey.shade400),
                                        width: hasQuantity ? 1.5 : 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child:
                                        hasQuantity
                                            ? Icon(
                                              Icons.check,
                                              color: Colors.green.shade600,
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

                                  // Shade name with color
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
                                                : _getColorCode(
                                                  shade,
                                                ), // Color directly applied to text
                                      ),
                                    ),
                                  ),

                                  // Already added label
                                  if (hasQuantity)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Added',
                                        style: GoogleFonts.poppins(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.green.shade700,
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

            // Actions
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
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
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
                          _selectedShades.isEmpty
                              ? null
                              : () {
                                Navigator.pop(
                                  context,
                                  _selectedShades.toList(),
                                );
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ).copyWith(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color?>((states) {
                              if (states.contains(MaterialState.disabled)) {
                                return Colors.grey.shade300;
                              }
                              return AppColors.primaryColor;
                            }),
                      ),
                      child: Text(
                        _selectedShades.isEmpty ? 'Add Shades' : 'Add',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color:
                              _selectedShades.isEmpty
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
  }

  // Helper method to get color for the shade name
  Color _getColorCode(String color) {
    switch (color.toLowerCase()) {
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
}

class _OrderForm2 extends StatefulWidget {
  final _OrderControllers2 controllers;
  final _DropdownData2 dropdownData;
  final Function(String?, String?) onPartySelected;
  final VoidCallback updateTotals;
  final Future<void> Function() saveOrder;
  final Map<String, dynamic> additionalInfo;
  final List<Consignee> consignees;
  final List<PytTermDisc> paymentTerms;
  final List<Item> bookingTypes;
  final Function(Map<String, dynamic>) onAdditionalInfoUpdated;
  final bool isSaving;

  const _OrderForm2({
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
  _OrderForm2State createState() => _OrderForm2State();
}

class _OrderForm2State extends State<_OrderForm2> {
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
        buildTextField2(
          context,
          "Select Date",
          widget.controllers.date,
          isDate: true,
          onTap: () => _selectDate2(context, widget.controllers.date),
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
        buildTextField2(context, "Comm (%)", widget.controllers.comm),
        _buildDropdown(
          "Transporter",
          "T",
          widget.controllers.selectedTransporter,
          (val, key) => widget.controllers.selectedTransporterKey = key,
        ),
        _buildResponsiveRow(
          context,
          buildTextField2(
            context,
            "Delivery Days",
            widget.controllers.deliveryDays,
            readOnly: true,
          ),
          buildTextField2(
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
                    .text = _OrderControllers2.formatDate(picked);
                widget.controllers.deliveryDays.text = difference.toString();
              }
            },
          ),
        ),
        buildFullField2(context, "Remark", widget.controllers.remark, true),
        _buildResponsiveRow(
          context,
          buildTextField2(
            context,
            "Total Item",
            widget.controllers.totalItem,
            readOnly: true,
          ),
          buildTextField2(
            context,
            "Total Quantity",
            widget.controllers.totalQty,
            readOnly: true,
          ),
        ),
        buildTextField2(
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
        //                 (context) => AddMoreInfoDialog2(
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
        //           backgroundColor: primaryBlue.withOpacity(0.1),
        //           foregroundColor: primaryBlue,
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
        //           backgroundColor: primaryBlue,
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
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownSearch<String>(
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return "$label is required";
          }
          return null;
        },
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

        /// 🔹 SEARCH ONLY BEFORE -->
        filterFn: (item, filter) {
          if (filter.isEmpty) return true;

          final namePart = item.split('-->').first.trim().toLowerCase();
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

Widget buildTextField2(
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
      onTap: onTap ?? (isDate ? () => _selectDate2(context, controller) : null),
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
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
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

Future<void> _selectDate2(
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
    controller.text = _OrderControllers2.formatDate(picked);
  }
}

Widget buildFullField2(
  BuildContext context,
  String label,
  TextEditingController controller,
  bool? isText,
) {
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: buildTextField2(context, label, controller, isText: isText ?? false),
  );
}

class AddMoreInfoDialog2 extends StatefulWidget {
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

  const AddMoreInfoDialog2({
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
  _AddMoreInfoDialog2State createState() => _AddMoreInfoDialog2State();
}

class _AddMoreInfoDialog2State extends State<AddMoreInfoDialog2> {
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
            // Header
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

                    // Reference No TextField
                    _buildTextField("Reference No", _refNoController),

                    // Station TextField
                    _buildTextField("Station", _stationController),

                    // Payment Days TextField
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

            // Footer Buttons
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
