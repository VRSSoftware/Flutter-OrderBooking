import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vrs_erp/catalog/image_zoom1.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/CartModel.dart';
import 'package:vrs_erp/models/CatalogOrderData.dart';
import 'package:vrs_erp/models/OrderMatrix.dart';
import 'package:vrs_erp/models/catalog.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_barcode2.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_data.dart';

class CatalogItem {
  final String styleCode;
  final String shadeName;
  final String sizeName;
  final int clQty;
  final double mrp;
  final double wsp;
  final String stkQty;
  final String upcoming_Stk;
  final String barcode;
  final String remark;

  CatalogItem({
    required this.styleCode,
    required this.shadeName,
    required this.sizeName,
    required this.clQty,
    required this.mrp,
    required this.wsp,
    required this.upcoming_Stk,
    required this.stkQty,
    required this.barcode,
    required this.remark,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      styleCode: json['styleCode']?.toString() ?? '',
      shadeName: json['shadeName']?.toString() ?? '',
      sizeName: json['sizeName']?.toString() ?? '',
      upcoming_Stk: json['upcoming_Stk']?.toString() ?? '',
      clQty: int.tryParse(json['clqty']?.toString() ?? '0') ?? 0,
      mrp: double.tryParse(json['mrp']?.toString() ?? '0') ?? 0,
      wsp: double.tryParse(json['wsp']?.toString() ?? '0') ?? 0,
      stkQty: json['data2']?.toString() ?? '0',
      barcode: json['barcode']?.toString() ?? '',
      remark: json['remark']?.toString() ?? '',
    );
  }
}

class BookOnBarcode1 extends StatefulWidget {
  final String barcode;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;
  final bool edit;

  const BookOnBarcode1({
    Key? key,
    required this.barcode,
    required this.onSuccess,
    required this.onCancel,
    this.edit = false,
  }) : super(key: key);

  @override
  State<BookOnBarcode1> createState() => _BookOnBarcode1State();
}

class _BookOnBarcode1State extends State<BookOnBarcode1> {
  List<CatalogOrderData> catalogOrderList = [];
  Map<String, Set<String>> selectedColors2 = {};
  Map<String, Map<String, Map<String, int>>> quantities = {};
  bool isLoading = true;
  bool hasData = false;
  final Map<String, TextEditingController> _controllers = {};
  String barcode = '';
  List<Map<String, dynamic>> addedItems = [];
  Map<String, List<String>> copiedRowsMap = {};
  Map<String, Map<String, double>> sizeMrpMap = {};
  Map<String, Map<String, double>> sizeWspMap = {};

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
    barcode = widget.barcode;
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      isLoading = true;
    });

    final catalogItems = await fetchCatalogData();
    final List<CatalogOrderData> tempList = [];

    if (catalogItems.isNotEmpty) {
      setState(() {
        hasData = true;
      });

      final styleGroups = <String, List<CatalogItem>>{};
      for (var item in catalogItems) {
        styleGroups.putIfAbsent(item.styleCode, () => []).add(item);
      }

      for (var styleCode in styleGroups.keys) {
        final items = styleGroups[styleCode]!;
        final uniqueShades =
            items.map((e) => e.shadeName).toSet().toList()..sort();
        final uniqueSizes =
            items.map((e) => e.sizeName).toSet().toList()..sort();

        // Build size MRP and WSP maps
        Map<String, double> tempSizeMrpMap = {};
        Map<String, double> tempSizeWspMap = {};
        for (var item in items) {
          tempSizeMrpMap[item.sizeName] = item.mrp;
          tempSizeWspMap[item.sizeName] = item.wsp;
        }
        sizeMrpMap[styleCode] = tempSizeMrpMap;
        sizeWspMap[styleCode] = tempSizeWspMap;

        final catalog = Catalog(
          itemSubGrpKey: '',
          itemSubGrpName: '',
          itemKey: '',
          itemName: 'Unknown Product',
          brandKey: '',
          brandName: '',
          styleKey: styleCode,
          styleCode: styleCode,
          shadeKey: '',
          shadeName: uniqueShades.join(','),
          styleSizeId: '',
          sizeName: uniqueSizes.join(','),
          mrp: items.first.mrp,
          wsp: items.first.wsp,
          onlyMRP: items.first.mrp,
          clqty: items.first.clQty,
          total: items.fold(0, (sum, item) => sum + item.clQty),
          upcoming_Stk: items.first.upcoming_Stk,
          fullImagePath: '/NoImage.jpg',
          remark:
              items.first.upcoming_Stk == '1'
                  ? 'Upcoming Stock'
                  : '', // Set remark based on stk type
          imageId: '',
          sizeDetails: uniqueSizes
              .map(
                (size) =>
                    '$size (${items.firstWhere((i) => i.sizeName == size).mrp},${items.firstWhere((i) => i.sizeName == size).wsp})',
              )
              .join(', '),
          sizeDetailsWithoutWSp: uniqueSizes
              .map(
                (size) =>
                    '$size (${items.firstWhere((i) => i.sizeName == size).mrp})',
              )
              .join(', '),
          sizeWithMrp: uniqueSizes
              .map(
                (size) =>
                    '$size (${items.firstWhere((i) => i.sizeName == size).mrp})',
              )
              .join(', '),
          styleCodeWithcount: styleCode,
          onlySizes: uniqueSizes.join(','),
          sizeWithWsp: uniqueSizes
              .map(
                (size) =>
                    '$size (${items.firstWhere((i) => i.sizeName == size).wsp})',
              )
              .join(', '),
          createdDate: '',
          shadeImages: '',
          barcode: items.first.barcode,
        );

        final matrix = <List<String>>[];
        for (var shade in uniqueShades) {
          final row = <String>[];
          for (var size in uniqueSizes) {
            final item = items.firstWhere(
              (i) => i.shadeName == shade && i.sizeName == size,
              orElse:
                  () => CatalogItem(
                    styleCode: styleCode,
                    shadeName: shade,
                    sizeName: size,
                    clQty: items.first.clQty,
                    mrp: items.first.mrp,
                    wsp: items.first.wsp,
                    upcoming_Stk: items.first.upcoming_Stk,
                    stkQty: items.first.stkQty,
                    barcode: items.first.barcode,
                    remark: items.first.remark,
                  ),
            );
            row.add('${item.mrp},${item.wsp},${item.clQty},${item.stkQty}');
          }
          matrix.add(row);
        }

        final orderMatrix = OrderMatrix(
          shades: uniqueShades,
          sizes: uniqueSizes,
          matrix: matrix,
        );

        tempList.add(
          CatalogOrderData(catalog: catalog, orderMatrix: orderMatrix),
        );

        selectedColors2[styleCode] = uniqueShades.toSet();
        quantities[styleCode] = {};
        copiedRowsMap[styleCode] = [];

        for (var shade in uniqueShades) {
          quantities[styleCode]![shade] = {};
          for (var size in uniqueSizes) {
            quantities[styleCode]![shade]![size] =
                UserSession.coBrName == 'G CUBE NX' ? 0 : 1;
            final controllerKey = '$styleCode-$shade-$size';
            final controller = TextEditingController(
              text: UserSession.coBrName == 'G CUBE NX' ? '0' : '1',
            );
            controller.addListener(() => setState(() {}));
            _controllers[controllerKey] = controller;
          }
        }
      }
    } else {
      setState(() {
        hasData = false;
      });
    }

    setState(() {
      catalogOrderList = tempList;
      isLoading = false;
    });

    if (!hasData && mounted) {
      Navigator.pop(context, false);
    }
  }

  Future<List<CatalogItem>> fetchCatalogData() async {
    String apiUrl = '';
    if (widget.edit) {
      apiUrl = '${AppConstants.BASE_URL}/orderBooking/GetBarcodeDetailsUpdated';
    } else {
      apiUrl = '${AppConstants.BASE_URL}/orderBooking/GetBarcodeDetails';
    }
    final Map<String, dynamic> requestBody = {
      "coBrId": UserSession.coBrId ?? '',
      "userId": UserSession.userName ?? '',
      "fcYrId": UserSession.userFcYr ?? '',
      "barcode": widget.barcode.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.map((e) => CatalogItem.fromJson(e)).toList();
        }
      } else if (response.statusCode == 500 &&
          response.body == 'Barcode already added') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This barcode is already added in the cart.'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      } else {
        debugPrint('Failed to fetch catalog data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching catalog data: $e');
    }
    return [];
  }

  int _getQuantity(String styleKey, String shade, String size) {
    return quantities[styleKey]?[shade]?[size] ?? 1;
  }

  void _setQuantity(String styleKey, String shade, String size, int value) {
    setState(() {
      quantities.putIfAbsent(styleKey, () => {});
      quantities[styleKey]!.putIfAbsent(shade, () => {});
      quantities[styleKey]![shade]![size] = value.clamp(0, 9999);
    });
  }

  void _deleteStyle(String styleKey) {
    setState(() {
      catalogOrderList.removeWhere(
        (order) => order.catalog.styleKey == styleKey,
      );
      selectedColors2.remove(styleKey);
      quantities.remove(styleKey);
      sizeMrpMap.remove(styleKey);
      sizeWspMap.remove(styleKey);
      _controllers.removeWhere((key, _) => key.contains('$styleKey-'));
    });

    widget.onCancel();
    Navigator.pop(context);
  }

  void _copyQtyInAllShade(String styleKey, String shade, List<String> sizes) {
    if (sizes.isEmpty) return;
    final firstSize = sizes.first;
    final firstQuantity = _getQuantity(styleKey, shade, firstSize);
    setState(() {
      for (var size in sizes) {
        _setQuantity(styleKey, shade, size, firstQuantity);
        final controllerKey = '$styleKey-$shade-$size';
        if (_controllers.containsKey(controllerKey)) {
          _controllers[controllerKey]!.text = firstQuantity.toString();
        }
      }
    });
  }

  void _copySizeQtyInAllShade(
    String styleKey,
    List<String> shades,
    List<String> sizes,
  ) {
    if (shades.isEmpty || sizes.isEmpty) return;
    final sourceShade = shades.first;

    for (var size in sizes) {
      final valueToCopy = _getQuantity(styleKey, sourceShade, size);
      for (var shade in shades) {
        _setQuantity(styleKey, shade, size, valueToCopy);
        final controllerKey = '$styleKey-$shade-$size';
        if (_controllers.containsKey(controllerKey)) {
          _controllers[controllerKey]!.text = valueToCopy.toString();
        }
      }
    }
    setState(() {});
  }

  void _copySizeQtyToOtherStyles(String sourceStyleKey) {
    for (var catalogOrder in catalogOrderList) {
      final targetStyleKey = catalogOrder.catalog.styleKey;
      if (targetStyleKey == sourceStyleKey) continue;

      final targetShades = catalogOrder.orderMatrix.shades;
      final targetSizes = catalogOrder.orderMatrix.sizes;
      final sourceShades =
          catalogOrderList
              .firstWhere((order) => order.catalog.styleKey == sourceStyleKey)
              .orderMatrix
              .shades;

      for (var shade in sourceShades) {
        if (targetShades.contains(shade)) {
          for (var size in targetSizes) {
            final sourceQty = _getQuantity(sourceStyleKey, shade, size);
            _setQuantity(targetStyleKey, shade, size, sourceQty);
            final controllerKey = '$targetStyleKey-$shade-$size';
            if (_controllers.containsKey(controllerKey)) {
              _controllers[controllerKey]!.text = sourceQty.toString();
            }
          }
        }
      }
    }
    setState(() {});
  }

  void _copyRow(String styleKey, String shade, List<String> sizes) {
    List<String> copiedRow = [];
    for (var size in sizes) {
      final qty = _getQuantity(styleKey, shade, size).toString();
      copiedRow.add(qty);
    }
    copiedRowsMap[styleKey] = copiedRow;
    setState(() {});
  }

  void _pasteRow(String styleKey, String shade, List<String> sizes) {
    final copiedRow = copiedRowsMap[styleKey] ?? [];
    if (copiedRow.isEmpty) return;

    for (int i = 0; i < sizes.length && i < copiedRow.length; i++) {
      final qty = int.tryParse(copiedRow[i]) ?? 0;
      _setQuantity(styleKey, shade, sizes[i], qty);
      final controllerKey = '$styleKey-$shade-${sizes[i]}';
      if (_controllers.containsKey(controllerKey)) {
        _controllers[controllerKey]!.text = qty.toString();
      }
    }
    setState(() {});
  }

  void _copyQtyInShadeOnly(String styleKey, String shade, List<String> sizes) {
    if (sizes.isEmpty) return;
    final firstSize = sizes.first;
    final firstQuantity = _getQuantity(styleKey, shade, firstSize);
    for (var size in sizes) {
      _setQuantity(styleKey, shade, size, firstQuantity);
      final controllerKey = '$styleKey-$shade-$size';
      if (_controllers.containsKey(controllerKey)) {
        _controllers[controllerKey]!.text = firstQuantity.toString();
      }
    }
    setState(() {});
  }

  Future<void> _submitAllOrders() async {
    List<Future<http.Response>> apiCalls = [];
    List<String> apiCallStyles = [];
    final cartModel = Provider.of<CartModel>(context, listen: false);
    addedItems.clear();

    List<CatalogOrderData> updatedCatalogOrderList = [];

    for (var catalogOrder in catalogOrderList) {
      final catalog = catalogOrder.catalog;
      final matrix = catalogOrder.orderMatrix;
      final styleCode = catalog.styleCode;
      final styleKey = catalog.styleKey;
      final remark = catalog.remark; // Use remark from catalog data

      final updatedMatrix = <List<String>>[];
      for (
        var shadeIndex = 0;
        shadeIndex < matrix.shades.length;
        shadeIndex++
      ) {
        final shade = matrix.shades[shadeIndex];
        final row = <String>[];
        for (var sizeIndex = 0; sizeIndex < matrix.sizes.length; sizeIndex++) {
          final size = matrix.sizes[sizeIndex];
          final matrixData = matrix.matrix[shadeIndex][sizeIndex].split(',');
          final mrp = matrixData.isNotEmpty ? matrixData[0] : '0';
          final wsp = matrixData.length > 1 ? matrixData[1] : '0';
          final stkQty = matrixData.length > 2 ? matrixData[2] : '0';
          final qty = quantities[styleKey]?[shade]?[size]?.toString() ?? '1';
          row.add('$mrp,$wsp,$qty,$stkQty');
        }
        updatedMatrix.add(row);
      }

      final updatedOrderMatrix = OrderMatrix(
        shades: matrix.shades,
        sizes: matrix.sizes,
        matrix: updatedMatrix,
      );

      final updatedCatalogOrder = CatalogOrderData(
        catalog: catalog,
        orderMatrix: updatedOrderMatrix,
      );
      updatedCatalogOrderList.add(updatedCatalogOrder);

      final quantityMap = quantities[styleKey];
      if (quantityMap != null) {
        for (var shade in quantityMap.keys) {
          final shadeIndex = matrix.shades.indexOf(shade.trim());
          if (shadeIndex == -1) continue;

          for (var size in quantityMap[shade]!.keys) {
            final sizeIndex = matrix.sizes.indexOf(size.trim());
            if (sizeIndex == -1) continue;

            final quantity = quantityMap[shade]![size]!;
            if (quantity > 0) {
              final matrixData = updatedMatrix[shadeIndex][sizeIndex].split(
                ',',
              );
              final mrp = matrixData.isNotEmpty ? matrixData[0] : '0';
              final wsp = matrixData.length > 1 ? matrixData[1] : mrp;
              final stkQty = matrixData.length > 2 ? matrixData[2] : '0';
              final item = {
                "designcode": styleCode,
                "mrp": mrp,
                "wsp": wsp,
                "size": size,
                "TotQty": _calculateCatalogQuantity(styleKey).toString(),
                "Note": remark,
                "color": shade,
                "Qty": quantity.toString(),
                "clqty": quantity.toString(),
                "cobrid": UserSession.coBrId ?? '',
                "user": "admin",
                "barcode": widget.barcode.trim(),
                "styleCode": styleCode,
                "shadeName": shade,
                "sizeName": size,
                "imagePath": catalog.fullImagePath ?? '/NoImage.jpg',
                "itemName": catalog.itemName ?? 'Unknown Product',
                "upcoming_Stk": stkQty,
              };
              addedItems.add(item);

              final payload = {
                "userId": UserSession.userName ?? '',
                "coBrId": UserSession.coBrId ?? '',
                "fcYrId": UserSession.userFcYr ?? '',
                "data": {
                  "designcode": styleCode,
                  "mrp": mrp,
                  "wsp": wsp,
                  "size": size,
                  "TotQty": _calculateCatalogQuantity(styleKey).toString(),
                  "Note": remark,
                  "color": shade,
                  "Qty": quantity.toString(),
                  "cobrid": UserSession.coBrId ?? '',
                  "user": "admin",
                  "barcode": widget.barcode.trim(),
                },
                "typ": 0,
                "barcode": "true",
              };
              if (!widget.edit) {
                apiCalls.add(
                  http.post(
                    Uri.parse(
                      '${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails',
                    ),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode(payload),
                  ),
                );
              }
              apiCallStyles.add(styleCode);
            }
          }
        }
      }
    }

    if (apiCalls.isEmpty && addedItems.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text("No Items"),
                content: const Text(
                  "No items with quantity greater than 0 to submit.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              ),
        );
      }
      return;
    }

    try {
      int successfulLineItems = 0;
      if (!widget.edit) {
        final responses = await Future.wait(apiCalls);
        for (final response in responses) {
          if (response.statusCode == 200) {
            try {
              final responseBody = jsonDecode(response.body);
              if (responseBody is Map<String, dynamic> &&
                  responseBody['success'] == true) {
                successfulLineItems++;
              } else if (response.body.trim() == "Success") {
                successfulLineItems++;
              }
            } catch (e) {
              if (response.body.trim() == "Success") {
                successfulLineItems++;
              } else {
                debugPrint('Error parsing response: $e');
              }
            }
          } else {
            debugPrint('API call failed with status: ${response.statusCode}');
          }
        }
      } else {
        successfulLineItems = addedItems.length;
      }

      if (successfulLineItems > 0) {
        cartModel.updateCount(cartModel.count + successfulLineItems);
        widget.onSuccess();
        if (widget.edit) {
          EditOrderData.data.addAll(updatedCatalogOrderList);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => EditOrderBarcode2(docId: '-1'),
              ),
            );
          }
        } else {
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text("Error"),
                  content: const Text("No items were successfully submitted."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text("Error"),
                content: Text("Failed to submit orders: $e"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              ),
        );
      }
      debugPrint('Submission error: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Order Booking - BarcodeWise',
          style: TextStyle(color: Colors.white),
        ),
       backgroundColor: Colors.blue,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
       
      ),
      body:Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                const Text(
                  "Barcode:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.barcode,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
          isLoading
              ? Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Please Wait...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 16),
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ],
                  ),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...catalogOrderList.map(
                      (catalogOrder) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildOrderItem(catalogOrder),
                      ),
                    ),
                  ],
                ),
              ),
         )])   );
  }

  Widget _buildOrderItem(CatalogOrderData catalogOrder) {
    final catalog = catalogOrder.catalog;
    final Set<String> selectedColors = selectedColors2[catalog.styleKey] ?? {};
    final sizes = catalogOrder.orderMatrix.sizes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with image and details
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onDoubleTap: () {
                final imageUrl =
                    catalog.fullImagePath.contains("http")
                        ? catalog.fullImagePath
                        : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ImageZoomScreen1(
                          imageUrls: [imageUrl],
                          item: catalog,
                          showShades: true,
                          showMRP: true,
                          showWSP: true,
                          showSizes: true,
                          showProduct: true,
                          showRemark: true,
                          isLargeScreen:
                              MediaQuery.of(context).size.width > 600,
                        ),
                  ),
                );
              },
              child: Container(
                width: 80,
                height: 120,
                margin: const EdgeInsets.only(left: 8, top: 8, right: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    catalog.fullImagePath.contains("http")
                        ? catalog.fullImagePath
                        : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.error,
                            size: 30,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          catalog.styleCode,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                title: const Text('Select an Action'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(dialogContext).pop();
                                        _copySizeQtyToOtherStyles(
                                          catalog.styleKey,
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'Copy Size Qty to other Styles',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _deleteStyle(catalog.styleKey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      // Order - always show
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Order: ${_calculateCatalogQuantity(catalog.styleKey)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                      ),

                      // Stock - always show
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Stock: ${_calculateStockQuantity(catalog.styleKey)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ),

                      // Amount - always show
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Amt: ₹${_calculateCatalogPrice(catalog.styleKey).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.purple,
                          ),
                        ),
                      ),

                      // Stock Type - always show with dynamic value
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Stock Type:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              catalog.upcoming_Stk == '1'
                                  ? 'Upcoming'
                                  : 'Ready',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color:
                                    catalog.upcoming_Stk == '1'
                                        ? Colors.orange.shade800
                                        : Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Remark - always show with dynamic value
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Remark:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                catalog.remark.isNotEmpty
                                    ? catalog.remark
                                    : 'No remarks',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Table for each shade
        ...selectedColors.map(
          (shade) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildShadeTable(catalogOrder, shade),
          ),
        ),

        // Cancel/Confirm buttons for each style
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => _deleteStyle(catalog.styleKey),
                  child: const Text('CANCEL', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _calculateTotalQuantity() > 0
                            ? Colors.green
                            : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed:
                      _calculateTotalQuantity() > 0 ? _submitAllOrders : null,
                  child: const Text('CONFIRM', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
        const Divider(thickness: 1, height: 24),
      ],
    );
  }

  Widget _buildShadeTable(CatalogOrderData catalogOrder, String shade) {
    final styleKey = catalogOrder.catalog.styleKey;
    final sizes = catalogOrder.orderMatrix.sizes;
    final sizeMrp = sizeMrpMap[styleKey] ?? {};
    final sizeWsp = sizeWspMap[styleKey] ?? {};

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 16,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Table(
                border: TableBorder.symmetric(
                  inside: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                columnWidths: _buildColumnWidths(sizes.length),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  // MRP Row
                  _buildPriceRow("MRP", sizeMrp, FontWeight.w600, sizes),
                  // WSP Row
                  _buildPriceRow("WSP", sizeWsp, FontWeight.w400, sizes),
                  // Header Row with Shade/Size diagonal
                  _buildHeaderRow(styleKey, shade, sizes),
                  // Quantity Row for this shade
                  _buildQuantityRow(catalogOrder, shade, sizes),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<int, TableColumnWidth> _buildColumnWidths(int sizeCount) {
    const baseWidth = 70.0;
    return {
      0: const FixedColumnWidth(
        90,
      ), // Slightly wider for shade column with icon
      for (int i = 0; i < sizeCount; i++)
        (i + 1): const FixedColumnWidth(baseWidth),
    };
  }

  TableRow _buildPriceRow(
    String label,
    Map<String, double> sizePriceMap,
    FontWeight weight,
    List<String> sizes,
  ) {
    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: weight,
                fontSize: 12,
                color: Colors.black,
              ),
            ),
          ),
        ),
        ...List.generate(sizes.length, (index) {
          final size = sizes[index];
          final price = sizePriceMap[size] ?? 0.0;
          return TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Center(
              child: Text(
                price.toStringAsFixed(0),
                style: TextStyle(
                  fontWeight: weight,
                  fontSize: 12,
                  color: Colors.black, // Black color for values
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  TableRow _buildHeaderRow(String styleKey, String shade, List<String> sizes) {
    return TableRow(
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 236, 212, 204),
      ),
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Container(
            height: 42,
            child: CustomPaint(
              painter: _DiagonalLinePainter(),
              child: Stack(
                children: [
                  Positioned(
                    left: 10,
                    top: 16,
                    child: Text(
                      'Shade',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 16,
                    child: Text(
                      'Size',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ...List.generate(sizes.length, (index) {
          return TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Center(
              child: Text(
                sizes[index],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }),
      ],
    );
  }

  TableRow _buildQuantityRow(
    CatalogOrderData catalogOrder,
    String shade,
    List<String> sizes,
  ) {
    final styleKey = catalogOrder.catalog.styleKey;

    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          title: const Text(
                            'Select Action',
                            style: TextStyle(fontSize: 15),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDialogOption(
                                'Copy Qty in shade only',
                                Colors.blue,
                                () {
                                  Navigator.of(context).pop();
                                  _copyQtyInShadeOnly(styleKey, shade, sizes);
                                },
                              ),
                              _buildDialogOption('Copy Row', Colors.blue, () {
                                Navigator.of(context).pop();
                                _copyRow(styleKey, shade, sizes);
                              }),
                              _buildDialogOption('Paste Row', Colors.green, () {
                                Navigator.of(context).pop();
                                _pasteRow(styleKey, shade, sizes);
                              }),
                              _buildDialogOption(
                                'Copy Qty in All Shade',
                                Colors.purple,
                                () {
                                  Navigator.of(context).pop();
                                  _copyQtyInAllShade(styleKey, shade, sizes);
                                },
                              ),
                              if (catalogOrderList.length > 1)
                                _buildDialogOption(
                                  'Copy Size Qty to other Styles',
                                  Colors.orange,
                                  () {
                                    Navigator.of(context).pop();
                                    _copySizeQtyToOtherStyles(styleKey);
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    child: const Icon(Icons.copy_all, size: 14),
                  ),
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    shade.length > 8 ? '${shade.substring(0, 6)}..' : shade,
                    style: TextStyle(
                      color: _getColorCode(shade),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        ...List.generate(sizes.length, (index) {
          final size = sizes[index];
          final quantity = _getQuantity(styleKey, shade, size);
          final controllerKey = '$styleKey-$shade-$size';
          final controller = _controllers[controllerKey];

          // Get stock quantity from matrix for hint
          final matrix = catalogOrder.orderMatrix;
          final shadeIndex = matrix.shades.indexOf(shade.trim());
          final sizeIndex = matrix.sizes.indexOf(size.trim());
          String stkQty = '0';
          if (shadeIndex != -1 && sizeIndex != -1) {
            final matrixData = matrix.matrix[shadeIndex][sizeIndex].split(',');
            stkQty = matrixData.length > 2 ? matrixData[2] : '0';
          }

          return TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  hintText: stkQty,
                  hintStyle: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Black color for quantity
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: (value) {
                  final newQuantity =
                      int.tryParse(value.isEmpty ? '0' : value) ?? 0;
                  _setQuantity(styleKey, shade, size, newQuantity);
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDialogOption(String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  int _calculateTotalQuantity() {
    int total = 0;
    for (var styleKey in quantities.keys) {
      for (var shade in quantities[styleKey]!.keys) {
        for (var size in quantities[styleKey]![shade]!.keys) {
          total += quantities[styleKey]![shade]![size]!;
        }
      }
    }
    return total;
  }

  double _calculateTotalPrice() {
    double total = 0;
    for (var catalogOrder in catalogOrderList) {
      total += _calculateCatalogPrice(catalogOrder.catalog.styleKey);
    }
    return total;
  }

  int _calculateCatalogQuantity(String styleKey) {
    int total = 0;
    for (var shade in quantities[styleKey]?.keys ?? []) {
      for (var size in quantities[styleKey]![shade]!.keys) {
        total += quantities[styleKey]![shade]![size]!;
      }
    }
    return total;
  }

  int _calculateStockQuantity(String styleKey) {
    int total = 0;
    for (var catalogOrder in catalogOrderList) {
      if (catalogOrder.catalog.styleKey == styleKey) {
        final matrix = catalogOrder.orderMatrix;
        for (
          var shadeIndex = 0;
          shadeIndex < matrix.shades.length;
          shadeIndex++
        ) {
          for (
            var sizeIndex = 0;
            sizeIndex < matrix.sizes.length;
            sizeIndex++
          ) {
            final matrixData = matrix.matrix[shadeIndex][sizeIndex].split(',');
            final stock =
                int.tryParse(matrixData.length > 2 ? matrixData[2] : '0') ?? 0;
            total += stock;
          }
        }
      }
    }
    return total;
  }

  double _calculateCatalogPrice(String styleKey) {
    double total = 0;
    for (var catalogOrder in catalogOrderList) {
      if (catalogOrder.catalog.styleKey == styleKey) {
        final matrix = catalogOrder.orderMatrix;
        for (var shade in quantities[styleKey]?.keys ?? <String>[]) {
          final shadeIndex = matrix.shades.indexOf(shade.trim());
          if (shadeIndex == -1) continue;
          for (var size in quantities[styleKey]![shade]!.keys) {
            final sizeIndex = matrix.sizes.indexOf(size?.trim() ?? '');
            if (sizeIndex == -1) continue;
            final rate =
                double.tryParse(
                  matrix.matrix[shadeIndex][sizeIndex].split(',')[0],
                ) ??
                0;
            final quantity = quantities[styleKey]![shade]![size]!;
            total += rate * quantity;
          }
        }
      }
    }
    return total;
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
