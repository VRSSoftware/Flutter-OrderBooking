import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vrs_erp/OrderBooking/orderbooking_booknow.dart';
import 'package:vrs_erp/catalog/imagezoom.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/CartModel.dart';
import 'package:vrs_erp/models/CatalogOrderData.dart';
import 'package:vrs_erp/models/OrderMatrix.dart';
import 'package:vrs_erp/models/catalog.dart';

class CreateOrderScreen extends StatefulWidget {
  final List<Catalog> catalogs;
  final VoidCallback onSuccess;
  final Map<String, dynamic>? routeArguments;
  const CreateOrderScreen({
    Key? key,
    required this.catalogs,
    required this.onSuccess,
    this.routeArguments,
  }) : super(key: key);

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  List<CatalogOrderData> catalogOrderList = [];
  Map<String, Set<String>> selectedColors2 = {};
  Map<String, Map<String, Map<String, int>>> quantities = {};
  bool isLoading = true;
  final Map<String, TextEditingController> _controllers = {};
  List<CatalogOrderData> filteredCatalogOrderList = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
    _searchController.addListener(_filterSearchResults);
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    _searchController.removeListener(_filterSearchResults); // ADD THIS LINE
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ADD THIS NEW METHOD
  void _filterSearchResults() {
    if (_searchController.text.isEmpty) {
      setState(() {
        filteredCatalogOrderList = List.from(catalogOrderList);
      });
    } else {
      String searchTerm = _searchController.text.toLowerCase().trim();
      setState(() {
        filteredCatalogOrderList =
            catalogOrderList.where((order) {
              return order.catalog.styleCode.toLowerCase().contains(searchTerm);
            }).toList();
      });
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
        "userId": UserSession.userName ?? '',
        "coBrId": UserSession.coBrId ?? '',
        "fcYrId": UserSession.userFcYr ?? '',
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
      filteredCatalogOrderList = List.from(tempList);
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
                // Style code highlight
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
            // Side-by-side buttons
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
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith<Color?>((
                        states,
                      ) {
                        if (states.contains(WidgetState.pressed)) {
                          return Colors.red.shade700;
                        }
                        return null;
                      }),
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
              final matrixData = matrix.matrix[shadeIndex][sizeIndex].split(
                ',',
              );
              final payload = {
                "userId": UserSession.userName ?? '',
                "coBrId": UserSession.coBrId ?? '',
                "fcYrId": UserSession.userFcYr ?? '',
                "data": {
                  "designcode": styleCode,
                  "mrp": matrixData[0],
                  "WSP": matrixData.length > 2 ? matrixData[2] : matrixData[0],
                  "size": size,
                  "TotQty":
                      _calculateCatalogQuantity(catalog.styleKey).toString(),
                  "Note": "",
                  "color": shade,
                  "Qty": quantity.toString(),
                  "cobrid": UserSession.coBrId ?? '',
                  "user": "admin",
                  "barcode": "",
                },
                "typ": 0,
              };

              apiCalls.add(
                http.post(
                  Uri.parse(
                    '${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails',
                  ),
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
          builder:
              (_) => AlertDialog(
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
            if (responseBody is Map<String, dynamic> &&
                responseBody['success'] == true) {
              successfulStyles.add(apiCallStyles[i]);
              cartModel.addItem(apiCallStyles[i]);
            }
          } catch (e) {
            // Handle plain text "Success" response
            if (response.body.trim() == "Success") {
              successfulStyles.add(apiCallStyles[i]);
              cartModel.addItem(apiCallStyles[i]);
            } else {
              print(
                'Failed to parse response for style ${apiCallStyles[i]}: $e, response: ${response.body}',
              );
            }
          }
        } else {
          print(
            'API call failed for style ${apiCallStyles[i]}: ${response.statusCode}, response: ${response.body}',
          );
        }
      }

      if (successfulStyles.isNotEmpty) {
        cartModel.updateCount(cartModel.count + successfulStyles.length);
        widget.onSuccess();

        if (mounted) {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text("Success"),
                  content: Text(
                    "Successfully submitted ${successfulStyles.length} item${successfulStyles.length > 1 ? 's' : ''}",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        
                        Navigator.pop(context);
                        Navigator.pop(context);
                        // Navigator.pushReplacement(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => OrderPage(),
                        //     settings: RouteSettings(
                        //       arguments: widget.routeArguments,
                        //     ),
                        //   ),
                        // );
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
            builder:
                (_) => AlertDialog(
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axis: Axis.horizontal,
                child: child,
              ),
            );
          },
          child:
              _isSearching
                  ? Container(
                    key: const ValueKey("search"),
                    height: 36, // smaller height
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25), // smooth curve
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Search by Style Code...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _isSearching = false;
                            });
                          },
                        ),
                      ),
                    ),
                  )
                  : Text(
                    'Order Booking',
                    key: const ValueKey("title"),
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
        ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });

                Future.delayed(const Duration(milliseconds: 200), () {
                  _searchFocusNode.requestFocus();
                });
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            40.0,
          ), // Increased height to accommodate content
          child: Container(
            color: AppColors.maroon, // Maroon background color
            child: Column(
              children: [
                const Divider(
                  color:
                      Colors
                          .white30, // Lighter divider color for better visibility
                  height: 1,
                  thickness: 1,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        'Total: ₹${_calculateTotalPrice().toStringAsFixed(2)}',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(height: 20, width: 1, color: Colors.white30),
                      Text(
                        'Total Item: ${filteredCatalogOrderList.length}',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(height: 20, width: 1, color: Colors.white30),
                      Text(
                        'Total Qty: ${_calculateTotalQuantity()}',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
      body: SafeArea(
        child:
            isLoading
                ? Stack(
                  children: [
                    Container(color: Colors.black.withOpacity(0.2)),
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          //   vertical: 12,
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
                : CustomScrollView(
                  slivers: [
                    ...filteredCatalogOrderList.map(
                      (catalogOrder) => _buildStickySection(catalogOrder),
                    ),
                  ],
                ),
        // : SingleChildScrollView(
        //   padding: const EdgeInsets.all(12.0),
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       const SizedBox(height: 10),
        //       ...filteredCatalogOrderList.map(
        //         // CHANGED THIS LINE
        //         (catalogOrder) => Column(
        //           children: [
        //             buildOrderItem(catalogOrder),
        //             const Divider(),
        //           ],
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ),
      bottomNavigationBar: SafeArea(
        child: SizedBox(
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 227, 238, 243),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'BACK',
                    style: GoogleFonts.montserrat(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor:
                        _calculateTotalQuantity() > 0
                            ? AppColors.primaryColor
                            : Colors.grey.shade300,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed:
                      _calculateTotalQuantity() > 0 ? _submitAllOrders : null,
                  child: Text(
                    'SAVE',
                    style: GoogleFonts.montserrat(
                      color:
                          _calculateTotalQuantity() > 0
                              ? Colors.white
                              : AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
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

  Widget _buildStickySection(CatalogOrderData catalogOrder) {
    final catalog = catalogOrder.catalog;
    final selectedColors = selectedColors2[catalog.styleKey] ?? {};

    return SliverMainAxisGroup(
      slivers: [
        /// 🔥 THIS IS YOUR STICKY CARD
        SliverPersistentHeader(
          pinned: true,
          delegate: _CardHeaderDelegate(
            child: buildOrderCardOnly(catalogOrder),
            height: 140, // adjust based on your card height
          ),
        ),

        /// 👇 SCROLLABLE COLOR ITEMS
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final color = selectedColors.elementAt(index);
            return Column(
              children: [
                _buildColorSection(catalogOrder, color),
                const SizedBox(height: 12),
              ],
            );
          }, childCount: selectedColors.length),
        ),
      ],
    );
  }

  Widget buildOrderCardOnly(CatalogOrderData catalogOrder) {
    final catalog = catalogOrder.catalog;
    final Set<String> selectedColors = selectedColors2[catalog.styleKey] ?? {};

    final imageUrl =
        catalog.fullImagePath.contains("http")
            ? catalog.fullImagePath
            : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}';

    return Container(
      color: Colors.white, // IMPORTANT for sticky
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                AppColors.primaryColor.withOpacity(0.03),
                AppColors.primaryColor.withOpacity(0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 Product Image
                Material(
                  borderRadius: BorderRadius.circular(8),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
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
                    child: Container(
                      width: 70,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade50, Colors.grey.shade100],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                color: Colors.grey.shade100,
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey.shade400,
                                  size: 30,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                /// 🔹 Details Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Style Code + Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          /// Style Code
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
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
                                color: AppColors.primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              catalog.styleCode,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),

                          /// Actions
                          Row(
                            children: [
                              /// Copy
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
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primaryColor.withOpacity(
                                            0.15,
                                          ),
                                          AppColors.primaryColor.withOpacity(
                                            0.05,
                                          ),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primaryColor
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.copy,
                                      size: 16,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              /// Delete
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
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.red.withOpacity(0.15),
                                          Colors.red.withOpacity(0.05),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.delete,
                                      size: 16,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// Qty / Pending / WIP
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            /// Qty
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.shopping_bag,
                                label: 'Qty',
                                value:
                                    '${_calculateCatalogQuantity(catalog.styleKey)}',
                                color: Colors.green,
                              ),
                            ),

                            _divider(),

                            /// Pending
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.pending,
                                label: 'Pending',
                                value: '0',
                                color: Colors.orange,
                              ),
                            ),

                            _divider(),

                            /// WIP
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.inventory,
                                label: 'WIP',
                                value: '0',
                                color: Colors.blue,
                              ),
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
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 4),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 9, color: Colors.grey)),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 30, color: Colors.grey.shade300);
  }

  Widget buildOrderItem(CatalogOrderData catalogOrder) {
    final catalog = catalogOrder.catalog;
    final Set<String> selectedColors = selectedColors2[catalog.styleKey] ?? {};

    final imageUrl =
        catalog.fullImagePath.contains("http")
            ? catalog.fullImagePath
            : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  AppColors.primaryColor.withOpacity(0.03),
                  AppColors.primaryColor.withOpacity(0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Product Image with improved styling
                  Material(
                    borderRadius: BorderRadius.circular(8),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
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
                      child: Container(
                        width: 70,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          gradient: LinearGradient(
                            colors: [Colors.grey.shade50, Colors.grey.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.network(
                            imageUrl,
                            width: 70,
                            height: 90,
                            fit: BoxFit.contain,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  width: 70,
                                  height: 90,
                                  color: Colors.grey.shade100,
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey.shade400,
                                    size: 30,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// Details Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        /// Style Code + Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            /// Style Code Chip - Improved design with gradient
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryColor.withOpacity(0.15),
                                    AppColors.primaryColor.withOpacity(0.08),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primaryColor.withOpacity(
                                    0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                catalog.styleCode,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),

                            /// Action Buttons Row
                            Row(
                              children: [
                                /// Copy Button with Material design and gradient
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
                                              sourceStyleCode:
                                                  catalog.styleCode,
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
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primaryColor.withOpacity(
                                              0.15,
                                            ),
                                            AppColors.primaryColor.withOpacity(
                                              0.05,
                                            ),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.primaryColor
                                              .withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.copy,
                                        size: 16,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                /// Delete Button with Material design and gradient
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
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.red.withOpacity(0.15),
                                            Colors.red.withOpacity(0.05),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.delete,
                                        size: 16,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        /// Qty, Pending, WIP in same line
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              /// Quantity
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.shopping_bag,
                                        size: 12,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Qty',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          '${_calculateCatalogQuantity(catalog.styleKey)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              /// Vertical Divider
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.grey.shade300,
                              ),

                              /// Pending
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.pending,
                                        size: 12,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Pending',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          '0',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              /// Vertical Divider
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.grey.shade300,
                              ),

                              /// WIP
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
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
                                    const SizedBox(width: 4),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'WIP',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          '0',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        //  const SizedBox(height: 10),

        /// Color Sections
        ...selectedColors.map(
          (color) => Column(
            children: [
              _buildColorSection(catalogOrder, color),
              const SizedBox(height: 12),
            ],
          ),
        ),

        const SizedBox(height: 10),
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

    // Debug print to see what's available
    print('Building color section for shade: $shade');
    print('Catalog shadeImages: ${catalogOrder.catalog.shadeImages}');

    final imageUrl = _getShadeImageUrl(catalogOrder.catalog, shade);
    print('Image URL for $shade: $imageUrl');
    print('Should show icon: ${imageUrl != null}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              // Header row with Shade text and copy icon
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
                          vertical: 8.0,
                          horizontal: 12.0,
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
                              "SHADE",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lora(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Copy icon with Material design
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  final result =
                                      await showDialog<Map<String, dynamic>>(
                                        context: context,
                                        builder:
                                            (context) => ShadeSelectionDialog(
                                              shades:
                                                  allShades
                                                      .where((s) => s != shade)
                                                      .toList(),
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
                                    } else if (result['option'] ==
                                        'other_shades') {
                                      final selectedShades =
                                          result['selectedShades']
                                              as Set<String>;
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
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor.withOpacity(
                                      0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.copy_all,
                                    size: 14,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildHeader("QUANTITY", 1),
                    _buildHeader("AMOUNT", 1),
                  ],
                ),
              ),

              Divider(height: 1, color: Colors.grey.shade300),

              // Shade value row with image icon
              Container(
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 12.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Shade name
                            Expanded(
                              child: Text(
                                shade,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: _getColorCode(shade),
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            // Always show a container for debugging
                            if (UserSession.imageDependsOn == 'S')
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap:
                                        imageUrl != null
                                            ? () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          ImageZoomScreen(
                                                            imageUrls: [
                                                              imageUrl,
                                                            ],
                                                            initialIndex: 0,
                                                          ),
                                                ),
                                              );
                                            }
                                            : null,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color:
                                            imageUrl != null
                                                ? AppColors.primaryColor
                                                    .withOpacity(0.1)
                                                : Colors.red.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.image,
                                        size: 16,
                                        color:
                                            imageUrl != null
                                                ? AppColors.primaryColor
                                                : Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
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
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 8.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          '₹${_calculateShadePrice(catalogOrder, shade).toStringAsFixed(0)}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
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
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(vertical: 4),
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
            ],
          ),
        ),
      ],
    );
  }

  String? _getShadeImageUrl(Catalog catalog, String shadeName) {
    if (catalog.shadeImages.isEmpty) {
      print('shadeImages is empty');
      return null;
    }

    print('Raw shadeImages: "${catalog.shadeImages}"');
    print('Looking for shade: "$shadeName"');

    // Clean the shade name
    final cleanShadeName = shadeName.trim().toLowerCase();

    // Try different parsing approaches
    String shadeImagesStr = catalog.shadeImages;

    // Approach 1: Split by ', ' first
    List<String> entries = shadeImagesStr.split(', ');

    // Approach 2: If that gives only one item but there are commas, try split by ','
    if (entries.length == 1 && shadeImagesStr.contains(',')) {
      entries = shadeImagesStr.split(',');
    }

    print('Entries after split: $entries');

    for (var entry in entries) {
      entry = entry.trim();
      if (entry.isEmpty) continue;

      print('Processing entry: "$entry"');

      // Find the first colon
      final colonIndex = entry.indexOf(':');
      if (colonIndex > 0) {
        final shade = entry.substring(0, colonIndex).trim().toLowerCase();
        final imageUrl = entry.substring(colonIndex + 1).trim();

        print('  Extracted shade: "$shade", URL: "$imageUrl"');

        if (shade == cleanShadeName) {
          print('  ✓ Match found!');
          return imageUrl;
        } else {
          print('  ✗ No match (shade: "$shade" vs "$cleanShadeName")');
        }
      } else {
        print('  No colon found in entry');
      }
    }

    print('No matching shade found for: $shadeName');
    return null;
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
      final rate =
          double.tryParse(matrix.matrix[shadeIndex][sizeIndex].split(',')[0]) ??
          0;
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
                      LengthLimitingTextInputFormatter(4),
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

class _CardHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _CardHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white, // 🔥 REQUIRED (prevents transparency bug)
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _CardHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
