import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/CatalogOrderData.dart';
import 'package:vrs_erp/models/OrderMatrix.dart';
import 'package:vrs_erp/models/catalog.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/addMoreItemsForEdit.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/customer_details_tab.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_data.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/transaction_tab.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/transaction_tab2.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/transaction_tab3.dart';

enum ActiveTab { transaction, customerDetails }

class EditOrderScreen extends StatefulWidget {
  final String docId;

  const EditOrderScreen({Key? key, required this.docId}) : super(key: key);

  @override
  _EditOrderScreenState createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  ActiveTab _activeTab = ActiveTab.transaction;
  late PageController _pageController;

  double totalAmount = 0;
  int totalItems = 0;
  int totalQuantity = 0;

  bool isOrderItemsLoaded = false;

  @override
  void initState() {
    super.initState();
    
    _pageController = PageController(initialPage: 0);
    // fetchOrderItems(doc_Id: widget.docId);
    if (widget.docId != '-1') {
      EditOrderData.clear();
      EditOrderData.doc_id = widget.docId;
      fetchOrderItems(doc_Id: widget.docId);
      fetchOrderHeaderDetails(widget.docId);
    }else{
      setState(() {
        isOrderItemsLoaded = true;
      });
    }

  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
   Future<void> _saveEditedOrder() async {
    final payload = {
      "doc_id": EditOrderData.doc_id,
      "login_id": UserSession.userName ?? 'admin',
      "coBr_id": UserSession.coBrId ?? '01',
      "fcYr_id": UserSession.userFcYr ?? '25',
      "data": {
        "delivarydate": EditOrderData.deliveryDate,
        // "duedate": EditOrderData.dueDate,
        "broker": EditOrderData.brokerKey,
        "comission": EditOrderData.commission,
        "transporter": EditOrderData.transporterKey,
        "remark": EditOrderData.remark,
        "delivaryday": EditOrderData.deliveryDays,
        "customer":EditOrderData.partyKey,
      },
      "items":
          EditOrderData.data.expand((item) {
            final styleCode = item.catalog.styleCode;
            final shade = item.catalog.shadeName;
            final mrp = item.catalog.mrp;
            final wsp = item.catalog.wsp;
            final barcode = item.catalog.barcode;
            final totalQty = item.catalog.clqty;
            final List<Map<String, dynamic>> matrixItems = [];
            for (int i = 0; i < item.orderMatrix.shades.length; i++) {
              for (int j = 0; j < item.orderMatrix.sizes.length; j++) {
                final matrixEntry = item.orderMatrix.matrix[i][j];
                final split = matrixEntry.split(',');
                final qty =
                    int.tryParse(split.length > 2 ? split[2] : '0') ?? 0;
                if (qty > 0) {
                  matrixItems.add({
                    "style_code": styleCode,
                    "shade": item.orderMatrix.shades[i],
                    "size": item.orderMatrix.sizes[j],
                    "qty": qty,
                    "totQty": totalQty,
                    "mrp": double.tryParse(split[0]) ?? mrp,
                    "wsp": double.tryParse(split[1]) ?? wsp,
                    "barcode": barcode,
                    "note": "",
                  });
                }
              }
            }
            return matrixItems;
          }).toList(),
    };

    try {
      final response = await http.post(
        Uri.parse(
          '${AppConstants.BASE_URL}/orderRegister/saveEditedSalesOrder',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${response.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> fetchOrderHeaderDetails(String docId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/users/detailsForEdit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"doc_id": docId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        EditOrderData.partyKey = data['Led_Key'] ?? '';
        EditOrderData.partyName = data['partyName'] ?? '';
        EditOrderData.brokerKey = data['Broker_Key'] ?? '';
        EditOrderData.transporterKey = data['Trsp_Key'] ?? '';
        EditOrderData.commission = data['Broker_Comm']?.toString() ?? '';
        EditOrderData.deliveryDays = data['dlv_Days']?.toString() ?? '';
        EditOrderData.deliveryDate =
            data['DlvDate']?.toString().substring(0, 10) ?? '';
        EditOrderData.remark = data['Remark'] ?? '';

        final brokerRes = await ApiService.fetchLedgers(
          ledCat: 'B',
          coBrId: UserSession.coBrId ?? '',
        );
        EditOrderData.brokerList =
            (brokerRes['result'] as List<KeyName>)
                .map((e) => {"key": e.key, "name": e.name})
                .toList();

        final transporterRes = await ApiService.fetchLedgers(
          ledCat: 'T',
          coBrId: UserSession.coBrId ?? '',
        );
        EditOrderData.transporterList =
            (transporterRes['result'] as List<KeyName>)
                .map((e) => {"key": e.key, "name": e.name})
                .toList();

        EditOrderData.brokerName =
            EditOrderData.brokerList.firstWhere(
              (e) => e['key'] == EditOrderData.brokerKey,
              orElse: () => {"name": ""},
            )['name']!;

        EditOrderData.transporterName =
            EditOrderData.transporterList.firstWhere(
              (e) => e['key'] == EditOrderData.transporterKey,
              orElse: () => {"name": ""},
            )['name']!;
      }
    } catch (e) {
      print('Error fetching header details: $e');
    }
  }

  // ✅ API Method
  Future<void> fetchOrderItems({required String doc_Id}) async {
    // docId = doc_Id;
    if (doc_Id != '-1') {
      EditOrderData.doc_id = doc_Id;
      try {
        final response = await http.post(
          Uri.parse('${AppConstants.BASE_URL}/orderRegister/editOrderData2'),
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
            calculateTotals();
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
    setState(() {
      isOrderItemsLoaded = true;
    });
  }

  void calculateTotals() {
    double totalAmt = 0;
    int totalQty = 0;
    int totalItms = 0;

    for (var item in EditOrderData.data) {
      totalAmt += item.catalog.wsp * item.catalog.clqty;
      totalQty += item.catalog.clqty;
      totalItms += 1;
    }

    setState(() {
      totalAmount = totalAmt;
      totalQuantity = totalQty;
      totalItems = totalItms;
    });
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
        final stkQty = item['data2']?.toString() ?? '0';
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
      barcode: '',
    );

    print('Catalog created for $styleKey: ${catalog.toJson()}');
    return CatalogOrderData(
      catalog: catalog,
      orderMatrix: OrderMatrix(shades: shades, sizes: sizes, matrix: matrix),
    );
  }

  // ✅ Tab Bar Widget
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
                    _pageController.animateToPage(
                      0,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  });
                },
                child: Text('Transaction'),
                style: TextButton.styleFrom(
                  foregroundColor:
                      _activeTab == ActiveTab.transaction
                          ? Colors.blue
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
                    _pageController.animateToPage(
                      1,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  });
                },
                child: Text('Customer Details'),
                style: TextButton.styleFrom(
                  foregroundColor:
                      _activeTab == ActiveTab.customerDetails
                          ? Colors.blue
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
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  // ✅ Bottom Navigation Buttons
  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_activeTab == ActiveTab.customerDetails) {
                  _pageController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Text('Back'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _activeTab ==  ActiveTab.transaction ?  ElevatedButton(
              onPressed: () {
                if (_activeTab == ActiveTab.transaction) {
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Text('Next'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ) :
             ElevatedButton(
              onPressed: () {
                if (_activeTab == ActiveTab.customerDetails) {
                  _saveEditedOrder();
                }
              },
              child: Text('Save'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ AppBar with Bottom Info
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Update Order', style: TextStyle(color: Colors.white)),
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
                  'Total: ₹${totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildDivider(),
              Flexible(
                child: Text(
                  'Items: $totalItems',
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildDivider(),
              Flexible(
                child: Text(
                  'Qty: $totalQuantity',
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 20,
      color: Colors.white.withOpacity(0.5),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
    );
  }
  

  // ✅ Main Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child:
                isOrderItemsLoaded
                    ? PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _activeTab =
                              index == 0
                                  ? ActiveTab.transaction
                                  : ActiveTab.customerDetails;
                        });
                      },
                      children: [TransactionTab3(), CustomerDetailTab()],
                    )
                    : const Center(child: CircularProgressIndicator()),
          ),
          _buildBottomButtons(),
        ],
      ),
            floatingActionButton: FloatingActionButton(
        onPressed: _handleAddAction,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add New Item',
      ),
    );
  }

 void _handleAddAction() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddMoreItemsForEdit(
              // onFilterPressed: (String filter) {},
              // edit: true,
            ),
      ),
    ).then((result) {
      if (result != null && result is List<Map<String, dynamic>>) {
        setState(() {
          final groupedByStyle = <String, List<dynamic>>{};
          for (var item in result) {
            final styleCode = item['styleCode']?.toString() ?? 'No Style Code';
            groupedByStyle.putIfAbsent(styleCode, () => []).add(item);
          }

          for (var entry in groupedByStyle.entries) {
            final styleCode = entry.key;
            final items = entry.value;
            final existingIndex = EditOrderData.data.indexWhere(
              (order) => order.catalog.styleCode == styleCode,
            );
            final catalogOrder = _convertToCatalogOrderData(styleCode, items);
            if (existingIndex != -1) {
              EditOrderData.data[existingIndex] = catalogOrder;
            } else {
              EditOrderData.data.add(catalogOrder);
            }
          }
        });
      }
    });
  }
}
