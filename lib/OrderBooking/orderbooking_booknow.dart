import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:vrs_erp/OrderBooking/booking2/booking2.dart';
import 'package:vrs_erp/OrderBooking/booking2/booking3.dart';
import 'package:vrs_erp/OrderBooking/booking2/multipleorderbooking.dart';
import 'package:vrs_erp/catalog/dotIndicatorDesign.dart';
import 'package:vrs_erp/catalog/filter.dart';
import 'package:vrs_erp/catalog/imagezoom.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/constants/constants.dart';
import 'package:vrs_erp/models/CartModel.dart';
import 'package:vrs_erp/models/PartyWithSpclMarkDwn.dart';
import 'package:vrs_erp/models/brand.dart';
import 'package:vrs_erp/models/catalog.dart';
import 'package:vrs_erp/models/shade.dart';
import 'package:vrs_erp/models/size.dart';
import 'package:vrs_erp/models/style.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/widget/booknowwidget.dart';

class OrderPage extends StatefulWidget {
  final String? itemKey;
  final String? itemSubGrpKey;
  final String? itemName;
  final String? coBr;
  final String? fcYrId;
  final PartyWithSpclMarkDwn? selectedParty;
  final String? type;
  final String? transactionType;
  final bool isMultiSelect;
  final bool isEdit;

  const OrderPage({
    Key? key,
    this.itemKey,
    this.itemSubGrpKey,
    this.itemName,
    this.coBr,
    this.fcYrId,
    this.selectedParty,
    this.type,
    this.transactionType,
    this.isMultiSelect = false,
    this.isEdit = false,
  }) : super(key: key);

  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  int viewOption = 1;
  List<Style> selectedStyles = [];
  List<Shade> selectedShades = [];
  List<Sizes> selectedSize = [];
  List<Catalog> catalogItems = [];
  List<Style> styles = [];
  List<Shade> shades = [];
  List<Sizes> sizes = [];
  String? itemKey;
  String? itemSubGrpKey;
  String? coBr;
  String? fcYrId;
  String fromMRP = "";
  String toMRP = "";
  String WSPfrom = "";
  String WSPto = "";
  String sortBy = "";
  bool isLoading = true;
  List<Catalog> selectedItems = [];
  bool showSizes = true;
  bool showProduct = true;
  List<Brand> brands = [];
  int pageNo = 1;
  bool hasMore = true;
  bool isLoadingMore = false;
  bool hasError = false;
  String? errorMessage;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  final int pageSize = 10;
  String fromDate = "";
  String toDate = "";
  List<Brand> selectedBrands = [];
  bool isEdit = false;
  String itemNamee = '';
  PartyWithSpclMarkDwn? selectedParty;
  String? name;
  String? type;
  String? transactionType;

  String? stockFilter;
  String? imageFilter;

  // @override
  // void initState() {
  //   super.initState();
  //   _scrollController.addListener(_scrollListener);
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     final args =
  //         ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

  //     if (args != null) {
  //       setState(() {
  //         itemKey = args['itemKey']?.toString();
  //         itemSubGrpKey = args['itemSubGrpKey']?.toString();
  //         coBr = UserSession.coBrId;
  //         fcYrId = UserSession.userFcYr;
  //         itemNamee = args['itemName']?.toString() ?? '';
  //         isEdit = args['edit'] ?? false;
  //         selectedParty = args['selectedParty'];
  //         type = args['type'];
  //         transactionType = args[Constants.TRANSACTION_TYPE];
  //       });

  //       if (coBr != null && fcYrId != null) {
  //         if (!isEdit) {
  //           _fetchCartCount();
  //         }
  //       }

  //       if (itemSubGrpKey != null && coBr != null) {
  //         _fetchCatalogItems();
  //       }

  //       if (itemKey != null) {
  //         _fetchStylesByItemKey(itemKey!);
  //         _fetchShadesByItemKey(itemKey!);
  //         _fetchStylesSizeByItemKey(itemKey!);
  //         _fetchBrands();
  //       } else if (itemSubGrpKey != null) {
  //         _fetchStylesByItemGrpKey(itemSubGrpKey!);
  //         _fetchShadesByItemGrpKey(itemSubGrpKey!);
  //         _fetchStylesSizeByItemGrpKey(itemSubGrpKey!);
  //         _fetchBrands();
  //       }
  //     }
  //   });
  // }
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    itemKey = widget.itemKey;
    itemSubGrpKey = widget.itemSubGrpKey;
    coBr = widget.coBr ?? UserSession.coBrId;
    fcYrId = widget.fcYrId ?? UserSession.userFcYr;
    itemNamee = widget.itemName ?? '';
    isEdit = widget.isEdit;
    selectedParty = widget.selectedParty;
    type = widget.type;
    transactionType = widget.transactionType;

    if (coBr != null && fcYrId != null) {
      if (!isEdit) {
        _fetchCartCount();
      }
    }

    if (itemSubGrpKey != null && coBr != null) {
      _fetchCatalogItems();
    }

    if (itemKey != null) {
      _fetchStylesByItemKey(itemKey!);
      _fetchShadesByItemKey(itemKey!);
      _fetchStylesSizeByItemKey(itemKey!);
      _fetchBrands();
    } else if (itemSubGrpKey != null) {
      _fetchStylesByItemGrpKey(itemSubGrpKey!);
      _fetchShadesByItemGrpKey(itemSubGrpKey!);
      _fetchStylesSizeByItemGrpKey(itemSubGrpKey!);
      _fetchBrands();
    }
  }

  void _openImageZoom(List<String> imageUrls) {
    if (imageUrls.isEmpty || imageUrls[0].isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageZoomScreen(imageUrls: imageUrls),
      ),
    );
  }

  Future<void> _fetchStylesByItemGrpKey(String itemGrpKey) async {
    try {
      final fetchedStyles = await ApiService.fetchStylesByItemGrpKey(
        itemGrpKey,
      );
      setState(() {
        styles = fetchedStyles;
      });
    } catch (e) {
      print('Failed to load styles: $e');
    }
  }

  void _scrollListener() {
    if (_debounce?.isActive ?? false) return;
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMore &&
        !hasError) {
      _debounce = Timer(Duration(milliseconds: 300), () {
        setState(() {
          isLoadingMore = true;
          pageNo++;
        });
        _fetchCatalogItems();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchStylesSizeByItemGrpKey(String itemKey) async {
    try {
      if (itemKey != null) {
        final fetchedSizes = await ApiService.fetchStylesSizeByItemKey(itemKey);
        setState(() {
          sizes = fetchedSizes;
        });
      } else if (itemSubGrpKey != null) {
        final fetchedSizes = await ApiService.fetchStylesSizeByItemGrpKey(
          itemSubGrpKey!,
        );
        setState(() {
          sizes = fetchedSizes;
        });
      }
    } catch (e) {
      print('Failed to load sizes: $e');
    }
  }

  Future<void> _fetchShadesByItemGrpKey(String itemKey) async {
    try {
      final fetchedShades = await ApiService.fetchShadesByItemGrpKey(itemKey);
      setState(() {
        shades = fetchedShades;
      });
    } catch (e) {
      print('Failed to load shades: $e');
    }
  }

  Future<void> _fetchBrands() async {
    try {
      brands = await ApiService.fetchBrands();
      setState(() {});
    } catch (e) {
      print('Failed to load brands: $e');
    }
  }

  void _toggleItemSelection(Catalog item) {
    final cartModel = Provider.of<CartModel>(context, listen: false);
    if (cartModel.addedItems.contains(item.styleCode)) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Item Already Booked'),
              content: Text(
                'The item "${item.styleCodeWithcount}" is already in your cart.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    setState(() {
      if (selectedItems.contains(item)) {
        selectedItems.remove(item);
      } else {
        selectedItems.add(item);
      }
    });
    debugPrint('Selected items: ${selectedItems.length}');
  }

  Future<void> _fetchCartCount() async {
    try {
      final data = await ApiService.getSalesOrderData(
        coBrId: UserSession.coBrId ?? '',
        userId: UserSession.userName ?? '',
        fcYrId: UserSession.userFcYr ?? '',
        barcode: '',
      );
      if (!mounted) return;
      final cartModel = Provider.of<CartModel>(context, listen: false);
      cartModel.updateCount(data['cartItemCount'] ?? 0);
    } catch (e) {
      print('Error fetching cart count: $e');
    }
  }

  List<Catalog> _getFilteredItems() {
    return catalogItems;
  }

  Future<void> _fetchCatalogItems() async {
    try {
      if (pageNo == 1) {
        setState(() {
          isLoading = true;
          hasError = false;
          errorMessage = null;
        });
      } else {
        setState(() {
          isLoadingMore = true;
        });
      }

      final result = await ApiService.fetchCatalogItem(
        itemSubGrpKey: itemSubGrpKey!,
        itemKey: itemKey,
        cobr: coBr!,
        sortBy: sortBy,
        // styleKey: selectedStyles.length == 1 ? selectedStyles[0].styleKey : null,
        styleKey:
            selectedStyles.isEmpty
                ? null
                : selectedStyles.map((s) => s.styleKey).join(','),
        shadeKey:
            selectedShades.isEmpty
                ? null
                : selectedShades.map((s) => s.shadeKey).join(','),
        sizeKey:
            selectedSize.isEmpty
                ? null
                : selectedSize.map((s) => s.itemSizeKey).join(','),
        fromMRP: fromMRP.isEmpty ? null : fromMRP,
        toMRP: toMRP.isEmpty ? null : toMRP,
        fromDate: fromDate.isEmpty ? null : fromDate,
        toDate: toDate.isEmpty ? null : toDate,
        brandKey: selectedBrands.isEmpty ? null : selectedBrands[0].brandKey,
        stockFilter: stockFilter == "" ? null : stockFilter, // Add this
        imageFilter: imageFilter == "" ? null : imageFilter, // Add this
        pageNo: pageNo,
      );

      int status = result["statusCode"];
      final items = result["catalogs"] as List<Catalog>;

      bool fetchedHasMore = items.length >= pageSize;

      double? wspFrom = double.tryParse(WSPfrom);
      double? wspTo = double.tryParse(WSPto);

      List<Catalog> wspFilteredCatalogs = items;

      if (wspFrom != null && wspTo != null) {
        wspFilteredCatalogs =
            wspFilteredCatalogs
                .where(
                  (catalog) => catalog.wsp >= wspFrom && catalog.wsp <= wspTo,
                )
                .toList();
      } else if (wspFrom != null) {
        wspFilteredCatalogs =
            wspFilteredCatalogs
                .where((catalog) => catalog.wsp >= wspFrom)
                .toList();
      } else if (wspTo != null) {
        wspFilteredCatalogs =
            wspFilteredCatalogs
                .where((catalog) => catalog.wsp <= wspTo)
                .toList();
      }

      if (selectedStyles.isNotEmpty) {
        final selectedStyleKeys =
            selectedStyles.map((style) => style.styleKey).toSet();
        wspFilteredCatalogs =
            wspFilteredCatalogs
                .where(
                  (catalog) => selectedStyleKeys.contains(catalog.styleKey),
                )
                .toList();
      }

      setState(() {
        catalogItems.addAll(wspFilteredCatalogs);
        isLoading = false;
        isLoadingMore = false;
        hasMore = fetchedHasMore;
        hasError = false;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
        hasError = true;
        errorMessage = e.toString();
      });
      print('Failed to load catalog items: $e');
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      pageNo = 1;
      hasMore = true;
      catalogItems.clear();
      selectedItems.clear();
      hasError = false;
      errorMessage = null;
    });
    await _fetchCatalogItems();
  }

  Future<void> _fetchStylesByItemKey(String itemKey) async {
    try {
      final fetchedStyles = await ApiService.fetchStylesByItemKey(itemKey);
      setState(() {
        styles = fetchedStyles;
      });
    } catch (e) {
      print('Failed to load styles: $e');
    }
  }

  Future<void> _fetchShadesByItemKey(String itemKey) async {
    try {
      final fetchedShades = await ApiService.fetchShadesByItemKey(itemKey);
      setState(() {
        shades = fetchedShades;
      });
    } catch (e) {
      print('Failed to load shades: $e');
    }
  }

  Future<void> _fetchStylesSizeByItemKey(String itemKey) async {
    try {
      final fetchedSizes = await ApiService.fetchStylesSizeByItemKey(itemKey);
      setState(() {
        sizes = fetchedSizes;
      });
    } catch (e) {
      print('Failed to load sizes: $e');
    }
  }

  String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .toLowerCase()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final cartModel = Provider.of<CartModel>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          toTitleCase(
            (itemNamee == null || itemNamee.trim().isEmpty)
                ? 'Booking Items'
                : itemNamee,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        ),
        actions: [
          // Cart Icon with badge
          if (!isEdit) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      CupertinoIcons.cart_badge_plus,
                      color: Colors.white,
                      size: 20,
                    ),
                    if (cartModel.count > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${cartModel.count}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  String viewOrderRoute;

                  if (AppConstants.bookingType == "1") {
                    viewOrderRoute = '/viewOrder';
                  } else if (AppConstants.bookingType == "2") {
                    viewOrderRoute = '/viewOrder2';
                  } else {
                    viewOrderRoute = '/viewOrder'; // Default fallback
                  }

                  Navigator.pushNamed(
                    context,
                    viewOrderRoute,
                    arguments: {'mrkDown': selectedParty?.splMkDown ?? 0.00},
                  );
                  _fetchCartCount();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'View Cart',
              ),
            ),
          ],

          // View toggle button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                viewOption == 0
                    ? Icons.grid_on_rounded
                    : viewOption == 1
                    ? Icons.view_list_rounded
                    : Icons.expand_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  viewOption = (viewOption + 1) % 3;
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Change view',
            ),
          ),

    
       // More options button
Container(
  margin: const EdgeInsets.only(left: 4, right: 8),
  width: 40,
  height: 40,
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.15),
    shape: BoxShape.circle,
  ),
  child: IconButton(
    icon: const Icon(
      Icons.more_vert_rounded,
      color: Colors.white,
      size: 20,
    ),
    onPressed: () {
      // Create temporary variables with current values
      bool tempShowProduct = showProduct;
      bool tempShowSizes = showSizes;
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width > 600
                      ? 24.0
                      : 20.0,
                ),
                child: StatefulBuilder(
                  builder: (context, setStateDialog) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width > 600
                                  ? 600
                                  : 440,
                          minWidth: 320,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // Header with icon and title
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor
                                        .withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.tune_rounded,
                                    color: AppColors.primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Options",
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width >
                                                600
                                            ? 22
                                            : 18,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const Spacer(),
                                // Close button
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: Colors.grey.shade700,
                                      size: 18,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    padding: const EdgeInsets.all(6),
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Options
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide =
                                    constraints.maxWidth > 400;
                                return isWide
                                    ? Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              children: [
                                                _buildToggleRow(
                                                  "Show Product",
                                                  tempShowProduct,
                                                  (val) {
                                                    setStateDialog(() {
                                                      tempShowProduct = val;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              children: [
                                                _buildToggleRow(
                                                  "Show Size",
                                                  tempShowSizes,
                                                  (val) {
                                                    setStateDialog(() {
                                                      tempShowSizes = val;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          _buildToggleRow(
                                            "Show Size",
                                            tempShowSizes,
                                            (val) {
                                              setStateDialog(() {
                                                tempShowSizes = val;
                                              });
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                          _buildToggleRow(
                                            "Show Product",
                                            tempShowProduct,
                                            (val) {
                                              setStateDialog(() {
                                                tempShowProduct = val;
                                              });
                                            },
                                          ),
                                        ],
                                      );
                              },
                            ),

                            const SizedBox(height: 24),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.grey.shade700,
                                      side: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Apply the changes when button is pressed
                                      setState(() {
                                        showProduct = tempShowProduct;
                                        showSizes = tempShowSizes;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(
                                      'Apply',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    },
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(),
    tooltip: 'More options',
  ),
),
     
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 16.0 : 8.0,
                    vertical: 8.0,
                  ),
                  child:
                      isLoading
                          ? Center(
                            child: LoadingAnimationWidget.waveDots(
                              color: AppColors.primaryColor,
                              size: 30,
                            ),
                          )
                          : hasError
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  errorMessage ?? "Failed to load items",
                                  style: TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      hasError = false;
                                      pageNo = 1;
                                      catalogItems.clear();
                                    });
                                    _fetchCatalogItems();
                                  },
                                  child: Text("Retry"),
                                ),
                              ],
                            ),
                          )
                          : catalogItems.isEmpty
                          ? Center(child: Text("No Item Available"))
                          : LayoutBuilder(
                            builder: (context, constraints) {
                              if (viewOption == 0) {
                                return _buildGridView(
                                  constraints,
                                  isLargeScreen,
                                  isPortrait,
                                );
                              } else if (viewOption == 1) {
                                return _buildListView(
                                  constraints,
                                  isLargeScreen,
                                );
                              }
                              return _buildExpandedView(isLargeScreen);
                            },
                          ),
                ),
              ),
            ),
            _buildBottomButtons(isLargeScreen),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 40,
        ), // Add bottom padding to move it up
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            FloatingActionButton(
              onPressed: _showFilterDialog,
              backgroundColor:
                  _getActiveFilterCount() > 0
                      ? Colors.pink
                      : AppColors.primaryBlue,
              child: Icon(Icons.filter_alt, color: Colors.white),
              tooltip: 'Filter',
            ),
            if (_getActiveFilterCount() > 0)
              Positioned(
                right: 0,
                top: -5,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '${_getActiveFilterCount()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(
    BoxConstraints constraints,
    bool isLargeScreen,
    bool isPortrait,
  ) {
    final filteredItems = _getFilteredItems();
    final crossAxisCount =
        isPortrait
            ? (isLargeScreen ? 3 : 2)
            : (constraints.maxWidth ~/ 300).clamp(3, 4);

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: filteredItems.length + (isLoadingMore ? 1 : 0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: isLargeScreen ? 1.0 : 8.0,
        childAspectRatio: _getChildAspectRatio(constraints, isLargeScreen),
      ),
      itemBuilder: (context, index) {
        if (index == filteredItems.length && isLoadingMore) {
          return Center(child: CircularProgressIndicator());
        }
        final item = catalogItems[index];
        return GestureDetector(
          onTap: () => _toggleItemSelection(item),
          child: _buildItemCard(item, isLargeScreen),
        );
      },
    );
  }

  double _getChildAspectRatio(BoxConstraints constraints, bool isLargeScreen) {
    if (constraints.maxWidth > 1000) return isLargeScreen ? 0.35 : 0.4;
    if (constraints.maxWidth > 600) return isLargeScreen ? 0.4 : 0.45;
    return 0.42;
  }

  Widget _buildListView(BoxConstraints constraints, bool isLargeScreen) {
    final filteredItems = _getFilteredItems();
    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredItems.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredItems.length && isLoadingMore) {
          return Center(
            child: LoadingAnimationWidget.waveDots(
              color: AppColors.primaryColor,
              size: 30,
            ),
          );
        }
        final item = catalogItems[index];
        final isSelected = selectedItems.contains(item);
        final cartModel = Provider.of<CartModel>(context);
        final isAdded = cartModel.addedItems.contains(item.styleCode);

        return GestureDetector(
          onTap: () => _toggleItemSelection(item),
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: Card(
              elevation: isSelected ? 8 : 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              color: isSelected ? Colors.blue.shade50 : Colors.white,
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(isLargeScreen ? 12.0 : 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Replace the current image section (around line 326-348) with:
                        Flexible(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image section
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(0),
                                  topRight: Radius.circular(0),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final maxImageHeight =
                                        constraints.maxWidth * 1.2;
                                    final imageUrls = _getImageUrls(item);
                                    final ValueNotifier<int> currentImageIndex =
                                        ValueNotifier<int>(0);

                                    return ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: maxImageHeight,
                                      ),
                                      child:
                                          imageUrls.isNotEmpty &&
                                                  imageUrls[0].isNotEmpty
                                              ? Stack(
                                                children: [
                                                  GestureDetector(
                                                    onDoubleTap:
                                                        () => _openImageZoom(
                                                          imageUrls,
                                                        ),
                                                    child: SizedBox(
                                                      height: maxImageHeight,
                                                      width: double.infinity,
                                                      child: PageView.builder(
                                                        itemCount:
                                                            imageUrls.length,
                                                        onPageChanged: (index) {
                                                          currentImageIndex
                                                              .value = index;
                                                        },
                                                        itemBuilder: (
                                                          context,
                                                          index,
                                                        ) {
                                                          return _buildSingleImage(
                                                            imageUrls[index],
                                                            maxImageHeight,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  if (imageUrls.length > 1)
                                                    Positioned(
                                                      bottom: 8,
                                                      left: 0,
                                                      right: 0,
                                                      child: ValueListenableBuilder<
                                                        int
                                                      >(
                                                        valueListenable:
                                                            currentImageIndex,
                                                        builder: (
                                                          context,
                                                          index,
                                                          child,
                                                        ) {
                                                          return DotIndicator(
                                                            count:
                                                                imageUrls
                                                                    .length,
                                                            currentIndex: index,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                ],
                                              )
                                              : _buildSingleImage(
                                                '',
                                                maxImageHeight,
                                              ),
                                    );
                                  },
                                ),
                              ),

                              // Range text below the image
                              if (item.minMRP != null && item.maxMRP != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8.0,
                                    left: 4.0,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppColors.primaryColor
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          ' ${item.minMRP} - ${item.maxMRP}',
                                          style: TextStyle(
                                            fontSize: isLargeScreen ? 15 : 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        SizedBox(width: isLargeScreen ? 16 : 8),
                        Flexible(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(
                                  isLargeScreen ? 16 : 12,
                                ),
                                child: Table(
                                  columnWidths: const {
                                    0: IntrinsicColumnWidth(),
                                    1: FixedColumnWidth(8),
                                    2: FlexColumnWidth(),
                                  },
                                  defaultVerticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  children: [
                                    TableRow(
                                      children: [
                                        _buildLabelText('Design'),
                                        const Text(':'),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Text(
                                            item.styleCodeWithcount,
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: isLargeScreen ? 20 : 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    _buildSpacerRow(),
                                    TableRow(
                                      children: [
                                        _buildLabelText('MRP'),
                                        const Text(':'),
                                        Text(
                                          item.mrp.toStringAsFixed(2),
                                          style: _valueTextStyle(isLargeScreen),
                                        ),
                                      ],
                                    ),
                                    _buildSpacerRow(),
                                    // if (item.minMRP != null &&
                                    //     item.maxMRP != null)
                                    //   TableRow(
                                    //     children: [
                                    //       _buildLabelText('Range'),
                                    //       const Text(':'),
                                    //       Text(
                                    //         '${item.minMRP} - ${item.maxMRP}',
                                    //         style: _valueTextStyle(
                                    //           isLargeScreen,
                                    //         ),
                                    //       ),
                                    //     ],
                                    //   ),
                                    // if (item.minMRP != null &&
                                    //     item.maxMRP != null)
                                    //   _buildSpacerRow(),
                                    if (showSizes && item.sizeName.isNotEmpty)
                                      TableRow(
                                        children: [
                                          _buildLabelText('Size'),
                                          const Text(':'),
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Text(
                                              item.sizeWithMrp,
                                              style: _valueTextStyle(
                                                isLargeScreen,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (showSizes && item.sizeName.isNotEmpty)
                                      _buildSpacerRow(),
                                    if (showProduct)
                                      TableRow(
                                        children: [
                                          _buildLabelText('Product'),
                                          const Text(':'),
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Text(
                                              item.itemName,
                                              style: _valueTextStyle(
                                                isLargeScreen,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              if (!isAdded && selectedItems.length <= 1)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 6.0,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                              AppColors.primaryColor,
                                            ),
                                        shape: MaterialStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      onPressed:
                                          () => _showBookingDialog(
                                            context,
                                            item,
                                            type!,
                                          ),
                                      child: Text(
                                        isEdit ? 'Add more' : 'BOOK NOW',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isLargeScreen ? 14 : 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (isAdded)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 6.0,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                              Colors.green,
                                            ),
                                        shape: MaterialStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      onPressed: null,
                                      child: Text(
                                        'Added',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isLargeScreen ? 14 : 12,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: AppColors.primaryColor,
                          size: isLargeScreen ? 24 : 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedView(bool isLargeScreen) {
    final filteredItems = _getFilteredItems();
    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredItems.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredItems.length && isLoadingMore) {
          return Center(child: CircularProgressIndicator());
        }
        final item = catalogItems[index];
        final isSelected = selectedItems.contains(item);
        final cartModel = Provider.of<CartModel>(context);
        final isAdded = cartModel.addedItems.contains(item.styleCode);

        return GestureDetector(
          onTap: () => _toggleItemSelection(item),
          child: Card(
            elevation: isSelected ? 8 : 4,
            margin: EdgeInsets.symmetric(
              vertical: 8,
              horizontal: isLargeScreen ? 16 : 8,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(0),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final maxImageHeight = constraints.maxWidth * 1.2;
                          final imageUrls = _getImageUrls(item);
                          final ValueNotifier<int> currentImageIndex =
                              ValueNotifier<int>(0);

                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: maxImageHeight,
                              minHeight: constraints.maxWidth,
                            ),
                            child:
                                imageUrls.isNotEmpty && imageUrls[0].isNotEmpty
                                    ? // Replace the current Stack with:
                                    Stack(
                                      children: [
                                        GestureDetector(
                                          onDoubleTap:
                                              () => _openImageZoom(imageUrls),
                                          child: SizedBox(
                                            height: maxImageHeight,
                                            width: double.infinity,
                                            child: PageView.builder(
                                              itemCount: imageUrls.length,
                                              onPageChanged: (index) {
                                                currentImageIndex.value = index;
                                              },
                                              itemBuilder: (context, index) {
                                                return _buildSingleImage(
                                                  imageUrls[index],
                                                  maxImageHeight,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        if (imageUrls.length > 1)
                                          Positioned(
                                            bottom: 8,
                                            left: 0,
                                            right: 0,
                                            child: ValueListenableBuilder<int>(
                                              valueListenable:
                                                  currentImageIndex,
                                              builder: (context, index, child) {
                                                return DotIndicator(
                                                  count: imageUrls.length,
                                                  currentIndex: index,
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    )
                                    : _buildSingleImage('', maxImageHeight),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
                      child: Table(
                        columnWidths: const {
                          0: IntrinsicColumnWidth(),
                          1: FixedColumnWidth(8),
                          2: FlexColumnWidth(),
                        },
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: [
                          TableRow(
                            children: [
                              _buildLabelText('Design'),
                              const Text(':'),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  item.styleCodeWithcount,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isLargeScreen ? 20 : 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          _buildSpacerRow(),
                          TableRow(
                            children: [
                              _buildLabelText('MRP'),
                              const Text(':'),
                              Text(
                                item.mrp.toStringAsFixed(2),
                                style: _valueTextStyle(isLargeScreen),
                              ),
                            ],
                          ),
                          _buildSpacerRow(),
                          if (item.minMRP != null && item.maxMRP != null)
                            TableRow(
                              children: [
                                _buildLabelText('Range'),
                                const Text(':'),
                                Text(
                                  '${item.minMRP} - ${item.maxMRP}',
                                  style: _valueTextStyle(isLargeScreen),
                                ),
                              ],
                            ),
                          if (item.minMRP != null && item.maxMRP != null)
                            _buildSpacerRow(),
                          if (showSizes && item.sizeName.isNotEmpty)
                            TableRow(
                              children: [
                                _buildLabelText('Size'),
                                const Text(':'),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    item.sizeWithMrp,
                                    style: _valueTextStyle(isLargeScreen),
                                  ),
                                ),
                              ],
                            ),
                          if (showSizes && item.sizeName.isNotEmpty)
                            _buildSpacerRow(),
                          if (showProduct)
                            TableRow(
                              children: [
                                _buildLabelText('Product'),
                                const Text(':'),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    item.itemName,
                                    style: _valueTextStyle(isLargeScreen),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (!isAdded && selectedItems.length <= 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 6.0,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(
                                AppColors.primaryColor,
                              ),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            onPressed:
                                () => _showBookingDialog(context, item, type!),
                            child: Text(
                              isEdit ? 'Add more' : 'BOOK NOW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isLargeScreen ? 14 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (isAdded)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 6.0,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(
                                Colors.green,
                              ),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            onPressed: null,
                            child: Text(
                              'Added',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isLargeScreen ? 14 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: AppColors.primaryColor,
                        size: isLargeScreen ? 24 : 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemCard(Catalog item, bool isLargeScreen) {
    final isSelected = selectedItems.contains(item);
    final cartModel = Provider.of<CartModel>(context);
    final isAdded = cartModel.addedItems.contains(item.styleCode);

    return Card(
      elevation: isSelected ? 8 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(0),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxImageHeight = constraints.maxWidth * 1.2;
                    final imageUrls = _getImageUrls(item);
                    final ValueNotifier<int> currentImageIndex =
                        ValueNotifier<int>(0);

                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxImageHeight),
                      child:
                          imageUrls.isNotEmpty && imageUrls[0].isNotEmpty
                              ? // Replace the current Stack with:
                              Stack(
                                children: [
                                  GestureDetector(
                                    onDoubleTap:
                                        () => _openImageZoom(imageUrls),
                                    child: SizedBox(
                                      height: maxImageHeight,
                                      width: double.infinity,
                                      child: PageView.builder(
                                        itemCount: imageUrls.length,
                                        onPageChanged: (index) {
                                          currentImageIndex.value = index;
                                        },
                                        itemBuilder: (context, index) {
                                          return _buildSingleImage(
                                            imageUrls[index],
                                            maxImageHeight,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  if (imageUrls.length > 1)
                                    Positioned(
                                      bottom: 8,
                                      left: 0,
                                      right: 0,
                                      child: ValueListenableBuilder<int>(
                                        valueListenable: currentImageIndex,
                                        builder: (context, index, child) {
                                          return DotIndicator(
                                            count: imageUrls.length,
                                            currentIndex: index,
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              )
                              : _buildSingleImage('', maxImageHeight),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
                child: Table(
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: FixedColumnWidth(8),
                    2: FlexColumnWidth(),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      children: [
                        _buildLabelText('Design'),
                        const Text(':'),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            item.styleCodeWithcount,
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: isLargeScreen ? 20 : 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    _buildSpacerRow(),
                    TableRow(
                      children: [
                        _buildLabelText('MRP'),
                        const Text(':'),
                        Text(
                          item.mrp.toStringAsFixed(2),
                          style: _valueTextStyle(isLargeScreen),
                        ),
                      ],
                    ),
                    _buildSpacerRow(),
                    // if (item.minMRP != null && item.maxMRP != null)
                    //   TableRow(
                    //     children: [
                    //       _buildLabelText('Range'),
                    //       const Text(':'),
                    //       Text(
                    //         '${item.minMRP} - ${item.maxMRP}',
                    //         style: _valueTextStyle(isLargeScreen),
                    //       ),
                    //     ],
                    //   ),
                    // if (item.minMRP != null && item.maxMRP != null)
                    //   _buildSpacerRow(),
                    if (showSizes && item.sizeName.isNotEmpty)
                      TableRow(
                        children: [
                          _buildLabelText('Size'),
                          const Text(':'),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              item.sizeWithMrp,
                              style: _valueTextStyle(isLargeScreen),
                            ),
                          ),
                        ],
                      ),
                    if (showSizes && item.sizeName.isNotEmpty)
                      _buildSpacerRow(),
                    if (showProduct)
                      TableRow(
                        children: [
                          _buildLabelText('Product'),
                          const Text(':'),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              item.itemName,
                              style: _valueTextStyle(isLargeScreen),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (!isAdded && selectedItems.length <= 1)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 6.0,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          AppColors.primaryColor,
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      onPressed: () => _showBookingDialog(context, item, type!),
                      child: Text(
                        isEdit ? 'Add more' : 'BOOK NOW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isLargeScreen ? 14 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              if (isAdded)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 6.0,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.green),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      onPressed: null,
                      child: Text(
                        'Added',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isLargeScreen ? 14 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.primaryColor,
                  size: isLargeScreen ? 24 : 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabelText(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          fontSize: 14,
        ),
      ),
    );
  }

  TextStyle _valueTextStyle(bool isLargeScreen) {
    return TextStyle(
      color: Colors.grey[800],
      fontSize: isLargeScreen ? 14 : 13,
    );
  }

  TableRow _buildSpacerRow() {
    return const TableRow(
      children: [SizedBox(height: 8), SizedBox(height: 8), SizedBox(height: 8)],
    );
  }

  Widget _buildBottomButtons(bool isLargeScreen) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLargeScreen ? 24 : 12,
          vertical: 5,
        ),
        child:
            isLargeScreen
                ? Row(children: _buildButtonChildren(isLargeScreen))
                : Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildButtonChildren(isLargeScreen),
                ),
      ),
    );
  }

  List<Widget> _buildButtonChildren(bool isLargeScreen) {
    final buttonColor = AppColors.primaryColor;

    final unifiedButtonGroup = Container(
      height: 44,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [
            buttonColor, // Primary color
            buttonColor.withOpacity(0.8), // Lighter version
            buttonColor.withOpacity(0.9), // Slightly darker
          ],
          stops: const [0.0, 0.6, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.black.withOpacity(0.3), // Dark border with opacity
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          9,
        ), // Slightly smaller to show border
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final currentArgs = ModalRoute.of(context)?.settings.arguments;
              Widget screen;

              if (AppConstants.bookingType == "1") {
                print('nav to typ 1');
                screen = MultiCatalogBookingPage(
                  catalogs: selectedItems,
                  routeArguments: currentArgs as Map<String, dynamic>?,
                  onSuccess: () {
                    setState(() {
                      selectedItems.clear();
                    });
                    _fetchCartCount();
                    Provider.of<CartModel>(
                      context,
                      listen: false,
                    ).refreshAddedItems();
                  },
                );
              } else if (AppConstants.bookingType == "2") {
                print("nav to typ 2");
                screen = CreateOrderScreen(
                  catalogs: selectedItems,
                  routeArguments: currentArgs as Map<String, dynamic>?,
                  onSuccess: () {
                    setState(() {
                      selectedItems.clear();
                    });
                    _fetchCartCount();
                    Provider.of<CartModel>(
                      context,
                      listen: false,
                    ).refreshAddedItems();
                  },
                );
              } else {
                print("nav to typ default");
                screen = CreateOrderScreen3(
                  catalogs: selectedItems,
                  onSuccess: () {
                    setState(() {
                      selectedItems.clear();
                    });
                    _fetchCartCount();
                    Provider.of<CartModel>(
                      context,
                      listen: false,
                    ).refreshAddedItems();
                  },
                );
              }
              print("navigating");
              print(
                "Navigating to CreateOrderScreen from: ${ModalRoute.of(context)?.settings.name ?? 'anonymous route'}",
              );

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => screen),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEdit ? Icons.add_circle : Icons.shopping_cart,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEdit ? 'ADD MORE' : 'BOOK NOW',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return [
      if (selectedItems.isNotEmpty)
        isLargeScreen
            ? Expanded(child: unifiedButtonGroup)
            : unifiedButtonGroup,
    ];
  }

  List<String> _getImageUrls(Catalog catalog) {
    final shadeImages = catalog.shadeImages ?? '';
    final fullImagePath = catalog.fullImagePath ?? '';

    List<String> imageUrls = [];

    // Add full image path first
    if (fullImagePath.isNotEmpty) {
      if (UserSession.onlineImage == '1') {
        imageUrls.add(fullImagePath);
      } else {
        final fileName =
            fullImagePath.split('/').last.split('\\').last.split('?').first;
        if (fileName.isNotEmpty) {
          imageUrls.add('${AppConstants.BASE_URL}/images/$fileName');
        }
      }
    }

    // Add shade images if imageDependsOn == 'S'
    if (UserSession.imageDependsOn == 'S' && shadeImages.isNotEmpty) {
      final imageEntries =
          shadeImages.split(',').map((entry) => entry.trim()).toList();

      for (var entry in imageEntries) {
        final parts = entry.split(':');
        if (parts.length < 2) continue;

        final path = parts.sublist(1).join(':').trim();
        if (path.isEmpty) continue;

        final fileName = path.split('/').last.split('\\').last;
        if (fileName.isEmpty) continue;

        if (UserSession.onlineImage == '1') {
          imageUrls.add(
            path.startsWith('http')
                ? path
                : '${AppConstants.BASE_URL}/images/$fileName',
          );
        } else {
          imageUrls.add('${AppConstants.BASE_URL}/images/$fileName');
        }
      }
    }

    // If no images, return placeholder
    if (imageUrls.isEmpty) {
      return [''];
    }

    return imageUrls;
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (selectedStyles.isNotEmpty) count++;
    if (selectedShades.isNotEmpty) count++;
    if (selectedSize.isNotEmpty) count++;
    if (selectedBrands.isNotEmpty) count++;
    if (fromMRP.isNotEmpty || toMRP.isNotEmpty) count++;
    if (WSPfrom.isNotEmpty || WSPto.isNotEmpty) count++;
    if (fromDate.isNotEmpty || toDate.isNotEmpty) count++;
    if (sortBy != null && sortBy!.isNotEmpty) count++;
    if (stockFilter != null && stockFilter!.isNotEmpty && stockFilter != '')
      count++;
    if (imageFilter != null && imageFilter!.isNotEmpty && imageFilter != 'All')
      count++;
    return count;
  }

  void _showFilterDialog() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FilterPage(),
        settings: RouteSettings(
          arguments: {
            'itemKey': itemKey,
            'itemSubGrpKey': itemSubGrpKey,
            'coBr': coBr,
            'fcYrId': fcYrId,
            'styles': styles,
            'shades': shades,
            'sizes': sizes,
            'selectedShades': selectedShades,
            'selectedSizes': selectedSize,
            'selectedStyles': selectedStyles,
            'selectedBrands': selectedBrands,
            'fromMRP': fromMRP,
            'toMRP': toMRP,
            'WSPfrom': WSPfrom,
            'WSPto': WSPto,
            'sortBy': sortBy,
            'fromDate': fromDate,
            'toDate': toDate,
            'brands': brands,
            'stockFilter': stockFilter,
            'imageFilter': imageFilter,
          },
        ),
        transitionDuration: Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: animation,
            alignment: Alignment.bottomRight,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );

    if (result != null) {
      setState(() {
        selectedStyles = result['styles'] ?? [];
        selectedSize = result['sizes'] ?? [];
        selectedShades = result['shades'] ?? [];
        selectedBrands = result['brands'] ?? [];
        fromMRP = result['fromMRP'] ?? "";
        toMRP = result['toMRP'] ?? "";
        WSPfrom = result['WSPfrom'] ?? "";
        WSPto = result['WSPto'] ?? "";
        sortBy = result['sortBy'];
        fromDate = result['fromDate'] ?? "";
        toDate = result['toDate'] ?? "";
        stockFilter = result['stockFilter'];
        imageFilter = result['imageFilter'];

        // Reset pagination
        pageNo = 1;
        catalogItems.clear();
        hasMore = true;
      });

      _fetchCatalogItems();
    }
  }
  // void _showBookingDialog(BuildContext context, Catalog item, String typee) {
  //   debugPrint(typee);
  //   showDialog(
  //     context: context,
  //     builder:
  //         (context) => Dialog(
  //           insetPadding: EdgeInsets.all(16),
  //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
  //           child: CatalogBookingTable(
  //             itemSubGrpKey: item.itemSubGrpKey.toString(),
  //             itemKey: item.itemKey.toString(),
  //             styleKey: item.styleKey.toString(),
  //             isEdit: isEdit,
  //             markDwn: selectedParty?.splMkDown ?? 0.00,
  //             type: typee,
  //             onSuccess: () {
  //               if (!isEdit) {
  //                 Provider.of<CartModel>(
  //                   context,
  //                   listen: false,
  //                 ).addItem(item.styleCode);
  //                 _fetchCartCount();
  //               }
  //             },
  //           ),
  //         ),
  //   );
  // }

  void _showBookingDialog(BuildContext context, Catalog item, String typee) {
    debugPrint(typee);
    final currentArgs = ModalRoute.of(context)?.settings.arguments;
    // Close any existing dialogs first
    // Navigator.of(context).pop();

    // Determine which screen to show based on bookingType
    Widget screen;

    if (AppConstants.bookingType == "1") {
      // For bookingType "1", show MultiCatalogBookingPage with single item
      screen = MultiCatalogBookingPage(
        catalogs: [item],
        routeArguments: currentArgs as Map<String, dynamic>?,
        onSuccess: () {
          if (!mounted) return;

          setState(() {
            selectedItems.remove(item);
          });

          if (!isEdit) {
            Provider.of<CartModel>(
              context,
              listen: false,
            ).addItem(item.styleCode);

            _fetchCartCount();

            Provider.of<CartModel>(context, listen: false).refreshAddedItems();
          }
        },
      );
    } else if (AppConstants.bookingType == "2") {
      // For bookingType "2", show CreateOrderScreen with single item
      screen = CreateOrderScreen(
        catalogs: [item],
        routeArguments: currentArgs as Map<String, dynamic>?,
        onSuccess: () {
          if (!mounted) return;

          setState(() {
            selectedItems.remove(item);
          });

          if (!isEdit) {
            Provider.of<CartModel>(
              context,
              listen: false,
            ).addItem(item.styleCode);

            _fetchCartCount();

            Provider.of<CartModel>(context, listen: false).refreshAddedItems();
          }
        },
      );
    } else {
      // For bookingType "3" or default, show CreateOrderScreen3 with single item
      screen = CreateOrderScreen3(
        catalogs: [item],
        onSuccess: () {
          if (!mounted) return;

          setState(() {
            selectedItems.remove(item);
          });

          if (!isEdit) {
            Provider.of<CartModel>(
              context,
              listen: false,
            ).addItem(item.styleCode);

            _fetchCartCount();

            Provider.of<CartModel>(context, listen: false).refreshAddedItems();
          }
        },
      );
    }

    // Navigate to the appropriate screen
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

Widget _buildToggleRow(String title, bool value, Function(bool) onChanged) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title), 
      Switch(
        value: value, 
        onChanged: onChanged,
        activeColor: AppColors.primaryColor,
        activeTrackColor: AppColors.primaryColor.withOpacity(0.5),
      ),
    ],
  );
}

  Widget _buildSingleImage(String imageUrl, double maxHeight) {
    return SizedBox(
      height: maxHeight,
      width: double.infinity,
      child: Center(
        child:
            imageUrl.isNotEmpty
                ? Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Center(child: Icon(Icons.error)),
                    );
                  },
                )
                : Container(
                  color: Colors.grey.shade300,
                  child: const Center(child: Icon(Icons.image_not_supported)),
                ),
      ),
    );
  }
}
