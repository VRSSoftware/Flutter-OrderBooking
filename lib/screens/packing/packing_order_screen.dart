
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:vrs_erp/OrderBooking/barcode/barcodewidget.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/constants/constants.dart';
import 'package:vrs_erp/dashboard/orderStatus.dart';
import 'package:vrs_erp/models/CartModel.dart';
import 'package:vrs_erp/models/PartyWithSpclMarkDwn.dart';
import 'package:vrs_erp/models/category.dart';
import 'package:vrs_erp/models/item.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/register/register.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/widget/bottom_navbar.dart';
import 'package:vrs_erp/widget/filterdailogwidget.dart';

class PackingBookingScreen extends StatefulWidget {
  @override
  _PackingBookingScreenState createState() => _PackingBookingScreenState();
}

class _PackingBookingScreenState extends State<PackingBookingScreen> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  String? _selectedCategoryKey = '-1';
  String? _selectedCategoryName = 'All';
  String? coBr = UserSession.coBrId ?? '';
  String? fcYrId = UserSession.userFcYr ?? '';
  List<Category> _categories = [];
  List<Item> _items = [];
  List<Item> _allItems = [];
  bool showBarcodeWidget = false;
  bool _isLoadingCategories = true;
  bool _isLoadingItems = false;
  bool hasFiltered = false;

  Set<String> _activeFilters = {'mrp', 'wsp', 'shades', 'stylecode'};

  void _updateFilters(Set<String> newFilters) {
    setState(() {
      _activeFilters = newFilters;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    fetchAllItems();

    if (coBr != null && fcYrId != null) {
      _fetchCartCount();
    }

  }

  // Replace the existing _fetchCartCount method
  Future<void> _fetchCartCount() async {
    try {
      final data = await ApiService.getSalesOrderData(
        coBrId: UserSession.coBrId ?? '',
        userId: UserSession.userName ?? '',
        fcYrId: UserSession.userFcYr ?? '',
        barcode: showBarcodeWidget ? 'true' : 'false',
      );

      final cartModel = Provider.of<CartModel>(context, listen: false);
      cartModel.updateCount(data['cartItemCount'] ?? 0);
    } catch (e) {
      print('Error fetching cart count: $e');
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final items = await ApiService.fetchAllItems();
      setState(() {
        _items = items;
        _allItems = items;
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> fetchAllItems() async {
    try {
      final categories = await ApiService.fetchCategories();
      setState(() {
        _categories = [
          //  Category(itemSubGrpKey: '-1', itemSubGrpName: "ALL"),
          ...categories,
        ];
        _isLoadingCategories = false;
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartModel = Provider.of<CartModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: DrawerScreen(),
      appBar: AppBar(
        title: Text(
          showBarcodeWidget ? 'Barcode' : 'Packing',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 1,
        leading:
            showBarcodeWidget
                ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      showBarcodeWidget = false;
                    });
                  },
                )
                : Builder(
                  builder:
                      (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                ),
        automaticallyImplyLeading: false,
        actions: [
          // Cart Icon for both modes (packing and Barcode)
          IconButton(
            icon: Stack(
              children: [
                const Icon(CupertinoIcons.cart_badge_plus, color: Colors.white),
                if (cartModel.count >= 0)
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
              if (showBarcodeWidget) {
                Navigator.pushNamed(
                  context,
                  '/viewOrderBarcode',
                  arguments: {Constants.barcode: showBarcodeWidget},
                ).then((_) => _fetchCartCount());
              } else {
                Navigator.pushNamed(
                  context,
                  '/viewOrder',
                  arguments: {Constants.barcode: showBarcodeWidget},
                ).then((_) => _fetchCartCount());
              }
            },
          ),

          // Orders icon
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0), // Reduced padding
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Button width: total width minus 16 (padding) minus 8 (gap), divided by 2, increased by 20%
            double buttonWidth = ((constraints.maxWidth - 16 - 8) / 2) * 1;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Checkbox(
                              value: showBarcodeWidget,
                              onChanged: (value) {
                                setState(() {
                                  showBarcodeWidget = value ?? false;
                                  _fetchCartCount();
                                });
                              },
                            ),
                            const Text(
                              "Packing Barcode Wise",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      if (showBarcodeWidget)
                        SizedBox(
                          width: double.infinity,
                          child: BarcodeWiseWidget(
                            onFilterPressed: (barcode) {
                              print("Barcode: $barcode");
                              setState(() {
                                hasFiltered = true;
                              });
                            },
                            // activeFilters: _activeFilters,
                          ),
                        ),
                      if (!showBarcodeWidget) ...[
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: const Text(
                            "Categories",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _isLoadingCategories
                            ? Center(
                              child: LoadingAnimationWidget.waveDots(
                                color: AppColors.primaryColor,
                                size: 30,
                              ),
                            )
                            : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Wrap(
                                spacing: 8, // Reduced gap between buttons
                                runSpacing: 10,
                                alignment: WrapAlignment.start,
                                children:
                                    _categories.map((category) {
                                      return SizedBox(
                                        width: buttonWidth, // Increased width
                                        child: OutlinedButton(
                                          onPressed: () {
                                            setState(() {
                                              // _selectedCategoryKey = category.itemSubGrpKey;
                                              // _selectedCategoryName = category.itemSubGrpName;
                                              // if (_selectedCategoryKey == '-1') {
                                              //   _items = _allItems;
                                              // } else {
                                              //   _items = _allItems
                                              //       .where(
                                              //         (item) => item.itemSubGrpKey == _selectedCategoryKey,
                                              //       )
                                              //       .toList();
                                              // }
                                            });
                                            Navigator.pushNamed(
                                              context,
                                              '/orderpage',
                                              arguments: {
                                                'itemKey': null,
                                                'itemSubGrpKey':
                                                    category.itemSubGrpKey,
                                                'itemName':
                                                    category.itemSubGrpName
                                                        .trim(),
                                                'coBr': coBr,
                                                'fcYrId': fcYrId,
                                                'type': Constants.PACKING,
                                                Constants.TRANSACTION_TYPE : Constants.PACKING
                                              },
                                            );
                                          },
                                          style: ButtonStyle(
                                            backgroundColor:
                                                WidgetStateProperty.all(
                                                  _selectedCategoryKey ==
                                                          category.itemSubGrpKey
                                                      ? AppColors.primaryColor
                                                      : Colors.white,
                                                ),
                                            side: WidgetStateProperty.all(
                                              BorderSide(
                                                color: AppColors.primaryColor,
                                                width: 1,
                                              ),
                                            ),
                                            shape: WidgetStateProperty.all(
                                              RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(0),
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            category.itemSubGrpName,
                                            textAlign:
                                                TextAlign.center, // Center text
                                            style: TextStyle(
                                              color:
                                                  _selectedCategoryKey ==
                                                          category.itemSubGrpKey
                                                      ? Colors.white
                                                      : AppColors.primaryColor,
                                              fontSize:
                                                  14, // Consistent font size
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                        const SizedBox(height: 20),
                        if (_selectedCategoryKey != null)
                          _buildCategoryItems(buttonWidth),
                      ],
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationWidget(currentScreen:  '/orderbooking',),
    );
  }

  Widget _buildCategoryItems(double buttonWidth) {
    double buttonHeight = 43;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            "Items in $_selectedCategoryName",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 10),
        _isLoadingItems
            ? Center(
              child: LoadingAnimationWidget.waveDots(
                color: AppColors.primaryColor,
                size: 30,
              ),
            )
            : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Wrap(
                spacing: 8, // Reduced gap between buttons
                runSpacing: 10,
                alignment: WrapAlignment.start,
                children:
                    _items.map((item) {
                      return SizedBox(
                        width: buttonWidth, // Increased width
                        height: buttonHeight,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                          ),
                          onPressed: () {
                            debugPrint(item.itemKey);
                            debugPrint(item.itemSubGrpKey);
                            Navigator.pushNamed(   
                              context,
                              '/orderpage',
                              arguments: {
                                'itemKey': item.itemKey,
                                'itemName': item.itemName.trim(),
                                'itemSubGrpKey': item.itemSubGrpKey,
                                'coBr': coBr,
                                'fcYrId': fcYrId,
                                'type': Constants.PACKING,
                                Constants.TRANSACTION_TYPE : Constants.PACKING
                              }, 
                            ).then((_) => _fetchCartCount());
                          },
                          child: Text(
                            item.itemName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
      ],
    );
  }
}