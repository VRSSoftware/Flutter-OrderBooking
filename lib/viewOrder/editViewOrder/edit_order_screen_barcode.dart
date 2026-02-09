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
import 'package:vrs_erp/register/register.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:vrs_erp/screens/home_screen.dart';
import 'package:vrs_erp/models/catalog.dart';
import 'package:vrs_erp/models/OrderMatrix.dart';
import 'package:vrs_erp/models/CatalogOrderData.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_data.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/more_order_using_barcode.dart';

enum ActiveTab { transaction, customerDetails }

class EditOrderScreenBarcode extends StatefulWidget {
  final String docId;

  const EditOrderScreenBarcode({Key? key, required this.docId})
    : super(key: key);

  @override
  _EditOrderScreenBarcodeState createState() => _EditOrderScreenBarcodeState();
}

class _EditOrderScreenBarcodeState extends State<EditOrderScreenBarcode> {
  late String docId;
  final _formKey = GlobalKey<FormState>();
  bool _showForm = false;
  final _orderControllers = _OrderControllers();
  final _dropdownData = _DropdownData();
  final _styleManager = _StyleManager();
  bool isLoading = true;
  bool barcodeMode = false;
  ActiveTab _activeTab = ActiveTab.transaction;
  Map<String, Map<String, Map<String, int>>> quantities = {};
  Map<String, Set<String>> selectedColors = {};
  bool _isSaving = false;



  @override
  void initState() {
    super.initState();
    docId = widget.docId;
    _styleManager.docId = docId; // Pass docId to _StyleManager

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey(Constants.barcode)) {
        barcodeMode = args[Constants.barcode] as bool;
      }
      _initializeData();
      _setInitialDates();
      _styleManager.updateTotalsCallback = _updateTotals;
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
    for (final catalogOrder in EditOrderData.data) {
      final styleCode = catalogOrder.catalog.styleCode;
      final shades = catalogOrder.orderMatrix.shades;
      final sizes = catalogOrder.orderMatrix.sizes;
      for (var shadeIndex = 0; shadeIndex < shades.length; shadeIndex++) {
        final shade = shades[shadeIndex];
        for (var sizeIndex = 0; sizeIndex < sizes.length; sizeIndex++) {
          final size = sizes[sizeIndex];
          final qty =
              int.tryParse(
                _styleManager.controllers[styleCode]?[shade]?[size]?.text ??
                    '0',
              ) ??
              0;
          final mrp =
              double.tryParse(
                catalogOrder.orderMatrix.matrix[shadeIndex][sizeIndex].split(
                  ',',
                )[0],
              ) ??
              0.0;
          total += qty * mrp;
        }
      }
    }
    return total;
  }

  int _calculateTotalItems() {
    return EditOrderData.data.length;
  }

  int _calculateTotalQuantity() {
    int total = 0;
    for (final catalogOrder in EditOrderData.data) {
      final styleCode = catalogOrder.catalog.styleCode;
      final shades = catalogOrder.orderMatrix.shades;
      final sizes = catalogOrder.orderMatrix.sizes;
      for (var shade in shades) {
        for (var size in sizes) {
          total +=
              int.tryParse(
                _styleManager.controllers[styleCode]?[shade]?[size]?.text ??
                    '0',
              ) ??
              0;
        }
      }
    }
    return total;
  }


Future<String> insertFinalSalesOrder(String orderDataJson) async {
  try {
    final response = await http.post(
      Uri.parse(
        '${AppConstants.BASE_URL}/orderRegister/saveEditedSalesOrder',
      ),
      headers: {'Content-Type': 'application/json'},
      body: orderDataJson,
    );

    if (response.statusCode == 200) {
      print('Success: ${response.body}');
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Success'),
          content: Text('Order Updated Successfully'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegisterPage(), // Your RegisterPage class
                  ),
                );
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
      return response.statusCode.toString();
    } else {
      print('Error: ${response.statusCode}');
      print('Response Body: ${response.body}');
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Failed'),
          content: Text('Failed to save order: ${response.statusCode}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    print('Error: $e');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text('Error saving order: $e'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
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
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    List<Map<String, dynamic>> addedItems = [];
    if (args != null && args.containsKey('addedItems')) {
      addedItems = List<Map<String, dynamic>>.from(args['addedItems']);
      print('Initial addedItems: $addedItems');
    }
    // if (docId == "-1") {
      _styleManager._initializeControllers();
      _initializeQuantitiesAndColors();
    // }

    // Fetch dropdown data first to ensure partyList is populated
    await _dropdownData.loadAllDropdownData();
   

    // Fetch order details from the new API
    // if (docId != '-1') {
      try {
        var response;
        if(docId != '-1'){
         response = await http.post(
          Uri.parse('${AppConstants.BASE_URL}/users/detailsForEdit'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({"doc_id": docId}),
        );
        }
        print(
          'detailsForEdit API Response: ${response.statusCode}, Body: ${response.body}',
        );
            if(docId == '-1'){
              response.statusCode = 200;
              response.body = jsonEncode(EditOrderData.detailsForEdit);
            }
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('Order details fetched: $data');
          setState(() {
            // Set party using partyName from API response
            if (data['partyName'] != null) {
              _orderControllers.selectedParty = data['partyName']?.toString();
              _orderControllers.selectedPartyKey = data['Led_Key']?.toString();
              print(
                'Set party from API partyName: ${_orderControllers.selectedParty} (${_orderControllers.selectedPartyKey})',
              );
            } else {
              // Fallback to partyList if partyName is missing
              
             
            }

            // Set broker
            final broker = _dropdownData.brokerList.firstWhere(
              (e) => e['ledKey'] == data['Broker_Key']?.toString(),
              orElse: () => {'ledKey': '', 'ledName': ''},
            );
            _orderControllers.selectedBrokerKey =
                data['Broker_Key']?.toString();
            _orderControllers.selectedBroker = broker['ledName'] ?? '';
            _orderControllers.comm.text =
                data['Broker_Comm']?.toString() ?? '0.00';

            // Set transporter
            final transporter = _dropdownData.transporterList.firstWhere(
              (e) => e['ledKey'] == data['Trsp_Key']?.toString(),
              orElse: () => {'ledKey': '', 'ledName': ''},
            );
            _orderControllers.selectedTransporterKey =
                data['Trsp_Key']?.toString();
            _orderControllers.selectedTransporter =
                transporter['ledName'] ?? '';

            // Set payment days, delivery date, and remark
            _orderControllers.deliveryDays.text =
                data['dlv_Days']?.toString() ?? '0';
            _orderControllers.deliveryDate.text =
                data['DlvDate'] != null
                    ? _OrderControllers.formatDate(
                      DateTime.parse(data['DlvDate']),
                    )
                    : _OrderControllers.formatDate(DateTime.now());
            _orderControllers.remark.text = data['Remark']?.toString() ?? '';

           
          });

      
        } else {
          print('Error fetching order details: ${response.statusCode}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to fetch order details: ${response.statusCode}',
              ),
            ),
          );
        }
      } catch (e) {
        print('Error fetching order details: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching order details: $e')),
        );
      }
    // }

    await Future.wait([
      _styleManager.fetchOrderItems(
        doc_Id: docId.toString(),
      ),
    ]);

    if (docId == '-1' && addedItems.isNotEmpty) {
      print('Processing addedItems for docId == -1');
      setState(() {
        EditOrderData.data.clear();
        for (var item in addedItems) {
          final styleCode = item['styleCode']?.toString() ?? 'No Style Code';
          final catalogOrder = _styleManager._convertToCatalogOrderData(
            styleCode,
            [item],
          );
          EditOrderData.data.add(catalogOrder);
          print(
            'Added item for style $styleCode: Matrix ${catalogOrder.orderMatrix.matrix}',
          );
        }
        _styleManager._initializeControllers();
        _initializeQuantitiesAndColors();
      });
    }

    _initializeQuantitiesAndColors();
    setState(() {
      isLoading = false;
    });
    print(
      'EditOrderData.data after initialization: ${EditOrderData.data.map((e) => e.catalog.styleCode)}',
    );
  }

  void _initializeQuantitiesAndColors() {
    quantities.clear();
    selectedColors.clear();
    print(
      'Initializing quantities and colors for ${EditOrderData.data.length} items',
    );

    for (var catalogOrder in EditOrderData.data) {
      final styleKey = catalogOrder.catalog.styleCode;
      final items = catalogOrder.orderMatrix;
      final shades = items.shades;
      final sizes = items.sizes;

      print(
        'Processing quantities for style: $styleKey, Shades: $shades, Sizes: $sizes',
      );

      selectedColors[styleKey] = shades.toSet();
      quantities[styleKey] = {};

      for (var shade in shades) {
        quantities[styleKey]![shade] = {};
        for (var size in sizes) {
          final shadeIndex = shades.indexOf(shade);
          final sizeIndex = sizes.indexOf(size);
          if (shadeIndex == -1 || sizeIndex == -1) {
            print(
              'Warning: Invalid indices for $styleKey/$shade/$size '
              '(shadeIndex: $shadeIndex, sizeIndex: $sizeIndex)',
            );
            quantities[styleKey]![shade]![size] = 0;
            continue;
          }
          final qty =
              int.tryParse(
                catalogOrder.orderMatrix.matrix[shadeIndex][sizeIndex].split(
                  ',',
                )[2],
              ) ??
              0;
          quantities[styleKey]![shade]![size] = qty;
          print('Quantity set for $styleKey/$shade/$size: $qty');
        }
      }
    }
    print('Quantities after initialization: $quantities');
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


  Future<void> _saveOrderLocally() async {
    if (!_formKey.currentState!.validate()) return;

    // Calculate totQty per style code
    final styleQuantities = <String, int>{};
    for (final catalogOrder in EditOrderData.data) {
      final styleCode = catalogOrder.catalog.styleCode;
      int totalQty = 0;
      final shades = catalogOrder.orderMatrix.shades;
      final sizes = catalogOrder.orderMatrix.sizes;
      for (var shade in shades) {
        for (var size in sizes) {
          totalQty +=
              int.tryParse(
                _styleManager.controllers[styleCode]?[shade]?[size]?.text ??
                    '0',
              ) ??
              0;
        }
      }
      styleQuantities[styleCode] = totalQty;
    }

    final orderData = {
      "doc_id": EditOrderData.doc_id,
      "login_id": UserSession.userName ?? 'admin',
      "coBr_id": UserSession.coBrId ?? '01',
      "fcYr_id": UserSession.userFcYr ?? '25',
      "data": {
        "customer": _orderControllers.selectedPartyKey ?? '',
       
        "orderdate": formatDate(_orderControllers.date.text, false),
        "delivarydate": formatDate(_orderControllers.deliveryDate.text, false),
        "date": '',
        "broker": _orderControllers.selectedBrokerKey ?? '',
        "comission":
            _orderControllers.comm.text.isEmpty
                ? '0.00'
                : _orderControllers.comm.text,
        "transporter": _orderControllers.selectedTransporterKey ?? '',
        "remark": _orderControllers.remark.text,
        "delivaryday":
            _orderControllers.deliveryDays.text.isEmpty
                ? '0'
                : _orderControllers.deliveryDays.text,
      },
      "items":
          EditOrderData.data
              .map((catalogOrder) {
                final styleCode = catalogOrder.catalog.styleCode;
                final shades = catalogOrder.orderMatrix.shades;
                final sizes = catalogOrder.orderMatrix.sizes;
                return shades
                    .asMap()
                    .entries
                    .map((shadeEntry) {
                      final shadeIndex = shadeEntry.key;
                      final shade = shadeEntry.value;
                      return sizes.asMap().entries.map((sizeEntry) {
                        final sizeIndex = sizeEntry.key;
                        final size = sizeEntry.value;
                        final qty =
                            _styleManager
                                .controllers[styleCode]?[shade]?[size]
                                ?.text ??
                            '0';
                        final matrixData = catalogOrder
                            .orderMatrix
                            .matrix[shadeIndex][sizeIndex]
                            .split(',');
                        return {
                          'style_code': styleCode,
                          'shade': shade,
                          'size': size,
                          'qty': int.tryParse(qty) ?? 0,
                          'totQty': styleQuantities[styleCode] ?? 0,
                          'mrp': double.tryParse(matrixData[0]) ?? 0.0,
                          'wsp':
                              double.tryParse(
                                matrixData.length > 1 ? matrixData[1] : '0',
                              ) ??
                              0.0,
                          'barcode':
                              catalogOrder
                                  .catalog
                                  .barcode, // Not available in current data
                          'note': "",
                        };
                      }).toList();
                    })
                    .expand((i) => i)
                    .toList();
              })
              .expand((i) => i)
              .where(
                (item) => (item['qty'] as int) > 0,
              ) // Exclude items with qty 0
              .toList(),
    };

    final orderDataJson = jsonEncode(orderData);
    print("Saved Order Data:");
    print(orderDataJson);

    try {
      await insertFinalSalesOrder(orderDataJson);
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
      final catalogOrder = EditOrderData.data.firstWhere(
        (order) => order.catalog.styleCode == style,
      );

      shades.forEach((shade, sizes) {
        final shadeIndex = catalogOrder.orderMatrix.shades.indexOf(shade);
        if (shadeIndex == -1) return;

        sizes.forEach((size, controller) {
          final qty = int.tryParse(controller.text) ?? 0;
          totalQty += qty;

          final sizeIndex = catalogOrder.orderMatrix.sizes.indexOf(size);
          if (sizeIndex == -1) return;

          final mrp =
              double.tryParse(
                catalogOrder.orderMatrix.matrix[shadeIndex][sizeIndex].split(
                  ',',
                )[0],
              ) ??
              0.0;
          totalAmt += qty * mrp;
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
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: DrawerScreen(),
      appBar: _buildAppBar(),
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
                            // additionalInfo: _additionalInfo,
                            // consignees: consignees,
                            // paymentTerms: paymentTerms,
                            // bookingTypes: _bookingTypes,
                            // onAdditionalInfoUpdated: (newInfo) {
                            //   setState(() {
                            //     _additionalInfo = newInfo;
                            //   });
                            // },
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
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddAction,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add New Item',
      ),
    );
  }

  Widget _buildTabBar() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _activeTab = ActiveTab.transaction;
                    _showForm = false;
                  });
                },
                child: Text('Transaction'),
                style: TextButton.styleFrom(
                  foregroundColor:
                      _activeTab == ActiveTab.transaction
                          ? AppColors.primaryColor
                          : Colors.grey,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _activeTab = ActiveTab.customerDetails;
                    _showForm = true;
                  });
                },
                child: Text('Customer Details'),
                style: TextButton.styleFrom(
                  foregroundColor:
                      _activeTab == ActiveTab.customerDetails
                          ? AppColors.primaryColor
                          : Colors.grey,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        Container(
          height: 2,
          color: Colors.grey[300],
          child: AnimatedAlign(
            duration: Duration(milliseconds: 300),
            alignment:
                _activeTab == ActiveTab.transaction
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width / 2,
              height: 2,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
            child: Text('CANCEL', style: TextStyle(color: Colors.red)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
          TextButton(
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
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_activeTab == ActiveTab.customerDetails)
                  Icon(Icons.arrow_back_ios, color: Colors.blue, size: 16),
                Text(
                  _activeTab == ActiveTab.transaction ? 'NEXT' : 'BACK',
                  style: TextStyle(color: Colors.blue),
                ),
                if (_activeTab == ActiveTab.transaction)
                  Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Update Order ', style: TextStyle(color: Colors.white)),
      backgroundColor: AppColors.primaryColor,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          color: AppColors.primaryColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Total: ₹${_calculateTotalAmount().toStringAsFixed(2)}',
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
    );
  }

  void _handlePartySelection(String? val, String? key) async {
    if (key == null) return;
    _orderControllers.selectedPartyKey = key;
    UserSession.userLedKey = key;
    try {
      //await fetchAndMapConsignees(key: key, CoBrId: UserSession.coBrId ?? '');
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

  void _handleAddAction() {
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MoreOrderBarcodePage(
              onFilterPressed: (String filter) {},
              edit: true,
              
            ),
      ),
    ).then((result) {
      if (result != null && result is List<Map<String, dynamic>>) {
        print('Received items from MoreOrderBarcodePage: $result');
        setState(() {
          // Group new items by styleCode
          final groupedByStyle = <String, List<dynamic>>{};
          for (var item in result) {
            final styleCode = item['styleCode']?.toString() ?? 'No Style Code';
            groupedByStyle.putIfAbsent(styleCode, () => []).add(item);
          }

          // Add or update CatalogOrderData for each style
          for (var entry in groupedByStyle.entries) {
            final styleCode = entry.key;
            final items = entry.value;
            final existingIndex = EditOrderData.data.indexWhere(
              (order) => order.catalog.styleCode == styleCode,
            );
            final catalogOrder = _styleManager._convertToCatalogOrderData(
              styleCode,
              items,
            );
            if (existingIndex != -1) {
              EditOrderData.data[existingIndex] = catalogOrder;
              print('Updated existing style: $styleCode');
            } else {
              EditOrderData.data.add(catalogOrder);
              print('Added new style: $styleCode');
            }
          }

          // Remove any styles in removedStyles
          EditOrderData.data.removeWhere(
            (order) =>
                _styleManager.removedStyles.contains(order.catalog.styleCode),
          );

          // Reinitialize controllers and quantities
          _styleManager._initializeControllers();
          _initializeQuantitiesAndColors();
          _updateTotals();
        });
        print(
          'EditOrderData.data after adding items: ${EditOrderData.data.map((e) => e.catalog.styleCode)}',
        );
      } else {
        print('No items returned from MoreOrderBarcodePage');
      }
    });
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
  List<Map<String, String>> brokerList = [];
  List<Map<String, String>> transporterList = [];

  Future<void> loadAllDropdownData() async {
    try {
      if(EditOrderData.doc_id != '-1'){
      final results = await Future.wait([
        _fetchLedgers("B"),
        _fetchLedgers("T"),
      ]);
      brokerList = results[0];
      transporterList = results[1];
      EditOrderData.brokerList = brokerList;
      EditOrderData.transporterList = transporterList;
      }
      else if(EditOrderData.doc_id == '-1'){
        brokerList = EditOrderData.brokerList;
        transporterList = EditOrderData.transporterList;
      }
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
  final Set<String> removedStyles = {};
  final Map<String, Map<String, Map<String, TextEditingController>>>
  controllers = {};
  VoidCallback? updateTotalsCallback;
  bool isOrderItemsLoaded = false;
  String? docId;

  Map<String, List<CatalogOrderData>> get groupedItems {
    final map = <String, List<CatalogOrderData>>{};
    for (final catalogOrder in EditOrderData.data) {
      final styleCode = catalogOrder.catalog.styleCode;
      if (removedStyles.contains(styleCode)) continue;
      map.putIfAbsent(styleCode, () => []).add(catalogOrder);
    }
    return map;
  }

  CatalogOrderData _convertToCatalogOrderData(
    String styleKey,
    List<dynamic> items,
  ) {
    print('Converting to CatalogOrderData for style: $styleKey, Items: $items');
    if (items.isEmpty) {
      print('Error: Empty items list for style $styleKey');
      return CatalogOrderData(
        catalog: Catalog(
          itemSubGrpKey: '',
          itemSubGrpName: '',
          itemKey: '',
          itemName: 'Unknown',
          brandKey: '',
          brandName: '',
          styleKey: styleKey,
          styleCode: styleKey,
          shadeKey: '',
          shadeName: '',
          styleSizeId: '',
          sizeName: '',
          mrp: 0.0,
          wsp: 0.0,
          onlyMRP: 0.0,
          clqty: 0,
          total: 0,
          fullImagePath: '/NoImage.jpg',
          remark: '',
          imageId: '',
          sizeDetails: '',
          sizeDetailsWithoutWSp: '',
          sizeWithMrp: '',
          styleCodeWithcount: styleKey,
          onlySizes: '',
          sizeWithWsp: '',
          createdDate: '',
          shadeImages: '',
          upcoming_Stk: '0',
        ),
        orderMatrix: OrderMatrix(shades: [], sizes: [], matrix: []),
      );
    }

    final shades =
        items
            .map((i) => i['shadeName']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
    final sizes =
        items
            .map((i) => i['sizeName']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
    final firstItem = items.first;

    if (shades.isEmpty || sizes.isEmpty) {
      print(
        'Error: Empty shades or sizes for style $styleKey (Shades: $shades, Sizes: $sizes)',
      );
    }

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
        final stkQty =  item['data2'] ?? '0';
        final matrixEntry = '$mrp,$wsp,$qty,$stkQty';
        print(
          'Matrix entry for $styleKey/$shadeIndex/$sizeIndex: $matrixEntry',
        );
        return matrixEntry;
      });
    });

    final catalog = Catalog(
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
      upcoming_Stk: firstItem['upcoming_Stk']?.toString() ?? '0',
      barcode: firstItem['barcode']?.toString() ?? 'Unknown',
    );

    print('Catalog created for $styleKey: ${catalog.toJson()}');
    return CatalogOrderData(
      catalog: catalog,
      orderMatrix: OrderMatrix(shades: shades, sizes: sizes, matrix: matrix),
    );
  }

  Future<void> fetchOrderItems({
    required String doc_Id,
  }) async {
    docId = doc_Id;
    if (doc_Id != '-1') {
      EditOrderData.doc_id = doc_Id;
      try {
        final response = await http.post(
          Uri.parse('${AppConstants.BASE_URL}/orderRegister/editOrderData'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({"doc_id": doc_Id}),
        );

        print(
          'Fetch API Response: ${response.statusCode}, Body: ${response.body}',
        );

        if (response.statusCode == 200) {
          final items = json.decode(response.body);
          if (items is List && items.isNotEmpty) {
            final groupedByStyle = <String, List<dynamic>>{};
            for (var item in items) {
              final styleCode =
                  item['styleCode']?.toString() ?? 'No Style Code';
              groupedByStyle.putIfAbsent(styleCode, () => []).add(item);
            }
            EditOrderData.data =
                groupedByStyle.entries.map((entry) {
                  final catalogOrder = _convertToCatalogOrderData(
                    entry.key,
                    entry.value,
                  );
                  print(
                    'Fetched style: ${entry.key}, Matrix: ${catalogOrder.orderMatrix.matrix}',
                  );
                  return catalogOrder;
                }).toList();
            _initializeControllers();
          } else {
            print('No items found in response');
            EditOrderData.data = [];
          }
        } else {
          print('API Error: ${response.statusCode}');
          EditOrderData.data = [];
        }
      } catch (e) {
        print('Error fetching order items: $e');
        EditOrderData.data = [];
      }
    }
    isOrderItemsLoaded = true;
  }

  Future<void> refreshOrderItems({required bool barcode}) async {
    if (docId != null && docId != '-1') {
      try {
        final response = await http.post(
          Uri.parse('${AppConstants.BASE_URL}/orderRegister/editOrderData'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({"doc_id": docId}),
        );

        print(
          'Refresh API Response: ${response.statusCode}, Body: ${response.body}',
        );

        if (response.statusCode == 200) {
          final newItems = json.decode(response.body);
          if (newItems is List && newItems.isNotEmpty) {
            final groupedByStyle = <String, List<dynamic>>{};
            for (var item in newItems) {
              final styleCode =
                  item['styleCode']?.toString() ?? 'No Style Code';
              groupedByStyle.putIfAbsent(styleCode, () => []).add(item);
            }
            EditOrderData.data =
                groupedByStyle.entries.map((entry) {
                  final catalogOrder = _convertToCatalogOrderData(
                    entry.key,
                    entry.value,
                  );
                  print(
                    'Refreshed style: ${entry.key}, Matrix: ${catalogOrder.orderMatrix.matrix}',
                  );
                  return catalogOrder;
                }).toList();
            _initializeControllers();
          } else {
            print('No items found in refresh response');
            EditOrderData.data = [];
          }
        } else {
          print('Error refreshing order items: ${response.statusCode}');
        }
      } catch (e) {
        print('Error refreshing order items: $e');
      }
    } else {
      print('Invalid docId: $docId');
    }
  }

  void copyStyle(String styleKey) {
    final catalogOrders = groupedItems[styleKey];
    if (catalogOrders != null && catalogOrders.isNotEmpty) {
      _initializeControllers();
      updateTotalsCallback?.call();
    }
  }

  void removeStyle(String styleKey) {
    removedStyles.add(styleKey);
    controllers.remove(styleKey);
    EditOrderData.data =
        EditOrderData.data
            .where((e) => e.catalog.styleCode != styleKey)
            .toList();
    updateTotalsCallback?.call();
  }

  void _initializeControllers() {
    final currentControllers =
        Map<String, Map<String, Map<String, TextEditingController>>>.from(
          controllers,
        );
    print(
      'Initializing controllers for styles: ${groupedItems.keys}, Removed styles: $removedStyles',
    );

    for (final entry in groupedItems.entries) {
      final styleKey = entry.key;
      final catalogOrder = entry.value.first;
      final sizes = catalogOrder.orderMatrix.sizes;
      final shades = catalogOrder.orderMatrix.shades;

      print('Processing style: $styleKey, Shades: $shades, Sizes: $sizes');

      controllers.putIfAbsent(styleKey, () => {});
      for (final shade in shades) {
        controllers[styleKey]!.putIfAbsent(shade, () => {});
        for (final size in sizes) {
          final matrix = catalogOrder.orderMatrix.matrix;
          String qty = '0';
          if (matrix.isNotEmpty) {
            final shadeIndex = shades.indexOf(shade);
            final sizeIndex = sizes.indexOf(size);
            if (shadeIndex >= 0 &&
                sizeIndex >= 0 &&
                shadeIndex < matrix.length &&
                sizeIndex < matrix[shadeIndex].length) {
              qty = matrix[shadeIndex][sizeIndex].split(',')[2];
            } else {
              print(
                'Warning: Invalid matrix indices for $styleKey/$shade/$size '
                '(shadeIndex: $shadeIndex, sizeIndex: $sizeIndex, matrix: $matrix)',
              );
            }
          } else {
            print('Warning: Empty matrix for style $styleKey');
          }
          final existingController =
              currentControllers[styleKey]?[shade]?[size];
          final controller =
              existingController ?? TextEditingController(text: qty)
                ..addListener(() => updateTotalsCallback?.call());
          controllers[styleKey]![shade]![size] = controller;
          print(
            'Controller set for $styleKey/$shade/$size: ${controller.text}',
          );
        }
      }
    }
  }
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
    } else if (EditOrderData.data.isEmpty ||
        styleManager.groupedItems.isEmpty) {
      return const Center(
        child: Text(
          'No items added',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    } else {
      return Column(
        children:
            EditOrderData.data
                .where(
                  (catalogOrder) =>
                      !styleManager.removedStyles.contains(
                        catalogOrder.catalog.styleCode,
                      ),
                )
                .map((catalogOrder) {
                  final styleKey = catalogOrder.catalog.styleCode;
                  return StyleCard(
                    styleCode: styleKey,
                    catalogOrder: catalogOrder,
                    quantities: quantities[styleKey] ?? {},
                    selectedColors: selectedColors[styleKey] ?? {},
                    getColor: getColor,
                    onUpdate: onUpdate,
                    styleManager: styleManager,
                  );
                })
                .toList(),
      );
    }
  }
}

class StyleCard extends StatelessWidget {
  final String styleCode;
  final CatalogOrderData catalogOrder;
  final Map<String, Map<String, int>> quantities;
  final Set<String> selectedColors;
  final Color Function(String) getColor;
  final VoidCallback onUpdate;
  final _StyleManager styleManager;

  const StyleCard({
    Key? key,
    required this.styleCode,
    required this.catalogOrder,
    required this.quantities,
    required this.selectedColors,
    required this.getColor,
    required this.onUpdate,
    required this.styleManager,
  }) : super(key: key);

  int _calculateCatalogQuantity(CatalogOrderData catalogOrder) {
    int total = 0;
    quantities.forEach((shade, sizes) {
      sizes.forEach((size, qty) {
        total += qty;
      });
    });
    return total;
  }

  int _calculateStockQuantity(CatalogOrderData catalogOrder) {
    int total = 0;
    final matrix = catalogOrder.orderMatrix;
    for (var shadeIndex = 0; shadeIndex < matrix.shades.length; shadeIndex++) {
      for (var sizeIndex = 0; sizeIndex < matrix.sizes.length; sizeIndex++) {
        final matrixData = matrix.matrix[shadeIndex][sizeIndex].split(',');
        final stock =
            int.tryParse(matrixData.length > 3 ? matrixData[3] : '0') ?? 0;
        total += stock;
      }
    }
    return total;
  }

  double _calculateCatalogPrice(CatalogOrderData catalogOrder) {
    double total = 0;
    final matrix = catalogOrder.orderMatrix;
    for (var shade in quantities.keys) {
      final shadeIndex = matrix.shades.indexOf(shade.trim());
      if (shadeIndex == -1) continue;
      for (var size in quantities[shade]!.keys) {
        final sizeIndex = matrix.sizes.indexOf(size.trim());
        if (sizeIndex == -1) continue;
        final rate =
            double.tryParse(
              matrix.matrix[shadeIndex][sizeIndex].split(',')[0],
            ) ??
            0;
        final quantity = quantities[shade]![size]!;
        total += rate * quantity;
      }
    }
    return total;
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
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: GestureDetector(
                      onDoubleTap: () {
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
                      child: Image.network(
                        catalog.fullImagePath.contains("http")
                            ? catalog.fullImagePath
                            : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}',
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
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
                        Expanded(
                          child: Align(
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
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: Text(
                                      'Are you sure you want to delete style ${catalog.styleCode}?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          styleManager.removeStyle(
                                            catalog.styleCode,
                                          );
                                          onUpdate();
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Style ${catalog.styleCode} removed',
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                            );
                          },
                          tooltip: 'Delete Style',
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
                        _buildTableRow('Remark', catalog.remark),
                        _buildTableRow(
                          'Stk Type',
                          catalog.upcoming_Stk == '1' ? 'Upcoming' : 'Ready',
                        ),
                        _buildTableRow(
                          'Stock Qty',
                          _calculateStockQuantity(catalogOrder).toString(),
                          valueColor: Colors.green[700],
                        ),
                        _buildTableRow(
                          'Order Qty',
                          _calculateCatalogQuantity(catalogOrder).toString(),
                          valueColor: Colors.orange[800],
                        ),
                        _buildTableRow(
                          'Order Amount',
                          _calculateCatalogPrice(
                            catalogOrder,
                          ).toStringAsFixed(2),
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
        ...selectedColors.map(
          (color) => Column(
            children: [
              _buildColorSection(catalogOrder, color),
              const SizedBox(height: 8),
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
          child: Text(":", style: TextStyle(fontSize: 14)),
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

  Widget _buildHeader(String text, int flex) => Expanded(
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

  Widget _buildSizeRow(
    CatalogOrderData catalogOrder,
    String shade,
    String size,
  ) {
    final matrix = catalogOrder.orderMatrix;
    final shadeIndex = matrix.shades.indexOf(shade.trim());
    final sizeIndex = matrix.sizes.indexOf(size.trim());

    String rate = '0';
    String wsp = '0';
    String qty = '0';
    String stock = '0';
    TextEditingController? controller;

    if (shadeIndex != -1 && sizeIndex != -1) {
      final matrixData = matrix.matrix[shadeIndex][sizeIndex].split(',');
      rate = matrixData[0];
      wsp = matrixData.length > 1 ? matrixData[1] : '0';
      qty = matrixData.length > 2 ? matrixData[2] : '0';
      stock = matrixData.length > 3 ? matrixData[3] : '0';
      controller = styleManager.controllers[styleCode]?[shade]?[size];
      print('Controller for $styleCode/$shade/$size: ${controller?.text}');
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
                SizedBox(
                  width: 22,
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
                      final newQuantity =
                          int.tryParse(value.isEmpty ? '0' : value) ?? 0;
                      if (quantities[shade] != null) {
                        quantities[shade]![size] = newQuantity;
                        if (shadeIndex != -1 && sizeIndex != -1) {
                          final matrixData = matrix
                              .matrix[shadeIndex][sizeIndex]
                              .split(',');
                          matrix.matrix[shadeIndex][sizeIndex] =
                              '${matrixData[0]},${matrixData[1]},$newQuantity,${matrixData.length > 3 ? matrixData[3] : '0'}';
                          print(
                            'Updated matrix for $styleCode/$shade/$size: ${matrix.matrix[shadeIndex][sizeIndex]}',
                          );
                        }
                        styleManager.updateTotalsCallback?.call();
                      }
                    },
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

  Widget _buildCell(String text, int flex) => Expanded(
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

  @override
  Widget build(BuildContext context) {
    return buildOrderItem(catalogOrder, context);
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
}

class _OrderForm extends StatefulWidget {
  final _OrderControllers controllers;
  final _DropdownData dropdownData;
  final Function(String?, String?) onPartySelected;
  final VoidCallback updateTotals;
  final Future<void> Function() saveOrder;

    final bool isSaving;

  const _OrderForm({
    required this.controllers,
    required this.dropdownData,
    required this.onPartySelected,
    required this.updateTotals,
    required this.saveOrder,
      required this.isSaving,
  });

  @override
  _OrderFormState createState() => _OrderFormState();
}

class _OrderFormState extends State<_OrderForm> {
  @override
  void initState() {
    super.initState();
    print(
      'OrderForm initState: userType=${UserSession.userType}, '
      'selectedParty=${widget.controllers.selectedParty}, '
      'selectedPartyKey=${widget.controllers.selectedPartyKey}, '
    
    );
  }



  @override
  void didUpdateWidget(covariant _OrderForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controllers != oldWidget.controllers) {
      setState(() {}); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildResponsiveRow(
          context,
          TextFormField(
            enabled: false, 
            controller: widget.controllers.orderNo,
            decoration: InputDecoration(
              labelText: "Order No",
              labelStyle: TextStyle(
                color:
                    Colors.grey[600], 
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            style: TextStyle(
              color: Colors.grey[600], 
            ),
          ),

          buildTextField(
            context,
            "Select Date",
            widget.controllers.date,
            isDate: true,
            readOnly: true,
            onTap: () => _selectDate(context, widget.controllers.date),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
            enabled: false, 
            initialValue: widget.controllers.selectedParty, 
            decoration: InputDecoration(
              labelText: "Party Name",
              labelStyle: TextStyle(
                color:
                    Colors.grey[600], 
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            style: TextStyle(
              color: Colors.grey[600], 
            ),
          ),
        //_buildPartyDropdownRow(context),
        _buildDropdown(
          "Broker",
          "B",
          widget.controllers.selectedBroker,
          (val, key) async {
            print('Broker selected: $val ($key)');
            widget.controllers.selectedBrokerKey = key;
            widget.controllers.selectedBroker = val;
            if (key != null) {
              if(EditOrderData.doc_id == '-1'){
                widget.controllers.comm.text = EditOrderData.commission;
              }
              else{

              final commission = await widget.dropdownData
                  .fetchCommissionPercentage(key);
              widget.controllers.comm.text = commission;
              EditOrderData.commission = commission;
              }
            }
            setState(() {});
          },
          isEnabled: UserSession.userType != 'C',
        ),
        buildTextField(context, "Comm (%)", widget.controllers.comm),
        _buildDropdown(
          "Transporter",
          "T",
          widget.controllers.selectedTransporter,
          (val, key) {
            print('Transporter selected: $val ($key)');
            widget.controllers.selectedTransporterKey = key;
            widget.controllers.selectedTransporter = val;
            setState(() {});
          },
        ),
        _buildResponsiveRow(
          context,
          buildTextField(
            context,
            "Delivery Days",
            widget.controllers.deliveryDays,
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
 Row(
  children: [
    Expanded(
      child: ElevatedButton(
        onPressed: widget.isSaving ? null : widget.saveOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.isSaving 
              ? Colors.grey 
              : AppColors.primaryColor,
          minimumSize: const Size(double.infinity, 50),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
        child: widget.isSaving
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Updating...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.black,
                    ),
                  ),
                ],
              )
            : const Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
      ),
    ),
  ],
)
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
        key: ValueKey('$ledCat-$selectedValue'),
        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: _getSearchHint(label),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        items: _getLedgerList(ledCat).map((e) => e['ledName']!).toList(),
        selectedItem: selectedValue,
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
          ),
        ),
        dropdownBuilder: (context, selectedItem) {
          return Text(
            selectedItem ?? 'Select $label',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16),
          );
        },
        onChanged:
            isEnabled
                ? (val) {
                  final key = _getKeyFromValue(ledCat, val);
                  onChanged(val, key);
                }
                : null,
        enabled: isEnabled,
      ),
    );
  }

  List<Map<String, String>> _getLedgerList(String ledCat) {
    switch (ledCat) {
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
        : Column(children: [first, const SizedBox(height: 10), second]);
  }

  Widget buildTextField(
    BuildContext context,
    String label,
    TextEditingController controller, {
    bool isText = false,
    bool isDate = false,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly || isDate,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
      ),
      keyboardType: isText ? TextInputType.text : TextInputType.number,
      onTap: onTap,
    );
  }

  Widget buildFullField(
    BuildContext context,
    String label,
    TextEditingController controller,
    bool isMultiline,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
        ),
        maxLines: isMultiline ? 3 : 1,
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = _OrderControllers.formatDate(picked);
    }
  }
}
