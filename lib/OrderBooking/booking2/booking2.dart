import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/CartModel.dart';
import 'package:vrs_erp/models/CatalogOrderData.dart';
import 'package:vrs_erp/models/OrderMatrix.dart';
import 'package:vrs_erp/models/catalog.dart';

class CreateOrderScreen extends StatefulWidget {
  final List<Catalog> catalogs;
  final VoidCallback onSuccess; 
  const CreateOrderScreen({Key? key, required this.catalogs,required this.onSuccess,}) : super(key: key);

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  List<CatalogOrderData> catalogOrderList = [];
  Map<String, Set<String>> selectedColors2 = {};
  Map<String, Map<String, Map<String, int>>> quantities = {};
  bool isLoading = true;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
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

  Future<void> _loadOrderDetails() async {
    setState(() {
      isLoading = true;
    });
    final List<CatalogOrderData> tempList = [];

    for (var item in widget.catalogs) {
      final payload = {
        "itemSubGrpKey": item.itemSubGrpKey,
        "itemKey": item.itemKey,
        "styleKey": item.styleKey,
        "userId": UserSession.userName??'',
        "coBrId": UserSession.coBrId??'',
        "fcYrId": UserSession.userFcYr??'',
      };

      try {
        final response = await http.post(
          Uri.parse('${AppConstants.BASE_URL}/catalog/GetOrderDetails2'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final orderMatrix = OrderMatrix.fromJson(data);
          tempList.add(
            CatalogOrderData(catalog: item, orderMatrix: orderMatrix),
          );

          selectedColors2[item.styleKey] =
              item.shadeName.split(',').map((e) => e.trim()).toSet();

          quantities[item.styleKey] = {};
          for (var shade in selectedColors2[item.styleKey]!) {
            quantities[item.styleKey]![shade] = {};
          }
        } else {
          debugPrint(
            'Failed to fetch order details for ${item.styleKey}: ${response.statusCode}',
          );
        }
      } catch (e) {
        debugPrint('Error fetching order details for ${item.styleKey}: $e');
      }
    }

    setState(() {
      catalogOrderList = tempList;
      isLoading = false;
    });
  }

  int _getQuantity(String styleKey, String shade, String size) {
    return quantities[styleKey]?[shade]?[size] ?? 0;
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
      final quantityToCopy = firstSize != null
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

Future<void> _submitAllOrders() async {
  List<Future<http.Response>> apiCalls = [];
  List<String> apiCallStyles = [];
  final cartModel = Provider.of<CartModel>(context, listen: false);

  // Filter out already added items to prevent duplicate submissions
  for (var catalogOrder in catalogOrderList) {
    final catalog = catalogOrder.catalog;
    final matrix = catalogOrder.orderMatrix;
    final styleCode = catalog.styleCode;

    // Skip if the item is already in the cart
    if (cartModel.addedItems.contains(styleCode)) {
      continue;
    }

    final quantityMap = quantities[catalog.styleKey];
    if (quantityMap != null) {
      for (var shade in quantityMap.keys) {
        final shadeIndex = matrix.shades.indexOf(shade.trim());
        if (shadeIndex == -1) continue;

        for (var size in quantityMap[shade]!.keys) {
          final sizeIndex = matrix.sizes.indexOf(size.trim());
          if (sizeIndex == -1) continue;

          final quantity = quantityMap[shade]![size]!;
          if (quantity > 0) {
            final matrixData = matrix.matrix[shadeIndex][sizeIndex].split(',');
            final payload = {
              "userId": UserSession.userName??'',
              "coBrId": UserSession.coBrId??'',
              "fcYrId": UserSession.userFcYr??'',
              "data": {
                "designcode": styleCode,
                "mrp": matrixData[0],
                "WSP": matrixData.length > 2 ? matrixData[2] : matrixData[0],
                "size": size,
                "TotQty": _calculateCatalogQuantity(catalog.styleKey).toString(),
                "Note": "",
                "color": shade,
                "Qty": quantity.toString(),
                "cobrid": UserSession.coBrId??'',
                "user": "admin",
                "barcode": "",
              },
              "typ": 0,
            };

            apiCalls.add(
              http.post(
                Uri.parse('${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(payload),
              ),
            );
            apiCallStyles.add(styleCode);
          }
        }
      }
    }
  }

  if (apiCalls.isEmpty) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Warning"),
          content: const Text("No new items to submit."),
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
    final responses = await Future.wait(apiCalls);
    final successfulStyles = <String>{};

    for (int i = 0; i < responses.length; i++) {
      final response = responses[i];
      if (response.statusCode == 200) {
        try {
          // Try parsing as JSON first
          final responseBody = jsonDecode(response.body);
          if (responseBody is Map<String, dynamic> && responseBody['success'] == true) {
            successfulStyles.add(apiCallStyles[i]);
            cartModel.addItem(apiCallStyles[i]);
          }
        } catch (e) {
          // Handle plain text "Success" response
          if (response.body.trim() == "Success") {
            successfulStyles.add(apiCallStyles[i]);
            cartModel.addItem(apiCallStyles[i]);
          } else {
            print('Failed to parse response for style ${apiCallStyles[i]}: $e, response: ${response.body}');
          }
        }
      } else {
        print('API call failed for style ${apiCallStyles[i]}: ${response.statusCode}, response: ${response.body}');
      }
    }

    if (successfulStyles.isNotEmpty) {
      cartModel.updateCount(cartModel.count + successfulStyles.length);
      widget.onSuccess();

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Success"),
            content: Text("Successfully submitted ${successfulStyles.length} item${successfulStyles.length > 1 ? 's' : ''}"),
            actions: [
              TextButton(
                onPressed: () {
                   Navigator.pop(context);
                    Navigator.pop(context);

                }, // Pop only the dialog
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Error"),
            content: const Text("No items were successfully submitted"),
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
        builder: (_) => AlertDialog(
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
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Order Booking',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.signal_cellular_alt),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Column(
            children: [
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'Total: ₹${_calculateTotalPrice().toStringAsFixed(2)}',
                    style: GoogleFonts.roboto(color: Colors.white),
                  ),
                  const VerticalDivider(color: Colors.white),
                  Text(
                    'Total Item: ${catalogOrderList.length}',
                    style: GoogleFonts.roboto(color: Colors.white),
                  ),
                  const VerticalDivider(color: Colors.white, thickness: 2),
                  Text(
                    'Total Qty: ${_calculateTotalQuantity()}',
                    style: GoogleFonts.roboto(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? Stack(
              children: [
                Container(color: Colors.black.withOpacity(0.2)),
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3.5),
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
                      children: [
                        Text(
                          'Please Wait...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 12),
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  ...catalogOrderList.map(
                    (catalogOrder) => Column(
                      children: [
                        buildOrderItem(catalogOrder),
                        const Divider(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomAppBar(
        height: 60,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('BACK', style: GoogleFonts.montserrat()),
              ),
              TextButton(
                onPressed: _calculateTotalQuantity() > 0 ? _submitAllOrders : null,
                child: Text(
                  'SAVE',
                  style: GoogleFonts.montserrat(
                    color: _calculateTotalQuantity() > 0 ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
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
      final styleKey = catalogOrder.catalog.styleKey;
      final matrix = catalogOrder.orderMatrix;
      for (var shade in quantities[styleKey]?.keys ?? []) {
        final shadeIndex = matrix.shades.indexOf(shade.toString().trim());
        if (shadeIndex == -1) continue;
        for (var size in quantities[styleKey]![shade]!.keys) {
          final sizeIndex = matrix.sizes.indexOf(size.trim());
          if (sizeIndex == -1) continue;
          final rate = double.tryParse(matrix.matrix[shadeIndex][sizeIndex].split(',')[0]) ?? 0;
          final quantity = quantities[styleKey]![shade]![size]!;
          total += rate * quantity;
        }
      }
    }
    return total;
  }

  Widget buildOrderItem(CatalogOrderData catalogOrder) {
    final catalog = catalogOrder.catalog;
    final Set<String> selectedColors = selectedColors2[catalog.styleKey] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  catalog.fullImagePath.contains("http")
                      ? catalog.fullImagePath
                      : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}',
                  width: 60,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 60),
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
                          child: Text(
                            catalog.styleCode,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.copy,
                                size: 16,
                                color: Colors.grey,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              onPressed: () async {
                                final result = await showDialog<Set<String>>(
                                  context: context,
                                  builder: (context) => CopyToStylesDialog(
                                    styleKeys: catalogOrderList
                                        .map((order) => order.catalog.styleKey)
                                        .where((key) => key != catalog.styleKey)
                                        .toList(),
                                    styleCodes: catalogOrderList
                                        .map((order) => order.catalog.styleCode)
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
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                size: 16,
                                color: Colors.red,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              onPressed: () {
                                _deleteStyle(catalog.styleKey);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Qty: ${_calculateCatalogQuantity(catalog.styleKey)}',
                      style: GoogleFonts.roboto(fontSize: 14),
                    ),
                    Text(
                      'Pending Qty: 0 | Wip Stock: 0',
                      style: GoogleFonts.roboto(fontSize: 14),
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
              const SizedBox(height: 15),
            ],
          ),
        ),
        const SizedBox(height: 15),
      ],
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

  Widget _buildColorSection(CatalogOrderData catalogOrder, String shade) {
    final sizes = catalogOrder.orderMatrix.sizes;
    final styleKey = catalogOrder.catalog.styleKey;
    final allShades =
        catalogOrder.catalog.shadeName.split(',').map((e) => e.trim()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Shade",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lora(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.copy_all_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: () async {
                              final result = await showDialog<Map<String, dynamic>>(
                                context: context,
                                builder: (context) => ShadeSelectionDialog(
                                  shades: allShades.where((s) => s != shade).toList(),
                                  sourceShade: shade,
                                ),
                              );

                              if (result != null) {
                                if (result['option'] == 'all_sizes') {
                                  _copyShadeToAllSizes(
                                    styleKey,
                                    shade,
                                    sizes,
                                  );
                                } else if (result['option'] == 'other_shades') {
                                  final selectedShades = result['selectedShades'] as Set<String>;
                                  if (selectedShades.isNotEmpty) {
                                    _copyShadeQuantities(
                                      styleKey,
                                      shade,
                                      selectedShades,
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildHeader("Quantity", 1),
                  _buildHeader("Price", 1),
                ],
              ),
              Divider(height: 1, color: Colors.grey.shade300),
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
                          color: _getColorCode(shade),
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
                        _calculateShadeQuantity(styleKey, shade).toString(),
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
                        '₹${_calculateShadePrice(catalogOrder, shade).toStringAsFixed(2)}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              Divider(height: 1, color: Colors.grey.shade300),
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
            style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      );

  int _calculateShadeQuantity(String styleKey, String shade) {
    int total = 0;
    for (var size in quantities[styleKey]?[shade]?.keys ?? []) {
      total += quantities[styleKey]![shade]![size]!;
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
      final rate = double.tryParse(matrix.matrix[shadeIndex][sizeIndex].split(',')[0]) ?? 0;
      final quantity = quantities[styleKey]![shade]![size]!;
      total += rate * quantity;
    }
    return total;
  }

  Widget _buildSizeRow(
    CatalogOrderData catalogOrder,
    String shade,
    String size,
  ) {
    final matrix = catalogOrder.orderMatrix;
    final shadeIndex = matrix.shades.indexOf(shade.trim());
    final sizeIndex = matrix.sizes.indexOf(size.trim());
    final styleKey = catalogOrder.catalog.styleKey;

    String rate = '';
    String stock = '0';
    String wsp = '0';
    if (shadeIndex != -1 && sizeIndex != -1) {
      final matrixData = matrix.matrix[shadeIndex][sizeIndex].split(',');
      rate = matrixData[0];
      stock = matrixData.length > 1 ? matrixData[2] : '0';
      wsp = matrixData.length > 1 ? matrixData[1] : '0';
    }

    final quantity = _getQuantity(styleKey, shade, size);
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
                IconButton(
                  onPressed: () {
                    _setQuantity(styleKey, shade, size, quantity - 1);
                    controller.text = _getQuantity(styleKey, shade, size).toString();
                  },
                  icon: const Icon(Icons.remove, size: 20),
                ),
                SizedBox(
                  width: 22,
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: GoogleFonts.roboto(fontSize: 14),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    onChanged: (value) {
                      final newQuantity = int.tryParse(value.isEmpty ? '0' : value) ?? 0;
                      _setQuantity(styleKey, shade, size, newQuantity);
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _setQuantity(styleKey, shade, size, quantity + 1);
                    controller.text = _getQuantity(styleKey, shade, size).toString();
                  },
                  icon: const Icon(Icons.add, size: 20),
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
}

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
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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