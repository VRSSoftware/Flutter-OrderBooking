import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/CatalogOrderData.dart';
import 'package:vrs_erp/models/OrderMatrix.dart';
import 'package:vrs_erp/models/catalog.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/customer_detail_barcode2.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_data.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/more_order_using_barcode.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/transaction_barcode2.dart';

class EditPackingOrderBarcodeScreen extends StatefulWidget {
  final String docId;

  const EditPackingOrderBarcodeScreen({super.key, required this.docId});

  @override
  State<EditPackingOrderBarcodeScreen> createState() => _EditPackingOrderBarcodeScreenState();
}

class _EditPackingOrderBarcodeScreenState extends State<EditPackingOrderBarcodeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isOrderItemsLoaded = false;
  List<CatalogOrderData> orderData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.docId != '-1') {
      EditOrderData.clear();
      EditOrderData.doc_id = widget.docId;
      fetchOrderItems(doc_Id: widget.docId);
      fetchOrderHeaderDetails(widget.docId);
    }
  }

  Future<void> fetchOrderItems({required String doc_Id}) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/orderRegister/editOrderData'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"doc_id": doc_Id}),
      );

      if (response.statusCode == 200) {
        final items = jsonDecode(response.body);
        if (items is List && items.isNotEmpty) {
          final groupedByStyle = <String, List<dynamic>>{};
          for (var item in items) {
            final styleCode = item['styleCode']?.toString() ?? 'No Style Code';
            groupedByStyle.putIfAbsent(styleCode, () => []).add(item);
          }

          setState(() {
            orderData =
                groupedByStyle.entries.map((entry) {
                  final catalogOrder = _convertToCatalogOrderData(
                    entry.key,
                    entry.value,
                  );
                  return catalogOrder;
                }).toList();

            EditOrderData.data = orderData;
            isOrderItemsLoaded = true;
          });
        }
      }
    } catch (e) {
      print('Error fetching order items: $e');
    }
  }

  CatalogOrderData _convertToCatalogOrderData(
    String styleKey,
    List<dynamic> items,
  ) {
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
      barcode: firstItem['barcode']?.toString() ?? '',
    );

    return CatalogOrderData(
      catalog: catalog,
      orderMatrix: OrderMatrix(shades: shades, sizes: sizes, matrix: matrix),
    );
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
          '${AppConstants.BASE_URL}/orderRegister/saveEditedSalesOrderBarcode',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false, // disable default back arrow
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ), // 👈 iOS back icon
          onPressed: () {
            Navigator.of(context).pop(); // 👈 go back when pressed
          },
        ),
        title: const Text(
          'Update Order',
          style: TextStyle(color: Colors.white),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                color: Colors.blue,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Total: ₹${_calculateTotalAmount().toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _divider(),
                    Flexible(
                      child: Text(
                        'Items: ${_calculateTotalItems()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _divider(),
                    Flexible(
                      child: Text(
                        'Qty: ${_calculateTotalQuantity()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Transactions'),
                    Tab(text: 'Customer Details'),
                  ],
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          TransactionBarcode2(),
          // TransactionBarcode2(orderData: orderData),
          const CustomerDetailBarcode2(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddAction,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add New Item',
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed:
                  _tabController.index > 0
                      ? () => setState(() => _tabController.index--)
                      : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
            ),
            _tabController.index == _tabController.length - 1
                ? ElevatedButton.icon(
                  onPressed: _saveEditedOrder,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                )
                : ElevatedButton.icon(
                  onPressed: () => setState(() => _tabController.index++),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 20,
      color: Colors.white.withOpacity(0.5),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
    );
  }

  double _calculateTotalAmount() {
    return orderData.fold(
      0.0,
      (sum, item) => sum + (item.catalog.mrp * item.catalog.clqty),
    );
  }

  int _calculateTotalItems() {
    return orderData.length;
  }

  double _calculateTotalQuantity() {
    return orderData.fold(0.0, (sum, item) => sum + item.catalog.clqty);
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
