import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
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
  final String fullImagePath;

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
    required this.fullImagePath,
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
      fullImagePath: json['fullImagePath']?.toString() ?? '/NoImage.jpg',
    );
  }
}

class BookOnBarcode2 extends StatefulWidget {
  final String barcode;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;
  final bool edit;

  const BookOnBarcode2({
    Key? key,
    required this.barcode,
    required this.onSuccess,
    required this.onCancel,
    this.edit = false,
  }) : super(key: key);

  @override
  State<BookOnBarcode2> createState() => _BookOnBarcode2State();
}

class _BookOnBarcode2State extends State<BookOnBarcode2> {
  List<CatalogOrderData> catalogOrderList = [];
  Map<String, Set<String>> selectedColors2 = {};
  Map<String, Map<String, Map<String, int>>> quantities = {};
  bool isLoading = true;
  bool hasData = false;
  final Map<String, TextEditingController> _controllers = {};
  String barcode = '';
  List<Map<String, dynamic>> addedItems = [];

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

    // Split barcodes if multiple
    final List<String> barcodes = widget.barcode.split(',');
    List<CatalogItem> allCatalogItems = [];

    // Fetch data for each barcode
    for (String singleBarcode in barcodes) {
      final catalogItems = await fetchCatalogData(singleBarcode.trim());
      allCatalogItems.addAll(catalogItems);
    }

    final List<CatalogOrderData> tempList = [];

    if (allCatalogItems.isNotEmpty) {
      setState(() {
        hasData = true;
      });

      final styleGroups = <String, List<CatalogItem>>{};
      for (var item in allCatalogItems) {
        styleGroups.putIfAbsent(item.styleCode, () => []).add(item);
      }

      for (var styleCode in styleGroups.keys) {
        final items = styleGroups[styleCode]!;
        final uniqueShades = items.map((e) => e.shadeName).toSet().toList();
        final uniqueSizes = items.map((e) => e.sizeName).toSet().toList();

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
          fullImagePath: items.first.fullImagePath,
          remark: '',
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
                    fullImagePath: items.first.fullImagePath,
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
        for (var shade in uniqueShades) {
          quantities[styleCode]![shade] = {};
          for (var size in uniqueSizes) {
            quantities[styleCode]![shade]![size] =
                UserSession.coBrName == 'G CUBE NX' ? 0 : 0;
            final controllerKey = '$styleCode-$shade-$size';
            final controller = TextEditingController(text: '0');
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

  Future<List<CatalogItem>> fetchCatalogData(String barcode) async {
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
      "barcode": barcode.trim(),
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
            content: Text('Barcode $barcode is already added in the cart.'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      } else {
        debugPrint(
          'Failed to fetch catalog data for barcode $barcode: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching catalog data for barcode $barcode: $e');
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
      _controllers.removeWhere((key, _) => key.contains('$styleKey-'));
    });

    widget.onCancel();
    Navigator.pop(context);
  }

  void _copyStyleQuantities(
    String sourceStyleKey,
    Set<String> targetStyleKeys,
  ) {
    final sourceQuantities = quantities[sourceStyleKey] ?? {};
    setState(() {
      for (var targetStyleKey in targetStyleKeys) {
        final targetCatalogOrder = catalogOrderList.firstWhere(
          (order) => order.catalog.styleKey == targetStyleKey,
        );
        final targetShades = selectedColors2[targetStyleKey] ?? {};
        final validSizes = targetCatalogOrder.orderMatrix.sizes;

        quantities[targetStyleKey] ??= {};
        for (var sourceShade in sourceQuantities.keys) {
          if (targetShades.contains(sourceShade)) {
            quantities[targetStyleKey]!.putIfAbsent(sourceShade, () => {});
            sourceQuantities[sourceShade]!.forEach((size, quantity) {
              if (validSizes.contains(size)) {
                quantities[targetStyleKey]![sourceShade]![size] = quantity;
                final controllerKey = '$targetStyleKey-$sourceShade-$size';
                if (_controllers.containsKey(controllerKey)) {
                  _controllers[controllerKey]!.text = quantity.toString();
                }
              }
            });
          }
        }
      }
    });
  }

  void _copyShadeQuantities(
    String styleKey,
    String sourceShade,
    Set<String> targetShades,
  ) {
    final sourceQuantities = quantities[styleKey]?[sourceShade] ?? {};
    setState(() {
      for (var targetShade in targetShades) {
        quantities[styleKey]!.putIfAbsent(targetShade, () => {});
        sourceQuantities.forEach((size, quantity) {
          quantities[styleKey]![targetShade]![size] = quantity;
          final controllerKey = '$styleKey-$targetShade-$size';
          if (_controllers.containsKey(controllerKey)) {
            _controllers[controllerKey]!.text = quantity.toString();
          }
        });
      }
    });
  }

  void _copyShadeToAllSizes(
    String styleKey,
    String sourceShade,
    List<String> validSizes,
  ) {
    setState(() {
      quantities[styleKey]!.putIfAbsent(sourceShade, () => {});
      // Get the quantity of the first size in the source shade, default to 0 if not set
      final firstSize = validSizes.isNotEmpty ? validSizes.first : null;
      final quantityToCopy =
          firstSize != null
              ? quantities[styleKey]![sourceShade]![firstSize] ?? 0
              : 0;

      // Copy the quantity to all sizes in the source shade
      for (var size in validSizes) {
        quantities[styleKey]![sourceShade]![size] = quantityToCopy;
        final controllerKey = '$styleKey-$sourceShade-$size';
        if (_controllers.containsKey(controllerKey)) {
          _controllers[controllerKey]!.text = quantityToCopy.toString();
        }
      }
    });
  }

  void _copyFirstSizeQuantity(
    String styleKey,
    String shade,
    List<String> sizes,
  ) {
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

  void _multiplyFirstSizeQuantity(
    String styleKey,
    String shade,
    List<String> sizes,
    int multiplier,
  ) {
    if (sizes.isEmpty) return;
    final firstSize = sizes.first;
    final firstQuantity = _getQuantity(styleKey, shade, firstSize);
    final multipliedQuantity = firstQuantity * multiplier;
    setState(() {
      for (var size in sizes) {
        _setQuantity(styleKey, shade, size, multipliedQuantity);
        final controllerKey = '$styleKey-$shade-$size';
        if (_controllers.containsKey(controllerKey)) {
          _controllers[controllerKey]!.text = multipliedQuantity.toString();
        }
      }
    });
  }

Future<void> _submitAllOrders() async {
  List<Future<http.Response>> apiCalls = [];
  List<String> apiCallStyles = [];
  addedItems.clear();

  List<CatalogOrderData> updatedCatalogOrderList = [];

  for (var catalogOrder in catalogOrderList) {
    final catalog = catalogOrder.catalog;
    final matrix = catalogOrder.orderMatrix;
    final styleCode = catalog.styleCode;
    final styleKey = catalog.styleKey;
    final itemBarcode = catalog.barcode ?? '';

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

        // Check if this is a no-shade placeholder
        final bool isNoShade = shade == '' || shade == '_no_shade_' || shade.isEmpty;
        
        // For no-shade, use empty string as color
        final String colorValue = isNoShade ? "" : shade;

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
              "Note": "",
              "color": colorValue, // Use empty string for no-shade
              "Qty": quantity.toString(),
              "clqty": quantity.toString(),
              "cobrid": UserSession.coBrId ?? '',
              "user": "admin",
              "barcode": itemBarcode,
              "styleCode": styleCode,
              "shadeName": colorValue, // Use empty string for no-shade
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
                "Note": "",
                "color": colorValue, // Use empty string for no-shade
                "Qty": quantity.toString(),
                "cobrid": UserSession.coBrId ?? '',
                "user": "admin",
                "barcode": itemBarcode,
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

  void _cancelAll() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel All Items'),
          content: const Text('Are you sure you want to cancel all items?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('NO'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (catalogOrderList.isNotEmpty) {
                  _deleteStyle(catalogOrderList.first.catalog.styleKey);
                } else {
                  widget.onCancel();
                  Navigator.pop(context);
                }
              },
              child: const Text('YES'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Order Booking - BarcodeWise2',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 48,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49.0),
          child: Column(
            children: [
              Container(
                height: 1,
                width: double.infinity,
                color: Colors.white.withOpacity(0.3),
              ),
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
                        'Total: ₹${_calculateTotalPrice().toStringAsFixed(2)}',
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
                        'Items: ${catalogOrderList.length}',
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
            Expanded(
              child:
                  isLoading
                      ? Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Loading...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(width: 16),
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      : SingleChildScrollView(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...catalogOrderList.map(
                              (catalogOrder) => Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: buildOrderItem(catalogOrder, context),
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          !isLoading && hasData && catalogOrderList.isNotEmpty
              ? SafeArea(
                child: Container(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildCompactGradientButton(
                          label: 'CANCEL',
                          icon: Icons.close,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9E9E9E), Color(0xFF757575)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onPressed: _cancelAll,
                          height: 48,
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      Expanded(
                        child: _buildCompactGradientButton(
                          label: 'CONFIRM',
                          icon: Icons.check,
                          gradient:
                              _calculateTotalQuantity() > 0
                                  ? LinearGradient(
                                    colors: [
                                      AppColors.primaryColor,
                                      AppColors.primaryColor.withOpacity(0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                  : const LinearGradient(
                                    colors: [
                                      Color(0xFFBDBDBD),
                                      Color(0xFF9E9E9E),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                          onPressed:
                              _calculateTotalQuantity() > 0
                                  ? _submitAllOrders
                                  : null,
                          height: 48,
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : null,
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
      final styleKey = catalogOrder.catalog.styleKey;
      final matrix = catalogOrder.orderMatrix;
      for (var shade in quantities[styleKey]?.keys ?? []) {
        final shadeIndex = matrix.shades.indexOf(shade.toString().trim());
        if (shadeIndex == -1) continue;
        for (var size in quantities[styleKey]![shade]!.keys) {
          final sizeIndex = matrix.sizes.indexOf(size.trim());
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
    return total;
  }

  Widget buildOrderItem(CatalogOrderData catalogOrder, BuildContext context) {
    final catalog = catalogOrder.catalog;
    final Set<String> selectedColors = selectedColors2[catalog.styleKey] ?? {};
    final String itemBarcode = catalog.barcode ?? '';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barcode header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primaryColor.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "BARCODE :",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    itemBarcode,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.maroon,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
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
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        catalog.fullImagePath.contains("http")
                            ? catalog.fullImagePath
                            : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}',
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.broken_image, size: 30),
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
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryColor.withOpacity(0.15),
                                    AppColors.primaryColor.withOpacity(0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primaryColor.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                catalog.styleCode,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              // Copy Style Button (only if has shades)
                              Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () async {
                                    final result = await showDialog<
                                      Set<String>
                                    >(
                                      context: context,
                                      builder:
                                          (context) => CopyToStylesDialog(
                                            styleKeys:
                                                catalogOrderList
                                                    .map(
                                                      (order) =>
                                                          order
                                                              .catalog
                                                              .styleKey,
                                                    )
                                                    .where(
                                                      (key) =>
                                                          key !=
                                                          catalog.styleKey,
                                                    )
                                                    .toList(),
                                            styleCodes:
                                                catalogOrderList
                                                    .map(
                                                      (order) =>
                                                          order
                                                              .catalog
                                                              .styleCode,
                                                    )
                                                    .toList(),
                                            sourceStyleKey: catalog.styleKey,
                                            sourceStyleCode: catalog.styleCode,
                                          ),
                                    );
                                    if (result != null && result.isNotEmpty) {
                                      _copyStyleQuantities(
                                        catalog.styleKey,
                                        result,
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor.withOpacity(
                                        0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.copy,
                                      size: 14,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Delete Button
                              Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    _confirmDeleteStyle(
                                      catalog.styleKey,
                                      catalog.styleCode,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.delete,
                                      size: 14,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Stats row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatRow(
                              'Stock',
                              _calculateStockQuantity(
                                catalog.styleKey,
                              ).toString(),
                              Icons.inventory,
                              Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildStatRow(
                              'Order',
                              _calculateCatalogQuantity(
                                catalog.styleKey,
                              ).toString(),
                              Icons.shopping_bag,
                              Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildStatRow(
                              'Amt',
                              '₹${_calculateCatalogPrice(catalog.styleKey).toStringAsFixed(0)}',
                              Icons.currency_rupee,
                              Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Color Sections - Conditionally show shade or no-shade table
          _buildTableSection(catalogOrder, selectedColors),

          const SizedBox(height: 12),

          // Note field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Note',
                labelStyle: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                prefixIcon: Icon(
                  Icons.note_outlined,
                  size: 16,
                  color: AppColors.primaryColor,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 30,
                ),
              ),
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Add this helper method to build the table section
  Widget _buildTableSection(
    CatalogOrderData catalogOrder,
    Set<String> selectedColors,
  ) {
    // Check if there are valid shades
    final bool hasShades = selectedColors.any(
      (color) => color.isNotEmpty && color != 'null',
    );

    if (hasShades) {
      // Return shade cards
      return Column(
        children:
            selectedColors.map((color) {
              if (color.isEmpty || color == 'null')
                return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildColorSection(catalogOrder, color),
              );
            }).toList(),
      );
    } else {
      // Return no-shade table
      return _buildNoShadeTable(catalogOrder);
    }
  }

  Widget _buildNoShadeTable(CatalogOrderData catalogOrder) {
    final matrix = catalogOrder.orderMatrix;
    final styleKey = catalogOrder.catalog.styleKey;
    final sizes = matrix.sizes;
    final totalQty = _calculateCatalogQuantity(styleKey);
    final totalAmount = _calculateCatalogPrice(styleKey);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // QUANTITY and AMOUNT Header Row (NO SHADE LABEL)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: const Text(" ", textAlign: TextAlign.center),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      "QUANTITY",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "AMOUNT",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade300),

          // Values Row
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: const Text(" ", textAlign: TextAlign.center),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      totalQty.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: Text(
                      '₹${totalAmount.toStringAsFixed(0)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade300),

          // Size Headers
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                _buildHeader("SIZE", 1),
                _buildHeader("QTY", 2),
                _buildHeader("MRP", 1),
                _buildHeader("WSP", 1),
                _buildHeader("STOCK", 1),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade300),

          // Size rows
          for (var i = 0; i < sizes.length; i++) ...[
            _buildNoShadeSizeRow(catalogOrder, sizes[i], matrix.matrix[0][i]),
            if (i != sizes.length - 1)
              Divider(height: 1, color: Colors.grey.shade300),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNoShadeSizeRow(
    CatalogOrderData catalogOrder,
    String size,
    String matrixData,
  ) {
    final styleKey = catalogOrder.catalog.styleKey;
    final matrixParts = matrixData.split(',');
    final rate = matrixParts.isNotEmpty ? matrixParts[0] : '0';
    final wsp = matrixParts.length > 1 ? matrixParts[1] : '0';
    final stock = matrixParts.length > 2 ? matrixParts[2] : '0';

    final shadeKey = '';
    final quantity = _getQuantity(styleKey, shadeKey, size);
    final controllerKey = '$styleKey-$shadeKey-$size';
    final controller = _controllers.putIfAbsent(
      controllerKey,
      () => TextEditingController(text: quantity.toString()),
    );

    if (controller.text != quantity.toString()) {
      controller.text = quantity.toString();
    }

    return Row(
      children: [
        // SIZE column
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              size,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
        ),
        // QTY column - COMPACT VERSION
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    final newQuantity = quantity > 0 ? quantity - 1 : 0;
                    _setQuantity(styleKey, shadeKey, size, newQuantity);
                    controller.text = newQuantity.toString();
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.remove, size: 14),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 35,
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 0,
                      ),
                      hintText: stock,
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 11),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      //LengthLimitingTextInputFormatter(3),
                    ],
                    onChanged: (value) {
                      final newQuantity =
                          int.tryParse(value.isEmpty ? '0' : value) ?? 0;
                      _setQuantity(styleKey, shadeKey, size, newQuantity);
                    },
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    final newQuantity = quantity + 1;
                    _setQuantity(styleKey, shadeKey, size, newQuantity);
                    controller.text = newQuantity.toString();
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.add, size: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        // MRP column
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              rate,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
        ),
        // WSP column
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              wsp,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
        ),
        // STOCK column
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              stock,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteStyle(String styleKey, String styleCode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: Colors.white,
          elevation: 8,
          titlePadding: const EdgeInsets.only(top: 30, bottom: 8),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 8,
          ),
          actionsPadding: const EdgeInsets.only(
            bottom: 24,
            right: 24,
            left: 24,
          ),
          title: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    styleCode,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to delete this style?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      backgroundColor: Colors.grey.shade50,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete_outline, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          "Delete",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _deleteStyle(styleKey);
    }
  }

  int uniqueShadesCount(String styleKey) {
    return selectedColors2[styleKey]?.length ?? 0;
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            flex: 0,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 2),
          Flexible(
            flex: 1,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactGradientButton({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback? onPressed,
    double height = 48,
    BorderRadius borderRadius = BorderRadius.zero,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(gradient: gradient, borderRadius: borderRadius),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          minimumSize: Size(double.infinity, height),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
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
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'pink':
        return Colors.pink;
      case 'brown':
        return Colors.brown;
      case 'grey':
      case 'gray':
        return Colors.grey;
      default:
        return Colors.primaries[color.hashCode % Colors.primaries.length];
    }
  }

  int _calculateShadeQuantity(String styleKey, String shade) {
    int total = 0;
    final shadeQuantities = quantities[styleKey]?[shade];
    if (shadeQuantities != null) {
      for (var qty in shadeQuantities.values) {
        total += qty;
      }
    }
    return total;
  }

  double _calculateShadePrice(CatalogOrderData catalogOrder, String shade) {
    double total = 0;
    final styleKey = catalogOrder.catalog.styleKey;
    final matrix = catalogOrder.orderMatrix;
    final shadeIndex = matrix.shades.indexOf(shade.trim());
    if (shadeIndex == -1) return total;
    for (var size in quantities[styleKey]?[shade]?.keys ?? []) {
      final sizeIndex = matrix.sizes.indexOf(size.toString().trim());
      if (sizeIndex == -1) continue;
      final rate =
          double.tryParse(matrix.matrix[shadeIndex][sizeIndex].split(',')[0]) ??
          0;
      final quantity = quantities[styleKey]![shade]![size]!;
      total += rate * quantity;
    }
    return total;
  }

  Widget _buildColorSection(CatalogOrderData catalogOrder, String shade) {
    final sizes = catalogOrder.orderMatrix.sizes;
    final styleKey = catalogOrder.catalog.styleKey;
    final totalQty = _calculateShadeQuantity(styleKey, shade);
    final totalAmount = _calculateShadePrice(catalogOrder, shade);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Header row - SHADE label only (no copy icon)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      "SHADE",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      "QUANTITY",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "AMOUNT",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade300),

          // Values row: Shade name, Quantity, Amount
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      shade,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getColorCode(shade),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      totalQty.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: Text(
                      '₹${totalAmount.toStringAsFixed(0)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade300),

          // Size headers
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                _buildHeader("SIZE", 1),
                _buildHeader("QTY", 2),
                _buildHeader("MRP", 1),
                _buildHeader("WSP", 1),
                _buildHeader("STOCK", 1),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade300),

          // Size rows
          for (var size in sizes) ...[
            _buildSizeRow(catalogOrder, shade, size),
            if (size != sizes.last)
              Divider(height: 1, color: Colors.grey.shade300),
          ],
          const SizedBox(height: 8),
        ],
      ),
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
        style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 14),
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
    final sizeIndex = matrix.sizes.indexOf(size?.trim() ?? '');
    final styleKey = catalogOrder.catalog.styleKey;

    String rate = '0';
    String wsp = '0';
    String stkQty = '0';

    if (shadeIndex != -1 && sizeIndex != -1) {
      final matrixData = matrix.matrix[shadeIndex][sizeIndex].split(',');
      rate = matrixData.isNotEmpty ? matrixData[0] : '0';
      wsp = matrixData.length > 1 ? matrixData[1] : '0';
      stkQty = matrixData.length > 2 ? matrixData[2] : '0';
    }

    int quantity = _getQuantity(styleKey, shade, size);
    final controllerKey = '$styleKey-$shade-$size';
    final controller = _controllers.putIfAbsent(
      controllerKey,
      () => TextEditingController(text: quantity.toString()),
    );

    if (controller.text != quantity.toString()) {
      controller.text = quantity.toString();
    }

    return Row(
      children: [
        // SIZE column
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              size,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
        ),
        // QTY column - COMPACT VERSION (like TransactionTab2)
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    final newQuantity = quantity > 0 ? quantity - 1 : 0;
                    _setQuantity(styleKey, shade, size, newQuantity);
                    controller.text = newQuantity.toString();
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.remove, size: 14),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 35,
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 0,
                      ),
                      hintText: stkQty,
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 11),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    onChanged: (value) {
                      final newQuantity =
                          int.tryParse(value.isEmpty ? '0' : value) ?? 0;
                      _setQuantity(styleKey, shade, size, newQuantity);
                    },
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    final newQuantity = quantity + 1;
                    _setQuantity(styleKey, shade, size, newQuantity);
                    controller.text = newQuantity.toString();
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.add, size: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        // MRP column
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              rate,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
        ),
        // WSP column
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              wsp,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
        ),
        // STOCK column
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              stkQty,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
        ),
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
}

// ShadeSelectionDialog Class (same as CreateOrderScreen)
class ShadeSelectionDialog extends StatefulWidget {
  final List<String> shades;
  final String sourceShade;

  const ShadeSelectionDialog({
    Key? key,
    required this.shades,
    required this.sourceShade,
  }) : super(key: key);

  @override
  _ShadeSelectionDialogState createState() => _ShadeSelectionDialogState();
}

class _ShadeSelectionDialogState extends State<ShadeSelectionDialog> {
  final Set<String> _selectedShades = {};
  bool _isAllSizesChecked = false;
  bool _showShadeSelection = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text('Copy Quantities', style: GoogleFonts.poppins()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_showShadeSelection) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Copy quantity in all sizes of "${widget.sourceShade}"',
                    style: GoogleFonts.roboto(),
                  ),
                  value: _isAllSizesChecked,
                  onChanged: (bool? value) {
                    setState(() {
                      _isAllSizesChecked = value ?? false;
                    });
                  },
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showShadeSelection = true;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Copy quantities of "${widget.sourceShade}" in other shades',
                          style: GoogleFonts.roboto(),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_showShadeSelection) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Copying from: ${widget.sourceShade}',
                  style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              ...widget.shades.map((shade) {
                return CheckboxListTile(
                  title: Text(shade, style: GoogleFonts.roboto()),
                  value: _selectedShades.contains(shade),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedShades.add(shade);
                      } else {
                        _selectedShades.remove(shade);
                      }
                    });
                  },
                );
              }).toList(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel', style: GoogleFonts.montserrat()),
        ),
        TextButton(
          onPressed: () {
            if (_isAllSizesChecked && !_showShadeSelection) {
              Navigator.pop(context, {
                'option': 'all_sizes',
                'sourceShade': widget.sourceShade,
              });
            } else if (_showShadeSelection && _selectedShades.isNotEmpty) {
              Navigator.pop(context, {
                'option': 'other_shades',
                'selectedShades': _selectedShades,
              });
            }
          },
          child: Text('OK', style: GoogleFonts.montserrat()),
        ),
      ],
    );
  }
}

// CopyToStylesDialog Class (same as CreateOrderScreen)
class CopyToStylesDialog extends StatefulWidget {
  final List<String> styleKeys;
  final List<String> styleCodes;
  final String sourceStyleKey;
  final String sourceStyleCode;

  const CopyToStylesDialog({
    Key? key,
    required this.styleKeys,
    required this.styleCodes,
    required this.sourceStyleKey,
    required this.sourceStyleCode,
  }) : super(key: key);

  @override
  _CopyToStylesDialogState createState() => _CopyToStylesDialogState();
}

class _CopyToStylesDialogState extends State<CopyToStylesDialog> {
  late Set<String> _selectedStyleKeys;

  @override
  void initState() {
    super.initState();
    _selectedStyleKeys = widget.styleKeys.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text('Copy Qty to Other Styles', style: GoogleFonts.poppins()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Copying from: ${widget.sourceStyleCode}',
                style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ...widget.styleKeys.asMap().entries.map((entry) {
              final index = entry.key;
              final styleKey = entry.value;
              final styleCode = widget.styleCodes[index];
              return CheckboxListTile(
                title: Text(styleCode, style: GoogleFonts.roboto()),
                value: _selectedStyleKeys.contains(styleKey),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedStyleKeys.add(styleKey);
                    } else {
                      _selectedStyleKeys.remove(styleKey);
                    }
                  });
                },
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel', style: GoogleFonts.montserrat()),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, _selectedStyleKeys);
          },
          child: Text('OK', style: GoogleFonts.montserrat()),
        ),
      ],
    );
  }
}
