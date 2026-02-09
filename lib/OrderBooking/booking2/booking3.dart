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

class CreateOrderScreen3 extends StatefulWidget {
  final List<Catalog> catalogs;
    final VoidCallback onSuccess;

  const CreateOrderScreen3({Key? key, required this.catalogs,required this.onSuccess})
      : super(key: key);

  @override
  State<CreateOrderScreen3> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen3> {
  List<CatalogOrderData> catalogOrderList = [];
  Map<String, String> selectedColors2 = {};
  Map<String, Map<String, Map<String, int>>> quantities = {};
  final Map<String, TextEditingController> _controllers = {};
  bool isLoading = true;
  final Set<String> _copiedShades = {}; // Format: "styleKey:shade"

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
          final shades =
              item.shadeName.split(',').map((s) => s.trim()).toList();
          selectedColors2[item.styleKey] = shades.isNotEmpty ? shades[0] : '';
          quantities[item.styleKey] = shades.isNotEmpty ? {shades[0]: {}} : {};
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
    return quantities[styleKey]?[shade.trim()]?[size] ?? 0;
  }

  void _setQuantity(String styleKey, String shade, String size, int value) {
    setState(() {
      quantities.putIfAbsent(styleKey, () => {});
      quantities[styleKey]!.putIfAbsent(shade.trim(), () => {});
      quantities[styleKey]![shade.trim()]![size] = value.clamp(0, 99999);
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
      _copiedShades.removeWhere((key) => key.startsWith('$styleKey:'));
    });
  }

  void _copyStyleQuantities(
    String sourceStyleKey,
    String sourceShade,
    Map<String, Set<String>> targetStyles,
  ) {
    final sourceQuantities = quantities[sourceStyleKey]?[sourceShade] ?? {};

    setState(() {
      for (var targetStyleKey in targetStyles.keys) {
        final targetCatalogOrder = catalogOrderList.firstWhere(
          (order) => order.catalog.styleKey == targetStyleKey,
        );
        final validSizes = targetCatalogOrder.orderMatrix.sizes;
        final targetShades =
            targetStyles[targetStyleKey] ??
                targetCatalogOrder.catalog.shadeName
                    .split(',')
                    .map((s) => s.trim())
                    .toSet();

        quantities[targetStyleKey] ??= {};
        for (var targetShade in targetShades) {
          quantities[targetStyleKey]!.putIfAbsent(targetShade, () => {});
          quantities[targetStyleKey]![targetShade]!.clear();

          sourceQuantities.forEach((size, quantity) {
            if (validSizes.contains(size)) {
              quantities[targetStyleKey]![targetShade]![size] = quantity;
              final controllerKey = '$targetStyleKey-$targetShade-$size';
              if (_controllers.containsKey(controllerKey)) {
                _controllers[controllerKey]!.text = quantity.toString();
              }
              _copiedShades.add('$targetStyleKey:$targetShade');
            }
          });
        }
      }
    });
  }

  void _copyShadesToOtherStyles(
    String sourceStyleKey,
    Set<String> sourceShades,
  ) {
    setState(() {
      for (var targetOrder in catalogOrderList) {
        final targetStyleKey = targetOrder.catalog.styleKey;
        if (targetStyleKey == sourceStyleKey) continue; // Skip source style

        final targetShades = targetOrder.catalog.shadeName
            .split(',')
            .map((s) => s.trim())
            .toSet();
        final targetSizes = targetOrder.orderMatrix.sizes;

        quantities[targetStyleKey] ??= {};
        for (var sourceShade in sourceShades) {
          if (targetShades.contains(sourceShade)) {
            // Copy quantities for matching sizes
            final sourceQuantities =
                quantities[sourceStyleKey]?[sourceShade] ?? {};
            quantities[targetStyleKey]!.putIfAbsent(sourceShade, () => {});
            quantities[targetStyleKey]![sourceShade]!.clear();

            sourceQuantities.forEach((size, quantity) {
              if (targetSizes.contains(size)) {
                quantities[targetStyleKey]![sourceShade]![size] = quantity;
                final controllerKey = '$targetStyleKey-$sourceShade-$size';
                if (_controllers.containsKey(controllerKey)) {
                  _controllers[controllerKey]!.text = quantity.toString();
                }
                _copiedShades.add('$targetStyleKey:$sourceShade');
              }
            });
          }
        }
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
      _copiedShades.add('$styleKey:$sourceShade');
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
                "cobrid": UserSession.userFcYr??'',
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
                onPressed: (){
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
  Color _getColorCode(String color) {
    switch (color.toLowerCase().trim()) {
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
                crossAxisAlignment: CrossAxisAlignment.center,
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
      body:
          isLoading
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
                onPressed:
                    _calculateTotalQuantity() > 0
                        ? () {
                          debugPrint('Quantities: $quantities');
                          _copiedShades.clear();
                          _submitAllOrders();
                          setState(() {});
                        }
                        : null,
                child: Text(
                  'SAVE',
                  style: GoogleFonts.montserrat(
                    color:
                        _calculateTotalQuantity() > 0
                            ? Colors.black
                            : Colors.grey,
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
        if (shadeIndex == -1) {
          debugPrint('Shade not found: $shade');
          continue;
        }
        for (var size in quantities[styleKey]![shade]!.keys) {
          final sizeIndex = matrix.sizes.indexOf(size.trim());
          if (sizeIndex == -1) {
            debugPrint('Size not found: $size');
            continue;
          }
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

  double _calculateCatalogPrice(String styleKey) {
    double total = 0;
    for (var catalogOrder in catalogOrderList) {
      if (catalogOrder.catalog.styleKey == styleKey) {
        final matrix = catalogOrder.orderMatrix;
        for (var shade in quantities[styleKey]?.keys ?? []) {
          final shadeIndex = matrix.shades.indexOf(shade.toString().trim());
          if (shadeIndex == -1) {
            debugPrint('Shade not found: $shade');
            continue;
          }
          for (var size in quantities[styleKey]![shade]!.keys) {
            final sizeIndex = matrix.sizes.indexOf(size.trim());
            if (sizeIndex == -1) {
              debugPrint('Size not found: $size');
              continue;
            }
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

  Widget buildOrderItem(CatalogOrderData catalogOrder) {
    final catalog = catalogOrder.catalog;
    if (!selectedColors2.containsKey(catalog.styleKey)) {
      final shades = catalog.shadeName.split(',').map((s) => s.trim()).toList();
      selectedColors2[catalog.styleKey] = shades.isNotEmpty ? shades[0] : '';
      quantities[catalog.styleKey] ??= {};
      if (shades.isNotEmpty) {
        quantities[catalog.styleKey]!.putIfAbsent(shades[0], () => {});
      }
    }
    String selectedColor = selectedColors2[catalog.styleKey]!;

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
                  errorBuilder:
                      (context, error, stackTrace) =>
                          const Icon(Icons.error, size: 60),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                    icon: const Icon(
                                      Icons.copy,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () async {
                                      setState(() {
                                        _copiedShades.add(
                                          '${catalog.styleKey}:$selectedColor',
                                        );
                                      });

                                      final result = await showDialog<
                                          Map<String, dynamic>
                                      >(
                                        context: context,
                                        builder:
                                            (context) => CopyToStylesDialog(
                                              catalogOrders:
                                                  catalogOrderList
                                                      .where(
                                                        (order) =>
                                                            order
                                                                .catalog
                                                                .styleKey !=
                                                            catalog.styleKey,
                                                      )
                                                      .toList(),
                                              sourceStyleKey: catalog.styleKey,
                                              sourceStyleCode:
                                                  catalog.styleCode,
                                              sourceShade: selectedColor,
                                              sourceShades:
                                                  catalog.shadeName
                                                      .split(',')
                                                      .map((s) => s.trim())
                                                      .toList(),
                                            ),
                                      );

                                      if (result != null) {
                                        if (result['option'] ==
                                            'copy_shades') {
                                          final selectedShades =
                                              result['selectedShades']
                                                  as Set<String>;
                                          _copyShadesToOtherStyles(
                                            catalog.styleKey,
                                            selectedShades,
                                          );
                                        } else if (result['option'] ==
                                            'copy_shade_to_styles') {
                                          final targetStyles =
                                              result['targetStyles']
                                                  as Map<String, Set<String>>;
                                          if (targetStyles.isNotEmpty) {
                                            _copyStyleQuantities(
                                              catalog.styleKey,
                                              selectedColor,
                                              targetStyles,
                                            );
                                          } else {
                                            setState(() {
                                              _copiedShades.remove(
                                                '${catalog.styleKey}:$selectedColor',
                                              );
                                            });
                                          }
                                        }
                                      } else {
                                        setState(() {
                                          _copiedShades.remove(
                                            '${catalog.styleKey}:$selectedColor',
                                          );
                                        });
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Confirm Delete'),
                                            content: Text(
                                              'Are you sure you want to delete "${catalog.styleCode}"?',
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text('Cancel'),
                                                onPressed: () {
                                                  Navigator.of(
                                                    context,
                                                  ).pop(); // Close the dialog
                                                },
                                              ),
                                              TextButton(
                                                child: Text('Delete'),
                                                onPressed: () {
                                                  Navigator.of(
                                                    context,
                                                  ).pop(); // Close the dialog
                                                  _deleteStyle(
                                                    catalog.styleKey,
                                                  ); // Perform delete
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
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
                            'Total Price: ₹${_calculateCatalogPrice(catalog.styleKey).toStringAsFixed(2)}',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.green,
                            ),
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
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Select Shade',
          style: GoogleFonts.lora(fontWeight: FontWeight.normal),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children:
              catalog.shadeName.split(',').map((color) {
                final trimmedColor = color.trim();
                final isSelected = selectedColor == trimmedColor;
                final isCopySelected = _copiedShades.contains(
                  '${catalog.styleKey}:$trimmedColor',
                );

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColors2[catalog.styleKey] = trimmedColor;
                      quantities[catalog.styleKey] ??= {};
                      quantities[catalog.styleKey]!.putIfAbsent(
                        trimmedColor,
                        () => {},
                      );
                    });
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.black,
                          ),
                        ),
                        child: Text(
                          trimmedColor,
                          style: GoogleFonts.roboto(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      if (isCopySelected)
                        Positioned(
                          top: -8,
                          right: -8,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 15),
        if (selectedColor.isNotEmpty)
          _buildColorSection(catalogOrder, selectedColor),
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
        catalogOrder.catalog.shadeName.split(',').map((s) => s.trim()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  shade,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: _getColorCode(shade.trim()),
                  ),
                ),
                const SizedBox(width: 5),
                IconButton(
                  icon: const Icon(
                    Icons.copy_all_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => ShadeSelectionDialog(
                        shades: allShades,
                        sourceShade: shade,
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        if (result['option'] == 'all_sizes') {
                          _copyShadeToAllSizes(
                            styleKey,
                            shade,
                            sizes,
                          );
                        } else if (result['option'] == 'other_shades') {
                          final selectedShades = result['selectedShades'] as Set<String>;
                          // Clear existing copied shades for this style
                          _copiedShades.removeWhere(
                            (s) => s.startsWith('$styleKey:'),
                          );
                          // Add selected shades
                          for (var s in selectedShades) {
                            _copiedShades.add('$styleKey:$s');
                          }
                          // Copy quantities to selected shades
                          final currentQuantities =
                              quantities[styleKey]?[shade] ?? {};
                          for (var targetShade in selectedShades) {
                            if (targetShade != shade) {
                              quantities[styleKey]!.putIfAbsent(
                                targetShade,
                                () => {},
                              );
                              quantities[styleKey]![targetShade]!.clear();
                              currentQuantities.forEach((size, quantity) {
                                quantities[styleKey]![targetShade]![size] =
                                    quantity;
                                final controllerKey =
                                    '$styleKey-$targetShade-$size';
                                if (_controllers.containsKey(controllerKey)) {
                                  _controllers[controllerKey]!.text =
                                      quantity.toString();
                                }
                              });
                            }
                          }
                        }
                      });
                    }
                  },
                ),
              ],
            ),
            Text(
              'Quantity: ${_calculateShadeQuantity(catalogOrder.catalog.styleKey, shade)}',
              style: GoogleFonts.roboto(),
            ),
            Row(
              children: [
                Text('Price: ', style: GoogleFonts.roboto()),
                Text(
                  '₹${_calculateShadePrice(catalogOrder, shade).toStringAsFixed(2)}',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
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
                _buildSizeRow(catalogOrder, shade, size.toString()),
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
    for (var size in quantities[styleKey]?[shade.trim()]?.keys ?? []) {
      total += quantities[styleKey]![shade.trim()]![size]!;
    }
    return total;
  }

  double _calculateShadePrice(CatalogOrderData catalogOrder, String shade) {
    double total = 0;
    final styleKey = catalogOrder.catalog.styleKey;
    final matrix = catalogOrder.orderMatrix;
    final shadeIndex = matrix.shades.indexOf(shade.trim());
    if (shadeIndex == -1) {
      debugPrint('Shade not found: $shade');
      return total;
    }
    for (var size in quantities[styleKey]?[shade.trim()]?.keys ?? []) {
      final sizeIndex = matrix.sizes.indexOf(size.toString().trim());
      if (sizeIndex == -1) {
        debugPrint('Size not found: $size');
        continue;
      }
      final rate =
          double.tryParse(matrix.matrix[shadeIndex][sizeIndex].split(',')[0]) ??
          0;
      final quantity = quantities[styleKey]![shade.trim()]![size]!;
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
    } else {
      debugPrint('Invalid shade or size: shade=$shade, size=$size');
    }

    final quantity = _getQuantity(styleKey, shade, size);
    final controllerKey = '$styleKey-${shade.trim()}-$size';
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
                    controller.text =
                        _getQuantity(styleKey, shade, size).toString();
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
                      LengthLimitingTextInputFormatter(5),
                    ],
                    onChanged: (value) {
                      final newQuantity =
                          int.tryParse(value.isEmpty ? '0' : value) ?? 0;
                      _setQuantity(styleKey, shade, size, newQuantity);
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _setQuantity(styleKey, shade, size, quantity + 1);
                    controller.text =
                        _getQuantity(styleKey, shade, size).toString();
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
  bool _isAllSizesChecked = false;
  bool _showShadeSelection = false;
  final Set<String> _selectedShades = {};

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
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Select an option:',
                style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
              ),
            ),
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
                  onChanged: shade == widget.sourceShade
                      ? null
                      : (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedShades.add(shade);
                            } else {
                              _selectedShades.remove(shade);
                            }
                          });
                        },
                  enabled: shade != widget.sourceShade,
                  controlAffinity: ListTileControlAffinity.leading,
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
  final List<CatalogOrderData> catalogOrders;
  final String sourceStyleKey;
  final String sourceStyleCode;
  final String sourceShade;
  final List<String> sourceShades;

  const CopyToStylesDialog({
    Key? key,
    required this.catalogOrders,
    required this.sourceStyleKey,
    required this.sourceStyleCode,
    required this.sourceShade,
    required this.sourceShades,
  }) : super(key: key);

  @override
  _CopyToStylesDialogState createState() => _CopyToStylesDialogState();
}

class _CopyToStylesDialogState extends State<CopyToStylesDialog> {
  bool _isCopyShadesChecked = false;
  bool _showStyleSelection = false;
  final Map<String, Set<String>> _selectedShadesPerStyle = {};
  final Set<String> _selectedSourceShades = {};

  @override
  void initState() {
    super.initState();
    // Initialize with all shades selected by default for each style
    for (var order in widget.catalogOrders) {
      _selectedShadesPerStyle[order.catalog.styleKey] =
          order.catalog.shadeName.split(',').map((s) => s.trim()).toSet();
    }
    // Initialize source shades as all selected by default
    _selectedSourceShades.addAll(widget.sourceShades);
  }

  Future<void> _showShadeSelectionDialog(
    String styleKey,
    List<String> shades,
  ) async {
    final tempSelectedShades = Set<String>.from(
      _selectedShadesPerStyle[styleKey] ?? {},
    );

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Shades for $styleKey'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: shades.map((shade) {
                  return CheckboxListTile(
                    title: Text(shade),
                    value: tempSelectedShades.contains(shade),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          tempSelectedShades.add(shade);
                        } else {
                          tempSelectedShades.remove(shade);
                        }
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, tempSelectedShades),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _selectedShadesPerStyle[styleKey] = result;
      });
    }
  }

  Future<void> _showSourceShadeSelectionDialog() async {
    final tempSelectedShades = Set<String>.from(_selectedSourceShades);

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Shades for ${widget.sourceStyleCode}'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.sourceShades.map((shade) {
                  return CheckboxListTile(
                    title: Text(shade),
                    value: tempSelectedShades.contains(shade),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          tempSelectedShades.add(shade);
                        } else {
                          tempSelectedShades.remove(shade);
                        }
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, tempSelectedShades),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _selectedSourceShades.clear();
        _selectedSourceShades.addAll(result);
      });
    }
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
                'Copying from: ${widget.sourceStyleCode} (${widget.sourceShade})',
                style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
              ),
            ),
            if (!_showStyleSelection) ...[
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
                    'Copy shade and size quantities to other styles',
                    style: GoogleFonts.roboto(),
                  ),
                  value: _isCopyShadesChecked,
                  onChanged: (bool? value) {
                    setState(() {
                      _isCopyShadesChecked = value ?? false;
                    });
                  },
                ),
              ),
              if (_isCopyShadesChecked)
                GestureDetector(
                  onTap: _showSourceShadeSelectionDialog,
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
                            'Selected shades: ${_selectedSourceShades.join(', ')}',
                            style: GoogleFonts.roboto(),
                          ),
                        ),
                        Icon(Icons.edit, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              if (!_isCopyShadesChecked)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showStyleSelection = true;
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
                            'Copy quantities of "${widget.sourceShade}" to other styles and shades',
                            style: GoogleFonts.roboto(),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
            ],
            if (_showStyleSelection) ...[
              const Divider(),
              ...widget.catalogOrders.map((order) {
                final styleKey = order.catalog.styleKey;
                final styleCode = order.catalog.styleCode;
                final shades =
                    order.catalog.shadeName.split(',').map((s) => s.trim()).toList();

                return ListTile(
                  title: Text(styleCode, style: GoogleFonts.roboto()),
                  subtitle: Text(
                    _selectedShadesPerStyle[styleKey]?.join(', ') ??
                        'No shades selected',
                    style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showShadeSelectionDialog(styleKey, shades),
                      ),
                      Checkbox(
                        value: _selectedShadesPerStyle[styleKey]?.isNotEmpty ?? false,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedShadesPerStyle[styleKey] = shades.toSet();
                            } else {
                              _selectedShadesPerStyle[styleKey] = {};
                            }
                          });
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.montserrat()),
        ),
        TextButton(
          onPressed: () {
            if (_isCopyShadesChecked && !_showStyleSelection) {
              Navigator.pop(context, {
                'option': 'copy_shades',
                'selectedShades': _selectedSourceShades,
              });
            } else if (_showStyleSelection) {
              // Filter out styles with no selected shades
              final result = Map<String, Set<String>>.from(
                _selectedShadesPerStyle,
              )..removeWhere((key, value) => value.isEmpty);
              Navigator.pop(context, {
                'option': 'copy_shade_to_styles',
                'targetStyles': result,
              });
            }
          },
          child: Text('OK', style: GoogleFonts.montserrat()),
        ),
      ],
    );
  }
}