import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:vrs_erp/OrderBooking/booking2/booking2.dart';
import 'package:vrs_erp/OrderBooking/booking2/booking3.dart';
import 'package:vrs_erp/OrderBooking/booking2/multipleorderbooking.dart';
import 'package:vrs_erp/catalog/filter.dart';
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
  final String? name;

    const OrderPage({Key? key, this.name}) : super(key: key);

  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  int viewOption = 0;
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args != null) {
        setState(() {
          itemKey = args['itemKey']?.toString();
          itemSubGrpKey = args['itemSubGrpKey']?.toString();
          coBr = UserSession.coBrId;
          fcYrId = UserSession.userFcYr;
          itemNamee = args['itemName']?.toString() ?? '';
          isEdit = args['edit'] ?? false;
          selectedParty = args['selectedParty'];
          type = args['type'];
          transactionType = args[Constants.TRANSACTION_TYPE];
        });

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
    });
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
          toTitleCase(itemNamee ?? ''),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          isEdit
              ? Container()
              : IconButton(
                icon: Stack(
                  children: [
                    const Icon(
                      CupertinoIcons.cart_badge_plus,
                      color: Colors.white,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '${cartModel.count}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/viewOrder',
                    arguments: {'mrkDown': selectedParty?.splMkDown ?? 0.00},
                  );
                  _fetchCartCount();
                },
              ),
          IconButton(
            icon: Icon(
              viewOption == 0
                  ? Icons.grid_on
                  : viewOption == 1
                  ? Icons.view_list
                  : Icons.expand,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                viewOption = (viewOption + 1) % 3;
              });
            },
          ),
          Builder(
            builder:
                (context) => IconButton(
                  icon: Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(
                              MediaQuery.of(context).size.width > 600
                                  ? 24.0
                                  : 16.0,
                            ),
                            child: StatefulBuilder(
                              builder: (context, setStateDialog) {
                                return SingleChildScrollView(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width >
                                                  600
                                              ? 600
                                              : 440,
                                      minWidth: 320,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Options",
                                          style: TextStyle(
                                            fontSize:
                                                MediaQuery.of(
                                                          context,
                                                        ).size.width >
                                                        600
                                                    ? 22
                                                    : 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            final isWide =
                                                constraints.maxWidth > 400;
                                            return isWide
                                                ? Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        children: [
                                                          _buildToggleRow(
                                                            "Show Product",
                                                            showProduct,
                                                            (val) {
                                                              showProduct = val;
                                                              setStateDialog(
                                                                () {},
                                                              );
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
                                                            showSizes,
                                                            (val) {
                                                              showSizes = val;
                                                              setStateDialog(
                                                                () {},
                                                              );
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
                                                      showSizes,
                                                      (val) {
                                                        showSizes = val;
                                                        setStateDialog(() {});
                                                      },
                                                    ),
                                                    _buildToggleRow(
                                                      "Show Product",
                                                      showProduct,
                                                      (val) {
                                                        showProduct = val;
                                                        setStateDialog(() {});
                                                      },
                                                    ),
                                                  ],
                                                );
                                          },
                                        ),
                                        const SizedBox(height: 20),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed:
                                                () =>
                                                    Navigator.of(context).pop(),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16.0,
                                                  ),
                                              child: Text(
                                                "Close",
                                                style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(
                                                                context,
                                                              ).size.width >
                                                              600
                                                          ? 18
                                                          : 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
      body: Column(
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
                              return _buildListView(constraints, isLargeScreen);
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: FloatingActionButton(
          onPressed: _showFilterDialog,
          backgroundColor: AppColors.primaryColor,
          child: const Icon(Icons.filter_alt_outlined, color: Colors.white),
          tooltip: 'Filter',
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
                borderRadius: BorderRadius.circular(0),
              ),
              color: isSelected ? Colors.blue.shade50 : Colors.white,
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(isLargeScreen ? 12.0 : 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          flex: 2,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(0),
                              topRight: Radius.circular(0),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final maxImageHeight =
                                    constraints.maxWidth * 1.2;
                                return ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: maxImageHeight,
                                  ),
                                  child: SizedBox(
                                    height: maxImageHeight,
                                    width: double.infinity,
                                    child: Center(
                                      child: Image.network(
                                        _getImageUrl(item),
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            color: Colors.grey.shade300,
                                            child: const Center(
                                              child: Icon(Icons.error),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
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
                                              0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      onPressed:
                                          () =>
                                              _showBookingDialog(context, item, type!),
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
                                              0,
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
              borderRadius: BorderRadius.circular(0),
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
                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: maxImageHeight,
                              minHeight: constraints.maxWidth,
                            ),
                            child: Image.network(
                              _getImageUrl(item),
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade300,
                                  child: const Center(child: Icon(Icons.error)),
                                );
                              },
                            ),
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
                                  borderRadius: BorderRadius.circular(0),
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
                              backgroundColor: MaterialStateProperty.all(
                                Colors.green,
                              ),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(0),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
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
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxImageHeight),
                      child: SizedBox(
                        height: maxImageHeight,
                        width: double.infinity,
                        child: Center(
                          child: Image.network(
                            _getImageUrl(item),
                            fit: BoxFit.contain,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade300,
                                child: const Center(child: Icon(Icons.error)),
                              );
                            },
                          ),
                        ),
                      ),
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
                            borderRadius: BorderRadius.circular(0),
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
                        backgroundColor: WidgetStateProperty.all(
                          Colors.green,
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
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
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: buttonColor, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: buttonColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => MultiCatalogBookingPage(
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
                          ),
                    ),
                  ),
              child: Text(isEdit ? 'Add more' : 'BOOK NOW'),
            ),
          ),
          Container(height: 42, width: 2, color: buttonColor),
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: buttonColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => CreateOrderScreen(
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
                          ),
                    ),
                  ),
              child: const Icon(Icons.shopping_cart),
            ),
          ),
          Container(height: 42, width: 2, color: buttonColor),
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: buttonColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => CreateOrderScreen3(
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
                          ),
                    ),
                  ),
              child: const Icon(Icons.assignment),
            ),
          ),
        ],
      ),
    );

    return [
      if (selectedItems.isNotEmpty)
        isLargeScreen
            ? Expanded(child: unifiedButtonGroup)
            : unifiedButtonGroup,
    ];
  }

  String _getImageUrl(Catalog catalog) {
    if (UserSession.onlineImage == '0') {
      final imagePath = catalog.fullImagePath ?? '';
      final imageName = imagePath.split('/').last.split('?').first;
      if (imageName.isEmpty) {
        return '';
      }
      return '${AppConstants.BASE_URL}/images/$imageName';
    } else if (UserSession.onlineImage == '1') {
      return catalog.fullImagePath ?? '';
    }
    return '';
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
            'fromMRP': fromMRP,
            'toMRP': toMRP,
            'WSPfrom': WSPfrom,
            'WSPto': WSPto,
            'sortBy': sortBy,
            'fromDate': fromDate,
            'toDate': toDate,
            'brands': brands.isEmpty ? [] : brands,
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
      Map<String, dynamic> selectedFilters = result;
      setState(() {
        selectedStyles = selectedFilters['styles'];
        selectedSize = selectedFilters['sizes'];
        selectedShades = selectedFilters['shades'];
        fromMRP = selectedFilters['fromMRP'];
        toMRP = selectedFilters['toMRP'];
        WSPfrom = selectedFilters['WSPfrom'];
        WSPto = selectedFilters['WSPto'];
        sortBy = selectedFilters['sortBy'];
        fromDate = selectedFilters['fromDate'];
        toDate = selectedFilters['toDate'];
        pageNo = 1;
        hasMore = true;
        catalogItems.clear();
        selectedItems.clear();
      });
      _fetchCatalogItems();
    }
  }

  void _showBookingDialog(BuildContext context, Catalog item, String typee) {
    debugPrint(typee);
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: CatalogBookingTable(
              itemSubGrpKey: item.itemSubGrpKey.toString(),
              itemKey: item.itemKey.toString(),
              styleKey: item.styleKey.toString(),
              isEdit: isEdit,
              markDwn: selectedParty?.splMkDown ?? 0.00,
              type: typee,
              onSuccess: () {
                if (!isEdit) {
                  Provider.of<CartModel>(
                    context,
                    listen: false,
                  ).addItem(item.styleCode);
                  _fetchCartCount();
                }
              },
            ),
          ),
    );
  }

  Widget _buildToggleRow(String title, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(title), Switch(value: value, onChanged: onChanged)],
    );
  }
}
